#!/usr/bin/env bash
# This script checks which foreign packages (such as AUR packages) are locally installed
# and it compares their names to the package names in the distribution's repository,
# outputting potential matches on a per-package basis.
# Note that this is not perfectly accurate due to differences in naming.

dist_pkgs=$(expac -S '%n') # List all distribution packages

while read -r pkg; do
    pkg_base=$(sed -E 's/-(bin|dev|devel|git|nightly|stable)$//' <<<"$pkg")
    perfect_match=$(grep -Fx "$pkg_base" <<<"$dist_pkgs")
    fuzzy_match=$(grep -E "^$pkg_base" <<<"$dist_pkgs" | grep -vx "$pkg_base" | sort -u)

    if [[ -n "$perfect_match" || -n "$fuzzy_match" ]]; then
        echo "$pkg"

        if [[ -n "$perfect_match" ]]; then
            echo "  Exact match:"
            echo "$perfect_match" | sed 's/^/    -> /'
        fi

        if [[ -n "$fuzzy_match" ]]; then
            echo "  Partial matches:"
            echo "$fuzzy_match" | sed 's/^/    -> /'
        fi

        echo
    fi

done < <(pacman -Qmq) # List foreign installed packages
