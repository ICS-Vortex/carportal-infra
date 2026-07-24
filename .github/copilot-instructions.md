# Car Portal AI Instructions

## Architecture rules

- Do not grow page files or single components into large monoliths. If a file approaches a few hundred lines or starts mixing unrelated responsibilities, split it before continuing.
- For frontend work, keep `src/app` thin. Put UI sections into `src/components`, data access into `src/lib`, and shared types or helpers into dedicated modules.
- Prefer feature composition over one-file dashboards. Authentication, vehicles, reminders, service logs, and admin/CMS screens should stay in separate components or modules.
- Root of this repository is orchestration-only. Do not reintroduce monorepo-style root package management.

## Working style

- Before large frontend edits, outline the target file split and keep each new file focused on one concern.
- When a feature is only partially implemented, update `TODO.md` in the root so implemented, in-progress, and pending work remain visible.
- Preserve existing project boundaries: `frontend`, `backend`, and `mobile` are intended to remain separable projects.
- If patch lines count is more than 1000 - split patch into smaller edits and submit separately.
- When you make changes to the mobile app - redeploy app to the emulator and run smoke tests to ensure the app is still functional. If you are making changes to the backend API, make sure to run the mobile app and verify that the API contract is still valid.