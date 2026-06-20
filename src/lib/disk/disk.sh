#!/usr/bin/env bash
#
# disk.sh: disk usage acquisition via df.
#
# disk_parse_df is pure. The df calls live behind seams tests can stub. df flags
# differ by platform, so each platform has its own seam.

[[ -n "${_DISK_REVAMPED_DISK_LOADED:-}" ]] && return 0
_DISK_REVAMPED_DISK_LOADED=1

_DISK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_DISK_LIB_DIR}/../utils/platform.sh"

# disk_parse_df TEXT -> "<pct> <used_gb> <total_gb>" from df output.
# Reads the data line that carries the capacity percentage, so a wrapped header
# does not matter. Used and total are reduced to plain integers in gigabytes.
disk_parse_df() {
  local line total used pct
  line=$(printf '%s\n' "${1}" | grep -E '[0-9]+%' | head -1)
  [[ -n "${line}" ]] || { echo ""; return 0; }
  total=$(awk '{ print $2 }' <<< "${line}" | tr -dc '0-9')
  used=$(awk '{ print $3 }' <<< "${line}" | tr -dc '0-9')
  pct=$(grep -oE '[0-9]+%' <<< "${line}" | head -1 | tr -d '%')
  echo "${pct:-0} ${used:-0} ${total:-0}"
}

# diskstats_io TEXT -> "<read_kb> <write_kb>" cumulative from /proc/diskstats.
# Sectors are 512 bytes, so sectors / 2 is kilobytes.
diskstats_io() {
  printf '%s\n' "${1}" | awk '{ r += $6; w += $10 } END { print int(r / 2), int(w / 2) }'
}

# disk_rate_compute CURRENT PREVIOUS SECONDS -> kilobytes per second, never negative.
disk_rate_compute() {
  [[ "${1}" =~ ^[0-9]+$ && "${2}" =~ ^[0-9]+$ && "${3}" =~ ^[0-9]+$ ]] || { echo 0; return 0; }
  (( ${3} <= 0 )) && { echo 0; return 0; }
  local d=$(( ${1} - ${2} ))
  (( d < 0 )) && d=0
  echo $(( d / ${3} ))
}

# disk_format_rate KB_PER_SEC -> human readable rate.
disk_format_rate() {
  [[ "${1}" =~ ^[0-9]+$ ]] || { echo "0KB/s"; return 0; }
  awk -v k="${1}" 'BEGIN {
    if (k >= 1024) printf "%.1fMB/s", k / 1024;
    else printf "%dKB/s", k;
  }'
}

# Host-probe seams.
_read_df_macos() { df -g "${1}" 2>/dev/null; }
_read_df_linux() { df -BG "${1}" 2>/dev/null; }
_read_diskstats() { cat /proc/diskstats 2>/dev/null; }

# read_disk_io -> "<read_kb> <write_kb>" cumulative, empty off Linux.
read_disk_io() {
  if is_linux; then
    diskstats_io "$(_read_diskstats)"
  fi
}

# read_disk MOUNT -> "<pct> <used_gb> <total_gb>", empty on an unknown platform.
read_disk() {
  local mount="${1:-/}"
  if is_macos; then
    disk_parse_df "$(_read_df_macos "${mount}")"
  elif is_linux; then
    disk_parse_df "$(_read_df_linux "${mount}")"
  else
    echo ""
  fi
}

export -f disk_parse_df
export -f diskstats_io
export -f disk_rate_compute
export -f disk_format_rate
export -f _read_df_macos
export -f _read_df_linux
export -f _read_diskstats
export -f read_disk
export -f read_disk_io
