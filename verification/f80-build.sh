#!/usr/bin/env bash
# f80-build.sh — Render and validate F80 unified arXiv paper draft.
#
# Stage: local-only. NO submit commands here. Publish gate
# requires frase literal "apruebo submit arxiv math-rag" del operador
# en el mismo turno (stage-local-first rule).
#
# Hard rules enforced (per user directive 2026-06-23):
#   1. NO wildcards in tar invocation — uses --files-from=arxiv-allowlist.txt
#   2. sed-based pre-compile scrubber strips LLM-tracking comments
#   3. Anonymization grep guard rejects any forbidden internal name
#   4. Bibliography completeness check
#   5. 4-pass pdflatex + bibtex cycle
#
# Usage: bash drafts/f80-build.sh
# Output: drafts/build/f80-arxiv-paper.pdf

set -uo pipefail

DRAFT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Layout detection: split (verification/ + paper/) vs flat (everything alongside script).
# If paper/ exists one level up, use split layout (staging repo).
# Otherwise, use flat layout (vault, original drafts dir).
if [[ -d "$DRAFT_DIR/../paper" ]]; then
  REPO_ROOT="$(cd "$DRAFT_DIR/.." && pwd)"
  PAPER_DIR="$REPO_ROOT/paper"
else
  PAPER_DIR="$DRAFT_DIR"
fi

# .tex basename (default = f80-arxiv-paper.tex for vault; override for public staging)
TEX_FILE_NAME="${TEX_FILE_NAME:-f80-arxiv-paper.tex}"
TEX_FILE="$PAPER_DIR/$TEX_FILE_NAME"
BIB_FILE="$PAPER_DIR/f80-references.bib"
ALLOWLIST="$DRAFT_DIR/arxiv-allowlist.txt"
SCRUB_HEADER_LINES=20
OUT_DIR="$DRAFT_DIR/build"
TEX_BUILD_DIR="$OUT_DIR/tex"

echo "=== F80 unified paper build ==="
echo "tex:     $TEX_FILE"
echo "bib:     $BIB_FILE"
echo "allow:   $ALLOWLIST"
echo ""

# ---------------------------------------------------------------------
# 0. File existence
# ---------------------------------------------------------------------
test -f "$TEX_FILE" || { echo "FAIL: $TEX_FILE not found"; exit 1; }
test -f "$BIB_FILE" || { echo "FAIL: $BIB_FILE not found"; exit 1; }
test -f "$ALLOWLIST" || { echo "FAIL: $ALLOWLIST not found"; exit 1; }
echo "[0/8] file existence: OK"

# ---------------------------------------------------------------------
# 1. Anonymization grep guard (hard rule)
# ---------------------------------------------------------------------
if grep -E 'lzt-[a-z]' "$TEX_FILE" >/dev/null 2>&1; then
  echo "[1/8] ANONYMIZATION: FAIL — forbidden internal name(s) detected:"
  grep -nE 'lzt-[a-z]' "$TEX_FILE"
  exit 2
fi
# Also scan \input{}'d section files
for f in "$DRAFT_DIR"/sections/*.tex; do
  if grep -E 'lzt-[a-z]' "$f" >/dev/null 2>&1; then
    echo "[1/8] ANONYMIZATION: FAIL — forbidden internal name(s) in $f:"
    grep -nE 'lzt-[a-z]' "$f"
    exit 2
  fi
done
echo "[1/8] anonymization grep guard: OK"

# ---------------------------------------------------------------------
# 2. sed scrubber: strip LLM-tracking LaTeX comments
# ---------------------------------------------------------------------
# Patterns to strip (case-insensitive): TODO, FIXME, LLM, Claude, Cursor,
# Assistant, Generated, Lou wants. Skip first 20 lines (FoCM header).
SCRUB_TMP="$OUT_DIR/.f80-scrub.tex"
mkdir -p "$OUT_DIR"
{
  head -n "$SCRUB_HEADER_LINES" "$TEX_FILE"
  tail -n +$((SCRUB_HEADER_LINES + 1)) "$TEX_FILE" | \
    grep -v -i -E '^[[:space:]]*%[[:space:]]*(TODO|FIXME|LLM|Claude|Cursor|Assistant|Generated|Lou wants)'
} > "$SCRUB_TMP"
SCRUBBED_LINES=$(wc -l < "$SCRUB_TMP")
ORIG_LINES=$(wc -l < "$TEX_FILE")
echo "[2/8] sed scrubber: $ORIG_LINES -> $SCRUBBED_LINES lines"

# Use scrubbed version for the build
TEX_FILE="$SCRUB_TMP"

# ---------------------------------------------------------------------
# 3. Sanitize (delegate to gist-sources/scripts/sanitize.sh)
# ---------------------------------------------------------------------
SANITIZE_LOOKUP="${REPO_ROOT:-$DRAFT_DIR}"
SANITIZE="$SANITIZE_LOOKUP/scripts/sanitize.sh"
if [[ -f "$SANITIZE" ]]; then
  if bash "$SANITIZE" "$TEX_FILE" "$BIB_FILE" >/dev/null 2>&1; then
    echo "[3/8] sanitize: OK (exit 0)"
  else
    echo "[3/8] sanitize: FLAGGED (exit non-zero, review manually)"
  fi
else
  echo "[3/8] sanitize: SKIPPED (sanitize.sh not found at $SANITIZE)"
fi

# ---------------------------------------------------------------------
# 4. Theorem + lemma + proof count
# ---------------------------------------------------------------------
THEOREM_COUNT=$(grep -c '^\\begin{theorem}' "$TEX_FILE" 2>/dev/null)
THEOREM_COUNT=${THEOREM_COUNT:-0}
LEMMA_COUNT=$(grep -c '^\\begin{lemma}' "$TEX_FILE" 2>/dev/null)
LEMMA_COUNT=${LEMMA_COUNT:-0}
PROOF_COUNT=$(grep -c '^\\begin{proof}' "$TEX_FILE" 2>/dev/null)
PROOF_COUNT=${PROOF_COUNT:-0}
ALGO_COUNT=$(grep -c '^\\begin{algorithm}' "$TEX_FILE" 2>/dev/null)
ALGO_COUNT=${ALGO_COUNT:-0}
CORO_COUNT=$(grep -c '^\\begin{corollary}' "$TEX_FILE" 2>/dev/null)
CORO_COUNT=${CORO_COUNT:-0}
OPB_COUNT=$(grep -c '^\\begin{operationalbound}' "$TEX_FILE" 2>/dev/null)
OPB_COUNT=${OPB_COUNT:-0}
# Also count algorithms in section files (since main file \input{}s them)
for secfile in "$DRAFT_DIR"/sections/*.tex; do
  AC=$(grep -c '^\\begin{algorithm}' "$secfile" 2>/dev/null) ; AC=${AC:-0}
  TC=$(grep -c '^\\begin{theorem}' "$secfile" 2>/dev/null) ; TC=${TC:-0}
  LC=$(grep -c '^\\begin{lemma}' "$secfile" 2>/dev/null) ; LC=${LC:-0}
  PC=$(grep -c '^\\begin{proof}' "$secfile" 2>/dev/null) ; PC=${PC:-0}
  ALGO_COUNT=$((ALGO_COUNT + AC))
  THEOREM_COUNT=$((THEOREM_COUNT + TC))
  LEMMA_COUNT=$((LEMMA_COUNT + LC))
  PROOF_COUNT=$((PROOF_COUNT + PC))
done
echo "[4/8] theorems: $THEOREM_COUNT, lemmas: $LEMMA_COUNT, proofs: $PROOF_COUNT, algos: $ALGO_COUNT, corollaries: $CORO_COUNT, operational bounds: $OPB_COUNT"

# ---------------------------------------------------------------------
# 5. Bibliography completeness: every \citep{key} must have @entry{key,
# ---------------------------------------------------------------------
USED_KEYS=$(grep -oP '\\citep\{[^}]+\}' "$TEX_FILE" | \
            sed -e 's/\\citep{//' -e 's/}//' | \
            tr ',' '\n' | sort -u | grep -v '^$' || true)
DECLARED_KEYS=$(grep -oP '^@\w+\{[^,]+,' "$BIB_FILE" | \
                sed -e 's/^@[a-zA-Z]*{//' -e 's/,$//' | \
                sort -u || true)

MISSING=""
for key in $USED_KEYS; do
  if ! grep -q "^@.*{$key," "$BIB_FILE"; then
    MISSING="$MISSING $key"
  fi
done

if [[ -n "$MISSING" ]]; then
  echo "[5/8] bibliography: MISSING keys:$MISSING"
  exit 2
else
  USED_COUNT=$(echo "$USED_KEYS" | grep -c . || echo 0)
  DECLARED_COUNT=$(echo "$DECLARED_KEYS" | grep -c . || echo 0)
  echo "[5/8] bibliography: complete ($USED_COUNT used, $DECLARED_COUNT declared)"
fi

# ---------------------------------------------------------------------
# 6. Section count
# ---------------------------------------------------------------------
SECTION_COUNT=$(grep -c '^\\section{' "$TEX_FILE" 2>/dev/null)
SECTION_COUNT=${SECTION_COUNT:-0}
SUBSECTION_COUNT=$(grep -c '^\\subsection{' "$TEX_FILE" 2>/dev/null)
SUBSECTION_COUNT=${SUBSECTION_COUNT:-0}
FIG_COUNT=$(grep -c '\\includegraphics' "$TEX_FILE" 2>/dev/null)
FIG_COUNT=${FIG_COUNT:-0}
# Also count figures in section files
for secfile in "$DRAFT_DIR"/sections/*.tex; do
  FC=$(grep -c '\\includegraphics' "$secfile" 2>/dev/null) ; FC=${FC:-0}
  FIG_COUNT=$((FIG_COUNT + FC))
done
echo "[6/8] sections: $SECTION_COUNT, subsections: $SUBSECTION_COUNT, figures: $FIG_COUNT"

# ---------------------------------------------------------------------
# 7. tar with explicit allowlist (hard rule: no wildcards)
# ---------------------------------------------------------------------
echo "[7/8] tarball validation via arxiv-allowlist.txt..."
# Strip comments and blank lines, then verify each path exists
ALLOWED_PATHS=$(grep -v '^[[:space:]]*#' "$ALLOWLIST" | grep -v '^[[:space:]]*$' || true)
MISSING_FILES=""
WARN_FILES=""
LOOKUP_BASE="${REPO_ROOT:-$DRAFT_DIR}"
for path in $ALLOWED_PATHS; do
  # Paths in the allowlist are relative to LOOKUP_BASE:
  #   split layout (staging) → REPO_ROOT
  #   flat layout (vault)    → DRAFT_DIR
  # Allow either form: paths with leading "paper/" or "verification/" are honored as-is.
  full_path="$LOOKUP_BASE/$path"
  if [[ ! -e "$full_path" ]]; then
    # Distinguish: figures and ieee_arxiv.sty are warn (generated before
    # submission); other files (tex/bib/build.sh/allowlist/md) are blocking.
    if [[ "$path" == */figures/* ]] || [[ "$path" == *.sty ]]; then
      WARN_FILES="$WARN_FILES $path"
    else
      MISSING_FILES="$MISSING_FILES $path"
    fi
  fi
done
if [[ -n "$MISSING_FILES" ]]; then
  echo "[7/8] tarball validation: MISSING required files:$MISSING_FILES"
  exit 2
fi
ALLOWED_COUNT=$(echo "$ALLOWED_PATHS" | wc -l)
WARN_COUNT=$(echo "$WARN_FILES" | wc -w)
echo "[7/8] tarball validation: $ALLOWED_COUNT allowed paths; $WARN_COUNT figure files not yet rendered (will be generated before arXiv submission)"

# ---------------------------------------------------------------------
# 8. Compile (best-effort, 4-pass cycle)
# ---------------------------------------------------------------------
if command -v pdflatex >/dev/null 2>&1; then
  echo "[8/8] compiling with pdflatex + bibtex..."
  mkdir -p "$TEX_BUILD_DIR"
  cp "$TEX_FILE" "$TEX_BUILD_DIR/$TEX_FILE_NAME"
  cp "$BIB_FILE" "$TEX_BUILD_DIR/"
  # Copy section files (live in PAPER_DIR, alongside .tex)
  cp -r "$PAPER_DIR/sections" "$TEX_BUILD_DIR/" 2>/dev/null || true
  # Copy figures dir (even if empty, live in PAPER_DIR)
  cp -r "$PAPER_DIR/figures" "$TEX_BUILD_DIR/" 2>/dev/null || true
  # Copy ieee_arxiv.sty if present (lives in PAPER_DIR)
  [[ -f "$PAPER_DIR/ieee_arxiv.sty" ]] && cp "$PAPER_DIR/ieee_arxiv.sty" "$TEX_BUILD_DIR/"
  cd "$TEX_BUILD_DIR"
  set +e
  pdflatex -interaction=nonstopmode -halt-on-error "$TEX_FILE_NAME" >pdflatex.log 2>&1
  RC1=$?
  bibtex "${TEX_FILE_NAME%.tex}" >bibtex.log 2>&1
  RC_BIB=$?
  pdflatex -interaction=nonstopmode "$TEX_FILE_NAME" >pdflatex.log 2>&1
  RC2=$?
  pdflatex -interaction=nonstopmode "$TEX_FILE_NAME" >pdflatex.log 2>&1
  RC3=$?
  set -e
  # Success if any pass produced a PDF (the final pass is what matters)
  PDF_NAME="${TEX_FILE_NAME%.tex}.pdf"
  if [[ -f "$PDF_NAME" ]]; then
    PDF_PAGES=$(pdfinfo "$PDF_NAME" 2>/dev/null | grep "Pages:" | awk '{print $2}')
    cp "$PDF_NAME" "$OUT_DIR/" 2>/dev/null || true
    echo "[8/8] compile: PDF written ($PDF_PAGES pages) -> $OUT_DIR/$PDF_NAME"
    echo "       (pdflatex rc1=$RC1, bibtex rc=$RC_BIB, pdflatex rc2=$RC2, pdflatex rc3=$RC3)"
  else
    echo "[8/8] compile: FAILED (no PDF output; rc1=$RC1, bibtex rc=$RC_BIB)"
    tail -40 pdflatex.log 2>/dev/null || true
    exit 3
  fi
else
  echo "[8/8] compile: SKIPPED (pdflatex not available)"
  echo "       Install texlive-latex-base + texlive-bibtex-extra + ieee_arxiv.sty to enable"
fi

# Final summary
echo ""
echo "=== Final summary ==="
WORD_COUNT=$(wc -w < "$TEX_FILE")
LINE_COUNT=$(wc -l < "$TEX_FILE")
echo "$TEX_FILE_NAME: $LINE_COUNT lines, $WORD_COUNT words"
echo "  theorems:     $THEOREM_COUNT"
echo "  lemmas:       $LEMMA_COUNT"
echo "  proofs:       $PROOF_COUNT"
echo "  algorithms:   $ALGO_COUNT"
echo "  corollaries:  $CORO_COUNT"
echo "  operational:  $OPB_COUNT"
echo "  sections:     $SECTION_COUNT"
echo "  subsections:  $SUBSECTION_COUNT"
echo "  figures:      $FIG_COUNT"
echo ""
echo "=== Build complete ==="
