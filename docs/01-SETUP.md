# Setup and Prerequisites

## Target environment

This repository is designed for:
- Windows 11 host
- WSL2 guest
- Debian (Trixie)

## Base preparation

Before running provisioning on a fresh environment:

```bash
sudo apt update
sudo apt dist-upgrade
```

## Configuration file flow

1. Copy `.env.sample` to `.env`
2. Edit values based on your setup profile
3. Run `sudo bash begin_here.sh`

## Common profile patterns

- Minimal shell + Git: enable only core settings
- App development stack: Java/Node/Python + DB + web server
- Moodle testing: choose PHP + DB + web server mix for your version

See [Config Reference](CONFIG-REFERENCE.md) for all variables.

## Security baseline

- `.env` contains environment-specific values and may include local development secrets.
- Keep `.env` local. Do not commit real credentials.
- Development defaults are intended for local WSL use, not production.
