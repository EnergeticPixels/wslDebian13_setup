#!/usr/bin/env bash
set -euo pipefail

log() {
	printf '[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"
PYTHON_LIB="$SCRIPT_DIR/lib/python.sh"

if [[ ! -f "$PYTHON_LIB" ]]; then
	echo "Error: Python library not found at $PYTHON_LIB" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$PYTHON_LIB"

main() {
	load_python_env
	validate_python_dev_mode

	# Early exit if Python is not enabled
	if ! python_is_enabled; then
		log "PYTHON_ENABLE is false. Skipping Python installation."
		exit 0
	fi

	log "=== Python Installation Starting ==="
	log "Base Python: ENABLED"
	log "Data Science Stack: $PYTHON_DATA_SCIENCE_STACK_ENABLE"
	log "Dev Mode: $PYTHON_DEV_MODE"

	# Update package lists
	apt-get update

	# Install base Python packages
	log "Installing base Python packages..."
	apt-get install -y \
		python3 \
		python3-pip \
		python3-venv \
		python3-dev \
		build-essential

	# Upgrade pip to latest version
	log "Upgrading pip to latest version..."
	python3 -m pip install --upgrade pip

	# Always install requests (core dependency)
	log "Installing requests (core dependency)..."
	pip_install_latest requests

	# Handle Data Science Stack (optional, only if enabled)
	if [[ "$PYTHON_DATA_SCIENCE_STACK_ENABLE" == "true" ]]; then
		log "Installing data science stack (numpy, pandas)..."
		pip_install_latest numpy pandas
	else
		log "Data science stack disabled (PYTHON_DATA_SCIENCE_STACK_ENABLE=false)"
	fi

	# Handle Dev Mode based on dispatcher pattern (optional)
	case "$PYTHON_DEV_MODE" in
		reflex)
			log "Dev Mode: Installing Reflex framework (recommended for Python development)"
			pip_install_latest reflex flask pytest
			;;
		flask)
			log "Dev Mode: Installing Flask framework"
			pip_install_latest flask pytest
			;;
		both)
			log "Dev Mode: Installing both Reflex and Flask frameworks"
			pip_install_latest reflex flask pytest
			;;
		none)
			log "Dev Mode disabled (PYTHON_DEV_MODE=none)"
			;;
		*)
			echo "Invalid PYTHON_DEV_MODE: $PYTHON_DEV_MODE" >&2
			exit 1
			;;
	esac

	# Verify installations
	log "Verifying Python installation..."
	verify_python_package sys

	# Verify requests (always installed)
	if ! verify_python_package requests; then
		log "WARNING: requests package could not be verified"
	fi

	# Verify data science stack if enabled
	if [[ "$PYTHON_DATA_SCIENCE_STACK_ENABLE" == "true" ]]; then
		if ! verify_python_package numpy; then
			log "WARNING: numpy package could not be verified"
		fi
		if ! verify_python_package pandas; then
			log "WARNING: pandas package could not be verified"
		fi
	fi

	# Verify dev frameworks if enabled
	case "$PYTHON_DEV_MODE" in
		reflex)
			if ! verify_python_package reflex; then
				log "WARNING: reflex package could not be verified"
			fi
			if ! verify_python_package flask; then
				log "WARNING: flask package could not be verified"
			fi
			if ! python3 -c "import pytest" 2>/dev/null; then
				log "WARNING: pytest module could not be verified"
			fi
			;;
		flask)
			if ! verify_python_package flask; then
				log "WARNING: flask package could not be verified"
			fi
			if ! python3 -c "import pytest" 2>/dev/null; then
				log "WARNING: pytest module could not be verified"
			fi
			;;
		both)
			if ! verify_python_package reflex; then
				log "WARNING: reflex package could not be verified"
			fi
			if ! verify_python_package flask; then
				log "WARNING: flask package could not be verified"
			fi
			if ! python3 -c "import pytest" 2>/dev/null; then
				log "WARNING: pytest module could not be verified"
			fi
			;;
		none)
			;;
	esac

	# Print summary
	log ""
	log "=== Python Installation Summary ==="
	log "Python: $(python3 --version)"
	log "pip: $(python3 -m pip --version)"

	if [[ "$PYTHON_DATA_SCIENCE_STACK_ENABLE" == "true" ]]; then
		log "numpy: $(get_pip_package_version numpy)"
		log "pandas: $(get_pip_package_version pandas)"
	fi

	log "requests: $(get_pip_package_version requests)"

	case "$PYTHON_DEV_MODE" in
		reflex)
			log "reflex: $(get_pip_package_version reflex) (recommended for Python development)"
			log "flask: $(get_pip_package_version flask)"
			log "pytest: $(python3 -m pip show pytest 2>/dev/null | grep Version: | cut -d' ' -f2)"
			;;
		flask)
			log "flask: $(get_pip_package_version flask)"
			log "pytest: $(python3 -m pip show pytest 2>/dev/null | grep Version: | cut -d' ' -f2)"
			;;
		both)
			log "reflex: $(get_pip_package_version reflex)"
			log "flask: $(get_pip_package_version flask)"
			log "pytest: $(python3 -m pip show pytest 2>/dev/null | grep Version: | cut -d' ' -f2)"
			;;
		none)
			;;
	esac

	log "=== Python Installation Complete ==="
}

main "$@"
