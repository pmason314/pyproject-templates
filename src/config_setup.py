"""Configuration script for setting up a newly created Python project, just after `uv init`."""

import datetime
import subprocess
import sys
import tomllib
from pathlib import Path

pyproject_path = Path("pyproject.toml")
precommit_path = Path(".pre-commit-config.yaml")
gitignore_path = Path(".gitignore")
license_path = Path("LICENSE")

if not pyproject_path.exists():
    raise FileNotFoundError("pyproject.toml not found in the current directory")

with pyproject_path.open("rb") as f:
    pyproject_data = tomllib.load(f)

CURRENT_YEAR = datetime.datetime.now(tz=datetime.UTC).year
PROJECT_NAME = pyproject_data.get("project", {}).get("name")

# Get author info from command-line arguments
if len(sys.argv) >= 3:
    AUTHOR_NAME = sys.argv[1]
    AUTHOR_EMAIL = sys.argv[2]
else:
    AUTHOR_NAME = ""
    AUTHOR_EMAIL = ""

lines = pyproject_path.read_text().splitlines()

try:
    readme_index = next(idx for idx, line in enumerate(lines) if line.strip().startswith("readme"))
except StopIteration as exc:
    raise ValueError("Could not find a 'readme' line in pyproject.toml") from exc

indent = lines[readme_index][: len(lines[readme_index]) - len(lines[readme_index].lstrip())]
authors_line = f'{indent}authors = [{{name = "{AUTHOR_NAME}", email = "{AUTHOR_EMAIL}"}}]'
license_line = f'{indent}license = "MIT"'
license_files_line = f'{indent}license-files = ["LICENSE"]'
classifiers_line = f'{indent}classifiers = ["Programming Language :: Python :: 3","Natural Language :: English",]'

insertion_index = readme_index + 1

if not any(line.strip().startswith("authors") for line in lines):
    lines.insert(insertion_index, authors_line)
    insertion_index += 1
if not any(line.strip().startswith("license") for line in lines):
    lines.insert(insertion_index, license_line)
    insertion_index += 1
if not any(line.strip().startswith("license-files") for line in lines):
    lines.insert(insertion_index, license_files_line)
    insertion_index += 1
if not any(line.strip().startswith("classifiers") for line in lines):
    lines.insert(insertion_index, classifiers_line)
pyproject_path.write_text("\n".join(lines) + "\n")


def fetch_to_file(url: str, destination: Path, append: bool = False) -> None:
    """Download content with cURL and optionally append it to a file.

    Args:
        url (str): URL to fetch and download from.
        destination (Path): Path of the file to write to.
        append (bool, optional): Whether to append or overwrite. Defaults to False.
    """
    result = subprocess.run(
        ["curl", "-L", url],
        check=True,
        capture_output=True,
        text=True,
    )
    mode = "a" if append else "w"
    with destination.open(mode, encoding="utf-8") as handle:
        handle.write(result.stdout)


def replace_placeholders(paths: list[Path], replacements: dict[str, str]) -> None:
    """Replace placeholder strings in files.

    Args:
        paths (list[Path]): List of file paths to process and replace placeholders in.
        replacements (dict[str, str]): Dictionary of placeholder strings and their replacement values.
    """
    for file_path in paths:
        if not file_path.exists():
            continue
        content = file_path.read_text(encoding="utf-8")
        for key, value in replacements.items():
            content = content.replace(key, value)
        file_path.write_text(content, encoding="utf-8")


subprocess.run(
    ["uv", "add", "--dev", "creosote", "ipykernel", "pre-commit", "pytest", "ruff"],
    check=True,
)
subprocess.run(["pre-commit", "install"], check=False)

fetch_to_file(
    "https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/pyproject_stub.toml",
    pyproject_path,
    append=True,
)
fetch_to_file(
    "https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/.pre-commit-config.yaml",
    precommit_path,
)
fetch_to_file(
    "https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/.gitignore",
    gitignore_path,
)
fetch_to_file(
    "https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/licenses/MIT_LICENSE",
    license_path,
)

replace_placeholders(
    [
        pyproject_path,
        precommit_path,
        gitignore_path,
        license_path,
    ],
    {
        "CURRENT_YEAR": str(CURRENT_YEAR),
        "PROJECT_NAME": PROJECT_NAME or "",
        "AUTHOR_NAME": AUTHOR_NAME or "",
    },
)


Path(PROJECT_NAME).mkdir(exist_ok=True)
Path(PROJECT_NAME, "__init__.py").touch()
Path("tests").mkdir(exist_ok=True)
if Path("main.py").exists():
    Path("main.py").rename(Path(PROJECT_NAME, "main.py"))
else:
    Path(PROJECT_NAME, "main.py").touch()
