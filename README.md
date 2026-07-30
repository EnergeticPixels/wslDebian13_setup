# WSL Debian Provisioning Kit

Opinionated provisioning scripts for Windows 11 + WSL2 (Debian/Trixie) focused on app development and Moodle testing.

## Quickstart

1. Update system packages:

```bash
sudo apt update
sudo apt dist-upgrade
```

2. Copy this repository into your Linux home directory.
3. Copy `.env.sample` to `.env` and edit values.
4. Run full provisioning:

```bash
sudo bash begin_here.sh
```

### Fresh clone quick start (Debian 13 WSL)

If you cloned the repo directly (recommended), run:

```bash
cd /path/to/your/cloned/repo
chmod +x provisioning.sh begin_here.sh

# Create .env from .env.sample
./provisioning.sh init

# Interactive setup (whiptail if available, plain prompts otherwise)
./provisioning.sh wizard

# Validate settings and preview plan
./provisioning.sh validate
./provisioning.sh plan

# Run provisioning
sudo bash ./provisioning.sh run
```

### Terminal interface (`provisioning.sh`)

You can use `provisioning.sh` as a terminal interface for `.env`-driven provisioning.
When available in an interactive shell, the wizard uses `whiptail` menu screens.
If `whiptail` is unavailable, it automatically falls back to plain prompts.
At wizard startup, it logs which mode is being used.

```bash
# Create .env from .env.sample
./provisioning.sh init

# Run interactive configuration wizard
./provisioning.sh wizard

# Force plain prompt mode even if whiptail is installed
PROVISIONING_NO_WHIPTAIL=true ./provisioning.sh wizard

# Validate current .env values against script validators
./provisioning.sh validate

# Show what provisioning will run with current .env
./provisioning.sh plan

# Run full provisioning
sudo bash ./provisioning.sh run

# Run a single component
sudo bash ./provisioning.sh run --only db
```

Config helpers:

```bash
./provisioning.sh config show
./provisioning.sh config get DATABASE_TYPE
./provisioning.sh config set DATABASE_TYPE=postgres POSTGRESQL_VERSION=17
./provisioning.sh config unset TMUX_CONFIG_URL
```

Other helpers:

```bash
# Dry run execution commands
sudo bash ./provisioning.sh run --dry-run
sudo bash ./provisioning.sh run --only node --dry-run

# Show recent provisioning logs
./provisioning.sh logs
```

### SSH and GPG key management
Keys are managed automatically each time `begin_here.sh` runs:

- [Documentation Home](docs/README.md)
- [00 - Quickstart](docs/00-QUICKSTART.md)
- [01 - Setup and Prerequisites](docs/01-SETUP.md)
- [02 - Core Services (Git, SSH/GPG, Vim, tmux)](docs/02-CORE-SERVICES.md)
- [03 - Runtimes (Java, Node, Python)](docs/03-RUNTIMES.md)
- [04 - Web Stack (Apache/Nginx, Tomcat, PHP)](docs/04-WEB-STACK.md)
- [05 - Databases (MariaDB, PostgreSQL, MongoDB)](docs/05-DATABASES.md)
- [06 - Cache Store (Redis)](docs/06-CACHE-STORE.md)
- [07 - WSL Notes and Service Behavior](docs/07-WSL-NOTES.md)
- [Config Reference (.env variables)](docs/CONFIG-REFERENCE.md)

## Script Entry Points

- Full run: `begin_here.sh`
- Script directory: `scripts/`
- Shared libraries: `scripts/lib/`

Run any installer directly if you only want one component, for example:

```bash
sudo bash scripts/node_install.sh
sudo bash scripts/database_install.sh
sudo bash scripts/redis_install.sh
```

## Notes

- Detailed guidance moved into `docs/` to keep this README focused.
- `.env` is expected to remain local and is not meant to be committed.
