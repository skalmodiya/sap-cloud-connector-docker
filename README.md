# SAP Cloud Connector — Docker

A minimal, reproducible Docker setup for running the **SAP Cloud Connector (SCC) Portable** edition on top of **SAP JVM** in an Ubuntu 22.04 container.

This repository ships only the build recipe (`Dockerfile` + `docker-compose.yml`). The SAP binaries themselves are **not** redistributed — you download them yourself from the SAP Software Center and drop them into the `downloads/` folder before building.

---

## Contents

| File | Purpose |
| --- | --- |
| `Dockerfile` | Builds an image with SAP JVM + SCC Portable on Ubuntu 22.04 |
| `docker-compose.yml` | One-command run, exposes the SCC admin UI on `:8443` |
| `downloads/` | You drop the SAP JVM zip and SCC tarball here (kept empty in git) |
| `.gitignore` | Prevents SAP binaries from being committed |

---

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** v2 (`docker compose ...`)
- A free **SAP Universal ID** (needed to download the binaries)
- ~3 GB of free disk space for the image
- Open port **8443** on the host (or change the mapping in `docker-compose.yml`)

---

## Step-by-step setup

### 1. Clone the repository

```bash
git clone https://github.com/skalmodiya/sap-cloud-connector-docker.git
cd sap-cloud-connector
```

### 2. Download the SAP binaries

You need **two** files from SAP. Both are free but require a logged-in SAP account.

#### a) SAP JVM 8 (Linux x64)

1. Go to <https://tools.hana.ondemand.com/#cloud> → **SAP JVM 8**.
2. Download the **Linux x64** ZIP, e.g. `sapjvm-8.1.110-linux-x64.zip`.

#### b) SAP Cloud Connector — Portable (Linux x64)

1. Go to <https://tools.hana.ondemand.com/#cloud> → **Cloud Connector**.
2. Pick the **Portable** flavor for **Linux x64**, e.g. `sapcc-2.19.0.2-linux-x64.tar.gz`.
   *(Don't grab the `.rpm` or `.zip` for Windows — the Dockerfile expects the `tar.gz`.)*

### 3. Place the files in `downloads/`

```text
sap-cloud-connector/
├── Dockerfile
├── docker-compose.yml
└── downloads/
    ├── sapcc-2.19.0.2-linux-x64.tar.gz
    └── sapjvm-8.1.110-linux-x64.zip
```

The Dockerfile globs by prefix (`sapjvm-*.zip`, `sapcc-*.tar.gz`), so newer versions work without editing the build.

### 4. Build and start the container

```bash
docker compose up -d --build
```

First build takes a few minutes while it unpacks SAP JVM (~400 MB) and SCC.

### 5. Open the admin UI

Browse to:

```text
https://localhost:8443
```

You'll get a self-signed certificate warning — accept it.

**Default login (first start only):**

| Field | Value |
| --- | --- |
| User | `Administrator` |
| Password | `manage` |

You'll be forced to change the password on first login.

---

## Common operations

### View logs

```bash
docker compose logs -f sap-cloud-connector
```

### Stop / start

```bash
docker compose stop
docker compose start
```

### Rebuild after changing binaries

```bash
docker compose down
docker compose up -d --build
```

### Open a shell in the container

```bash
docker exec -it sap-cloud-connector bash
```

SCC lives at `/opt/scc`, SAP JVM at `/opt/sapjvm`.

---

## Persisting configuration

Out of the box the container is **stateless** — uninstalling the container loses all SCC configuration (subaccount registrations, system mappings, certs, etc.).

To persist state across rebuilds, mount a volume on `/opt/scc/config_master` (and optionally `/opt/scc/log`). Add to `docker-compose.yml`:

```yaml
services:
  sap-cloud-connector:
    build: .
    container_name: sap-cloud-connector
    ports:
      - "8443:8443"
    restart: unless-stopped
    volumes:
      - ./scc-config:/opt/scc/config_master
      - ./scc-data:/opt/scc/log
```

Both `scc-config/` and `scc-data/` are pre-listed in `.gitignore`.

---

## Troubleshooting

**Build fails with `find: ... No such file`**
You forgot to put the SAP binaries into `downloads/`. The folder must contain exactly one `sapjvm-*.zip` and one `sapcc-*.tar.gz`.

**Port 8443 already in use**
Change the host side of the mapping in `docker-compose.yml`, e.g. `"9443:8443"`, then visit `https://localhost:9443`.

**Container exits immediately / SCC won't start**
Run `docker compose logs sap-cloud-connector`. The most common cause is an architecture mismatch — make sure you grabbed the **linux-x64** flavor of both binaries (Apple Silicon users: build with `--platform linux/amd64`).

**"Operation not permitted" on Apple Silicon**
Add platform pinning to `docker-compose.yml`:

```yaml
services:
  sap-cloud-connector:
    platform: linux/amd64
    build: .
    ...
```

---

## License & redistribution

The SAP JVM and SAP Cloud Connector binaries are licensed by SAP — read SAP's developer license terms before redistributing them. **Do not commit them to a public repository.** This repo's `.gitignore` is configured to keep that from happening by accident.

The Dockerfile and compose file in this repo are provided as-is, no warranty.
