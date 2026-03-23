#!/usr/bin/env bash
# 跨平台音效通知 hook
# 用法: notify-sound.sh [stop|notification]
# 在 Stop 和 Notification 事件中自动播放不同音效

EVENT_TYPE="${1:-stop}"

# 用户自定义音效优先（如果存在）
CUSTOM_DONE="$HOME/.claude/sounds/done.wav"
CUSTOM_CONFIRM="$HOME/.claude/sounds/confirm.wav"

play_sound() {
  local sound_file="$1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    afplay "$sound_file" &
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Windows (Git Bash / MSYS2)
    powershell -c "(New-Object Media.SoundPlayer '$sound_file').PlaySync()" &
  elif [[ "$OSTYPE" == "linux"* ]]; then
    # Linux
    if command -v paplay &>/dev/null; then
      paplay "$sound_file" &
    elif command -v aplay &>/dev/null; then
      aplay "$sound_file" &
    fi
  fi
}

play_system_sound() {
  local sound_type="$1"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$sound_type" == "done" ]]; then
      afplay /System/Library/Sounds/Glass.aiff &
    else
      afplay /System/Library/Sounds/Ping.aiff &
    fi
  elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    if [[ "$sound_type" == "done" ]]; then
      powershell -c "(New-Object Media.SoundPlayer 'C:/Windows/Media/tada.wav').PlaySync()" &
    else
      powershell -c "(New-Object Media.SoundPlayer 'C:/Windows/Media/Windows Notify.wav').PlaySync()" &
    fi
  elif [[ "$OSTYPE" == "linux"* ]]; then
    # Linux: 用 beep 作为 fallback
    if command -v paplay &>/dev/null; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &
    else
      printf '\a'
    fi
  fi
}

case "$EVENT_TYPE" in
  stop)
    if [[ -f "$CUSTOM_DONE" ]]; then
      play_sound "$CUSTOM_DONE"
    else
      play_system_sound "done"
    fi
    ;;
  notification)
    if [[ -f "$CUSTOM_CONFIRM" ]]; then
      play_sound "$CUSTOM_CONFIRM"
    else
      play_system_sound "confirm"
    fi
    ;;
  *)
    play_system_sound "done"
    ;;
esac
