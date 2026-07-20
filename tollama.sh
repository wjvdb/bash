#!/bin/bash

tollama() {
    local cmd

    cmd=$(ollama run qwen2.5-coder:7b "
You are a shell command generator.

Rules:
- Return exactly one bash command.
- No markdown.
- No explanations.
- No code fences.

Task:
$*
")

    cmd=$(echo "$cmd" | sed '/^```/d')

    echo
    echo "Generated:"
    echo "$cmd"
    echo

    read -p "Execute? [y/N] " yn

    [[ ! "$yn" =~ ^[Yy]$ ]] && return

    if [[ "$cmd" =~ ^cd[[:space:]] ]]; then
        eval "$cmd"
    else
        bash -c "$cmd"
    fi
}