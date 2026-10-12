# Final release scope and publication steps

The original six-stage preparation plan is retained as history in the component
and integration notes. The current release-scope decision is documented in
`MANUSCRIPT_CODE_MAP.md`; it does not claim to supply absent workflows.

## Stage 5: completed in the prepared local candidate

- Reviewed the GitHub-downloaded tree against root/component manifests and the
  four author-tested source archives. All 69 component files, all 30 component
  MATLAB files and all four PASS reports matched.
- Finalized MIT licensing and the sole declared software creator/copyright
  holder, Kazushi Ukishiro, using the rights holder's explicit instructions.
- Added CFF citation metadata without inventing a DOI, release date or ORCID.
- Added two unchanged supplied sources: matched Figure 4 colour v3 and the
  residual-splenium function. Their lack of new automated runtime validation
  is explicit. No old Figure 4 source or private figure data was substituted.
- Defined the release as analysis sources/refactored components with synthetic
  demonstrations, not a complete clinical end-to-end reproduction package.
  Final Figure 1 artwork, Figure 2/3 rendering, Figure 5 composite and private
  cohort assembly/exclusion/outcome workflows are outside this release.
- Reviewed the current upload set for private data and credentials. Git history
  remains outside the inspected source ZIP.

The candidate files are local deliverables until the author commits them to
GitHub. The packaging environment did not execute MATLAB or publish anything.
No additional synthetic test or new research analysis is required merely to
store these unchanged source files and their explicitly scoped documentation.

## Stage 6: still to be performed by the repository owner

Upload the stage-5 delta at repository root, preserve the tested components and
verify the intended metadata/scope. Keep private until ready to publish. Ensure
that no private data or secret was previously committed; any such history needs
separate handling, not only current-tree deletion.

Then complete the GitHub Public/release and Zenodo-archive steps in
`RELEASE_STEPS.md`, verify the version-specific DOI and update the manuscript's
availability statement to the actual scope and identifiers. Do not state that
all clinical results or all publication figures were independently reproduced.
