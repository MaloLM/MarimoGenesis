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
  log "Configuration du thème marimo sur 'system' dans ${config_file}"
  
  if [ ! -f "${config_file}" ]; then
    echo '[display]' > "${config_file}"
    echo 'theme = "system"' >> "${config_file}"
  else
    if ! grep -q "\[display\]" "${config_file}"; then
      echo -e "\n[display]\ntheme = \"system\"" >> "${config_file}"
    elif ! grep -q "theme = \"system\"" "${config_file}"; then
      # Si [display] existe mais pas theme=system, on tente un remplacement simple ou ajout
      # Pour rester safe et simple, on s'assure juste que la ligne theme est là sous [display]
      sed -i.bak '/\[display\]/a \
theme = "system"' "${config_file}" && rm "${config_file}.bak"
    fi
  fi
}

command -v python3 >/dev/null 2>&1 || fail "python3 introuvable dans le PATH."
[ -f "${REQ_FILE}" ] || fail "requirements.txt introuvable: ${REQ_FILE}"

configure_marimo_theme

if [ ! -d "${NOTEBOOK_DIR}" ]; then
  log "Création du dossier notebooks: ${NOTEBOOK_DIR}"
  mkdir -p "${NOTEBOOK_DIR}"
fi

if [ -d "${VENV_DIR}/bin" ]; then
  log "Environnement virtuel existant détecté: ${VENV_DIR}"
else
  log "Création de l'environnement virtuel: ${VENV_DIR}"
  python3 -m venv "${VENV_DIR}" || fail "Impossible de créer le virtualenv."
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

CURRENT_PYTHON="$(command -v python)"
EXPECTED_PYTHON="${VENV_DIR}/bin/python"
[ "${CURRENT_PYTHON}" = "${EXPECTED_PYTHON}" ] || fail "Python actif inattendu: ${CURRENT_PYTHON} (attendu: ${EXPECTED_PYTHON})"

log "Mise à jour de pip et installation des dépendances (fichier locké)."
python -m pip install --upgrade pip
python -m pip install --upgrade -r "${REQ_FILE}"

if [ ! -f "${MARIMO_NOTEBOOK}" ]; then
  log "Création d'un notebook marimo minimal: ${MARIMO_NOTEBOOK}"
  cat > "${MARIMO_NOTEBOOK}" <<'PYEOF'
import marimo

__generated_with = "0.9.27"
app = marimo.App(width="medium")


@app.cell
def __():
    import numpy as np
    import polars as pl
    return np, pl


@app.cell
def __(np, pl):
    df = pl.DataFrame({"x": np.arange(5), "y": np.arange(5) ** 2})
    return (df,)


@app.cell
def __(df):
    df
    return


if __name__ == "__main__":
    app.run()
PYEOF
fi

log "Lancement de marimo (local-only)."
log "URL attendue: http://127.0.0.1:2718"
log "Arrêt: Ctrl+C dans la fenêtre Terminal ouverte par le script."
log "Venv utilisé: ${VENV_DIR}"

exec python -m marimo edit "${MARIMO_NOTEBOOK}" --host 127.0.0.1 --port 2718
