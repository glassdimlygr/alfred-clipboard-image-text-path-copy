# Clipboard Image to Path — Alfred Workflow

Save clipboard images as PNG files and copy the file path to your clipboard. Designed for tools like [OpenCode](https://opencode.ai), Cursor, or any app where you need to reference images by file path.

Works with Lightshot, macOS screenshots, browser copies, GIMP, and anything else that puts image data on the clipboard.

## Requirements

- macOS
- [Alfred 4+](https://www.alfredapp.com/) with Powerpack
- Clipboard History enabled in Alfred (Preferences > Features > Clipboard History > Keep Images)

## Install

```sh
git clone https://github.com/glassdimly/alfred-clipboard-image.git
cd alfred-clipboard-image
./install.sh
```

To update, `git pull` and run `./install.sh` again.

## Usage

1. Copy an image to the clipboard (screenshot tool, browser, etc.)
2. Open Alfred, type `img`
3. **Current clipboard** image appears at the top — select it and press Enter
4. The file path (e.g. `/Users/you/.config/alfred/clipboard-image/images/clipboard-1234567890.png`) is copied to your clipboard
5. Paste the path wherever you need it

Below the current clipboard item, you'll also see images from Alfred's clipboard history with relative timestamps ("2 min ago", "yesterday", etc.).

## How it works

- **Live clipboard capture**: Uses `osascript` to grab PNG data directly from the system pasteboard. This catches apps like Lightshot where Alfred's own clipboard history fails to persist the image data.
- **Alfred clipboard history**: Queries Alfred's `clipboard.alfdb` SQLite database for previously copied images and converts the stored TIFF files to PNG.
- **Auto-cleanup**: Images older than 7 days in `~/.config/alfred/clipboard-image/images/` are deleted automatically.
- **Caching**: Converted images use content-hash filenames to avoid duplicate conversions.

## Files

| File | Purpose |
|---|---|
| `script_filter.sh` | Script Filter — queries clipboard, outputs Alfred JSON |
| `info.plist` | Alfred workflow definition |
| `install.sh` | Installer script |

## Uninstall

Delete the workflow from Alfred Preferences, then:

```sh
rm -rf ~/.config/alfred/clipboard-image
```

## License

MIT
