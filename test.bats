#!/usr/bin/env bats

SCRIPT="./bulk-timestamp-archiver.sh"
TEST_DIR=""

setup() {
  # Create a temporary test directory
  TEST_DIR=$(mktemp -d)
  echo "Test directory: $TEST_DIR" >&3
}

teardown() {
  # Clean up test directory
  if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
  fi
}

# Helper function to create a test file with specific modification time
create_test_file() {
  local filename="$1"
  local modified_time="${2:-202301011200}" # Default: 2023-01-01 12:00
  touch -t "$modified_time" "$TEST_DIR/$filename"
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
  [[ "$output" =~ "1 files renamed" ]]
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
  create_test_file "file1.txt"
  create_test_file "file2.txt"
  create_test_file "file3.txt"

  # Process directory with 'y' confirmation
  run bash -c "echo 'y' | $SCRIPT $TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "3 files renamed" ]]
}

@test "detects files correctly before processing" {
  create_test_file "test1.txt"
  create_test_file "test2.txt"

  run bash -c "echo 'y' | $SCRIPT $TEST_DIR"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Detected 2 file(s)" ]]
}

@test "handles non-existent file gracefully" {
  run "$SCRIPT" "$TEST_DIR/nonexistent.txt"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "No files to process" ]]
}
