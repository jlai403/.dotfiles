alias cls=clear

# git aliases
alias gi='git init'
alias gcl='git clone'
alias gco='git checkout'
alias gd="git diff --output-indicator-new=' ' --output-indicator-old=' '"
alias ga='git add -A'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gu='git pull'
alias gl="git log --all --graph --pretty=\
	format:'%C(magenta)%h %C(white) %an %ar%C(auto) %D%n%s%n'"
alias gb='git branch'

# aws
function av() {
	aws-vault exec "$1" -- zsh -i
}

# terragrunt
alias tgf='terragrunt hcl format && terraform fmt --recursive'
alias tgt='TG_TF_PATH=$(which terraform) terragrunt'
alias tgts='TG_TF_PATH=$(~/Developer/binaries/terraform@1.9.8/terraform) terragrunt'
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

# dev
alias v=nvim
alias cd=z
alias cdi=zi
alias ls=eza
alias lg=lazygit
