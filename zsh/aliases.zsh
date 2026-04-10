alias cls=clear

function orphaned_symlinks() {
  local dry_run=false
  local paths=()

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      -h|--help)
        echo "Usage: orphaned_symlinks [-n|--dry-run] [path ...]"
        echo ""
        echo "Examples:"
        echo "  orphaned_symlinks                     # scan default Homebrew paths"
        echo "  orphaned_symlinks -n /usr/local/bin   # dry run on path"
        echo "  orphaned_symlinks /some/path          # delete orphaned links"
        return 0
        ;;
      *)
        paths+=("$1")
        shift
        ;;
    esac
  done

  # Default paths (Intel + ARM Homebrew bins)
  if [[ ${#paths[@]} -eq 0 ]]; then
    paths=(/usr/local/bin /opt/homebrew/bin)
  fi

  # Run
  if $dry_run; then
    echo "DRY RUN — showing broken symlinks in: ${paths[*]}"
    find "${paths[@]}" -type l ! -exec test -e {} \; -exec echo rm {} \;
  else
    echo "Removing broken symlinks in: ${paths[*]}"
    find "${paths[@]}" -type l ! -exec test -e {} \; -exec rm {} \;
  fi
}

# aws
function av() {
	aws-vault exec "$1" -- zsh -i
}

function av_add_role() {
	local profile_name role_arn source_profile region
	local config_file="${HOME}/.aws/config"

	read "profile_name?Profile name: "
	if [[ -z "$profile_name" ]]; then
		echo "Error: profile name cannot be empty"
		return 1
	fi

	read "role_arn?Role ARN: "

	read "source_profile?Source (base) profile: "
	if [[ -z "$source_profile" ]]; then
		echo "Error: source profile cannot be empty"
		return 1
	fi

	read "region?Region (optional, press Enter to skip): "

	# Validate role ARN format
	if [[ ! "$role_arn" =~ ^arn:aws:iam::[0-9]{12}:role/.+ ]]; then
		echo "Error: invalid role ARN format. Expected: arn:aws:iam::<account-id>:role/<role-name>"
		return 1
	fi

	# Create config file if it doesn't exist
	[[ ! -f "$config_file" ]] && mkdir -p "$(dirname "$config_file")" && touch "$config_file"

	# Check for duplicate profile
	if grep -qF "[profile ${profile_name}]" "$config_file"; then
		echo "Error: profile '${profile_name}' already exists in ${config_file}"
		return 1
	fi

	# Verify source profile exists
	if ! grep -qF "[profile ${source_profile}]" "$config_file"; then
		echo "Error: source profile '${source_profile}' does not exist in ${config_file}"
		return 1
	fi

	# Append profile block
	if [[ -n "$region" ]]; then
		printf '\n[profile %s]\nrole_arn = %s\nsource_profile = %s\nregion = %s\n' \
			"$profile_name" "$role_arn" "$source_profile" "$region" >> "$config_file"
	else
		printf '\n[profile %s]\nrole_arn = %s\nsource_profile = %s\n' \
			"$profile_name" "$role_arn" "$source_profile" >> "$config_file"
	fi

	echo "Added profile '${profile_name}' to ${config_file}"
}

# terragrunt
alias tgf='terragrunt hcl format && terraform fmt --recursive'
alias tgt='TG_TF_PATH=$(which terraform) terragrunt'
alias tgo='TG_TF_PATH=$(which tofu) terragrunt'
cleartf() {
  local dirpath="${1:-.}"
  find "$dirpath" \
    \( -type d -name '.terraform' -o -type d -name '.terragrunt-cache' -o -type f -name '.terraform.lock.hcl' \) \
    -print -exec rm -rf {} +
}
# python
alias svenv='source .venv/bin/activate'

# docker
alias dc='docker-compose'

# borders
alias borders-start='nohup borders active_color=0xff00cfe6 inactive_color=0xff494d64 width=4.0 > /dev/null 2>&1 &'

# dev
alias v=nvim
alias cd=z
alias cdi=zi
alias ls=eza
alias lg=lazygit

# suffix aliases
if [[ "$SHELL" == *"zsh"* ]]; then
  alias -s {md,txt,json,yaml,yml,toml,conf,ini}=nvim
  alias -s log="tail -f"
fi
