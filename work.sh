alias devportal="cd /c/dev/"

function inject() {
local bashrc_file="$HOME/.bashrc"
 local bashfile_path="$(realpath "$0")"
local source_command="source $bashfile_path"

# Check if the source command is already in .bashrc
if ! grep -Fxq "$source_command" "$bashrc_file"; then
 echo "$source_command" >> "$bashrc_file"
 echo "Added $bashfile_path to $bashrc_file"
 refrsh
fi
}
inject