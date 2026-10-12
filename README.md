# Car Portal Infra

Infrastructure and orchestration for the Car Portal monorepo. This repo wires together the separate application repos with Docker, nginx, PostgreSQL, pgAdmin, and shared environment configuration.

Related repositories:

| Repo | Description | README |
| --- | --- | --- |
| [carportal-frontend](https://github.com/ICS-Vortex/carportal-frontend) | Next.js 16 + TypeScript UI | [frontend/README.md](frontend/README.md) |
| [carportal-backend](https://github.com/ICS-Vortex/carportal-backend) | Node.js + TypeScript API | [backend/README.md](backend/README.md) |
| [carportal-mobile](https://github.com/ICS-Vortex/carportal-mobile) | Flutter mobile client | [mobile/README.md](mobile/README.md) |
| **carportal-infra** (this repo) | Docker, nginx, PostgreSQL, pgAdmin | this file |

Local hostnames:

- Frontend: `carmain.local` / `carmain.localhost.com`
- API: `api.carmain.local` / `api.carmain.localhost.com`
- CMS: `cms.carmain.local` / `cms.carmain.localhost.com`
- RabbitMQ: `rabbitmq.carmain.local` / `rabbitmq.carmain.localhost.com`
- pgAdmin: `pgadmin.carmain.local` / `pgadmin.localhost.com`

## Features in the starter

- garage with vehicles, VIN, mileage, year, and model fields
- maintenance procedures catalog and schedule templates
- service logs with multiple maintenance items per visit
- reminders model for in-app and email notifications
- email/password auth and Google auth backend endpoints
- admin CMS endpoints for procedures and maintenance schedule templates
- CSRF, XSS mitigation, security headers, and parameterized SQL queries

## What's in this repo

```
.
├── docker-compose.yml          # Development stack with hot reload
├── docker-compose.prod.yml     # Production-style build and run
├── .env.example                # Shared environment template
├── nginx/conf.d/default.conf   # Reverse proxy routing
└── infra/postgres/init/        # PostgreSQL init scripts (extensions, etc.)
```

Clone the application repos as sibling folders if you develop outside Docker bind mounts:

```bash
git clone git@github.com:ICS-Vortex/carportal-infra.git car-portal
cd car-portal
git clone git@github.com:ICS-Vortex/carportal-backend.git backend
git clone git@github.com:ICS-Vortex/carportal-frontend.git frontend
git clone git@github.com:ICS-Vortex/carportal-mobile.git mobile
```

## Local setup

1. Copy `.env.example` to `.env` and adjust secrets.
2. Generate local TLS certificates (mkcert recommended) and enable HTTPS in nginx:

```bash
chmod +x scripts/dev-tls.sh scripts/trust-dev-ca.sh
./scripts/dev-tls.sh
./scripts/trust-dev-ca.sh   # once per machine (sudo) so the browser trusts HTTPS
docker compose up -d --force-recreate nginx backend frontend
```

Use `https://carmain.localhost.com` in the browser. `.env.example` already uses `https://…` URLs and `COOKIE_SECURE=true`.

3. Add hosts:
   - `127.0.0.1 carmain.local carmain.localhost.com`
   - `127.0.0.1 api.carmain.local api.carmain.localhost.com`
   - `127.0.0.1 cms.carmain.local cms.carmain.localhost.com`
   - `127.0.0.1 rabbitmq.carmain.local rabbitmq.carmain.localhost.com`
   - `127.0.0.1 pgadmin.carmain.local pgadmin.localhost.com`
3. Start the development stack with hot reload:

```bash
docker compose up -d
```

The default `docker-compose.yml` now runs in development mode:

- frontend uses `next dev` with HMR behind nginx
- backend uses `tsx watch` for live API reloads
- worker uses `tsx watch` for reminder loop reloads
- the CMS stores sessions and application cache in Redis
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
   - `https://carmain.localhost.com`
   - `https://carmain.localhost.com/dashboard`
   - `https://cms.carmain.localhost.com/admin`
   - `https://rabbitmq.carmain.localhost.com`
   - `https://api.carmain.localhost.com/v1/health`
   - `https://pgadmin.localhost.com`

## Google OAuth setup

For the current Google Sign-In flow you need one OAuth 2.0 Client ID of type `Web application` in Google Cloud Console.

1. Open Google Cloud Console.
2. Select or create a project for Car Portal.
3. Go to `APIs & Services` -> `OAuth consent screen`.
4. Configure the app name, support email, and add your test users if the app is still in testing mode.
5. Go to `APIs & Services` -> `Credentials`.
6. Click `Create Credentials` -> `OAuth client ID`.
7. Choose `Web application`.
8. Add Authorized JavaScript origins (match the URL you use in the browser):
   - `https://carmain.localhost.com` (local HTTPS via `scripts/dev-tls.sh`)
   - `http://carmain.localhost.com` only if you still serve plain HTTP
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

## Migrations

Schema changes are Doctrine migrations in the CMS. The CMS container applies them on startup:

```bash
docker compose exec cms php bin/console doctrine:migrations:migrate --no-interaction
```

The Node API does not run migrations.

## Security baseline

- parameterized SQL queries through `pg`
- request payload validation with `zod`
- sanitized rich text and notes fields on input
- CSRF token handshake for mutating API requests
- HTTP-only auth cookie with `SameSite=Lax`
- baseline security headers and strict CORS allowlist

## API contract

- OpenAPI-style contract: [docs/api/openapi.yaml](docs/api/openapi.yaml)
- Versioning and backward-compatibility policy: [docs/api/versioning.md](docs/api/versioning.md)
- Contract test command:

```bash
cd backend
npm run test:contracts
```
