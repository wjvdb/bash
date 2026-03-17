alias devportal="cd /c/dev/"

# ===============================
# Git Migration Clone Function
# Clones all repos with ALL branches for migration
# ===============================

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
    echo "To push to new server, run:"
    echo "  push_repos_to_new_server 'https://newserver.com/git'"
}

# Push all mirrored repos to a new git server
# Usage: push_repos_to_new_server <new_server_base_url> [repos_dir]
# Example: push_repos_to_new_server "https://newserver.com/git"
push_repos_to_new_server() {
    local new_server="${1}"
    local repos_dir="${2:-.}"
    
    if [[ -z "$new_server" ]]; then
        echo "ERROR: New server URL required"
        echo "Usage: push_repos_to_new_server <new_server_base_url> [repos_dir]"
        echo "Example: push_repos_to_new_server 'https://newserver.com/git'"
        return 1
    fi
    
    cd "$repos_dir" || return 1
    
    local count=0
    for repo in *.git; do
        if [[ -d "$repo" ]]; then
            ((count++))
            local repo_name="${repo}"
            local new_url="${new_server}/${repo_name}"
            
            echo ""
            echo "[$count] Pushing: $repo_name -> $new_url"
            
            cd "$repo" || continue
            
            # Set the new remote
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
