#!/bin/bash


tollama() {
    local cmd

    cmd=$(ollama run qwen2.5-coder:7b "
You are a shell command generator.

Rules:
- Return exactly one bash command.
- No markdown.
- No explanations.

Task:
$*
")

    cmd=$(echo "$cmd" | sed '/^```/d')

    echo
    echo "Generated:"
    printf '[%s]\n' "$cmd"
    echo

    read -p "Execute? [y/N] " yn

    if [[ "$yn" =~ ^[Yy]$ ]]; then
        echo "Executing..."
        eval "$cmd"
        echo "Exit code: $?"
        pwd
    fi
}