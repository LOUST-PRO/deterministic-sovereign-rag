# IP-Boundary Lexicon — Public Summary

> **Status**: Public-safe summary of the IP-boundary contract enforced by
> `verification/f80-build.sh` for the *Deterministic Sovereign RAG* paper
> and all derivative artifacts.
>
> **Scope**: This file documents the public-side pseudonym mapping and
> the rules that govern the public surface. The operator's internal
> inverse mapping (which is needed to apply these rules in the
> operator's private monorepo) lives in the operator's vault and is
> deliberately not shipped here.

## 1. Public-Side Pseudonym Mapping

The paper uses public pseudonyms for the operator's implementation
components. The mapping below is intentionally one-directional: it tells
readers what the public name means, without revealing the private
implementation details of the operator's monorepo.

| Public pseudonym | Role |
|---|---|
| **Asymmetric Prefill Gateway (APG)** | Routing plane (Layer 2) that mediates between the LLM client and the semantic cache, using a keep-alive protocol. |
| **Deterministic Sovereign Vector Heap (DSVH)** | Sub-millisecond retrieval plane (Layer 1) implementing FNV-1a + L₂ + cosine over a fixed-D=128 vector store. |
| **Cold-Cache Edge Benchmark Harness (CCEBH)** | Measurement plane for cold-cache latency, edge-transport behaviour, and zero-trust edge cases. |
| **Sub-Millisecond Retrieval Plane (SRP)** | Layer 1 (synonym for the deterministic FNV-1a + L₂ + cosine plane). |
| **Agentic Reasoning Layer (ARL)** | Layer 3 (autonomous agent plane) that owns corpus ingestion, LLM chunking, and FTS5 indexing. |
| **Reference Implementation (Rademacher Embedder)** | Educational reproducer of the FNV-1a + L₂ + cosine pipeline; not the production binary. |

## 2. Mathematical Symbols (rebound to academic notation)

| Operator notation | Paper notation | Justification |
|---|---|---|
| Internal dynamic-eviction threshold | $\mathcal{H}_{\text{evict}}$ | Stochastic control variable, not a configuration knob. |
| Internal keep-alive probe (zero-prefill) | **Zero-Prefill Keep-Alive Probe** | Concept, not API call. |
| Cache miss indicator | $\mathbf{1}_{\text{miss}}$ | Binary indicator function. |
| Cache hit indicator | $\mathbf{1}_{\text{hit}}$ | Binary indicator function. |
| Idle-delta random variable | $\tau_n$ | Standard index-`n` time-series notation. |
| Hit/miss gamma parameters | $\gamma_{\text{hit}}, \gamma_{\text{miss}}$ | Already in mathematical notation. |
| Cache state indicator | $S_n \in \{0, 1\}$ | Standard. |
| Weibull scale | $\lambda$ | Standard. |
| Weibull shape | $k$ | Standard. |

## 3. High-Level Component Mapping

| Paper-side name | Role |
|---|---|
| **Sub-Millisecond Retrieval Plane (SRP)** | The deterministic FNV-1a plane (Layer 1). |
| **Asymmetric Prefill Gateway (APG)** | The keep-alive routing plane (Layer 2). |
| **Agentic Reasoning Layer (ARL)** | The autonomous agent plane (Layer 3). |

## 4. Anti-Leak Invariants (enforced in `f80-build.sh`)

The build script enforces the following hard rules on the LaTeX source
**before** compilation. Any violation aborts the build with a non-zero
exit code.

1. **No operator-side binary name in any prose.** The build script
   performs a generic-prefix grep over the `.tex` source (and all
   `\input{}` subfiles) to catch any operator-side identifier that
   might have leaked into the public manuscript. The full list of
   forbidden prefixes lives in the operator's vault.

2. **No operator-side symbol in pseudocode.** Pseudocode blocks may
   only use the academic pseudonyms documented above. Subagents that
   emit operator-side API calls in pseudocode are immediately
   rejected.

3. **No internal path in any figure or table caption.** All figure
   references must use paths relative to `paper/figures/`. Absolute
   paths to operator-side directories are forbidden.

4. **No internal GitHub or organization name in any reference.** The
   paper cites the arXiv preprints and the public papers, not the
   operator's monorepo. The companion repositories listed in
   §11 and Appendix C are the only public-bound cross-references to
   operator-side code.

## 5. Operator-Document Sanitization (for peer-review copies)

This section codifies the patterns discovered during peer-review
sweeps of operator-internal documents (MANIFESTs, issue-body drafts,
prose excerpts). The rules below apply to any operator document that
may be shared with a third party (peer reviewer, conference PC, or
public archive). They do **not** affect the arXiv paper itself
(covered by sections 1–4), but they do affect operator docs that
might be staged for third-party review.

| Operator-internal phrasing | Public-safe phrasing | Why |
|---|---|---|
| Use of operator-speak in section titles (jargon that names an internal operator discipline) | Use neutral prose such as "operator-side analysis" or "design rationale" | Section titles should describe the technical content, not invoke the operator's internal workflow taxonomy. |
| Internal binary prefixes in section headers or table rows | Use the public pseudonym from §1, or remove the parenthetical | Operator-side binary names leak the operator's monorepo topology. |
| Sprint codenames referring to **precursor** work (audits, test suites, adaptations) | Drop the codename; use a generic descriptor (e.g., "the math test suite" instead of a sprint codename) | The paper itself may carry an internal codename, but its precursor sprints leak operator workflow state if named in the public surface. |
| Internal tag-name taxonomies (bracketed scope markers, internal labels) | Remove the brackets and rephrase as flowing prose | Bracketed tag conventions are operator-internal. |
| Internal paths in forbidden-example illustrations | Use generic placeholders such as `<internal/path/>` | The example itself should illustrate the rule, not leak the actual path. |
| Internal subagent roster labels (e.g., single-letter subagent IDs) | Use generic role descriptors (e.g., "scoring subagent", "dedicated scoring subagent") | Subagent labels are operator-internal. |
| Internal tag-name taxonomies (operator-side organization names used as tag prefixes) | Generic placeholder or remove entirely | The prefix leaks the operator's organization name into public docs. |
| Cross-references that name upstream-maintainer diagnoses (e.g., "false-positive cluster from PR #XXXX spam model") | Rephrase to neutral cross-references ("cross-references from PR #XXXX community discussion") | Operator diagnoses are not appropriate for shared docs. |
| Operational details (e.g., "5+ weeks unanswered", "auto-blocked with no human-review path") | Remove entirely | Operational SLA tracking is operator-internal. |
| Sprint/coordination codenames referencing multiple internal tasks (e.g., `T1+T2+T3` style) | Rephrase to neutral ("close out the remaining triage tasks", "scoring, cross-link, draft") | Sprint/coordination labels are operator workflow state. |
| Repo slugs in public-bound docs (judgment call) | Keep the slug if the repo is real and will be public; otherwise prefer a generic slug | Repo slugs are public-facing identifiers by design; the operator's prefix is an org convention, not a hidden leak. The decision depends on whether the repo will exist publicly. |

**Note on the inverse mapping.** This file documents the public-side
mapping (operator-internal name → public pseudonym) only. The inverse
mapping (public pseudonym → operator-internal name) is operator-side
and lives in the operator's vault. It is not shipped to the public
repository, the arXiv tarball, or the Zenodo deposit.

---

**Last updated**: 2026-06-23.
**Enforcement**: `verification/f80-build.sh` (see stage 1: anonymization grep guard).
