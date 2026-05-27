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

Behavior details:
- Apache and Nginx both use `php-fpm` integration
- The scripts prefer Debian package sources first
- If the requested version is unavailable in current apt sources, the installer adds the Sury PHP repository and retries package resolution
- Lowercase keys (`php_enable`, `php_version`, `php_extensions_baseline`, `php_extensions_extra`, `php_extensions_strict`) are accepted for compatibility

Current baseline profile:
- `common` maps to: `mbstring`, `xml`, `curl`, `zip`, `intl`, `gd`, `bcmath`, `mysql`, `opcache`, `readline`
