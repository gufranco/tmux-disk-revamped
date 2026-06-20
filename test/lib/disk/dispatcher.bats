#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DISK_LOADED _DISK_REVAMPED_RENDER_LOADED
  export CACHE_SYNC=1
  source "${BATS_TEST_DIRNAME}/../../../src/disk.sh"
  read_disk() { echo "55 100 466"; }
  read_disk_io() { echo ""; }
}

teardown() {
  cleanup_test_environment
}

@test "disk.sh dispatcher - functions are defined" {
  function_exists main
  function_exists disk_refresh
  function_exists disk_tick
  function_exists disk_max_age
  function_exists disk_mount
}

@test "disk.sh dispatcher - disk_max_age default is 30" {
  [[ "$(disk_max_age)" == "30" ]]
}

@test "disk.sh dispatcher - disk_mount default is root" {
  [[ "$(disk_mount)" == "/" ]]
}

@test "disk.sh dispatcher - disk_mount honors the option" {
  set_tmux_option "@disk_revamped_mount" "/home"
  [[ "$(disk_mount)" == "/home" ]]
}

@test "disk.sh dispatcher - disk_refresh caches percent, used, total" {
  disk_refresh
  [[ "$(cache_get percent)" == "55" ]]
  [[ "$(cache_get used)" == "100" ]]
  [[ "$(cache_get total)" == "466" ]]
}

@test "disk.sh dispatcher - refresh subcommand caches values" {
  main refresh
  [[ "$(cache_get percent)" == "55" ]]
}

@test "disk.sh dispatcher - percentage renders the cached value" {
  run main percentage
  [[ "${output}" == "55%" ]]
}

@test "disk.sh dispatcher - icon maps the cached value" {
  run main icon
  [[ "${output}" == "▰▱▱" ]]
}

@test "disk.sh dispatcher - used and total render with a suffix" {
  run main used
  [[ "${output}" == "100G" ]]
  run main total
  [[ "${output}" == "466G" ]]
}

@test "disk.sh dispatcher - disk_refresh_io stores then computes rates" {
  read_disk_io() { echo "1000 2000"; }
  export MOCK_EPOCH=1000
  disk_refresh_io
  [[ "$(cache_get rd_raw)" == "1000" ]]
  read_disk_io() { echo "3048 6096"; }
  export MOCK_EPOCH=1002
  disk_refresh_io
  [[ "$(cache_get read)" == "1.0MB/s" ]]
  [[ "$(cache_get write)" == "2.0MB/s" ]]
}

@test "disk.sh dispatcher - read and write subcommands echo the cache" {
  cache_set read "5.0MB/s"
  cache_set write "1.0MB/s"
  run main read
  [[ "${output}" == "5.0MB/s" ]]
  run main write
  [[ "${output}" == "1.0MB/s" ]]
}

@test "disk.sh dispatcher - unknown subcommand produces no output" {
  run main bogus
  [[ -z "${output}" ]]
}
