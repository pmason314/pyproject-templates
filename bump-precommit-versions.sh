 # Script to programmatically update pre-commit hook versions in the cookiecutter.
 # Grabs the most recent versions using `pip index versions`, since package versions on PyPI match the 
 #  GitHub pre-commit releases apart from the initial `v` (e.g. `v1.2.3` vs. `1.2.3`)

# Pre-commit dependency list
deps=(pre-commit-hooks codespell ruff creosote)
pc_path="src/.pre-commit-config.yaml"

for hook in ${deps[@]}
do
    python -m pip install --upgrade pip >/dev/null 2>&1
    version=$(python -m pip index versions $hook 2>/dev/null | grep -Po '\(\K([\d|\.]+)')
    # ruff-pre-commit doesn't have a PyPI package but instead matches the ruff version number for its releases
    if [ $hook = "ruff" ]; then
        hook="ruff-pre-commit"
    fi
    echo "Version $version found for $hook"
    perl -0777pi -e "s/(?<=- repo: https:\/\/github.com\/.{1,50}$hook\s{1,10}rev: v?)([\d|\.]{1,20})/$version/g" "$pc_path" >/dev/null 2>&1
done

# Perl regex primer for sanity:
# - The "-0777" applies the regex to the entire file instead of line-by-line
# - The "i" flag applies case-insensitive matching
# - The "p" flag preserves the matched string for use after matching.  Ignored in Perl >=5.20
# - "s/x/y" substitutes x with y
# - "?<=" is a zero-width positive lookbehind assertion.  Can match a word that comes after another word, without including the second word in the match.