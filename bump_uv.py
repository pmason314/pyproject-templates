# /// script
# requires-python = ">=3.11"
# ///
"""Bump pyproject.toml dependency minimum versions to match uv.lock.

Runs `uv sync --all-extras --upgrade`, then updates all `>=`, `~=`, and `>`
version specifiers in pyproject.toml files to reflect the resolved versions.

Usage:
    uv run uv_bump.py [-v|--verbose] [--no-upgrade] [pyproject.toml]
"""

import argparse
import re
import subprocess
import sys
import tomllib
from pathlib import Path

LOCK_FILE_NAME = "uv.lock"
PYPROJECT_FILE_NAME = "pyproject.toml"


def main() -> None:
    """Bump minimum versions of pyproject.toml dependency specifiers.

    Run as `uv run uv_bump.py`.

    Returns:
        None
    """
    parser = argparse.ArgumentParser(description="Bump pyproject.toml minimum versions to match uv.lock")
    parser.add_argument("-v", "--verbose", action="store_true", help="show per-file version changes")
    parser.add_argument("--no-upgrade", action="store_true", help="skip --upgrade flag on uv sync")
    args = parser.parse_args()

    root = Path(PYPROJECT_FILE_NAME)
    lock_path = root.parent / LOCK_FILE_NAME

    # Scan pyproject files first to find which packages have bumpable specifiers
    pyproject_files = collect_pyproject_files(lock_path)
    relevant_packages = set()
    for pyproject_file in pyproject_files:
        relevant_packages.update(scan_bumpable_packages(pyproject_file))

    lock_before = collect_lock_versions(lock_path, relevant_packages)
    run_uv_sync()
    lock_after = collect_lock_versions(lock_path, relevant_packages)

    for pyproject_file in pyproject_files:
        packages_updated, before_versions = update_pyproject(pyproject_file, lock_after)
        if args.verbose:
            print(f"Processed {pyproject_file}")
            print_changes(before_versions, packages_updated, lock_before, lock_after)


def run_uv_sync() -> None:
    """Run `uv sync` as a subprocess.

    Returns:
        None
    """
    args = ["uv", "sync", "--all-extras", "--upgrade"]
    result = subprocess.run(args, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)


def scan_bumpable_packages(pyproject_file: Path) -> set[str]:
    """Find package names in a pyproject.toml that have bumpable version specifiers (>=, ~=, >)."""
    text = pyproject_file.read_text(encoding="utf-8")
    pattern = r'"([a-zA-Z0-9](?:[a-zA-Z0-9._-]*[a-zA-Z0-9])?)(?:\[[^\]]*\])?\s*(?:>=|~=|>)'
    return {re.sub(r"[-_.]+", "-", m.group(1)).lower() for m in re.finditer(pattern, text)}


def collect_lock_versions(lock_path: Path, relevant: set[str]) -> dict[str, str]:
    """Collect versions only for packages we care about, avoiding a full parse of large lock files."""
    contents = tomllib.loads(lock_path.read_text(encoding="utf-8"))
    return {p["name"]: p["version"] for p in contents["package"] if "version" in p and p["name"] in relevant}


def collect_pyproject_files(lock_path: Path) -> list[Path]:
    """Determine all pyproject.toml file locations from uv.lock, supporting workspaces.

    Args:
        lock_path: Path to the uv.lock file.

    Returns:
        List of paths to pyproject.toml files in the project.
    """
    contents = tomllib.loads(lock_path.read_text(encoding="utf-8"))
    if "manifest" in contents and "members" in contents["manifest"]:
        paths: list[Path] = []
        for member in contents["manifest"]["members"]:
            paths.extend(
                lock_path.parent / pkg["source"][source_type] / PYPROJECT_FILE_NAME
                for pkg in contents["package"]
                if pkg["name"] == member
                for source_type in ("editable", "virtual")
                if source_type in pkg["source"]
            )
        return paths
    return [lock_path.parent / PYPROJECT_FILE_NAME]


def update_pyproject(file: Path, package_versions: dict[str, str]) -> tuple[list[str], dict[str, str]]:
    """Update a pyproject.toml file, bumping minimum version bounds to match the lock file.

    Args:
        file: Path to the pyproject.toml file to update.
        package_versions: Mapping of package names to their resolved versions.

    Returns:
        Tuple of (list of updated package names, dict mapping package to its previous version).
    """
    contents = file.read_text(encoding="utf-8")
    updated = []
    before_versions = {}
    for package, version in package_versions.items():
        contents, count, before = _replace_version(contents, package, version)
        if count > 0:
            updated.append(package)
            if before is not None:
                before_versions[package] = before
    file.write_text(contents, encoding="utf-8")
    return updated, before_versions


def _replace_version(text: str, package: str, version: str) -> tuple[str, int, str | None]:
    escaped = re.escape(package)
    pattern = r'"(' + escaped + r'(?:\[[^\]]*\])?)\s*(>=|~=|>)\s*([^"`,;]+)'
    replacement = r'"\1>=' + version

    match = re.search(pattern, text)
    before = match.group(3).strip() if match else None

    text_updated = re.sub(pattern, replacement, text)
    num_changes = sum(a != b for a, b in zip(text.splitlines(), text_updated.splitlines(), strict=True))
    return text_updated, num_changes, before


def print_changes(
    before_versions: dict[str, str],
    packages_updated: list[str],
    lock_before: dict[str, str],
    lock_after: dict[str, str],
) -> None:
    """Print a table showing lock file and pyproject.toml version changes.

    Args:
        before_versions: Mapping of package names to their previous pyproject.toml versions.
        packages_updated: List of package names that were bumped.
        lock_before: Lock file versions before sync.
        lock_after: Lock file versions after sync.
    """
    print("\tPackage\t\tLock file\t\tpyproject.toml")
    for pkg in packages_updated:
        lock_b, lock_a = lock_before.get(pkg, "?"), lock_after.get(pkg, "?")
        pyproject_b = before_versions.get(pkg, "?")
        lock_str = f"{lock_b} → {lock_a}" if lock_b != lock_a else "-"
        print(f"\t{pkg}\t\t{lock_str}\t\t{pyproject_b} → {lock_a}")
    if not packages_updated:
        print("\tNo packages updated")


if __name__ == "__main__":
    main()
