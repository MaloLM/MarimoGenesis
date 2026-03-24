#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENV_DIR="${SCRIPT_DIR}/python-dev-env-marimo"
REQ_FILE="${SCRIPT_DIR}/requirements.txt"
NOTEBOOK_DIR="${SCRIPT_DIR}/notebooks"
MARIMO_NOTEBOOK="${NOTEBOOK_DIR}/marimo_notebook.py"
LOG_PREFIX="[MarimoGenesis:marimo]"

log() {
  echo "${LOG_PREFIX} $1"
}

fail() {
  echo "${LOG_PREFIX} ERROR: $1" >&2
  exit 1
}

configure_marimo_theme() {
  local config_file="${HOME}/.marimo.toml"
  log "Configuring marimo theme to 'system' in ${config_file}"
  
  if [ ! -f "${config_file}" ]; then
    echo '[display]' > "${config_file}"
    echo 'theme = "system"' >> "${config_file}"
  else
    if ! grep -q "\[display\]" "${config_file}"; then
      echo -e "\n[display]\ntheme = \"system\"" >> "${config_file}"
    elif ! grep -q "theme = \"system\"" "${config_file}"; then
      # If [display] exists but theme=system is missing, try a simple replacement or append
      # Keep it safe and simple: ensure the theme line is present under [display]
      sed -i.bak '/\[display\]/a \
theme = "system"' "${config_file}" && rm "${config_file}.bak"
    fi
  fi
}

command -v python3 >/dev/null 2>&1 || fail "python3 not found in PATH."
[ -f "${REQ_FILE}" ] || fail "requirements.txt not found: ${REQ_FILE}"

configure_marimo_theme

if [ ! -d "${NOTEBOOK_DIR}" ]; then
  log "Creating notebooks directory: ${NOTEBOOK_DIR}"
  mkdir -p "${NOTEBOOK_DIR}"
fi

if [ -d "${VENV_DIR}/bin" ]; then
  log "Existing virtual environment detected: ${VENV_DIR}"
else
  log "Creating virtual environment: ${VENV_DIR}"
  python3 -m venv "${VENV_DIR}" || fail "Unable to create virtual environment."
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

CURRENT_PYTHON="$(command -v python)"
EXPECTED_PYTHON="${VENV_DIR}/bin/python"
[ "${CURRENT_PYTHON}" = "${EXPECTED_PYTHON}" ] || fail "Unexpected active Python: ${CURRENT_PYTHON} (expected: ${EXPECTED_PYTHON})"

log "Updating pip and installing dependencies (locked file)."
python -m pip install --upgrade pip
python -m pip install --upgrade -r "${REQ_FILE}"

if [ ! -f "${MARIMO_NOTEBOOK}" ]; then
  log "Creating a minimal marimo notebook: ${MARIMO_NOTEBOOK}"
  cat > "${MARIMO_NOTEBOOK}" <<'PYEOF'
import marimo

__generated_with = "0.9.27"
app = marimo.App(width="medium")


@app.cell
def __():
    import polars as pl
    return pl


if __name__ == "__main__":
    app.run()
PYEOF
fi

log "Launching marimo (local-only)."
log "Expected URL: http://127.0.0.1:2718"
log "Stop: Ctrl+C in the Terminal window opened by the script."
log "Using venv: ${VENV_DIR}"

cd "${PROJECT_DIR}"
exec python -m marimo edit "${MARIMO_NOTEBOOK}" --host 127.0.0.1 --port 2718
