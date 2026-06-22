#!/usr/bin/env bash

if [ -f "$1" ]; then
    sed '/^#/d; /^$/d' "$1" | xargs sudo pacman -S --needed
else
    echo "Profile '$1' not found."
fi
