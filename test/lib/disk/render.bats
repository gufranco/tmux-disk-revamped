#!/usr/bin/env bats

load "${BATS_TEST_DIRNAME}/../../helpers.bash"

setup() {
  setup_test_environment
  unset _DISK_REVAMPED_RENDER_LOADED
  source "${BATS_TEST_DIRNAME}/../../../src/lib/disk/render.sh"
}

teardown() {
  cleanup_test_environment
}

@test "render.sh - _disk_level classifies by thresholds" {
  [[ "$(_disk_level 10 70 90)" == "low" ]]
  [[ "$(_disk_level 75 70 90)" == "medium" ]]
  [[ "$(_disk_level 95 70 90)" == "high" ]]
}

@test "render.sh - _disk_level treats non-numeric as zero" {
  [[ "$(_disk_level zz 70 90)" == "low" ]]
}

@test "render.sh - disk_render_percentage is empty on cold start" {
  [[ -z "$(disk_render_percentage "")" ]]
}

@test "render.sh - disk_render_all joins disks and honors a separator" {
  [[ -z "$(disk_render_all "")" ]]
  local txt=$'/ 55%\n/home 30%'
  [[ "$(disk_render_all "${txt}")" == "/ 55%, /home 30%" ]]
  set_tmux_option "@disk_revamped_separator" " | "
  [[ "$(disk_render_all "${txt}")" == "/ 55% | /home 30%" ]]
}

@test "render.sh - disk_render_percentage uses the default format" {
  [[ "$(disk_render_percentage 55)" == "55%" ]]
}

@test "render.sh - disk_render_percentage honors a custom format" {
  set_tmux_option "@disk_revamped_percentage_format" "disk %s%%"
  [[ "$(disk_render_percentage 55)" == "disk 55%" ]]
}

@test "render.sh - disk_render_icon maps levels" {
  [[ "$(disk_render_icon 95)" == "▰▰▰" ]]
  [[ "$(disk_render_icon 75)" == "▰▰▱" ]]
  [[ "$(disk_render_icon 10)" == "▰▱▱" ]]
}

@test "render.sh - disk_render_icon is empty on cold start" {
  [[ -z "$(disk_render_icon "")" ]]
}

@test "render.sh - disk_render_icon honors a custom icon" {
  set_tmux_option "@disk_revamped_high_icon" "FULL"
  [[ "$(disk_render_icon 95)" == "FULL" ]]
}

@test "render.sh - disk_render_fg returns the configured color" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=red]"
  [[ "$(disk_render_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - disk_render_fg is empty on cold start" {
  [[ -z "$(disk_render_fg "")" ]]
}

@test "render.sh - disk_render_fg passes through an ANSI name verbatim" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=red]"
  [[ "$(disk_render_fg 95)" == "#[fg=red]" ]]
}

@test "render.sh - disk_render_fg passes through a 256 color spec verbatim" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=colour203]"
  [[ "$(disk_render_fg 95)" == "#[fg=colour203]" ]]
}

@test "render.sh - disk_render_fg passes through a hex color verbatim" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=#f38ba8]"
  [[ "$(disk_render_fg 95)" == "#[fg=#f38ba8]" ]]
}

@test "render.sh - disk_render_fg passes through a combined fg and bg spec verbatim" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(disk_render_fg 95)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - disk_render_fg passes through a bright ANSI name verbatim" {
  set_tmux_option "@disk_revamped_high_fg_color" "#[fg=brightred]"
  [[ "$(disk_render_fg 95)" == "#[fg=brightred]" ]]
}

@test "render.sh - disk_render_bg passes through an ANSI name verbatim" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=red]"
  [[ "$(disk_render_bg 10)" == "#[bg=red]" ]]
}

@test "render.sh - disk_render_bg passes through a 256 color spec verbatim" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=colour203]"
  [[ "$(disk_render_bg 10)" == "#[bg=colour203]" ]]
}

@test "render.sh - disk_render_bg passes through a hex color verbatim" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=#f38ba8]"
  [[ "$(disk_render_bg 10)" == "#[bg=#f38ba8]" ]]
}

@test "render.sh - disk_render_bg passes through a combined fg and bg spec verbatim" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[fg=#f38ba8,bg=#1e1e2e]"
  [[ "$(disk_render_bg 10)" == "#[fg=#f38ba8,bg=#1e1e2e]" ]]
}

@test "render.sh - disk_render_bg passes through a bright ANSI name verbatim" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=brightred]"
  [[ "$(disk_render_bg 10)" == "#[bg=brightred]" ]]
}

@test "render.sh - disk_render_bg returns the configured color" {
  set_tmux_option "@disk_revamped_low_bg_color" "#[bg=green]"
  [[ "$(disk_render_bg 10)" == "#[bg=green]" ]]
}

@test "render.sh - disk_render_size formats with a gigabyte suffix" {
  [[ -z "$(disk_render_size "")" ]]
  [[ "$(disk_render_size 466)" == "466G" ]]
}

@test "render.sh - disk_render_size honors a custom format" {
  set_tmux_option "@disk_revamped_size_format" "%s GiB"
  [[ "$(disk_render_size 100)" == "100 GiB" ]]
}
