#!/usr/bin/env bats

SCRIPT="./bulk-timestamp-archiver.sh"
TEST_DIR=""

# Helper function to create a test file with specific modification time
create_test_file() {
  local filename="$1"
  local modified_time="${2:-202301011200}" # Default: 2023-01-01 12:00
  touch -t "$modified_time" "$TEST_DIR/$filename"
}

setup() {
  # Create a temporary test directory
  TEST_DIR=$(mktemp -d)
}

teardown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

@test "script exists and is executable" {
  [ -f "$SCRIPT" ]
  [ -x "$SCRIPT" ]
}

@test "shows usage when no arguments are provided" {
  run "$SCRIPT"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Usage" ]]
}

@test "spaces replaced with underscores" {
  create_test_file "my test file.txt"

  run "$SCRIPT" "$TEST_DIR/my test file.txt"
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_DIR/my test file.txt" ]
  local count=$(find "$TEST_DIR" -name "*my_test_file.txt" | wc -l)
  [ "$count" -eq 1 ]
}

@test "converts to lowercase" {
  create_test_file "MyTestFile.TXT"

  run "$SCRIPT" "$TEST_DIR/MyTestFile.TXT"
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_DIR/MyTestFile.TXT" ]
  local newfile=$(find "$TEST_DIR" -type f -name "*mytestfile.txt")
  [[ "$newfile" =~ mytestfile\.txt$ ]]
}

@test "removes accents" {
  create_test_file "café_résumé.txt"

  run "$SCRIPT" "$TEST_DIR/café_résumé.txt"
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_DIR/café_résumé.txt" ]
  # After accent removal and lowercase: cafe_resume.txt
  local count=$(find "$TEST_DIR" -name "*cafe_resume.txt" | wc -l)
  [ "$count" -eq 1 ]
}

@test "adds modified date prefix" {
  # Create file with timestamp: 2023-06-15 10:30:00
  create_test_file "document.txt" "202306151030"

  run "$SCRIPT" "$TEST_DIR/document.txt"
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_DIR/document.txt" ]
  local count=$(find "$TEST_DIR" -name "2023_06_15-10_30_*document.txt" | wc -l)
  [ "$count" -eq 1 ]
}

@test "complete transformation workflow" {
  create_test_file "My Test File.txt" "202301151430"

  run "$SCRIPT" "$TEST_DIR/My Test File.txt"
  [ "$status" -eq 0 ]

  [ ! -f "$TEST_DIR/My Test File.txt" ]
  local count=$(find "$TEST_DIR" -name "2023_01_15-14_30_00-my_test_file.txt" | wc -l)
  [ "$count" -eq 1 ]
}

@test "skips file if target already exists" {
  create_test_file "test.txt" "202301011200"

  # Run once to create the renamed file
  "$SCRIPT" "$TEST_DIR/test.txt"

  # Create the same file again
  create_test_file "test.txt" "202301011200"

  # Try to rename again - should skip
  run "$SCRIPT" "$TEST_DIR/test.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "already exists" ]]
}

@test "processes single file" {
  create_test_file "file1.txt"

  run "$SCRIPT" "$TEST_DIR/file1.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1 file renamed" ]]
}

@test "processes multiple files without confirmation prompt" {
  create_test_file "file1.txt"
  create_test_file "file2.txt"

  # Only 2 files, should not prompt for confirmation
  run "$SCRIPT" "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "2 files renamed" ]]
}

@test "processes directory" {
  mkdir -p "$TEST_DIR/my_test_folder"
  create_test_file "file1.txt" "202301011200"
  create_test_file "file2.txt" "202301011200"
  create_test_file "file3.txt" "202301011200"

  # Move files into the folder
  mv "$TEST_DIR/file1.txt" "$TEST_DIR/my_test_folder/"
  mv "$TEST_DIR/file2.txt" "$TEST_DIR/my_test_folder/"
  mv "$TEST_DIR/file3.txt" "$TEST_DIR/my_test_folder/"

  # Process the folder itself (should rename the folder, not files inside)
  run "$SCRIPT" "$TEST_DIR/my_test_folder"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1 folder renamed" ]]

  # Original folder should not exist
  [ ! -d "$TEST_DIR/my_test_folder" ]

  # Renamed folder should exist with timestamp prefix
  local count=$(find "$TEST_DIR" -type d -name "*my_test_folder" | wc -l)
  [ "$count" -eq 1 ]
}

@test "detects files correctly before processing" {
  create_test_file "test1.txt"
  create_test_file "test2.txt"

  run "$SCRIPT" "$TEST_DIR/test1.txt" "$TEST_DIR/test2.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Detected 2 files" ]]
}

@test "handles non-existent file gracefully" {
  run "$SCRIPT" "$TEST_DIR/nonexistent.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No files or folders to process." ]]
}

@test "file already processed" {
  # Create a file that already matches the expected format
  local timestamp="202301011200"
  create_test_file "testfile.txt" "$timestamp"

  # First rename it
  "$SCRIPT" "$TEST_DIR/testfile.txt"

  # Get the new filename
  local newfile=$(find "$TEST_DIR" -name "*testfile.txt" -print -quit)

  # Try to rename it again - should show "No change needed"
  run "$SCRIPT" "$newfile"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No change needed" ]]
}

@test "preserves file extension" {
  create_test_file "document.pdf"

  run "$SCRIPT" "$TEST_DIR/document.pdf"
  [ "$status" -eq 0 ]

  local count=$(find "$TEST_DIR" -name "*.pdf" | wc -l)
  [ "$count" -eq 1 ]
}

@test "handles files with multiple dots in name" {
  create_test_file "my.file.name.tar.gz"

  run "$SCRIPT" "$TEST_DIR/my.file.name.tar.gz"
  [ "$status" -eq 0 ]

  local count=$(find "$TEST_DIR" -name "*my.file.name.tar.gz" | wc -l)
  [ "$count" -eq 1 ]
}

@test "cancellation on confirmation prompt" {
  create_test_file "file1.txt"
  create_test_file "file2.txt"
  create_test_file "file3.txt"

  # Process files with 'n' to cancel
  run bash -c "echo 'n' | $SCRIPT $TEST_DIR/file1.txt $TEST_DIR/file2.txt $TEST_DIR/file3.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cancelled" ]]

  # Original files should still exist
  [ -f "$TEST_DIR/file1.txt" ]
  [ -f "$TEST_DIR/file2.txt" ]
  [ -f "$TEST_DIR/file3.txt" ]
}

@test "summary shows correct counts" {
  create_test_file "file1.txt"
  create_test_file "file2.txt"

  run "$SCRIPT" "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Summary: 2 files renamed, 0 skipped" ]]
}

@test "renaming a folder should work even if files are inside" {
  mkdir "$TEST_DIR/my folder"
  touch "$TEST_DIR/my folder/file1.txt"
  touch "$TEST_DIR/my folder/file2.txt"

  run "$SCRIPT" "$TEST_DIR/my folder"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "1 folder renamed" ]]

  # Original folder should not exist
  [ ! -d "$TEST_DIR/my folder" ]

  # Renamed folder should exist (with timestamp prefix and spaces replaced)
  local count=$(find "$TEST_DIR" -type d -name "*my_folder" | wc -l)
  [ "$count" -eq 1 ]
}
