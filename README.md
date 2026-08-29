# Clippy

A clipboard history picker for the Omarchy bar. The bar icon opens a popup
list of your recent clipboard entries (text and images); click an entry to
copy it back to the clipboard and paste it anywhere.

## Dependencies

Clippy is a viewer over Omarchy's built-in clipboard history. It depends on
the bundled `omarchy.clipboard` plugin, which owns the capture watchers
(`wl-paste --watch`), the history file
(`~/.local/state/omarchy/clipboard-history.json`), and the
`omarchy-clipboard-paste-text` / `omarchy-clipboard-paste-file` binaries used
to copy an entry back. Clippy adds no processes, watchers, or services of its
own — it only reads the history file and runs those binaries on click.

## Install

```sh
omarchy plugin add https://github.com/<you>/omarchy-clippy.git --enable
```

The plugin appears in the bar automatically (right section, next to the tray).

## Usage

- Click the clipboard icon in the bar to open the clipboard history panel.
- Click any entry to copy it back to the clipboard (the panel closes, ready
  to paste). Images copy as images.
- Press Escape or click outside to close.
- The row under the cursor is highlighted; entries whose text starts with a
  blank line display their first non-empty line.

## Configure

Move the icon to another bar section:

```sh
omarchy bar move mark.clippy --section left
```

Keyboard shortcut style summoning (same route the bar uses):

```sh
omarchy-shell shell summon mark.clippy
omarchy-shell shell hide mark.clippy
```

## Remove

```sh
omarchy plugin remove mark.clippy
```

## License

MIT — see [LICENSE](LICENSE).
