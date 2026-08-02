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

brew-dump() {
  local dry_run=false
  local arch=$(uname -m)
  local brewfile="${BREWFILE:-$HOME/.dotfiles/Brewfile}"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run) dry_run=true; shift ;;
      -h|--help)
        echo "Usage: brew-dump [-n|--dry-run]"
        echo ""
        echo "Compare current brew installs against Brewfile and interactively sync."
        echo "  -n, --dry-run   Show proposed changes without applying"
        return 0
        ;;
      *) shift ;;
    esac
  done

  if [[ ! -f "$brewfile" ]]; then
    echo "Error: Brewfile not found at $brewfile" >&2
    return 1
  fi

  echo "Current arch: $arch"
  echo "Brewfile: $brewfile"
  $dry_run && echo "(dry run — no changes will be written)"
  echo ""

  local tmpfile=$(mktemp)
  brew bundle dump --force --no-describe --file="$tmpfile" 2>/dev/null

  # Parse Brewfile into parallel arrays
  local -a bf_keys=() bf_lines=() bf_conds=()
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    local type="${line%% *}"
    local rest="${line#* }"
    [[ "$rest" =~ ^\"([^\"]+)\" ]] || continue
    local key="$type ${match[1]}"
    local cond="shared"
    [[ "$line" =~ if[[:space:]]+Hardware::CPU\.arm\? ]] && cond="arm"
    [[ "$line" =~ if[[:space:]]+Hardware::CPU\.intel\? ]] && cond="intel"
    bf_keys+=("$key")
    bf_lines+=("$line")
    bf_conds+=("$cond")
  done < "$brewfile"

  # Parse dump
  local -a dump_keys=() dump_lines=()
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    local type="${line%% *}"
    local rest="${line#* }"
    [[ "$rest" =~ ^\"([^\"]+)\" ]] || continue
    local key="$type ${match[1]}"
    dump_keys+=("$key")
    dump_lines+=("$line")
  done < "$tmpfile"

  # Check if key exists in array
  in_arr() {
    local needle="$1"; shift
    for k in "$@"; do
      [[ "$k" == "$needle" ]] && return 0
    done
    return 1
  }

  # Strip tap prefix from cask for comparison (nikitabobko/tap/aerospace -> aerospace)
  strip_cask_tap() {
    local name="$1"
    [[ "$name" == */* ]] && echo "${name##*/}" || echo "$name"
  }

  # Check if two cask keys match (with/without tap prefix)
  cask_eq() {
    local k1="$1" k2="$2"
    [[ "${k1%% *}" == "cask" && "${k2%% *}" == "cask" ]] || return 1
    local n1="${k1#* }" n2="${k2#* }"
    [[ "$n1" == "$n2" ]] && return 0
    [[ "$(strip_cask_tap "$n1")" == "$(strip_cask_tap "$n2")" ]] && return 0
    return 1
  }

  local changes=0
  local -a simplified_keys=()

  # --- Auto-simplify: strip conditionals and cask tap prefixes ---
  for i in {1..${#bf_keys[@]}}; do
    local bk="${bf_keys[$i]}" bl="${bf_lines[$i]}" cond="${bf_conds[$i]}"
    local new_line="$bl"

    # Strip conditional (arm/intel -> shared)
    if [[ "$cond" != "shared" ]]; then
      new_line="${new_line%% if *}"
    fi

    # Strip cask tap prefix (cask "foo/bar/baz" -> cask "baz")
    if [[ "${bk%% *}" == "cask" ]]; then
      local bn="${bk#* }"
      if [[ "$bn" == */* ]]; then
        local short_name
        short_name=$(strip_cask_tap "$bn")
        new_line="cask \"${short_name}\""
      fi
    fi

    [[ "$new_line" == "$bl" ]] && continue

    echo "  ~ $bl"
    echo "    → $new_line"
    if $dry_run; then
      echo "    (would simplify)"
    else
      command grep -vF "$bl" "$brewfile" > "$tmpfile.2" && command mv "$tmpfile.2" "$brewfile"
      echo "$new_line" >> "$brewfile"
      echo "    ✓ Simplified"
    fi
    simplified_keys+=("$bk")
    ((changes++))
  done

  # --- Missing from Brewfile (in dump, not in Brewfile) ---
  local has_missing=0
  for dk in "${dump_keys[@]}"; do
    in_arr "$dk" "${bf_keys[@]}" && continue
    local found=false
    for bk in "${bf_keys[@]}"; do
      cask_eq "$dk" "$bk" && { found=true; break; }
    done
    $found && continue
    has_missing=1
  done

  if [[ $has_missing -eq 1 ]]; then
    echo ""
    echo "=== Add to Brewfile ==="
    for dk in "${dump_keys[@]}"; do
      in_arr "$dk" "${bf_keys[@]}" && continue
      local found=false
      for bk in "${bf_keys[@]}"; do
        cask_eq "$dk" "$bk" && { found=true; break; }
      done
      $found && continue
      local dl="${dump_lines[$(( dump_keys[(I)$dk] ))]}"
      echo "  + $dl"
      read "resp?    Add as shared package? [y/n]: "
      if [[ "$resp" =~ ^[Yy] ]]; then
        if $dry_run; then
          echo "    (would add)"
        else
          echo "$dl" >> "$brewfile"
          echo "    ✓ Added"
        fi
        ((changes++))
      fi
    done
  fi

  # --- Stale in Brewfile (in Brewfile, not in dump) ---
  local has_stale=0
  for bk in "${bf_keys[@]}"; do
    in_arr "$bk" "${simplified_keys[@]}" && continue
    in_arr "$bk" "${dump_keys[@]}" && continue
    local found=false
    for dk in "${dump_keys[@]}"; do
      cask_eq "$bk" "$dk" && { found=true; break; }
    done
    $found && continue
    has_stale=1
  done

  if [[ $has_stale -eq 1 ]]; then
    echo ""
    echo "=== Remove from Brewfile ==="
    for bk in "${bf_keys[@]}"; do
      in_arr "$bk" "${simplified_keys[@]}" && continue
      in_arr "$bk" "${dump_keys[@]}" && continue
      local found=false
      for dk in "${dump_keys[@]}"; do
        cask_eq "$bk" "$dk" && { found=true; break; }
      done
      $found && continue
      local bl="${bf_lines[$(( bf_keys[(I)$bk] ))]}"
      echo "  - $bl"
      read "resp?    Remove from Brewfile? [y/n]: "
      if [[ "$resp" =~ ^[Yy] ]]; then
        if $dry_run; then
          echo "    (would remove)"
        else
          command grep -vF "$bl" "$brewfile" > "$tmpfile.2" && command mv "$tmpfile.2" "$brewfile"
          echo "    ✓ Removed"
        fi
        ((changes++))
      fi
    done
  fi

  # --- Summary ---
  echo ""
  if [[ $changes -gt 0 ]]; then
    echo "Made $changes change(s) to $brewfile"
  else
    echo "Brewfile is up to date"
  fi

  rm "$tmpfile"
}

# aws
function awsv() {
	aws-vault exec "$1" -- zsh -i
}

function awsv_add_role() {
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
alias grep='rg'
alias sed=sd
alias find='fd'
alias cat='bat --style=auto'
alias ls='eza --icons --group-directories-first'
alias lg=lazygit
alias findlock="ioreg -l -w 0 | grep SecureInput"

# suffix aliases
if [[ "$SHELL" == *"zsh"* ]]; then
  alias -s {md,txt,json,yaml,yml,toml,conf,ini}=nvim
  alias -s log="tail -f"
fi
