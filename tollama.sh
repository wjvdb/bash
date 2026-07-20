#!/bin/bash


tollama() {
    local cmd

    cmd=$( ollama run qwen2.5-coder:7b "
Return only a bash command.

Task:
$*
")

    echo "Command:"
    echo "$cmd"

    read -p "Execute? [y/N] " yn

    [[ "$yn" =~ ^[Yy]$ ]] && eval "$cmd"
}