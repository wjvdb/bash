unalias devportal 2>/dev/null

devportal() {
    local base_dir="/c/dev"

    if [ -n "$1" ]; then
        cd "$base_dir/$1"
    else
        cd "$base_dir"
    fi
}

# ===============================
# Git Migration Clone Function
# Clones all repos with ALL branches for migration
# ===============================

# Interactive clone with PAT authentication
# Tries multiple methods until one works
# Usage: clone_with_pat
clone_with_pat() {
    echo "=========================================="
    echo "  Azure DevOps Clone with PAT Auth"
    echo "=========================================="
    echo ""
    
    # Get user input
    read -p "Azure DevOps Server URL (e.g. sdipsse1001.onead.schipholgroupcloud.nl): " server
    server="${server:-sdipsse1001.onead.schipholgroupcloud.nl}"
    
    read -p "Organization/Collection (e.g. DefaultCollection): " org
    org="${org:-DefaultCollection}"
    
    read -p "Project name: " project
    
    read -p "Repository name: " repo_name
    
    read -p "Username (can be anything for PAT, e.g. pat): " username
    username="${username:-pat}"
    
    read -p "Personal Access Token (PAT): " pat
    
    read -p "Output directory [./cloned]: " output_dir
    output_dir="${output_dir:-./cloned}"
    
    # Build the base URL
    local base_url="https://${server}/${org}/${project}/_git/${repo_name}"
    
    echo ""
    echo "Target: $base_url"
    echo "=========================================="
    
    mkdir -p "$output_dir"
    cd "$output_dir" || return 1
    
    # Remove existing clone attempts
    rm -rf "$repo_name" "$repo_name.git" 2>/dev/null
    
    local success=false
    
    # ============================================
    # METHOD 1: URL-encoded PAT in URL
    # ============================================
    if [[ "$success" == "false" ]]; then
        echo ""
        echo "[Method 1] Trying URL with encoded PAT..."
        
        # URL-encode the PAT (replace special chars)
        local encoded_pat=$(printf '%s' "$pat" | sed 's/!/%21/g; s/#/%23/g; s/\$/%24/g; s/&/%26/g; s/'\''/%27/g; s/(/%28/g; s/)/%29/g; s/*/%2A/g; s/+/%2B/g; s/,/%2C/g; s/:/%3A/g; s/;/%3B/g; s/=/%3D/g; s/?/%3F/g; s/@/%40/g; s/\[/%5B/g; s/\]/%5D/g')
        
        local auth_url="https://${username}:${encoded_pat}@${server}/${org}/${project}/_git/${repo_name}"
        
        if GIT_TERMINAL_PROMPT=0 git clone "$auth_url" "$repo_name" 2>&1; then
            echo "  -> SUCCESS with Method 1"
            success=true
        else
            rm -rf "$repo_name" 2>/dev/null
            echo "  -> Failed"
        fi
    fi
    
    # ============================================
    # METHOD 2: Using http.extraheader
    # ============================================
    if [[ "$success" == "false" ]]; then
        echo ""
        echo "[Method 2] Trying with http.extraheader..."
        
        # Create Basic auth header (empty username : PAT)
        local base64_auth=$(printf ":%s" "$pat" | base64 -w 0 2>/dev/null || printf ":%s" "$pat" | base64)
        local auth_header="Authorization: Basic ${base64_auth}"
        
        if GIT_TERMINAL_PROMPT=0 git -c "http.extraheader=$auth_header" clone "$base_url" "$repo_name" 2>&1; then
            echo "  -> SUCCESS with Method 2"
            success=true
            
            # Configure repo to use this method for future operations
            cd "$repo_name"
            git config http.extraheader "$auth_header"
            cd ..
        else
            rm -rf "$repo_name" 2>/dev/null
            echo "  -> Failed"
        fi
    fi
    
    # ============================================
    # METHOD 3: Using credential helper 'store'
    # ============================================
    if [[ "$success" == "false" ]]; then
        echo ""
        echo "[Method 3] Trying with credential.helper store..."
        
        # Store credentials in .git-credentials
        local cred_line="https://${username}:${pat}@${server}"
        local cred_file=~/.git-credentials
        
        # Backup existing
        [[ -f "$cred_file" ]] && cp "$cred_file" "${cred_file}.bak"
        
        # Add credential
        echo "$cred_line" >> "$cred_file"
        
        if GIT_TERMINAL_PROMPT=0 git -c credential.helper=store clone "$base_url" "$repo_name" 2>&1; then
            echo "  -> SUCCESS with Method 3"
            success=true
        else
            rm -rf "$repo_name" 2>/dev/null
            # Restore backup
            [[ -f "${cred_file}.bak" ]] && mv "${cred_file}.bak" "$cred_file"
            echo "  -> Failed"
        fi
    fi
    
    # ============================================
    # METHOD 4: Using GIT_ASKPASS with PAT
    # ============================================
    if [[ "$success" == "false" ]]; then
        echo ""
        echo "[Method 4] Trying with GIT_ASKPASS..."
        
        # Create temporary askpass script
        local askpass_script=$(mktemp)
        echo "#!/bin/bash" > "$askpass_script"
        echo "echo '$pat'" >> "$askpass_script"
        chmod +x "$askpass_script"
        
        if GIT_TERMINAL_PROMPT=0 GIT_ASKPASS="$askpass_script" git clone "$base_url" "$repo_name" 2>&1; then
            echo "  -> SUCCESS with Method 4"
            success=true
        else
            rm -rf "$repo_name" 2>/dev/null
            echo "  -> Failed"
        fi
        
        rm -f "$askpass_script"
    fi
    
    # ============================================
    # METHOD 5: Empty username with PAT (Azure DevOps style)
    # ============================================
    if [[ "$success" == "false" ]]; then
        echo ""
        echo "[Method 5] Trying with empty username (Azure style)..."
        
        local encoded_pat=$(printf '%s' "$pat" | sed 's/!/%21/g; s/#/%23/g; s/\$/%24/g; s/&/%26/g; s/'\''/%27/g; s/(/%28/g; s/)/%29/g; s/*/%2A/g; s/+/%2B/g; s/,/%2C/g; s/:/%3A/g; s/;/%3B/g; s/=/%3D/g; s/?/%3F/g; s/@/%40/g; s/\[/%5B/g; s/\]/%5D/g')
        
        # Azure DevOps accepts empty username with PAT
        local auth_url="https://:${encoded_pat}@${server}/${org}/${project}/_git/${repo_name}"
        
        if GIT_TERMINAL_PROMPT=0 git clone "$auth_url" "$repo_name" 2>&1; then
            echo "  -> SUCCESS with Method 5"
            success=true
        else
            rm -rf "$repo_name" 2>/dev/null
            echo "  -> Failed"
        fi
    fi
    
    # ============================================
    # RESULT
    # ============================================
    echo ""
    echo "=========================================="
    if [[ "$success" == "true" ]]; then
        echo "Clone SUCCESSFUL!"
        echo "Repository cloned to: $output_dir/$repo_name"
        echo ""
        echo "For future clones, use the method that worked."
    else
        echo "All methods FAILED"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Verify your PAT is correct and not expired"
        echo "  2. Check PAT has 'Code (Read)' permission"
        echo "  3. Verify the URL is correct:"
        echo "     $base_url"
        echo "  4. Try in PowerShell with migrate.ps1 (uses different auth)"
        echo ""
        echo "To test manually:"
        echo "  curl -u ':YOUR_PAT' '$base_url/info/refs?service=git-upload-pack'"
    fi
    echo "=========================================="
}

# Clone all repos using the method that works
# Usage: clone_all_repos_interactive
clone_all_repos_interactive() {
    echo "=========================================="
    echo "  Clone All Repos with PAT Auth"
    echo "=========================================="
    echo ""
    
    read -p "Azure DevOps Server [sdipsse1001.onead.schipholgroupcloud.nl]: " server
    server="${server:-sdipsse1001.onead.schipholgroupcloud.nl}"
    
    read -p "Organization/Collection [DefaultCollection]: " org
    org="${org:-DefaultCollection}"
    
    read -p "Project name: " project
    
    read -p "Personal Access Token (PAT): " pat
    
    read -p "Output directory [./repos]: " output_dir
    output_dir="${output_dir:-./repos}"
    
    # Test auth first with a simple request
    echo ""
    echo "Testing authentication..."
    local base64_auth=$(printf ":%s" "$pat" | base64 -w 0 2>/dev/null || printf ":%s" "$pat" | base64)
    local test_url="https://${server}/${org}/${project}/_apis/git/repositories?api-version=6.0"
    
    local test_result=$(curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic ${base64_auth}" "$test_url")
    
    if [[ "$test_result" != "200" ]]; then
        echo "Authentication test failed (HTTP $test_result)"
        echo "Check your PAT and permissions"
        return 1
    fi
    echo "Authentication OK!"
    
    mkdir -p "$output_dir"
    cd "$output_dir" || return 1
    
    local auth_header="Authorization: Basic ${base64_auth}"
    local count=0
    local failed=0
    local total=${#REPO_URLS[@]}
    
    echo ""
    echo "Cloning $total repositories..."
    echo "=========================================="
    
    for url in "${REPO_URLS[@]}"; do
        ((count++))
        local repo_name=$(basename "$url" .git)
        local target_url="https://${server}/${org}/${project}/_git/${repo_name}"
        
        echo ""
        echo "[$count/$total] $repo_name"
        
        if [[ -d "$repo_name" ]] || [[ -d "$repo_name.git" ]]; then
            echo "  -> Already exists, skipping"
            continue
        fi
        
        # Use extraheader method (most reliable)
        if GIT_TERMINAL_PROMPT=0 git -c "http.extraheader=$auth_header" clone --mirror "$target_url" "${repo_name}.git" 2>&1; then
            echo "  -> SUCCESS"
        else
            echo "  -> FAILED"
            ((failed++))
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "Done! Cloned $((count - failed))/$count repositories"
    [[ $failed -gt 0 ]] && echo "Failed: $failed"
    echo "Location: $output_dir"
}

# Repository URLs to clone
REPO_URLS=(
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/BadgeCenterEmail.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/BaseTarget.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/BiometricBackBone.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/BiometrieDevelopment.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/bsp.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/BusGateControlPanel.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/cvstogit.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/devops_scripts.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Digifalls.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Doc.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/GateControlPanel.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Helios.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/LoggingService.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Passwords.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/PCP_Test.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Prepoas.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/PriorityAGP.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Privium.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/SAMTranslator.git"
    "https://sdipcsv4001.onead.schipholgroupcloud.nl/gitserver/Vesta.git"
)

# Clone all repos with all branches for migration
# Usage: clone_repos_for_migration [output_dir]
clone_repos_for_migration() {
    local output_dir="${1:-./repos}"
    
    # Create output directory
    mkdir -p "$output_dir"
    cd "$output_dir" || return 1
    
    local count=0
    local total=${#REPO_URLS[@]}
    
    echo "Cloning $total repositories"
    echo "Output directory: $output_dir"
    echo "=========================================="
    
    for url in "${REPO_URLS[@]}"; do
        ((count++))
        local repo_name
        repo_name=$(basename "$url" .git)
        
        echo ""
        echo "[$count/$total] Cloning: $repo_name"
        echo "URL: $url"
        
        if [[ -d "$repo_name.git" ]]; then
            echo "  -> Already exists, skipping..."
            continue
        fi
        
        # Use --mirror to get ALL branches, tags, and refs for migration
        if git clone --mirror "$url"; then
            echo "  -> SUCCESS"
        else
            echo "  -> FAILED"
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "Clone complete! $count repositories processed."
    echo ""
    echo "To push to new server with PAT auth, run:"
    echo "  push_repos_to_new_server 'https://server.com/git' 'username' 'your-pat-token'"
}

# Push all mirrored repos to a new git server using PAT authentication
# Usage: push_repos_to_new_server <new_server_base_url> <username> <pat> [repos_dir]
# Example: push_repos_to_new_server "https://dev.azure.com/org/project/_git" "username" "your-pat-token"
push_repos_to_new_server() {
    local new_server="${1}"
    local username="${2}"
    local pat="${3}"
    local repos_dir="${4:-.}"
    
    if [[ -z "$new_server" ]] || [[ -z "$username" ]] || [[ -z "$pat" ]]; then
        echo "ERROR: Server URL, username, and PAT are required"
        echo ""
        echo "Usage: push_repos_to_new_server <new_server_base_url> <username> <pat> [repos_dir]"
        echo ""
        echo "Examples:"
        echo "  # Azure DevOps:"
        echo "  push_repos_to_new_server 'https://dev.azure.com/org/project/_git' 'username' 'your-pat'"
        echo ""
        echo "  # GitHub:"
        echo "  push_repos_to_new_server 'https://github.com/org' 'username' 'ghp_xxxx'"
        echo ""
        echo "  # Generic Git server:"
        echo "  push_repos_to_new_server 'https://gitserver.com/repos' 'username' 'token'"
        return 1
    fi
    
    cd "$repos_dir" || return 1
    
    # Build authenticated URL: https://username:pat@server.com/path
    # Extract protocol and rest of URL
    local protocol="${new_server%%://*}"
    local server_path="${new_server#*://}"
    local auth_base="${protocol}://${username}:${pat}@${server_path}"
    
    local count=0
    for repo in *.git; do
        if [[ -d "$repo" ]]; then
            ((count++))
            local repo_name="${repo}"
            local new_url="${auth_base}/${repo_name}"
            # Display URL without PAT for security
            local display_url="${new_server}/${repo_name}"
            
            echo ""
            echo "[$count] Pushing: $repo_name -> $display_url"
            
            cd "$repo" || continue
            
            # Set the new remote with auth
            git remote set-url origin "$new_url"
            
            # Push everything (all branches, tags, refs)
            if git push --mirror; then
                echo "  -> SUCCESS"
            else
                echo "  -> FAILED"
            fi
            
            cd ..
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "Push complete! $count repositories processed."
}

clonebiometrie() {
    # @desc Clone all Biometrie repos and checkout main
    # Usage:
    #   clonebiometrie           # Clone all repos
    #   clonebiometrie -l        # List repos without cloning
    
    local base_url="https://sdipsse1001.onead.schipholgroupcloud.nl/DefaultCollection/Biometrie/_git"
    local repos=(
        "BadgeCenterEmail"
        "BaseTarget"
        "BiometricBackBone"
        "BiometrieDevelopment"
        "bsp"
        "BusGateControlPanel"
        "cvstogit"
        "devops_scripts"
        "Digifalls"
        "Doc"
        "GateControlPanel"
        "Helios"
        "LoggingService"
        "Passwords"
        "PCP_Test"
        "Prepoas"
        "PriorityAGP"
        "Privium"
        "SAMTranslator"
        "Vesta"
    )
    
    if [ "$1" = "-l" ] || [ "$1" = "--list" ]; then
        echo "Available repositories:"
        for repo in "${repos[@]}"; do
            echo "  - $repo"
        done
        return 0
    fi
    
    echo "Cloning ${#repos[@]} Biometrie repositories..."
    echo "Base URL: $base_url"
    echo "=============================================="
    echo ""
    
    local success=0
    local failed=0
    
    for repo in "${repos[@]}"; do
        echo "----------------------------------------"
        echo "Cloning: $repo"
        echo "----------------------------------------"
        
        if [ -d "$repo" ]; then
            echo "  Directory already exists - skipping"
            ((failed++))
            continue
        fi
        
        git clone "${base_url}/${repo}" || {
            echo "  Error: Failed to clone $repo"
            ((failed++))
            continue
        }
        
        cd "$repo" || {
            echo "  Error: Could not enter $repo directory"
            ((failed++))
            continue
        }
        
        # Checkout main (or master if main doesn't exist)
        if git show-ref --verify --quiet refs/heads/main; then
            git checkout main
            echo "  ✓ Checked out main"
        elif git show-ref --verify --quiet refs/heads/master; then
            git checkout master
            echo "  ✓ Checked out master (main not found)"
        else
            echo "  Warning: No main/master branch found"
        fi
        
        cd ..
        ((success++))
        echo ""
    done
    
    echo "=============================================="
    echo "Done! Cloned: $success, Skipped/Failed: $failed"
}
# Open current directory in PowerShell
# Usage: powershell
powershell() {
    powershell.exe -NoExit -Command "Set-Location '$(pwd)'"
}


sum_builds() {
    iconv -f UTF-16LE -t UTF-8 "$1" |
    awk '
    /succeeded, .* failed, .* skipped/ {
        s += $4
        f += $6
        k += $8
    }
    END {
        printf "Succeeded: %d\n", s
        printf "Failed:    %d\n", f
        printf "Skipped:   %d\n", k
        printf "Total:     %d\n", s + f + k
    }'
}

guff() {
    local pattern max_commits

    read -rp "File pattern (e.g. *.cs, *.json, *.java): " pattern
    read -rp "Maximum commit count (0 = never committed after introduction): " max_commits

    echo
    echo "Scanning files matching '$pattern'..."
    echo

    git ls-files "$pattern" | while IFS= read -r file; do
        commits=$(git log --follow --oneline -- "$file" 2>/dev/null | wc -l)

        if [ "$commits" -le "$max_commits" ]; then
            printf "%5d  %s\n" "$commits" "$file"
        fi
    done | sort -n
}

ccf() {
    local pattern max_commits

    read -rp "File pattern (e.g. *.cpp): " pattern
    read -rp "Maximum commits for low-touch files: " max_commits

    git ls-files "$pattern" |
    while IFS= read -r file; do
        commits=$(git rev-list --count HEAD -- "$file" 2>/dev/null)
        folder=$(dirname "$file")

        echo "$folder|$commits"
    done |
    awk -F'|' -v max="$max_commits" '
    {
        total[$1]++
        commitsum[$1]+=$2

        if ($2 <= max)
            low[$1]++

        if (length($1) > maxlen)
            maxlen = length($1)
    }
    END {
        width = maxlen + 2

        printf "%-" width "s %8s %8s %8s %12s\n",
               "Folder", "Files", "Low", "Low%", "AvgCommits"

        for (f in total) {
            pct = (low[f] * 100) / total[f]
            avg = commitsum[f] / total[f]

            printf "%-" width "s %8d %8d %7.1f%% %12.1f\n",
                   f, total[f], low[f], pct, avg
        }
    }' |
    {
        read -r header
        echo "$header"
        sort -k4 -nr
    }
}

ccfu() {
    local max_commits min_files

    read -rp "Maximum commits for low-touch files: " max_commits
    read -rp "Minimum files per folder [0]: " min_files

    min_files=${min_files:-0}

    git ls-files |
    while IFS= read -r file; do
        commits=$(git rev-list --count HEAD -- "$filedev/null)
        folder=$(dirname "$file")

        echo "$folder|$commits"
    done |
    awk -F'|' -v max="$max_commits" -v min_files="$min_files" '
    {
        total[$1]++
        commitsum[$1]+=$2

        if ($2 <= max)
            low[$1]++

        if (length($1) > maxlen)
            maxlen = length($1)
    }
    END {
        print "Folder\tFiles\tLow\tLow%\tAvgCommits"

        for (f in total) {
            if (total[f] < min_files)
                continue

            pct = (low[f] * 100) / total[f]
            avg = commitsum[f] / total[f]

            printf "%s\t%d\t%d\t%.1f%%\t%.1f\n",
                   f, total[f], low[f], pct, avg
        }
    }' |
    {
        read -r header
        echo "$header"
        sort -t $'\t' -k4 -nr
    } |
    column -t -s $'\t'
}