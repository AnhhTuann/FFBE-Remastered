# Per-prompt Git checkpoint workflow

This workflow applies to every subsequent development prompt in FFBE Remastered.
It protects completed work while keeping each milestone independently reviewable.

1. Start from the verified previous milestone commit and branch.
2. Create a dedicated development branch for the authorized prompt scope.
3. Implement only that prompt's authorized scope.
4. Run regression and feature tests; record actual commands, exit codes and logs.
5. Perform real GUI QA where applicable; retain metadata and runtime-error evidence.
6. Review repository size, secrets, rights and restricted content before publication.
7. Commit validated changes; preserve milestone commits and avoid destructive history edits.
8. Push only the explicitly authorized safe milestone branch.
9. Create a stacked pull request against the preceding milestone branch.
10. Verify the remote branch, exact SHA, tags and PR independently.
11. Deliver the final report and wait for the owner's approval before the next prompt.

Rules:

- No automatic merge into `main`.
- No force push, hard reset, `git clean`, destructive rebase or `git push --all`/`--mirror`.
- No publication of restricted original game assets, archives, local saves, credentials or build executables.
- No engine upgrade or export-template substitution without explicit authorization.
- The owner reviews each milestone before authorizing the next one.
