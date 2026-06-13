# My Windows 11 WSL/Debian 13

## Used for App development and Moodle testing

### Pre-Provisioning Steps
Since security is a big thing in modern times, you will need to accomplish the following steps before setting this repo into automatic provisioning a brand new Linux setup.
1. Update/upgrade the system
```bash
sudo apt update
sudo apt dist-upgrade
```

### To begin:
1. Download a .zip copy of this repo.
2. Extract the contents of the .zip into a temporary folder in your home directory.
3. Change to that temporary folder.
4. Change the filename of .env.sample to .env
5. Edit the properties to your liking. Then:
```bash
sudo bash begin_here.sh
```

### SSH and GPG key management
Keys are managed automatically each time `begin_here.sh` runs:

- **No key found** — a new key is generated.
- **Key exists and healthy** (more than 30 days before expiry) — skipped; the log records the days remaining.
- **Key exists and near expiry** (within 30 days) — the old key is replaced. The previous SSH key is backed up as `~/.ssh/id_github.bak` before overwrite.

Key expiry TTLs are set in `.env`:
- `GPG_EXPIRATION=1y` — GPG key lifetime (uses GPG's own expiry field as the authoritative source)
- `SSH_KEY_EXPIRATION=1y` — SSH key lifetime (tracked via the key file's modification timestamp + TTL)

**Public key display:** At the end of provisioning, if any key was generated or regenerated during that run, both the GPG and SSH public keys are printed to the terminal and the script pauses so you can copy them into GitHub Settings. If no keys changed, this display is skipped. You can always view existing public keys manually:

```bash
# GPG public key
gpg --armor --export "$GIT_EMAIL"

# SSH public key
cat ~/.ssh/id_github.pub
```

WSL/GPG note:
- If signed commits fail with `Inappropriate ioctl for device`, make sure your shell exports `GPG_TTY=$(tty)`.
- `scripts/gpg_gen.sh` now adds that line to the invoking user's `~/.bashrc` so it persists in new terminals.
- If GPG pinentry still complains in the current terminal, run `gpg-connect-agent updatestartuptty /bye` once after exporting `GPG_TTY`.

### Provision Git identity and aliases
Git identity and signing are configured by `scripts/git-config.sh` during the main provisioning flow.

Set these in `.env`:
- `GIT_NAME` and `GIT_EMAIL` for Git identity

Default aliases are built into `scripts/git-config.sh`:
- `br = branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate`
- `lg = !git log --pretty=format:"%C(magenta)%h%Creset %C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30`

Optional advanced override (not required):
- `GIT_ALIAS_BR` to override `br`
- `GIT_ALIAS_LG` to override `lg`

Run Git setup only:

```bash
sudo bash scripts/git-config.sh
```

### Install Neovim 0.12 only
If you only want Neovim (without running the full provisioning flow):

```bash
sudo NEOVIM_VERSION=0.12.0 bash scripts/neovim_install.sh
```

The installer:
- Supports amd64 and arm64
- Downloads Neovim from the official GitHub release assets
- Verifies the SHA-256 checksum before installation
- Installs to /opt/nvim and symlinks /usr/local/bin/nvim

You can also set NEOVIM_VERSION in .env (default: 0.12.0) and run the regular flow with begin_here.sh.

### Provision Java runtime and server
Java provisioning is modular and optional. The main flow calls `scripts/java_install.sh`, which routes to dedicated installers:
- `scripts/tomcat_install.sh` when `JAVA_SERVER_MODE=tomcat`
- `scripts/java_service_install.sh` when `JAVA_SERVER_MODE=jar`

Set these in `.env`:
- `JAVA_ENABLE=true` to enable Java provisioning (default is false)
- `JAVA_VERSION=8` for legacy compatibility
- `JAVA_SERVER_MODE=tomcat` or `JAVA_SERVER_MODE=jar`
- `JAVA_DISTRO=temurin` (recommended on Debian 13)

If using `JAVA_SERVER_MODE=jar`, also set:
- `JAVA_APP_JAR_PATH=/absolute/path/to/app.jar`
- `JAVA_APP_PORT=8081`
- `JAVA_APP_ARGS=` (optional arguments)

Run Java setup only:

```bash
sudo bash scripts/java_install.sh
```

Tomcat notes:
- The script prefers `tomcat9` from apt when available.
- If `tomcat9` is unavailable, it installs Apache Tomcat 9 manually under `/opt/tomcat`.

WSL notes:
- If systemd is not enabled in WSL, services may need to be started manually each session.

### Provision Node.js with NVM
Node.js provisioning is optional and uses NVM to install and switch versions per user.

Set these in `.env`:
- `NODE_ENABLE=true` to enable Node.js provisioning (default is false)
- `NODE_DEFAULT_VERSION=22` to set the default Node version alias
- `NODE_VERSIONS=22` for a comma-separated list of Node versions to install
- `NODE_NVM_VERSION=v0.40.3` to pin the NVM installer version
- `NODE_GLOBAL_PACKAGES=` for future global npm package support (placeholder)

Behavior details:
- NVM installs into the invoking user's home directory (`~/.nvm`)
- The script appends NVM init lines to `~/.bashrc` when missing
- `NODE_DEFAULT_VERSION` is installed and set as NVM default alias
- If `NODE_DEFAULT_VERSION` is not listed in `NODE_VERSIONS`, it is auto-added

Run Node setup only:

```bash
sudo bash scripts/node_install.sh
```

### Provision GitHub CLI (gh)
GitHub CLI provisioning is optional and can be enabled for the full provisioning flow.

Set these in `.env`:
- `GH_ENABLE=true` to install GitHub CLI during provisioning (default is false)
- `GH_AUTH_MODE=none` for install-only behavior (supported values: `none`, `token`, `device`)
- `GH_HOST=github.com` to choose the GitHub host target for auth status checks

Behavior details:
- The installer prefers distro apt sources first
- If `gh` is unavailable in default apt sources, the script adds the official GitHub CLI apt repository and retries installation
- `GH_AUTH_MODE=none` installs gh and reports auth status only
- `GH_AUTH_MODE=token` performs non-interactive auth using a runtime token from `GH_TOKEN` or `GITHUB_TOKEN`
- `GH_AUTH_MODE=device` runs an interactive `gh auth login` flow (requires an interactive terminal)
- After successful auth (`token` or `device`), the script runs `gh auth setup-git`
- Lowercase keys (`gh_enable`, `gh_auth_mode`, `gh_host`) are accepted for compatibility

Token auth note:
- Keep tokens out of `.env`; pass them only in the runtime environment (for example with `sudo -E`)

Run GitHub CLI setup only:

```bash
sudo bash scripts/gh_install.sh
```

Authenticate after provisioning (optional):

```bash
gh auth login -h github.com
gh auth status -h github.com
```

Run token auth through the installer (Phase 2):

```bash
sudo GH_ENABLE=true GH_AUTH_MODE=token GH_TOKEN=<your-token> bash scripts/gh_install.sh
```

### Provision standalone GitHub Copilot CLI (preferred)
This project provisions the standalone `copilot` CLI as the preferred Copilot terminal experience.
The old `github/gh-copilot` extension path is deprecated and not used by this provisioning flow.

Set these in `.env`:
- `COPILOT_ENABLE=true` to install standalone GitHub Copilot CLI (default is false)
- `COPILOT_VERSION=latest` to install the latest available release

Behavior details:
- Uses the official GitHub installer endpoint: `https://gh.io/copilot-install`
- Runs in root mode during provisioning, so the binary installs to `/usr/local/bin`
- Accepts lowercase compatibility keys (`copilot_enable`, `copilot_version`)
- Authentication is user-driven after install (`copilot` then `/login`), or by runtime token environment variables

Run standalone Copilot CLI setup only:

```bash
sudo bash scripts/copilot_cli_install.sh
```

Verify installation:

```bash
copilot --version
copilot
```

### Front-end Creative Apps
Most front-end creative tools (Inkscape, GIMP, Blender, Audacity, and DaVinci Resolve) have been moved to a separate repository for better maintainability.

**For these tools, see:** [debian-fe-tools](https://github.com/EnergeticPixels/debian-fe-tools.git)

**Video Editor Support:**
This repository still supports OpenShot video editor as an optional feature:

Set in `.env`:
- `VIDEO_EDITOR=openshot` to install OpenShot video editor
- `VIDEO_EDITOR=none` (default) to skip video editor installation

Run video editor setup only:

```bash
sudo bash scripts/video_editor_install.sh
```

### Developed with


### Provisioning with:


### Constraints
This repo is targeted for Windows 11 host with WSL2 and Debian (Trixie) distribution.
If you want tmux configured automatically, set `TMUX_CONFIG_URL` in `.env` to your raw Gist URL for `.tmux.conf`.
Example: https://gist.github.com/<your-github-username>/<gist-hash>/raw/<your-gist-filename>
If no URL is provided, the provisioning flow skips tmux installation and continues normally.  You can always install tmux after the automated provisioning scripts complete.

Set `WEB_SERVER` in `.env` to choose which web server gets installed during provisioning:
- `WEB_SERVER=apache` installs Apache (`apache2` package)
- `WEB_SERVER=nginx` installs Nginx (`nginx` package)

If `WEB_SERVER` is not set, the web server install step is skipped.
`web_server` is also accepted for compatibility.

Web server scripts are split for future per-server customization:
- `scripts/web_server_install.sh` selects which installer to run based on `WEB_SERVER`
- `scripts/web_server_apache_install.sh` handles Apache installation/configuration
- `scripts/web_server_nginx_install.sh` handles Nginx installation/configuration

PHP provisioning can be enabled per run:
- `PHP_ENABLE=true` installs PHP alongside the selected web server
- `PHP_ENABLE=false` skips PHP installation

Choose the PHP version in `.env` with `PHP_VERSION`:
- Supported values: `7.4`, `8.0`, `8.1`, `8.2`, `8.3`
- Default in `.env.sample`: `PHP_VERSION=7.4`

Configure PHP extension planning with:
- `PHP_EXTENSIONS_BASELINE=common` for the default extension profile
- `PHP_EXTENSIONS_BASELINE=none` to disable baseline extension selection
- `PHP_EXTENSIONS_EXTRA=` for comma-separated extension names (example: `soap,pgsql`)
- `PHP_EXTENSIONS_STRICT=true` to fail if any requested extension package is unavailable
- `PHP_EXTENSIONS_STRICT=false` to skip unavailable extension packages with warnings
- `PHP_DB_DRIVER_MODE=auto` to control database driver extension selection (`auto`, `mysql`, `postgres`, `none`)

Behavior details:
- Apache and Nginx both use `php-fpm` integration
- The scripts prefer Debian package sources first
- If the requested version is unavailable in current apt sources, the installer adds the Sury PHP repository and retries package resolution
- Lowercase keys (`php_enable`, `php_version`, `php_extensions_baseline`, `php_extensions_extra`, `php_extensions_strict`) are accepted for compatibility

Current baseline profile:
- `common` maps to: `mbstring`, `xml`, `curl`, `zip`, `intl`, `gd`, `bcmath`, `opcache`, `readline`

Database driver extension behavior:
- With `PHP_DB_DRIVER_MODE=auto` (default), PHP driver extensions follow `DATABASE_TYPE`
- `DATABASE_TYPE=mysql` adds the `mysql` extension package
- `DATABASE_TYPE=postgres` adds the `pgsql` extension package
- `DATABASE_TYPE=mongodb` adds no SQL database driver extension
- `DATABASE_TYPE=none` adds no database driver extension
- You can override automatic behavior with `PHP_DB_DRIVER_MODE=mysql|postgres|none`

### Database Configuration

Database provisioning is optional and mutually exclusive. Choose between MariaDB, PostgreSQL, MongoDB, or no database installation.

Set `DATABASE_TYPE` in `.env` to control database provisioning:
- `DATABASE_TYPE=none` (default) — no database installation
- `DATABASE_TYPE=mysql` — installs MariaDB (MySQL-compatible drop-in replacement)
- `DATABASE_TYPE=postgres` — installs and configures PostgreSQL
- `DATABASE_TYPE=mongodb` — installs and configures MongoDB Community Edition

#### MariaDB (MySQL) Provisioning

MariaDB is the recommended MySQL-compatible database for Debian. It is installed from official Debian repositories with full compatibility for MySQL clients and tools.

**Configuration variables:**
- `MARIADB_VERSION=10.5` — database server version (supported: 10.5–10.11, 11.0–11.6; default: 10.5)
- `DB_DEV_SETUP=false` — enable automatic development database and user creation

**Optional development setup** (only active if `DB_DEV_SETUP=true`):
- `DB_DEV_DB_NAME=dev_db` — development database name
- `DB_DEV_USER=dev_user` — development database user
- `DB_DEV_PASSWORD=dev_password` — development user password (**WARNING: plaintext in .env, dev-only**)
- `DB_DEV_USER_HOST=localhost` — host(s) the development user can connect from

**Example .env configuration to enable MariaDB with dev setup:**
```bash
DATABASE_TYPE=mysql
MARIADB_VERSION=10.5
DB_DEV_SETUP=true
DB_DEV_DB_NAME=my_app_db
DB_DEV_USER=app_user
DB_DEV_PASSWORD=app_password
DB_DEV_USER_HOST=localhost
```

**Connection examples:**

Connect as root user:
```bash
mariadb -u root
```

Connect as development user (after dev setup is enabled):
```bash
mariadb -u app_user -p -h localhost my_app_db
# When prompted for password, enter: app_password
```

Verify MariaDB installation:
```bash
mariadb -u root -e "SELECT VERSION();"
```

Check MariaDB service status:
```bash
systemctl status mariadb
```

Run database setup only (without full provisioning):
```bash
sudo bash scripts/database_install.sh
```

Behavior details:
- MariaDB service is enabled to start automatically on system boot
- If MariaDB is already installed, the installer skips reinstallation and logs the current version
- Development database and user are created only if `DB_DEV_SETUP=true`
- Lowercase keys (`database_type`, `mariadb_version`, `db_dev_setup`, etc.) are accepted for compatibility
- On WSL systems with systemd enabled, MariaDB service will start automatically
- If systemd is not available, start MariaDB manually: `sudo systemctl start mariadb` or `sudo service mariadb start`

#### PostgreSQL Provisioning

PostgreSQL provisioning is implemented. Set `DATABASE_TYPE=postgres` to install and configure PostgreSQL.

PostgreSQL provisioning uses the same shared development setup variables as MariaDB:
- `DB_DEV_SETUP=false` — enable automatic development database and user creation
- `DB_DEV_DB_NAME=dev_db` — development database name
- `DB_DEV_USER=dev_user` — development database user
- `DB_DEV_PASSWORD=dev_password` — development user password (**WARNING: plaintext in .env, dev-only**)
- `DB_DEV_USER_HOST=localhost` — host used for local development connections

PostgreSQL version variable:
- `POSTGRESQL_VERSION=17` — supported versions: `14`, `15`, `16`, `17`

Example `.env` values for PostgreSQL setup:
```bash
DATABASE_TYPE=postgres
POSTGRESQL_VERSION=17
DB_DEV_SETUP=true
DB_DEV_DB_NAME=my_app_db
DB_DEV_USER=app_user
DB_DEV_PASSWORD=app_password
DB_DEV_USER_HOST=localhost
```

Run PostgreSQL setup only (without full provisioning):
```bash
sudo bash scripts/postgresql_install.sh
```

Connection examples:

Connect as postgres superuser:
```bash
sudo -u postgres psql
```

Connect as development user:
```bash
psql "host=localhost dbname=my_app_db user=app_user password=app_password"
```

Verify PostgreSQL installation:
```bash
psql --version
sudo -u postgres psql -c "SELECT version();"
```

Check PostgreSQL service status:
```bash
systemctl status postgresql
```

Behavior details:
- Installs `postgresql-<version>` and `postgresql-client-<version>` when available in apt sources
- Falls back to default `postgresql` and `postgresql-client` packages if the requested versioned package is unavailable
- Enables and starts PostgreSQL service (`systemctl` when available, otherwise `service` fallback)
- Development database and user are created only if `DB_DEV_SETUP=true`

#### MongoDB Provisioning

MongoDB provisioning is implemented. Set `DATABASE_TYPE=mongodb` to install and configure MongoDB Community Edition.

MongoDB provisioning uses the same shared development setup variables:
- `DB_DEV_SETUP=false` — enable automatic development database and user creation
- `DB_DEV_DB_NAME=dev_db` — development database name
- `DB_DEV_USER=dev_user` — development database user
- `DB_DEV_PASSWORD=dev_password` — development database user password (**WARNING: plaintext in .env, dev-only**)

MongoDB version variable:
- `MONGODB_VERSION=8.0` — supported versions: `6.0`, `7.0`, `8.0`

Example `.env` values for MongoDB setup:
```bash
DATABASE_TYPE=mongodb
MONGODB_VERSION=8.0
DB_DEV_SETUP=true
DB_DEV_DB_NAME=my_app_db
DB_DEV_USER=app_user
DB_DEV_PASSWORD=app_password
```

Run MongoDB setup only (without full provisioning):
```bash
sudo bash scripts/mongodb_install.sh
```

Connection examples:

Connect to local MongoDB shell:
```bash
mongosh
```

Connect as development user:
```bash
mongosh "mongodb://app_user:app_password@localhost:27017/my_app_db?authSource=my_app_db"
```

Verify MongoDB installation:
```bash
mongosh --version
```

Check MongoDB service status:
```bash
systemctl status mongod
```

Behavior details:
- Installs MongoDB Community Edition from the official MongoDB apt repository
- On Debian trixie and unknown codenames, the installer falls back to MongoDB's `bookworm` repository track
- Enables and starts MongoDB service (`systemctl` when available, otherwise `service` fallback)
- Development database and user are created only if `DB_DEV_SETUP=true`

#### Security Notes

- Development database credentials are stored in plaintext in `.env` — this is acceptable for **development and WSL environments only**
- Never commit `.env` (with real credentials) to version control; `.env` is gitignored by default
- For production environments, use strong passwords, secure credential management, and restrict database user privileges appropriately
- WSL is a local development environment; network-level database security is not a concern for WSL-local connections

### Redis Cache Provisioning

Redis provisioning is optional and controlled by a dedicated toggle.

Set these in `.env`:
- `REDIS_ENABLE=true` to install and start Redis during provisioning (default: `false`)
- `REDIS_VERSION=7.0` to declare your preferred Redis version target

Notes about `REDIS_VERSION`:
- The installer validates format (for example: `7.0` or `7.0.15`)
- Installation uses distro apt repositories, so the final installed version depends on package availability
- If the installed version differs from your requested `REDIS_VERSION`, the script logs a warning

Run Redis setup only:

```bash
sudo bash scripts/redis_install.sh
```

Verify Redis installation:

```bash
redis-server --version
redis-cli ping
```

Check Redis service status:

```bash
systemctl status redis-server
```

WSL note:
- If systemd is not enabled in WSL, start Redis manually each session with `sudo service redis-server start`.
