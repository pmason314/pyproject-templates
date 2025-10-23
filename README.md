# Pyproject Templates <!-- omit in toc -->

A streamlined setup script for creating fully configured Python projects out of the box.

## Table of Contents <!-- omit in toc -->
- [Overview and Features](#overview-and-features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Development Workflow](#development-workflow)
- [Contributing](#contributing)
- [License](#license)

## Overview and Features

This repository provides a setup script that configures new Python projects with an opinionated but comprehensive configuration setup for various development tools.  It's designed to work with brand-new projects (i.e. an empty folder) or projects that have just been instantiated with [uv](https://docs.astral.sh/uv/)'s `uv init`.  The setup script does the following:
- **Project Initialization**: Creates a new Python project using uv if one doesn't already exist
- **Development Tooling**: Installs and configures:
  - [ruff](https://github.com/astral-sh/ruff) - Fast Python linter and formatter
  - [pytest](https://pytest.org/) - Unit testing framework
  - [pre-commit](https://pre-commit.com/) - Git hooks for automated linting, formatting, and other quality checks
  - [creosote](https://github.com/fredrikaverpil/creosote) - Unused dependency checker
  - [ipykernel](https://ipython.readthedocs.io/en/stable/install/kernel_install.html) - Jupyter notebook support
- **License Templates**: Supports [selecting an appropriate open-source license](https://choosealicense.com/licenses/) (MIT, Apache 2.0, GPLv3, AGPLv3)
- **Pre-Configured Settings**: Includes (opinionated) rules and settings for the each of the above development tools

## Quick Start

Run the setup script in either an empty directory or an existing project after running `uv init`:
```bash
curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh -o setup.sh && sh setup.sh
```

You can also create an alias for the setup script for easier repeated use.  A couple examples:

**Bash**

```bash
echo 'alias pysetup="curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh -o setup.sh && sh setup.sh"' >> ~/.bashrc && source ~/.bashrc
```

**Zsh**

```bash
echo 'alias pysetup="curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh -o setup.sh && sh setup.sh"' >> ~/.zshrc && source ~/.zshrc
```

Then simply call `pysetup` to run the setup script in your project directory.

To inspect the setup script before running it:
```bash
curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh | less -R
```

## Project Structure

After running the setup script on a brand new project, your project will look like:

```
your-project/
├── .git/
├── .gitignore
├── .pre-commit-config.yaml
├── .venv/
├── .env
├── LICENSE (if selected)
├── pyproject.toml
├── your-project/
│   ├── __init__.py
│   └── main.py
└── tests/
```

## Requirements

- [**uv**](https://docs.astral.sh/uv/): Will be automatically installed if not present
- [**curl**](https://curl.se/): For downloading files from this repository

## Development Workflow

After setup, use these common commands:

```bash
# Activate the virtual environment
source .venv/bin/activate

# Add new production dependencies
uv add <package-name>

# Add new development dependencies
uv add --dev <package-name>

# Lint and format code
uv run ruff check .
uv run ruff format .

# Check for unused dependencies
uv run creosote

# Run tests
uv run pytest
```

You can adjust configurations for all of these tools in pyproject.toml.  Each section has a link to the relevant options or rules.

Additionally, pre-commit is automatically installed and several pre-commit hooks are pre-configured in .pre-commit-config.yaml.  

## Contributing

Contributions are welcome! Feel free to report bugs or suggest new features.

## License

This project is available under the MIT License.
