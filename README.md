# Car Portal

Car Portal is a split project for a Ukrainian-language driver dashboard:

- `frontend` - Next.js 16 + TypeScript personal cabinet UI on `carmain.local` and `carmain.localhost.com`
- `backend` - Node.js + TypeScript API with raw SQL repositories on `api.carmain.local` and `api.carmain.localhost.com`
- `mobile` - reserved Flutter workspace for a future mobile client
- root - Docker, reverse proxy, PostgreSQL, pgAdmin, and shared environment setup

## Features in the starter

- garage with vehicles, VIN, mileage, year, and model fields
- maintenance procedures catalog and schedule templates
- service logs with multiple maintenance items per visit
- reminders model for in-app and email notifications
- email/password auth and Google auth backend endpoints
- admin CMS endpoints for procedures and maintenance schedule templates
- CSRF, XSS mitigation, security headers, and parameterized SQL queries

## Local setup

1. Copy `.env.example` to `.env` and adjust secrets.
   Keep `COOKIE_SECURE=false` for local HTTP hosts and switch it to `true` when the stack is served over HTTPS.
2. Add hosts:
   - `127.0.0.1 carmain.local carmain.localhost.com`
   - `127.0.0.1 api.carmain.local api.carmain.localhost.com`
   - `127.0.0.1 pgadmin.carmain.local pgadmin.localhost.com`
3. Start the development stack with hot reload:

```bash
docker compose up -d
```

The default `docker-compose.yml` now runs in development mode:

- frontend uses `next dev` with HMR behind nginx
- backend uses `tsx watch` for live API reloads
- worker uses `tsx watch` for reminder loop reloads
- source code is mounted into containers, so edits no longer require rebuilding images

If dependencies change, restart the affected service once:

```bash
docker compose restart frontend
docker compose restart backend worker
```

For a production-style run, use the separate compose file:

```bash
docker compose -f docker-compose.prod.yml up --build -d
```

4. Open:
   - `http://carmain.localhost.com`
   - `http://carmain.localhost.com/dashboard`
   - `http://carmain.localhost.com/admin`
   - `http://api.carmain.localhost.com/v1/health`
   - `http://pgadmin.localhost.com`

## Google OAuth setup

For the current Google Sign-In flow you need one OAuth 2.0 Client ID of type `Web application` in Google Cloud Console.

1. Open Google Cloud Console.
2. Select or create a project for Car Portal.
3. Go to `APIs & Services` -> `OAuth consent screen`.
4. Configure the app name, support email, and add your test users if the app is still in testing mode.
5. Go to `APIs & Services` -> `Credentials`.
6. Click `Create Credentials` -> `OAuth client ID`.
7. Choose `Web application`.
8. Add Authorized JavaScript origins:
   - `http://carmain.localhost.com`
   - optionally `http://localhost:3000` if you also run frontend outside Docker
9. Save and copy the generated `Client ID`.

Put the same value into both environment variables:

```env
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
```

Why both are needed:

- `NEXT_PUBLIC_GOOGLE_CLIENT_ID` is used by the frontend Google Identity button
- `GOOGLE_CLIENT_ID` is used by the backend to validate the returned Google token

With the current popup/token flow, redirect URIs are not required yet. If later we switch to a full OAuth redirect flow, we will add explicit redirect URIs too.

## Migrations strategy

The backend uses plain SQL migration files from `backend/src/db/migrations` and a lightweight migration runner.

- schema changes stay explicit and reviewable
- no ORM or query builder is required
- repositories continue to use native SQL with positional parameters (`$1`, `$2`, ...)

Run migrations:

```bash
cd backend
npm run db:migrate
```

## Security baseline

- parameterized SQL queries through `pg`
- request payload validation with `zod`
- sanitized rich text and notes fields on input
- CSRF token handshake for mutating API requests
- HTTP-only auth cookie with `SameSite=Lax`
- baseline security headers and strict CORS allowlist

## API contract

- OpenAPI-style contract: [docs/api/openapi.yaml](/home/vortex/projects/car-portal/docs/api/openapi.yaml)
- Versioning and backward-compatibility policy: [docs/api/versioning.md](/home/vortex/projects/car-portal/docs/api/versioning.md)
- Contract test command:

```bash
cd backend
npm run test:contracts
```
