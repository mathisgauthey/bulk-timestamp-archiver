# bulk-timestamp-archiver

A small command line tool that allows to timestamp files for archiving purposes.

## Features

- Renames files with timestamp prefixes based on modification date
- Replaces spaces with underscores
- Converts filenames to lowercase
- Removes accents from characters
- Cross-platform compatible (Linux/macOS)

## Installation

Either way, the script will be installed to `/usr/local/bin/bta` for easy access from anywhere in the terminal.

### One-Click Install

Using curl:

```bash
curl -fsSL https://raw.githubusercontent.com/mathisgauthey/bulk-timestamp-archiver/main/install.sh | sudo bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/mathisgauthey/bulk-timestamp-archiver/main/install.sh | sudo bash
```

### Manual Install

```bash
git clone https://github.com/mathisgauthey/bulk-timestamp-archiver.git
cd bulk-timestamp-archiver
sudo ./install.sh
```

## Usage

```bash
bta <file1> <file2> <directory> <directory/*>
```

The script will rename files to include a timestamp prefix in the format: `YYYY_MM_DD-HH_MM_SS-filename_with_accents_removed_and_spaces_replaced.ext`

### Example

```bash
bta document.txt photo.jpg Downloads/ files_inside_directory/*
```

This will rename files based on their modification date, for example:
- `document.txt` → `2026_02_12-14_30_45-document.txt`
- `photo.jpg` → `2026_01_15-09_22_13-photo.jpg`

## Uninstallation

To remove the script:

```bash
sudo rm /usr/local/bin/bta
```
