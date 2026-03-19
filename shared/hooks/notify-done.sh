#!/bin/bash
# Stop hook: macOS notification when Claude finishes
osascript -e 'display notification "Claude Code finished!" with title "Claude Brain"' 2>/dev/null
exit 0
