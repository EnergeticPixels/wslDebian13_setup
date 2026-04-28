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

### Developed with


### Provisioning with:


### Constraints
This repo is targeted for Windows 11 host with WSL2 and Debian (Trixie) distribution.
If you want tmux configured automatically, set `TMUX_CONFIG_URL` in `.env` to your raw Gist URL for `.tmux.conf`.
Example: https://gist.github.com/<your-github-username>/<gist-hash>/raw/<your-gist-filename>
If no URL is provided, the provisioning flow skips tmux installation and continues normally.  You can always install tmux after the automated provisioning scripts complete.
