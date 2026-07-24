# TODO

## Implemented

- Root Docker orchestration for frontend, backend, worker, PostgreSQL, pgAdmin, and nginx host routing.
- Frontend and backend project split.
- Initial domain model for users, vehicles, maintenance procedures, schedules, logs, and reminders.
- Backend starter with raw SQL repositories, CSRF, JWT cookie auth, and reminder worker.
- Frontend email/password auth flow with live API calls, CSRF handshake, and cookie session support.
- Frontend live integration for garage, service log creation, reminders, and dashboard API snapshot.
- Backend admin CMS API for maintenance procedures and schedule templates.
- Frontend CMS page for filling, editing, and deleting procedures plus template rules.
- Vehicle-specific maintenance plans with snapshot items assigned from CMS templates.
- Maintenance statuses per plan item with skip/complete actions, mileage/date overdue logic, and service-log synchronization.
- Honda HR-V RU1 seeded maintenance template based on a concrete service table for production bootstrap.
- Admin user management with blocking, role switching, and soft deactivation.
- Snapshot plans now warn about stale CMS templates and auto-reassign when the plan is still untouched.
- Frontend Google Sign-In integration hook with Google Identity Services.
- Public landing page on `/` and protected driver cabinet moved to `/dashboard`.
- Docker development workflow with bind mounts and hot reload for frontend/backend.
- Public marketing content API for landing sliders, banners, downloads, and news.
- Shared shell as the single access gate for authenticated pages.
- Frontend dashboard and core user pages localized in Ukrainian.
- Separate normalized vehicle catalog with brands, models, and generations instead of free-form user-created make/model records.
- Garage now creates user vehicles from the internal catalog, while service plans auto-bind to the selected vehicle configuration.
- Service log procedure selection now follows the active maintenance plan for the chosen car instead of the global procedure list.
- Vehicle catalog now supports configuration-level selection by engine and transmission, and garage removal works via soft delete.
- Admin template workflow now uses catalog-driven brand/model/generation/configuration selection instead of free text fields.
- Seeded catalog and maintenance template workflow already expanded to configuration-specific matching.
- Maintenance page now lets users notify admins when a ready-made plan is missing for their vehicle, and admin overview shows these requests.
- Honda HR-V RU1 now has a standard-configuration fallback plan so previously created vehicles without a specific engine/transmission choice still receive a maintenance plan.
- Admin overview now lets the administrator close a missing-plan request after the required regulation is added.
- Existing covered generations now receive standard-configuration fallback templates automatically, so older vehicles created before exact configuration selection still get a plan.
- Reminders now sync from actual maintenance plan items, so due and overdue service work appears even without manually seeded reminder rows.
- Reminders page is simplified to the actual queue of service events without the extra informational channels block.
- API responses are normalized for client apps: successful responses now use a stable `data` envelope, and errors return structured `error.code`, `error.message`, and optional `error.details`.
- OpenAPI-style API contract is published in `docs/api/openapi.yaml` for web/mobile consumers.
- Contract test suite now checks the shared response envelope and critical auth/public error cases.
- API versioning and backward-compatibility rules are documented for `/v1`.
- Flutter SDK is installed inside WSL at `~/sdk/flutter`, so the mobile toolchain no longer depends on the broken Windows `/mnt/c/flutter` path.
- Base Flutter application scaffold is created in `mobile`.
- Mobile app now has the first real slice: auth bootstrap, email login, API client with cookie/CSRF handling, and a protected home shell with live garage/reminder summary.
- Mobile app now has real garage list/detail, reminders list/detail, and profile screens backed by live API data.
- Mobile app visual refresh now uses layered surfaces, stronger hero sections, and richer garage/reminder/profile presentation instead of flat dark cards.
- Android SDK, JDK 17, and AVDs are installed in WSL user space under `~/android-sdk` and `~/tools/jdk-17`, and `flutter doctor -v` now reports a healthy Android toolchain.

## In Progress

- Runtime Google OAuth browser verification with the configured Client ID in `.env`.
- Mobile UX polish pass: real vehicle imagery support, richer fallback artwork, and stronger product-style presentation for core screens.

## Pending

- Real SMTP provider configuration and reminder delivery tracking.
- Broader import pipeline for a larger production-grade vehicle catalog beyond the starter seeded dataset.
- Extend ready-made maintenance schedules for part of the newly enriched configuration-level models.
- Expand premium Audi, BMW, and Mercedes generations with more than two precise engine/transmission variants per generation.
- Grant WSL access to KVM for live Android emulator runs, or use a Windows-host emulator/device bridge as the live-run target.
- Install Linux desktop build dependencies (`clang`, `cmake`, `ninja-build`, `pkg-config`) if local Linux desktop runs are needed.
- Add maintenance and service-log mobile screens plus action flows from reminder detail into the correct next step.
