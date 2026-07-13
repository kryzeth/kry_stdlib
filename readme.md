# Factorio Standard Library

An unofficial community-maintained continuation of the Factorio Standard Library for Factorio 2.1.

The library provides reusable utilities for events, data-stage prototype manipulation, positions, areas, tables, logging, player data and other common modding tasks.

## Usage

In your `info.json`, add `stdlib` as a required dependency:

```json
"dependencies": [
  "kry_stdlib"
]
```

In your `data.lua`, `control.lua`, or any other lua scripts, import required stdlib modules:

```lua
local Recipe = require("__kry_stdlib__/stdlib/data/recipe")
local Event = require("__kry_stdlib__/stdlib/event/event")
```

Mods using the former stdlib import node must update their imports when switching to this version.

## Documentation

-- add this later

## Credits

Originally created by Afforess during Factorio versions 1.0 and 1.1, and maintained primarily by Kryzeth for Factorio versions 2.0 and 2.1, as well as the Factorio modding community. This version preserves the original licence and attribution.

## Development

Please report reproducible Factorio 2.1 compatibility problems through the mod portal or this repository's issue tracker. Include the failing module, error message and a minimal usage example where possible.
