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

## Documentation Map

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
