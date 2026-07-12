#!/usr/bin/env python3
"""Apply the stdlib2 continuation rename and initial Factorio 2.1 port.

This script is intentionally deterministic and idempotent. It rewrites the
cross-mod import root throughout the repository, updates release metadata, and
applies the first confirmed Factorio 2.1 compatibility fixes.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SELF = Path(__file__).resolve()
OLD_IMPORT_ROOT = "__stdlib2__"
NEW_IMPORT_ROOT = "__stdlib2-continued__"
SEPARATOR = "-" * 99 + "\n"


def read_text(path: Path) -> str | None:
    """Return UTF-8 text, skipping binary and non-UTF-8 files."""
    data = path.read_bytes()
    if b"\0" in data:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return None


def write_if_changed(path: Path, content: str) -> bool:
    current = path.read_text(encoding="utf-8") if path.exists() else None
    if current == content:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    return True


def rewrite_import_roots() -> list[Path]:
    changed: list[Path] = []
    skipped_directories = {".git", "dist", "__pycache__"}

    for path in ROOT.rglob("*"):
        if not path.is_file() or path == SELF:
            continue
        if any(part in skipped_directories for part in path.parts):
            continue

        text = read_text(path)
        if text is None or OLD_IMPORT_ROOT not in text:
            continue

        updated = text.replace(OLD_IMPORT_ROOT, NEW_IMPORT_ROOT)
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed.append(path)

    return changed


def update_info_json() -> bool:
    path = ROOT / "info.json"
    info = json.loads(path.read_text(encoding="utf-8"))
    info.update(
        {
            "name": "stdlib2-continued",
            "version": "2.1.0",
            "factorio_version": "2.1",
            "title": "Factorio Standard Library 2.1 Continued",
            "author": "Afforess, Jackie P. Mueller, Goakiller900",
            "contact": "https://github.com/goakiller900/stdlib2/issues",
            "homepage": "https://github.com/goakiller900/stdlib2",
            "dependencies": ["base >= 2.1"],
            "description": (
                "Community-maintained continuation of Factorio Standard Library "
                "for Factorio 2.1. Provides commonly used utilities and helper "
                "APIs for other mods."
            ),
        }
    )
    return write_if_changed(path, json.dumps(info, indent=2, ensure_ascii=False) + "\n")


def patch_lua_object_detection() -> bool:
    path = ROOT / "stdlib" / "utils" / "is.lua"
    text = path.read_text(encoding="utf-8")
    old = "return M.Table(var) and var.__self and var"
    new = "return M.Userdata(var) and var"

    if new in text:
        return False
    if old not in text:
        raise RuntimeError(f"Expected LuaObject detection code was not found in {path}")

    return write_if_changed(path, text.replace(old, new, 1))


def patch_recipe_categories() -> bool:
    path = ROOT / "stdlib" / "data" / "recipe.lua"
    text = path.read_text(encoding="utf-8")
    old = """--- Change the recipe category.\n-- @tparam string category_name The new crafting category\n-- @treturn self\nfunction Recipe:change_category(category_name)\n    if self:is_valid() then\n        local Category = require('__stdlib2-continued__/stdlib/data/category')\n        self.category = Category(category_name, 'recipe-category'):is_valid() and category_name or self.category\n    end\n    return self\nend\nRecipe.set_category = Recipe.change_category\n"""
    new = """--- Change the recipe categories.\n-- @tparam string|table category_names The new crafting category or categories\n-- @treturn self\nfunction Recipe:change_category(category_names)\n    if not self:is_valid() then\n        return self\n    end\n\n    if type(category_names) == 'string' then\n        category_names = {category_names}\n    end\n    if type(category_names) ~= 'table' or #category_names == 0 then\n        return self\n    end\n\n    local Category = require('__stdlib2-continued__/stdlib/data/category')\n    local valid_categories = {}\n    for _, category_name in ipairs(category_names) do\n        if Category(category_name, 'recipe-category'):is_valid() then\n            valid_categories[#valid_categories + 1] = category_name\n        end\n    end\n\n    if #valid_categories == #category_names then\n        self.categories = valid_categories\n        self.category = nil\n    end\n    return self\nend\nRecipe.set_category = Recipe.change_category\nRecipe.set_categories = Recipe.change_category\n"""

    if new in text:
        return False
    if old not in text:
        raise RuntimeError(f"Expected recipe category function was not found in {path}")

    return write_if_changed(path, text.replace(old, new, 1))


def patch_recipe_copy_guard() -> bool:
    path = ROOT / "stdlib" / "data" / "data.lua"
    text = path.read_text(encoding="utf-8")
    old = "if copy.type == 'recipe' then\n            -- recipes with more than 1 result are too ambiguous to replace\n            if #copy.results == 1 then"
    new = "if copy.type == 'recipe' and copy.results then\n            -- recipes with more than 1 result are too ambiguous to replace\n            if #copy.results == 1 then"

    if new in text:
        return False
    if old not in text:
        raise RuntimeError(f"Expected recipe copy block was not found in {path}")

    return write_if_changed(path, text.replace(old, new, 1))


def update_changelog() -> bool:
    path = ROOT / "changelog.txt"
    text = path.read_text(encoding="utf-8")
    if "Version: 2.1.0" in text:
        return False

    entry = (
        SEPARATOR
        + "Version: 2.1.0\n"
        + "Date: 2026-07-12\n"
        + "  Changes:\n"
        + "    - Renamed the mod to stdlib2-continued for a new community-maintained Mod Portal release.\n"
        + "    - Updated the minimum supported Factorio version to 2.1.\n"
        + "    - Rewrote all cross-mod import paths for the new internal mod name.\n"
        + "  Bugfixes:\n"
        + "    - Updated Recipe:change_category to use the Factorio 2.1 categories array.\n"
        + "    - Updated LuaObject detection for userdata-based Factorio objects.\n"
        + "    - Made recipe copying tolerate recipes without a results table.\n"
    )
    return write_if_changed(path, entry + text)


def update_readme() -> bool:
    path = ROOT / "readme.md"
    content = """# Factorio Standard Library 2.1 Continued

An unofficial community-maintained continuation of the Factorio Standard Library for Factorio 2.1.

The library provides reusable utilities for events, data-stage prototype manipulation, positions, areas, tables, logging, player data and other common modding tasks.

## Status

This branch is the initial Factorio 2.1 port and is still undergoing compatibility testing. The existing public API is preserved where practical, but not every historical module has yet been exercised in Factorio 2.1.

## Usage

Add the continuation as a dependency:

```json
"dependencies": [
  "stdlib2-continued >= 2.1.0"
]
```

Import modules through the new mod root:

```lua
local Event = require("__stdlib2-continued__/stdlib/event/event")
```

Mods using the former `__stdlib2__/` path must update their imports when switching to this continuation.

## Compatibility

- Factorio 2.1
- Base game required
- Space Age is optional

## Credits

Originally created by Afforess and maintained by the Factorio modding community. The Factorio 2.0 reupload and fixes by Jackie P. Mueller and contributors are retained. This continuation preserves the original licence and attribution.

## Development

Please report reproducible Factorio 2.1 compatibility problems through this repository's issue tracker. Include the failing module, error message and a minimal usage example where possible.
"""
    return write_if_changed(path, content)


def validate() -> None:
    info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
    assert info["name"] == "stdlib2-continued"
    assert info["version"] == "2.1.0"
    assert info["factorio_version"] == "2.1"

    stale_paths: list[str] = []
    for path in ROOT.rglob("*"):
        if not path.is_file() or path == SELF or ".git" in path.parts:
            continue
        text = read_text(path)
        if text is not None and OLD_IMPORT_ROOT in text:
            stale_paths.append(str(path.relative_to(ROOT)))

    if stale_paths:
        raise RuntimeError(
            "Legacy __stdlib2__ import roots remain in: " + ", ".join(stale_paths)
        )


def main() -> None:
    changed = rewrite_import_roots()
    direct_changes = {
        "info.json": update_info_json(),
        "stdlib/utils/is.lua": patch_lua_object_detection(),
        "stdlib/data/recipe.lua": patch_recipe_categories(),
        "stdlib/data/data.lua": patch_recipe_copy_guard(),
        "changelog.txt": update_changelog(),
        "readme.md": update_readme(),
    }
    validate()

    changed.extend(ROOT / path for path, did_change in direct_changes.items() if did_change)
    unique = sorted({path.relative_to(ROOT).as_posix() for path in changed})
    print(f"Updated {len(unique)} files.")
    for path in unique:
        print(path)


if __name__ == "__main__":
    main()
