# Deterministic Sovereign RAG via Signed-Hash Projection

> Formalization of FNV-1a 64-bit + L₂ spherical projection at D=128 for
> reproducible retrieval on sovereign cloud infrastructure.

| | |
|---|---|
| **Author** | David Mireles |
| **ORCID** | [0009-0008-4374-2254](https://orcid.org/0009-0008-4374-2254) |
| **Contact** | research@loust.pro |
| **Venue** | arXiv (cs.IR + cs.DS) |
| **Status** | Pre-submission draft, June 23 2026 |
| **License** | Apache-2.0 |
| **Canonical** | https://github.com/LOUST-PRO/deterministic-sovereign-rag |

## What this paper formalizes

A four-formula pipeline for deterministic, sub-millisecond retrieval over
sovereign cloud corpora:

1. **FNV-1a 64-bit feature hashing** into a fixed D=128 vector.
2. **Sign-flipping cancellation** to eliminate embedding drift across
   re-indexes (signed-hash projection).
3. **L₂ spherical normalization** to unit length on the 128-sphere.
4. **Cosine similarity** for top-k retrieval, with formal bounds from
   the Johnson-Lindenstrauss lemma and Chernoff concentration.

The architecture is reproducible end-to-end: the same corpus hashes to
the same vectors on the same substrate, with bit-identical output. No
external embedding model. No GPU dependency. No SaaS.

## Repository layout

```
deterministic-sovereign-rag/
├── README.md              # this file
├── LICENSE                # Apache-2.0
├── CITATION.cff           # machine-readable citation
├── paper/
│   ├── deterministic-sovereign-rag.tex   # canonical LaTeX master
│   ├── f80-references.bib    # BibTeX
│   ├── ieee_arxiv.sty        # IEEEtran-style arXiv preamble
│   ├── sections/             # 8 modular subfiles (\input{})
│   └── figures/              # 10 TikZ source + baked PDFs
├── verification/
│   ├── f80-build.sh          # reproducible 4-pass compile
│   ├── arxiv-allowlist.txt   # 24 paths, binding
│   └── anonymization-lexicon.md   # public-safe IP-boundary summary
├── docs/                    # submission plan, related work, review log
├── companion/               # reproduction notes (pseudocode pointers)
└── .github/workflows/
    └── build-paper.yml      # CI: paper compiles + figures OK
```

## How to build the paper

```bash
cd verification
bash f80-build.sh           # 8-stage validation + 4-pass compile
```

The build script enforces the IP boundary: any content matching the
`anonymization-lexicon.md` patterns is rejected before compilation.
The arXiv allowlist restricts the tarball to the 24 paths in
`verification/arxiv-allowlist.txt` — nothing else ships.

## How to cite

```bibtex
@misc{mireles2026deterministic,
  author       = {David Mireles},
  title        = {Deterministic Sovereign RAG via Signed-Hash Projection:
                  An Operator-Stack Formalization of FNV-1a 64-bit +
                  L\textsubscript{2} Spherical Projection at D=128 for
                  Reproducible Retrieval on Sovereign Cloud Infrastructure},
  year         = {2026},
  month        = jun,
  howpublished = {arXiv preprint cs.IR / cs.DS},
  note         = {ORCID: 0009-0008-4374-2254},
  url          = {https://github.com/LOUST-PRO/deterministic-sovereign-rag}
}
```

## Companion artifacts

The paper's formalization is implemented in production at the
companion repository
[`LOUST-PRO/dsvh-verification-suite`](https://github.com/LOUST-PRO/dsvh-verification-suite).
That implementation provides the reference reproducer for the
mathematical claims in §3 (preliminaries) and §8 (DET keep-alive).

The gap between the formalization (cosine) and the production runtime
(Jaccard) is documented in §12 of the paper (Adversarial: When NOT
to Use DET).

## Submission status

- **arXiv submission**: pending. The submission gate requires the
  operator's approval (per the operator's local-first policy).
- **Endorsement**: required per arXiv policy for first-time submitters.
  Plan documented in `docs/submission-plan.md` (forthcoming).
- **Zenodo DOI**: a Concept DOI will be reserved after the first
  arXiv publication, and the manuscript will be updated to reference
  the canonical citation identifier.
- **ORCID linkage**: public record at
  https://orcid.org/0009-0008-4374-2254.

## License

Apache-2.0. See [LICENSE](LICENSE).
