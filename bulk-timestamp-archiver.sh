#!/bin/bash

set -euo pipefail
# e : Exit immediately if a command exits with a non-zero status.
# u : Treat unset variables as an error and exit immediately.
# o pipefail : The return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status.

remove_accents() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null || echo "$1"
}

# Function to process a single file
process_file() {
  local filepath="$1"
  local dirpath
  dirpath=$(dirname "$filepath")
  local filename
  filename=$(basename "$filepath")
  local newname="$filename"

  echo "Processing: '$filename'"

  # Check if filename already matches the expected pattern: YYYY_MM_DD-HH_MM_SS-*
  if [[ "$filename" =~ ^[0-9]{4}_[0-9]{2}_[0-9]{2}-[0-9]{2}_[0-9]{2}_[0-9]{2}- ]]; then
    echo "  ⚠ No change needed"
    echo ""
    return 0
  fi

  # ──────────────────────────────────────── Replace Spaces With Underscores ─────────────────────────────────────────
  newname="${newname// /_}"
  echo "  After space replacement: '$newname'"

  # ────────────────────────────────────────────── Convert To Lowercase ──────────────────────────────────────────────
  newname=$(echo "$newname" | tr '[:upper:]' '[:lower:]')
  echo "  After lowercase: '$newname'"

  # ───────────────────────────────────────────────── Remove Accents ─────────────────────────────────────────────────
  newname=$(remove_accents "$newname")
  echo "  After accent removal: '$newname'"

  # ──────────────────────────────────────────── Add Modified Date Prefix ────────────────────────────────────────────
  local modtime=$(stat -c %Y "$filepath" 2>/dev/null || stat -f %m "$filepath" 2>/dev/null)
  local dateprefix=$(date -d @"$modtime" "+%Y_%m_%d-%H_%M_%S-" 2>/dev/null || date -r "$modtime" "+%Y_%m_%d-%H_%M_%S-" 2>/dev/null)
  newname="${dateprefix}${newname}"
  echo "  After date prefix: '$newname'"

  # ───────────────────────────────────────────── Construct New Filepath ─────────────────────────────────────────────
  local newpath="${dirpath}/${newname}"

  # Check if rename is needed
  if [ "$filepath" != "$newpath" ]; then
    # Check if target already exists
    if [ -e "$newpath" ]; then
      echo "  ❌ Warning: '$newname' already exists, skipping"
      return 1
    fi

    echo "  ✓ Renaming to: '$newname'"
    mv "$filepath" "$newpath"
    echo ""
    return 0
  else
    echo "  ⚠ No change needed"
    echo ""
    return 0
  fi
}

main() {
  if [ $# -eq 0 ]; then
    echo "Usage: $0 <file|folder|folder/*>"
    echo ""
    echo "Examples:"
    echo "  $0 myfile.txt                 # Rename a single file"
    echo "  $0 myfolder                   # Rename all files in folder"
    echo "  $0 myfolder/*                 # Rename all files in folder (expanded by shell)"
    exit 1
  fi

  # First pass: collect all files to process
  local files_to_process=()

  for item in "$@"; do
    if [ -f "$item" ]; then
      files_to_process+=("$item")
    elif [ -d "$item" ]; then
      while IFS= read -r -d '' file; do
        files_to_process+=("$file")
      done < <(find "$item" -maxdepth 1 -type f -print0)
    else
      echo "Error: '$item' is not a file or directory"
    fi
  done

  # Show detected files
  echo "========================================="
  echo "Detected ${#files_to_process[@]} file(s):"
  echo "========================================="
  for file in "${files_to_process[@]}"; do
    echo "  - $(basename "$file")"
  done
  echo ""

  if [ ${#files_to_process[@]} -eq 0 ]; then
    echo "No files to process."
    exit 0
  fi

  # Ask for confirmation if there are many files
  if [ ${#files_to_process[@]} -gt 2 ]; then
    read -p "Process ${#files_to_process[@]} files? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Cancelled."
      exit 0
    fi
  fi

  echo "========================================="
  echo "Starting the renaming process..."
  echo "========================================="

  local processed=0
  local skipped=0

  for file in "${files_to_process[@]}"; do
    if process_file "$file"; then
      processed=$((processed + 1))
    else
      skipped=$((skipped + 1))
    fi
  done

  echo ""
  echo "========================================="
  echo "Summary: $processed files renamed, $skipped skipped"
  echo "========================================="
  return 0
}

main "$@"
