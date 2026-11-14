#!/usr/bin/env bash
# app-a's `paint` script prints `color=` and then a red `red` when FORCE_COLOR is set, `plain` when it is not.
# Starting from an empty cache, runs `turbo run paint` four times:
#   1. FORCE_COLOR=3, which records the task's log with its color codes;
#   2. --no-color;
#   3. NO_COLOR=1;
#   4. --force, with no color asked, which runs the task again.
# Prints `turbo info`, then each run's cache status line and the task's `color=` line with escape codes shown as ^[.
# Exits 1 while run 2 or run 3 prints a color code in the task's line, 0 once neither does, and 2 when a step fails,
# run 1 does not execute the task and print red in color, run 4 does not print plain, or a run prints anything else,
# turbo's own status line in color under run 2 or run 3 among it.
set -Eeuo pipefail
trap 'echo "failed: $BASH_COMMAND" >&2; exit 2' ERR
cd "$(dirname "$0")"
logs=$(mktemp -d)
trap 'rm -rf "$logs"' EXIT
pnpm install --frozen-lockfile > "$logs/install.log" 2>&1 || { cat "$logs/install.log"; exit 2; }
rm -rf .turbo apps/app-a/.turbo
echo '$ turbo info'
pnpm exec turbo info 2>&1
esc=$(printf '\033')
# Runs `turbo run paint --filter=app-a --ui=stream` with the arguments after the second, under the variable assignment
# the second names (none when it is empty), keeping its output in a log the first names; prints the log and exits 2 when
# it fails.
run_paint() {
  local name=$1 assignment=$2 status=0
  shift 2
  env ${assignment:+"$assignment"} pnpm exec turbo run paint --filter=app-a --ui=stream "$@" > "$logs/$name.log" 2>&1 \
    < /dev/null || status=$?
  sed "s/$esc\[[0-9;]*m//g" "$logs/$name.log" > "$logs/$name.plain"
  if [ "$status" != 0 ]; then
    cat "$logs/$name.log"
    echo "$name: ${assignment:+$assignment }turbo run paint $* exited $status"
    exit 2
  fi
}
run_paint colored FORCE_COLOR=3
run_paint no-color '' --no-color
run_paint no_color-env NO_COLOR=1
run_paint forced '' --force
# The line number of the run's cache status line, or of its `color=` line, in its log.
line_of() {
  grep -n -m 1 -E "^app-a:paint: $2" "$logs/$1.plain" | cut -d: -f1 || true
}
# Prints the run's line at that number as it was printed, escape codes as ^[, or `(none)`.
shown() {
  if [ -n "$2" ]; then sed -n "${2}p" "$logs/$1.log" | cat -v; else echo '(none)'; fi
}
unexpected=()
replayed=()
for run in colored no-color no_color-env forced; do
  case $run in
    colored) label='FORCE_COLOR=3 turbo run paint' ;;
    no-color) label='turbo run paint --no-color' ;;
    no_color-env) label='NO_COLOR=1 turbo run paint' ;;
    forced) label='turbo run paint --force' ;;
  esac
  status_line=$(line_of "$run" 'cache (miss|hit|bypass)')
  color_line=$(line_of "$run" 'color=')
  echo
  echo "== $label"
  shown "$run" "$status_line"
  shown "$run" "$color_line"
  if [ -z "$status_line" ] || [ -z "$color_line" ]; then
    unexpected+=("$label printed no cache status line or no color= line")
    continue
  fi
  status_text=$(sed -n "${status_line}p" "$logs/$run.plain")
  color_raw=$(sed -n "${color_line}p" "$logs/$run.log")
  color_text=$(sed -n "${color_line}p" "$logs/$run.plain")
  status_raw=$(sed -n "${status_line}p" "$logs/$run.log")
  case $run in
    colored)
      [[ $status_text == 'app-a:paint: cache miss, executing '* ]] && [ "$color_text" = 'app-a:paint: color=red' ] \
        && [[ $color_raw == *"${esc}[31mred${esc}[39m" ]] \
        || unexpected+=("$label did not execute the task and print red in color")
      ;;
    forced)
      [[ $status_text == 'app-a:paint: cache bypass, force executing '* ]] \
        && [ "$color_text" = 'app-a:paint: color=plain' ] && [[ $color_raw != *"$esc"* ]] \
        || unexpected+=("$label did not execute the task and print plain")
      ;;
    *)
      if [ "$color_text" != 'app-a:paint: color=red' ] && [ "$color_text" != 'app-a:paint: color=plain' ]; then
        unexpected+=("$label printed neither red nor plain")
      elif [[ $status_raw == *"$esc"* ]]; then
        unexpected+=("$label printed turbo's own status line in color")
      elif [[ $color_raw == *"$esc"* ]]; then
        if [ "$run" = no-color ]; then replayed+=(--no-color); else replayed+=(NO_COLOR=1); fi
      fi
      ;;
  esac
done
echo
if [ "${#unexpected[@]}" != 0 ]; then
  for run in colored no-color no_color-env forced; do
    echo "$run printed:"
    cat -v "$logs/$run.log"
  done
  printf '%s\n' "${unexpected[@]}"
  exit 2
fi
case ${#replayed[@]} in
  0)
    echo 'neither --no-color nor NO_COLOR=1 prints a color code in the task output'
    exit 0
    ;;
  1)
    echo "the cache hit replays the recorded color codes under ${replayed[0]}"
    exit 1
    ;;
  *)
    echo 'the cache hit replays the recorded color codes under --no-color and NO_COLOR=1'
    exit 1
    ;;
esac
