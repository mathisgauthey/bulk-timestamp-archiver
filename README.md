# bulk-timestamp-archiver

A small command line tool that allows to timestamp files for archiving purposes.

## Features

- Renames files with timestamp prefixes based on modification date
- Replaces spaces with underscores
- Converts filenames to lowercase
- Removes accents from characters
- Cross-platform compatible (Linux/macOS)

## Installation

### Quick Install

```bash
git clone https://github.com/mg-okteo/bulk-timestamp-archiver.git
cd bulk-timestamp-archiver
sudo ./install.sht
```

This will install the script as `bta` command in `/usr/local/bin/`.

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
