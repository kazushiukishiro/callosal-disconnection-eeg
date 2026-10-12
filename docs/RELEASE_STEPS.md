# GitHub and Zenodo release procedure

Repository: https://github.com/kazushiukishiro/callosal-disconnection-eeg
Prepared version: `1.0.0`; intended first Git tag: `v1.0.0`.
Creator/copyright holder: Kazushi Ukishiro. License: MIT.

This document describes intended owner actions; it does not certify that a
public release or archive exists.

1. Commit the reviewed stage-5 update at repository root. Keep the four
   component snapshots intact. Check that `LICENSE`, `CITATION.cff`, updated
   README/docs and the supplementary source folder are present.
2. Confirm that neither the current tree nor earlier commits contain private
   records or secrets. The reviewed source ZIP covers the current tree only.
   If something sensitive was committed, handle the history separately before
   public visibility; deleting it from the current branch is not sufficient.
3. When ready, the repository owner changes visibility to Public in Settings.
4. Sign in to Zenodo, connect the correct GitHub account, synchronize the
   repository list and enable this repository. Enable the integration **before**
   creating the release to be archived.
5. Create GitHub Release `v1.0.0` from the reviewed main-branch commit, with a
   title such as `v1.0.0 - MATLAB analysis components and synthetic demonstrations`.
   Describe the actual bounded scope and point to `docs/VALIDATION.md`.
   Do not upload private-data attachments or output folders as release assets.
6. Confirm Zenodo ingested this release. Verify software title, version, creator
   `Ukishiro, Kazushi`, license MIT, repository link and archived file contents.
   Confirm the record is published/accessibly downloadable and the DOI resolves.
7. Use the **version-specific DOI** for the submitted software version, not a
   concept DOI that always leads to the series of all versions. Copy the actual
   DOI to the manuscript and to the GitHub release description.

`CITATION.cff` is the only software-metadata input supplied; `.zenodo.json` is not
included. Zenodo can use CFF metadata, whereas `.zenodo.json` would take
precedence if both existed. No guessed DOI/date appears in CFF.

A software archive need not contain its own newly minted DOI in its source files.
Record the DOI in the release description and manuscript once assigned rather
than rewriting or moving the published tag. If later editing CFF/README or other
tracked files, regenerate the root checksum manifest before describing the
updated tree as checksum-verified. Keep the original archived version fixed.

Official guides consulted for the procedure:
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-citation-files
- https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
- https://help.zenodo.org/docs/github/enable-repository/
- https://help.zenodo.org/docs/github/describe-software/citation-file/
- https://help.zenodo.org/docs/github/describe-software/

No automated remote write, visibility change, GitHub release or Zenodo deposit
was performed by the local packaging process.
