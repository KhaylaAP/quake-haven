#!/bin/sh
printf '\033c\033]0;%s\a' QuakeHaven
base_path="$(dirname "$(realpath "$0")")"
"$base_path/QuakeHaven.x86_64" "$@"
