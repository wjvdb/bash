#!/bin/bash
cppllama() {
    local prompt
    local cmd

    if [[ $# -eq 0 ]]; then
        read -e -p "Prompt: " prompt
    else
        prompt="$*"
    fi

    cmd=$(ollama run qwen2.5-coder:7b "
You are a cpp assistant.

return raw cpp code only, without any explanations or comments. Do not include any markdown formatting. Do not include any text outside of the code block. Do not include any code fences. Do not include any additional text or instructions.


Task:
$prompt
")
cmd=$(printf '%s\n' "$cmd" | sed '/^```.*$/d')

    echo
    echo "Generated:"
    echo "----------------------------------------"
    echo "$cmd"
    echo "----------------------------------------"
    echo

    read -p "[y] Execute [f] Save as file [a] Append to file [n] Cancel: " choice

    case "$choice" in
        y|Y)
            if [[ "$cmd" =~ ^cd[[:space:]] ]]; then
                eval "$cmd"
            else
                bash -c "$cmd"
            fi
            ;;

        f|F)
            read -e -p "Filename: " filename
            printf '%s\n' "$cmd" > "$filename"
            echo "Saved to $filename"
            ;;

        a|A)
            read -e -p "Append to file: " filename
            printf '%s\n' "$cmd" >> "$filename"
            echo "Appended to $filename"
            ;;

        *)
            echo "Cancelled"
            ;;
    esac
}
 