# Personal fitness + nutrition tracker — Windows 11 / Android

**Status:** prepared starter kit, **NOT deployed**. This branch does not modify wger application source, does not create a user account, and does not alter the production/default branch.

## Architecture / why two repos

- **App source:** [SquaredMoe/wger](https://github.com/SquaredMoe/wger) is the personal fork for later patches.
- **Runtime:** use the *official, separately maintained* [wger-project/docker](https://github.com/wger-project/docker) deployment. By default it runs **official** `wger/server` images, **NOT an image built from SquaredMoe/wger**. Custom fork builds and testing are a later step.
- **Services:** wger + PostgreSQL + Redis + nginx + Celery + PowerSync. The newest mobile client sync requires a one-time PowerSync storage setup.
- **AI layer (optional, later):** [wger-project/mcp-server](https://github.com/wger-project/mcp-server), an independently hosted bridge to wger's REST API. The upstream project warns it is WIP. Never assume this chat already has a connection to your local wger instance.
- **Initial access:** local computer only. No public port forwarding, no remote admin, no secrets in GitHub.

## Step 1 — prerequisites

Install **Docker Desktop for Windows** with WSL2 backend and **Git for Windows**. Launch Docker Desktop and confirm the engine is running. In **PowerShell**, check:

```powershell
docker info
docker compose version
git --version
```

Use Docker Compose >= **2.24.4**. Prefer an always-on dedicated host for 24/7 mobile logging; if this Windows PC/VM is off, the private server is offline.

## Step 2 — download and run the setup script

Inspect the script before running it. It clones official deployment files to `$HOME\wger-personal-stack`, generates distinct local app/database/storage credentials, sets `Asia/Beirut`, prevents new registrations, and confines the web port to `127.0.0.1:8080`. It never starts containers, and it never writes credentials to GitHub.

```powershell
$src = "https://raw.githubusercontent.com/SquaredMoe/wger/personal-fitness-setup-2026-11-21/docs/personal-fitness/setup-wger-local.ps1"
$dst = Join-Path $HOME "setup-wger-local.ps1"
Invoke-WebRequest -Uri $src -OutFile $dst
notepad $dst
& $dst
```

The runtime checkout has no Git metadata (to prevent accidentally committing `config/prod.env`). If the target already exists, the script stops instead of overwriting data. Keep a secure, offline backup of the runtime configuration.

## Step 3 — local-only first start

```powershell
cd (Join-Path $HOME "wger-personal-stack")
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose exec web ./manage.py setup-powersync-storage
```

Wait for healthy containers. Open **http://localhost:8080** on **that same Windows host**. The official first-run example provisions a default administrative login (`admin` / `adminadmin`). **Change that password immediately** using the wger account interface. Keep port 8080 bound to loopback throughout.

## Step 4 — rotate JWT signing keys before any outside connection

The upstream deployment template includes sample JWT signing keys. They **MUST** be replaced before exposing this instance to other devices or networks.

```powershell
docker compose exec web ./manage.py generate-jwt-keys
```

This prints a `JWT_PRIVATE_KEY=` and `JWT_PUBLIC_KEY=` pair. Copy those exact two lines to `config/prod.env` on the local host, replacing the sample entries. Keep the private key private. Do not paste the lines into chat or commit them. Then apply:

```powershell
docker compose up -d --force-recreate
docker compose ps
```

The setup script already rotates `SECRET_KEY`, PostgreSQL password, and PowerSync storage password before startup. Verify that the admin password and JWT keys have now also been rotated.

## Step 5 — populate fitness + nutrition catalogs

On a new instance the ingredient catalog is initially empty. Load the upstream starter fixtures:

```powershell
docker compose exec web wger load-online-fixtures
```

Verify that the exercise selector works, nutrition ingredients can be searched, and that a test weight entry can be saved. The official web health endpoint is:

```powershell
(Invoke-WebRequest -UseBasicParsing "http://localhost:8080/api/v2/version/").StatusCode
```

Expected HTTP result: 200. If containers fail, inspect `docker compose ps` and `docker compose logs --tail=100 web nginx powersync`; do not keep restarting blindly.

## Step 6 — personalize data model

Profile: `kg`, `cm`, `g`, `kcal`, timezone **Asia/Beirut**. Record:
- **Meals** every day: portions in grams, calories, protein/carbs/fat, optional fiber.
- **Training** 4 sessions/week: exercise, sets, reps, working weight, subjective effort/RIR, any discomfort.
- **Body metrics**: morning body weight at least 3 times/week, weekly waist at same point and time, optional photos.
- **Context**: sleep, average steps, energy, digestion notes. For changes to thyroid medicine or any clinical concerns, consult the treating clinician.

Build baseline for 2 weeks before interpreting trends or changing calories. A snapshot of the weekly AI review format is in [AI_COACH.md](AI_COACH.md).

## Step 7 — Android access (after hardening)

- Install the official wger Android client using the link from [wger](https://github.com/wger-project/wger#readme).
- `localhost` only works on the host, **not** from your Android phone.
- To use your own instance remotely, set up **authenticated HTTPS access** through a private VPN/Tailscale and a TLS reverse proxy or another suitably secured setup. Configure `SITE_URL`, Django CSRF trust, media/static URLs where required, and preserve nginx's `/ps/` reverse proxy path for PowerSync. Follow [official reverse proxy docs](https://wger.readthedocs.io/en/latest/installation/docker.html).
- Do not change the loopback-only binding to `0.0.0.0` or forward the public Internet to this host merely to enable phone access. First confirm the remote network and TLS plan.
- An always-on host is required for reliable remote connectivity while away.

## Step 8 — future AI bridge

For an AI assistant supporting MCP, use the maintained [wger MCP server](https://github.com/wger-project/mcp-server). With wger >= 2.7, prefer native wger OAuth for a network-reachable deployment; use read-only scopes first. Local stdio mode also exists for supported desktop MCP clients using a private wger API key. **Connecting a local MCP server to this ChatGPT conversation is not automatic.** It requires a supported remote connection, secured authentication, and explicit setup.

MVP: weekly **read-only** reports for weight/waist trends, calorie and protein consistency, workout frequency, set volume, recovery and outliers; AI proposes changes, person approves before the app writes new targets or routines.

## Maintenance + backups

Back up PostgreSQL and uploaded media, as well as `config/prod.env` stored securely and separately; never commit medical/fitness records or credentials to public GitHub. The upstream Docker repo includes a [DB backup script](https://github.com/wger-project/docker/blob/master/backup/backup-db.sh); schedule and restore-test backups before relying on the system. Update only after reviewing upstream migration/release instructions. Never use `docker compose down -v` for routine maintenance: it removes persistent data volumes.

## Reference

- [Official installation docs](https://wger.readthedocs.io/en/latest/installation/docker.html)
- [wger documentation](https://wger.readthedocs.io)
- [wger MCP bridge](https://github.com/wger-project/mcp-server)
- [wger license (AGPL-3.0-or-later)](https://github.com/SquaredMoe/wger/blob/master/LICENSE.txt)

**Not completed here:** Docker installation on the Windows host, server start, default admin password rotation, JWT rotation, mobile access, backups, live data sync, and MCP authentication. These require access to the target host and account.
