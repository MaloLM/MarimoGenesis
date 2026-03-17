# MarimoGenesis

This repository allows you to quickly launch a ready-to-use local Python environment via script (double-click supported), powered by **marimo**.

![software launching demo gif](./docs/launching_demo.gif)

## Supported Systems

- **macOS** (Bash scripts)
- **Ubuntu/Linux** (Bash scripts)
- **Windows** (PowerShell scripts)

## Prerequisites

- Python 3.10+ recommended, present in your `PATH`
- Internet connection for the first run (dependency installation)

## Available Scripts

In the `scripts/` folder:

- `_start-marimo-macos.sh`
- `_start-marimo-windows.ps1`
- `_start-marimo-ubuntu.sh`

## Dependencies

The repository uses a **single `requirements.txt`** (locked versions):

```txt
polars==1.6.0
marimo[sql]==0.9.17
```

Each script:

1. creates the venv if missing,
2. updates pip,
3. installs/upgrades dependencies via `pip install -r requirements.txt`,
4. launches marimo.

## Virtual Environment (Isolation)

- marimo: `scripts/python-dev-env-marimo`

This keeps your system clean and ensures a simple UX (one script = one environment = one use case).

## Security & Local UX

To respect the "double-click, browser opens automatically" usage:

- local binding to `127.0.0.1`
- automatic browser opening
- **no token/password** for local loopback
- **System theme** configured by default for marimo

> Important: this mode is intended for local use only (personal machine, not exposed).

## Execution

### macOS

```bash
chmod +x scripts/*.sh
./scripts/_start-marimo-macos.sh
```

### Windows (PowerShell)

```powershell
.\scripts\_start-marimo-windows.ps1
```

### Ubuntu/Linux

```bash
chmod +x scripts/*.sh
./scripts/_start-marimo-ubuntu.sh
```

## marimo Notes

On the first run, if `marimo_notebook.py` does not exist in `scripts/notebooks/`, a minimal notebook is automatically generated.

## Customizing Icons

The customization guide is available here:
[Custom Icon Guide](/docs/CUSTOM_ICON.md)

## License

MIT. See [LICENSE](./LICENSE).

## Disclaimer

This software is provided **"as is"**, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
