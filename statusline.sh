#!/usr/bin/env bash
# Claude Code status line — powerline style.
# Receives JSON on stdin; outputs one line of bg-filled segments.
# NOTE: the arrow glyph () needs a Nerd Font / Powerline font in the terminal.

input=$(cat)

# Parallel segment arrays: text (no ANSI), fg color, bg color (256-palette).
texts=(); fgs=(); bgs=()
push() { texts+=("$1"); fgs+=("$2"); bgs+=("$3"); }

# Level color by usage % -> dark bg suitable for white fg
lvl_bg() { # $1=pct -> echoes bg
  if   [ "$1" -lt 50 ]; then echo 22    # dark green
  elif [ "$1" -lt 80 ]; then echo 94    # dark amber
  else echo 52; fi                       # dark red
}

# --- Profile -----------------------------------------------------------------
case "${CLAUDE_CONFIG_DIR:-}" in
  *claude-work*) push "WORK" 231 124 ;;       # white on red
  *)             push "PERSONAL" 231 25 ;;     # white on blue
esac

# --- Caveman mode ------------------------------------------------------------
FLAG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ -f "$FLAG" ] && [ ! -L "$FLAG" ]; then
  MODE=$(head -c 64 "$FLAG" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]')
  MODE=$(printf '%s' "$MODE" | tr -cd 'a-z0-9-')
  case "$MODE" in
    off|lite|full|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      if [ -z "$MODE" ] || [ "$MODE" = "full" ]; then
        push "CAVEMAN" 231 130
      else
        push "CAVEMAN:$(printf '%s' "$MODE" | tr '[:lower:]' '[:upper:]')" 231 130
      fi ;;
  esac
fi

# --- Directory ---------------------------------------------------------------
dir=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
[ -n "$dir" ] && push "$(basename "$dir")" 252 238

# --- Git branch + remote repo ------------------------------------------------
if [ -n "$dir" ]; then
  br=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$br" ]; then
    [ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty="*" || dirty=""
    push "⎇ ${br}${dirty}" 114 236
    remote=$(git -C "$dir" remote get-url origin 2>/dev/null)
    if [ -n "$remote" ]; then
      host=$(printf '%s' "$remote" | sed -E 's#^(git@|https?://|ssh://(git@)?)##; s#[:/].*##')
      path=$(printf '%s' "$remote" | sed -E 's#^(git@|https?://|ssh://(git@)?)[^/:]+[:/]##; s#\.git$##')
      case "$host" in
        *github*) tag="gh";  rfg=75  ;;
        *gitlab*) tag="gl";  rfg=208 ;;
        *)        tag="git"; rfg=251 ;;
      esac
      [ -n "$path" ] && push "${tag}:${path}" "$rfg" 237
    fi
  fi
fi

# --- Model -------------------------------------------------------------------
model=$(echo "$input" | jq -r '.model.display_name // empty')
[ -n "$model" ] && push "$model" 231 240

# Mark where "metrics" begin so we can wrap onto a 2nd line on narrow terminals.
split_at=${#texts[@]}

# --- Lines changed -----------------------------------------------------------
added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
if [ "$added" -gt 0 ] 2>/dev/null || [ "$removed" -gt 0 ] 2>/dev/null; then
  push "+${added} -${removed}" 151 235
fi

# --- Cost --------------------------------------------------------------------
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
[ -n "$cost" ] && push "$(printf '$%.2f' "$cost")" 180 238

# --- Context window ----------------------------------------------------------
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
over200k=$(echo "$input" | jq -r '.exceeds_200k_tokens // false')
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")
  filled=$(( (pct + 5) / 10 )); [ "$filled" -gt 10 ] && filled=10
  bar=""
  for i in $(seq 1 10); do [ "$i" -le "$filled" ] && bar+="▰" || bar+="▱"; done
  txt="${bar} ${pct}%"
  [ "$over200k" = "true" ] && txt="${txt} ⚠200k"
  push "$txt" 231 "$(lvl_bg "$pct")"
fi

# --- Subscription limits (Pro/Max; present after first API response) ---------
now=$(date +%s 2>/dev/null)
countdown() { # $1=resets_at -> dim " · 3h" (time until reset) or empty
  [ -z "$1" ] || [ "$1" = "null" ] || [ -z "$now" ] && return
  local s=$(( $1 - now )) v; [ "$s" -le 0 ] && return
  if   [ "$s" -ge 86400 ]; then v="$((s/86400))d"
  elif [ "$s" -ge 3600 ];  then v="$((s/3600))h"
  else v="$((s/60))m"; fi
  echo "\033[38;5;253m · ${v}\033[38;5;231m"   # dim, then back to white
}
push_window() { # $1=pct $2=resets_at $3=label
  local p="$1"; [ -z "$p" ] || [ "$p" = "null" ] && return
  p=$(printf "%.0f" "$p")
  push "$3 ${p}%$(countdown "$2")" 231 "$(lvl_bg "$p")"
}
push_window "$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')" \
            "$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')" "5h"
push_window "$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')" \
            "$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')" "7d"

# --- Render powerline --------------------------------------------------------
SEP=$''   # powerline right-arrow
n=${#texts[@]}

# Visible width of a segment = text chars + 2 padding spaces + 1 arrow.
# Countdown text carries inline ANSI (\033...m) that prints zero-width — strip
# it before counting so wrap math stays accurate.
total=0
for ((i=0; i<n; i++)); do
  clean=$(printf '%b' "${texts[i]}" | sed 's/\x1b\[[0-9;]*m//g')
  total=$(( total + ${#clean} + 3 ))
done

render_line() { # $1=start $2=end(exclusive)
  local out="" i bg fg
  for ((i=$1; i<$2; i++)); do
    bg=${bgs[i]}; fg=${fgs[i]}
    out+="\033[38;5;${fg};48;5;${bg}m ${texts[i]} "
    if (( i < $2-1 )); then
      out+="\033[38;5;${bg};48;5;${bgs[i+1]}m${SEP}"
    else
      out+="\033[0m\033[38;5;${bg}m${SEP}\033[0m"
    fi
  done
  printf '%b\n' "$out"
}

cols=${COLUMNS:-9999}
if (( total > cols && split_at > 0 && split_at < n )); then
  render_line 0 "$split_at"        # identity row
  render_line "$split_at" "$n"     # metrics row
else
  render_line 0 "$n"
fi
