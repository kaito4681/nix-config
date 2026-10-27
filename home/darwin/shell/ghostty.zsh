if [[ "$OSTYPE" == darwin* ]]; then
  gst() {
    local mode="tab"
    local dir="."

    case "$1" in
      -w|--window)
        mode="window"
        shift
        ;;
    esac

    dir="${1:-.}"

    if [[ ! -d "$dir" ]]; then
      echo "gst: directory not found: $dir" >&2
      return 1
    fi

    dir="$(cd "$dir" && pwd -P)"

    if [[ "$(osascript -e 'application "Ghostty" is running')" != "true" ]]; then
      open -a Ghostty --args --working-directory="$dir"
      return
    fi

    osascript - "$dir" "$mode" <<'APPLESCRIPT'
on run argv
    set dirPath to item 1 of argv
    set openMode to item 2 of argv

    tell application "Ghostty"
        set cfg to new surface configuration
        set initial working directory of cfg to dirPath

        if openMode is "window" then
            set newWin to new window with configuration cfg
        else
            if (count of windows) = 0 then
                set newWin to new window with configuration cfg
            else
                set newTab to new tab in front window with configuration cfg
                select tab newTab
            end if
        end if

        activate
    end tell
end run
APPLESCRIPT
  }
fi
