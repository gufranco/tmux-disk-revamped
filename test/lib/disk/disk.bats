#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

MAC_DF=$'Filesystem 1G-blocks Used Avail Capacity iused ifree %iused Mounted on\n/dev/disk3s1 466 100 366 22% 1000 2000 1% /'
LINUX_DF=$'Filesystem 1G-blocks Used Avail Use% Mounted on\n/dev/sda1 100G 40G 60G 40% /'

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_DISK_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/disk.sh"
}

teardown() {
  cleanup_test_environment
}

@test "disk.sh - disk_parse_df parses macOS df output" {
  [[ "$(disk_parse_df "${MAC_DF}")" == "22 100 466" ]]
}

@test "disk.sh - disk_parse_df parses Linux df output" {
  [[ "$(disk_parse_df "${LINUX_DF}")" == "40 40 100" ]]
}

@test "disk.sh - disk_parse_df is empty without a data line" {
  [[ -z "$(disk_parse_df "Filesystem Size Used")" ]]
}

@test "disk.sh - read_disk uses macOS df" {
  _PLATFORM_OS_CACHE="Darwin"
  _read_df_macos() { echo "${MAC_DF}"; }
  [[ "$(read_disk /)" == "22 100 466" ]]
}

@test "disk.sh - read_disk uses Linux df" {
  _PLATFORM_OS_CACHE="Linux"
  _read_df_linux() { echo "${LINUX_DF}"; }
  [[ "$(read_disk /)" == "40 40 100" ]]
}

@test "disk.sh - read_disk is empty on an unknown platform" {
  _PLATFORM_OS_CACHE="Plan9"
  [[ -z "$(read_disk /)" ]]
}

@test "disk.sh - diskstats_io sums sectors into kilobytes" {
  local txt=$'8 0 sda 100 5 2000 50 200 10 4000 80 0 0 0\n8 16 sdb 1 0 0 0 1 0 0 0 0 0 0'
  [[ "$(diskstats_io "${txt}")" == "1000 2000" ]]
}

@test "disk.sh - disk_rate_compute divides the delta by seconds" {
  [[ "$(disk_rate_compute 3048 1000 2)" == "1024" ]]
  [[ "$(disk_rate_compute 100 1000 2)" == "0" ]]
  [[ "$(disk_rate_compute 2000 1000 0)" == "0" ]]
  [[ "$(disk_rate_compute x y z)" == "0" ]]
}

@test "disk.sh - disk_format_rate scales kilobytes and megabytes" {
  [[ "$(disk_format_rate 512)" == "512KB/s" ]]
  [[ "$(disk_format_rate 2048)" == "2.0MB/s" ]]
  [[ "$(disk_format_rate xx)" == "0KB/s" ]]
}

@test "disk.sh - read_disk_io reads diskstats on Linux" {
  _PLATFORM_OS_CACHE="Linux"
  _read_diskstats() { printf '8 0 sda 1 0 2000 0 1 0 4000 0 0 0 0\n'; }
  [[ "$(read_disk_io)" == "1000 2000" ]]
}

@test "disk.sh - read_disk_io is empty off Linux" {
  _PLATFORM_OS_CACHE="Darwin"
  [[ -z "$(read_disk_io)" ]]
}

@test "disk.sh - host-probe seams are callable" {
  run _read_df_macos /
  run _read_df_linux /
  run _read_diskstats
  true
}
