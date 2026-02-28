$ErrorActionPreference = "Stop"

function Log($message) {
    Write-Output "[MarimoGenesis:marimo] $message"
}

function Fail($message) {
    Write-Error "[MarimoGenesis:marimo] ERROR: $message"
    exit 1
}

function Configure-MarimoTheme {
    $configFile = Join-Path -Path $HOME -ChildPath ".marimo.toml"
    Log "Configuration du thème marimo sur 'system' dans $configFile"
    
    if (-not (Test-Path -Path $configFile)) {
        @'
[display]
theme = "system"
'@ | Set-Content -Path $configFile -Encoding UTF8
    } else {
        $content = Get-Content -Path $configFile -Raw
        if ($content -notmatch "\[display\]") {
            $content += "`r`n[display]`r`ntheme = `"system`""
            $content | Set-Content -Path $configFile -Encoding UTF8
        } elseif ($content -notmatch "theme\s*=\s*`"system`"") {
            # Si [display] existe mais pas theme=system, on l'ajoute après [display]
            $content = $content -replace "\[display\]", "[display]`r`ntheme = `"system`""
            $content | Set-Content -Path $configFile -Encoding UTF8
        }
    }
}

$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$projectPath = (Resolve-Path (Join-Path -Path $scriptPath -ChildPath "..")).Path
$venvDir = Join-Path -Path $scriptPath -ChildPath "python-dev-env-marimo"
$reqFile = Join-Path -Path $scriptPath -ChildPath "requirements.txt"
$notebookDir = Join-Path -Path $scriptPath -ChildPath "notebooks"
$marimoNotebook = Join-Path -Path $notebookDir -ChildPath "marimo_notebook.py"

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Fail "python introuvable dans le PATH."
}

if (-not (Test-Path -Path $reqFile)) {
    Fail "requirements.txt introuvable: $reqFile"
}

Configure-MarimoTheme

if (-not (Test-Path -Path $notebookDir)) {
    Log "Création du dossier notebooks: $notebookDir"
    New-Item -ItemType Directory -Path $notebookDir
}

$venvPython = Join-Path -Path $venvDir -ChildPath "Scripts\python.exe"

if (Test-Path -Path $venvPython) {
    Log "Environnement virtuel existant détecté: $venvDir"
} else {
    Log "Création de l'environnement virtuel: $venvDir"
    python -m venv $venvDir
}

Log "Mise à jour de pip et installation des dépendances (fichier locké)."
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install --upgrade -r $reqFile

if (-not (Test-Path -Path $marimoNotebook)) {
    Log "Création d'un notebook marimo minimal: $marimoNotebook"
    @'
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
'@ | Set-Content -Path $marimoNotebook -Encoding UTF8
}

Log "Lancement de marimo (local-only)."
Log "URL attendue: http://127.0.0.1:2718"
Log "Arrêt: Ctrl+C dans cette fenêtre PowerShell."
Log "Venv utilisé: $venvDir"

& $venvPython -m marimo edit $marimoNotebook --host 127.0.0.1 --port 2718
