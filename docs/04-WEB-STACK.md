# Web Stack

## Web server selection

Set `WEB_SERVER` in `.env`:
- `WEB_SERVER=apache` installs Apache (`apache2` package)
- `WEB_SERVER=nginx` installs Nginx (`nginx` package)

If `WEB_SERVER` is unset, web server installation is skipped.
`web_server` is accepted for compatibility.

Scripts:
- `scripts/web_server_install.sh` selects installer by `WEB_SERVER`
- `scripts/web_server_apache_install.sh` handles Apache
- `scripts/web_server_nginx_install.sh` handles Nginx

Run only web server setup:

```bash
sudo bash scripts/web_server_install.sh
```

## PHP provisioning

Enable/disable per run:
- `PHP_ENABLE=true` installs PHP alongside selected web server
- `PHP_ENABLE=false` skips PHP

Set PHP version:
- `PHP_VERSION=7.4|8.0|8.1|8.2|8.3`

Extension planning:
- `PHP_EXTENSIONS_BASELINE=common` for default profile
- `PHP_EXTENSIONS_BASELINE=none` to disable baseline
- `PHP_EXTENSIONS_EXTRA=` comma-separated extras (example: `soap,pgsql`)
- `PHP_EXTENSIONS_STRICT=true` fail when requested extension package is unavailable
- `PHP_EXTENSIONS_STRICT=false` skip unavailable packages with warning

Database driver extension selection:
- `PHP_DB_DRIVER_MODE=auto|mysql|postgres|none`
- In `auto` mode, selection follows `DATABASE_TYPE`

Behavior details:
- Apache and Nginx use `php-fpm` integration
- Scripts prefer distro packages first
- If requested version is unavailable, installer adds Sury repository and retries
- Lowercase compatibility keys are accepted (`php_enable`, `php_version`, etc.)

Current baseline profile:
- `common` maps to `mbstring`, `xml`, `curl`, `zip`, `intl`, `gd`, `bcmath`, `opcache`, `readline`

## Tomcat note

If Java mode is Tomcat, see runtime details in [Runtimes](03-RUNTIMES.md).
