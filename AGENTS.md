# AGENTS.md

Agent operating guide for this repository (`~/.config/nvim`).

## Scope
- Applies to the entire repo.
- Language: Lua (Neovim runtime), not a standalone Lua app.
- Keep changes small, local, and reversible.
- Prefer existing patterns over introducing new architecture.

## Repository Map
- `init.lua`: entrypoint; requires core config modules.
- `lua/config/set.lua`: options and core autocmds.
- `lua/config/remap.lua`: global keymaps and utility mappings.
- `lua/config/lazy.lua`: lazy.nvim bootstrap + setup.
- `lua/config/plugins/init.lua`: plugin specs.
- `after/plugin/*.lua`: plugin-specific setup after load.
- `plugin/*.lua`: custom runtime plugins/commands.
- `lua/config/services.lua`: optional local service definitions.
- `lua/config/git_workflow.lua`: optional local git workflow settings.
- `lazy-lock.json`: pinned plugin versions.

## Rule Files (Cursor / Copilot)
- Checked `.cursor/rules/`: not present.
- Checked `.cursorrules`: not present.
- Checked `.github/copilot-instructions.md`: not present.
- If added later, treat those as higher-priority constraints for covered files.

## Build / Sync Commands
Run in `~/.config/nvim`.

```bash
# install/update plugins and run plugin build hooks
nvim --headless "+Lazy! sync" "+qa"

# inspect available plugin updates
nvim --headless "+Lazy! check" "+qa"

# remove plugins no longer in spec
nvim --headless "+Lazy! clean" "+qa"
```

Notes:
- There is no conventional compile/build step in this repo.
- Native plugin builds (example: telescope-fzf-native) happen via Lazy hooks.

## Lint / Format Commands
No `stylua.toml`, `.luacheckrc`, or `selene.toml` found.
Use tools only if installed on the machine.

```bash
# format all Lua sources
stylua init.lua lua plugin after

# format one file
stylua lua/config/remap.lua

# lint all Lua sources
luacheck init.lua lua plugin after

# lint one file
luacheck plugin/floaterminal.lua
```

Guideline:
- Avoid full-repo reformat unless requested.
- If formatter causes large unrelated churn, keep edits minimal.

## Test / Verification Commands
No automated tests are currently present (`tests/` not found).
Use startup + health smoke checks.

```bash
# startup smoke test
nvim --headless "+qa"

# Neovim health diagnostics
nvim --headless "+checkhealth" "+qa"

# module load check (example)
nvim --headless "+lua require('config.remap')" "+qa"
```

### Single Test Command (when tests are added)
Preferred test style is plenary + busted.

```bash
# run one spec file
nvim --headless "+PlenaryBustedFile tests/path/to_spec.lua" "+qa"

# run all specs
nvim --headless "+PlenaryBustedDirectory tests/" "+qa"
```

If narrowing scope temporarily (for example `it.only`), remove it before finish.

## Code Style Guidelines

### Imports and module loading
- Require modules near the top of each file.
- Bind imports to `local` names.
- Use `pcall(require, ...)` only for optional/user-local modules.
- Avoid duplicate `require` calls in one file.
- Keep import aliases short and clear (`cmp`, `builtin`, `conf`).

### Formatting
- Use 2-space indentation for Lua (matches `after/ftplugin/lua.lua`).
- Prefer one statement per line.
- Use trailing commas in multiline tables.
- Avoid unnecessary semicolons.
- Keep line width near 80 when practical.
- Preserve nearby style when touching existing code.

### Types and data-shape discipline
- Lua is dynamic: guard inputs with `type(...)` checks.
- Validate required keys before action.
- Use early returns on invalid preconditions.
- Keep config tables stable and predictable.
- Merge defaults with `vim.tbl_deep_extend("force", defaults, user)`.

### Naming conventions
- File names: `snake_case.lua`.
- Locals/functions: `snake_case`.
- Boolean helpers: `is_*`, `has_*`, `can_*`.
- User commands: `PascalCase` verb form (`ServiceStart`, `BranchSyncBase`).
- Add `desc` on non-trivial keymaps.

### Error handling and notifications
- Prefer `vim.notify` over `print` for user-facing issues.
- Use explicit log levels (`ERROR`, `WARN`, `INFO`).
- Include context in messages (service name, branch, command).
- Check command/job exit states before continuing.
- In async paths, clean state on success and failure.

### Neovim API usage
- Prefer `vim.api` / `vim.fn` / `vim.system` wrappers.
- Avoid shell string hacks when API alternatives exist.
- Check win/buf validity before using handles.
- Keep autocmd callbacks small and explicit.
- Use buffer-local mappings where appropriate.

### Plugin config conventions
- Add plugin specs in `lua/config/plugins/init.lua`.
- Put plugin behavior in `after/plugin/<name>.lua` when possible.
- Keep specs declarative (`event`, `ft`, `dependencies`, `build`).
- Do not duplicate plugin entries unless intentionally overriding behavior.
- Update `lazy-lock.json` when plugin versions change.

### Local machine boundaries
- `lua/config/services.lua` may contain user-private paths and commands.
- Do not add new machine-specific absolute paths unless requested.
- For local-only behavior, prefer optional config loaded via `pcall`.

## Agent Checklist Before Finishing
- Startup still works: `nvim --headless "+qa"`.
- If plugin specs changed: `nvim --headless "+Lazy! sync" "+qa"`.
- If Lua changed significantly: run lint/format if available.
- Keep edits targeted; avoid unrelated cleanups.
- Update this file if workflow/tooling conventions change.

## Commit Guidance (only when user asks)
- Keep commit scope single-purpose.
- Explain behavioral intent in commit message.
- Mention verification commands when useful.
