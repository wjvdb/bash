#!/bin/bash

# Add your custom bash functions and aliases here

tollama() {
    local action="$1"
    shift

    local prompt="$*"

    case "$action" in
        search)
            ollama run qwen2.5-coder:7b "
You are a terminal assistant.

Return ONLY a shell command.

Task:
$prompt
"
            ;;

        make)
            ollama run qwen3 "
You are a terminal assistant.

Create files using shell commands.

Return ONLY executable bash.
Task:
$prompt
"
            ;;

        *)
            echo "Usage: tollama {search|make} <prompt>"
            ;;
    esac
}