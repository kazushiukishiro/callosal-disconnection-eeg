# Stage-5 review of the GitHub-downloaded snapshot

Input archive: `callosal-disconnection-eeg-main.zip`.
Archive SHA-256: `f8facb46ea436ec67a32446833067c4112c1aee3739d817935fc7f39ee7d2a53`.
Git commit in ZIP comment: `ed6ee982f5f145da43944ec09d7f7de8e309b133`.

## Observed results

- 82 non-directory files; all could be inspected as UTF-8 text.
- All 81 root-manifest entries matched their file SHA-256 values.
- All 69 component files matched the four author-tested source archives,
  including all 30 MATLAB files. No missing, extra or changed component files.
- The four internal manifests had 16, 16, 16 and 17 checked entries; all matched.
- All four root PASS reports were byte-identical to the author-uploaded reports.
- No bundled EEG/MAT, spreadsheet, CSV/TSV or image file was present. No matching
  private-key/token or local-path pattern was found. The earlier v2 FAIL report
  inside stage 2 is historical evidence, explicitly distinguished from v3 PASS.

This establishes current-tree transfer integrity, not clinical correctness or a
review of Git history. No MATLAB session, clinical refit or new synthetic test
was run during this review. Do not use it to extend the scope of the PASS reports.

## Prepared changes

The rights holder authorized MIT licensing with sole creator/copyright holder
Kazushi Ukishiro. Root LICENSE/CFF/NOTICE and scope/input/release documentation
were prepared. No DOI, release date, ORCID or additional author was invented.

Two previously supplied sources were added without alteration: matched Figure 4
colour v3 and residual-splenium per-recording analysis. No clinical inputs from
their original packages were copied. They are labelled as not newly runtime-tested.
All stage-1 to stage-4 component code, documentation, internal manifests and the
four runtime reports remain byte-for-byte unchanged.

Release scope is explicitly analysis code/refactored components and synthetic
examples, not a complete clinical all-results/all-figures pipeline. The map lists
missing plotting/cohort-assembly workflows rather than silently replacing them.
The package still needs the owner to commit this update and complete public
visibility/release/Zenodo actions. The original ZIP was not modified.
