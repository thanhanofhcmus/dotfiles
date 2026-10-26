# Noctalia config

## Load order

Later files override earlier ones, key by key:

1. Built-in defaults
2. Every `*.toml` directly in this directory, merged in alphabetical order
   (subdirectories and non-`.toml` files are ignored)
3. `~/.local/state/noctalia/settings.toml` (written by the Settings UI; wins over everything)

Inspect the result with `noctalia config export` (or `export full` to include defaults).

## Files

| File | Tracked | Contents |
|---|---|---|
| `config.toml` | yes | Shared config: bar, theme, widgets, idle behaviors |
| `zz-local.toml` | no | Machine-specific config: wallpapers, lockscreen widget layout (anything tied to monitor names or paths) |

The `zz-` prefix keeps the local file loading last. Don't use a numeric prefix:
digits sort before letters, so `99-local.toml` would load *before* `config.toml`.

`zz-local.toml` is ignored via `~/dev/dotfiles/info/exclude`, which is per-clone;
add the line on each new machine.

## Gotchas

- Defining a table such as `[idle.behavior.screen-off]` replaces the built-in
  entry rather than merging with it, so set every required field (e.g. `action`).
- Changes are picked up automatically; force it with `noctalia msg config-reload`.
- Check `noctalia config validate` and `~/.cache/noctalia/noctalia.log` when a
  setting doesn't take effect.
