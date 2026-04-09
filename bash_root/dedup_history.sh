#!/bin/bash
HISTFILE="$HOME/.bash_history"

if [ ! -f "$HISTFILE" ]; then
    echo "dedup_history: $HISTFILE not found" >&2
    exit 1
fi

before=$(wc -l < "$HISTFILE")
if tac "$HISTFILE" | awk '!seen[$0]++' | tac > "$HISTFILE.tmp" && mv "$HISTFILE.tmp" "$HISTFILE"; then
    after=$(wc -l < "$HISTFILE")
    echo "dedup_history: $before → $after lines (removed $((before - after)) duplicates)"
    rm -- "$0"
else
    rm -f "$HISTFILE.tmp"
    echo "dedup_history: failed, $HISTFILE unchanged" >&2
    exit 1
fi
