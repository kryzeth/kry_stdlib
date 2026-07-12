# Factorio Standard Library 2.1 Continued

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

Mods using the former stdlib2 import root must update their imports when switching to this continuation.

## Compatibility

- Factorio 2.1
- Base game required
- Space Age is optional

## Credits

Originally created by Afforess and maintained by the Factorio modding community. The Factorio 2.0 reupload and fixes by Jackie P. Mueller and contributors are retained. This continuation preserves the original licence and attribution.

## Development

Please report reproducible Factorio 2.1 compatibility problems through this repository's issue tracker. Include the failing module, error message and a minimal usage example where possible.
