---
name: lua-guidelines
description: "Lua language guidelines for scripts and configuration (.lua), including formatting and validation (lua-language-server / luac -p / selene). Activates for: Lua style, module patterns, wezterm/hammerspoon/rime config, luac, selene. 中文触发：Lua 规范/风格、Lua 配置、wezterm/hammerspoon/rime、luac 校验、selene。"
---

# Lua Guidelines

## Purpose

Define Lua coding standards for scripts and configuration files: style, module boundaries, and lightweight validation.

## Scope

In-scope:
- Editing or creating Lua files (`.lua`)
- Lua-based configuration ecosystems (for example: WezTerm, Hammerspoon, Rime, Neovim tooling)

Out-of-scope:
- Language selection (see `rules/15-language-decision-tree.md`)
- Tool selection and search/refactor workflow (see `rules/20-tool-decision-tree.md`)

## Tool Management

PREFERRED: Use mise to manage Lua toolchain:
```toml
# ~/.config/mise/config.toml
[tools]
lua = "latest"
lua-language-server = "latest"
stylua = "latest"
"cargo:selene" = "latest"
```

REQUIRED: Ensure Rust toolchain is available for cargo backend (mise can manage: `mise use cargo-binstall@latest`).

## Rules (Hard Constraints)

### Namespace
REQUIRED: Use `local` for variables and functions.
PROHIBITED: Mutate `_G` directly; return a module table instead.

### Module Patterns
REQUIRED: Use `local M = {}` + `return M` for modules.
PREFERRED: Use `pcall(require, "mod")` when importing optional dependencies.

### Formatting
PREFERRED: Use `stylua` if available; otherwise use consistent indentation and table formatting.

### Validation
PREFERRED: Use `lua-language-server --check` when available for comprehensive diagnostics.
PREFERRED: Use `luac -p path/to/file.lua` when `luac` is available.
PREFERRED: Fallback to `lua -e 'assert(loadfile("path/to/file.lua"))'` when `lua` is available.

### Linting
PREFERRED: Use `selene` when available; configure per-repo if needed.

## Checklist

- No unintended globals
- Consistent module return style
- Syntax validated (`lua-language-server --check`, `luac -p`, or `loadfile`)
- Lint clean when `selene` is available

## Error Handling

For generic error handling patterns (resilience, resource management, monitoring), see `error-patterns` skill.

### Protected Calls
REQUIRED: Use `pcall` or `xpcall` for operations that may fail.
REQUIRED: Handle errors explicitly; do not ignore return values from `pcall`.

Example:
```lua
local function safe_require(module_name)
    local ok, result = pcall(require, module_name)
    if not ok then
        print("ERROR: Failed to load module: " .. module_name)
        return nil
    end
    return result
end

local function with_error_handler(func, ...)
    local ok, result = xpcall(func, function(err)
        return debug.traceback(err, 2)
    end, ...)
    if not ok then
        print("ERROR: " .. result)
        return nil
    end
    return result
end
```
