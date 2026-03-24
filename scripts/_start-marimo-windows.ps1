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
    Log "Configuring marimo theme to 'system' in $configFile"
    
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
            # If [display] exists but theme=system is missing, add it after [display]
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
    Fail "python not found in PATH."
}

if (-not (Test-Path -Path $reqFile)) {
    Fail "requirements.txt not found: $reqFile"
}

Configure-MarimoTheme

if (-not (Test-Path -Path $notebookDir)) {
    Log "Creating notebooks directory: $notebookDir"
    New-Item -ItemType Directory -Path $notebookDir
}

$venvPython = Join-Path -Path $venvDir -ChildPath "Scripts\python.exe"

if (Test-Path -Path $venvPython) {
    Log "Existing virtual environment detected: $venvDir"
} else {
    Log "Creating virtual environment: $venvDir"
    python -m venv $venvDir
}

Log "Updating pip and installing dependencies (locked file)."
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install --upgrade -r $reqFile

if (-not (Test-Path -Path $marimoNotebook)) {
    Log "Creating a minimal marimo notebook: $marimoNotebook"
    @'
import marimo

__generated_with = "0.9.27"
app = marimo.App(width="medium")


@app.cell
def __():
    import polars as pl
    return pl


if __name__ == "__main__":
    app.run()
'@ | Set-Content -Path $marimoNotebook -Encoding UTF8
}

Log "Launching marimo (local-only)."
Log "Expected URL: http://127.0.0.1:2718"
Log "Stop: Ctrl+C in this PowerShell window."
Log "Using venv: $venvDir"

& $venvPython -m marimo edit $marimoNotebook --host 127.0.0.1 --port 2718
