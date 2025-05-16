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
alias tgt='TERRAGRUNT_TFPATH=$(which terraform) terragrunt'
alias tgo='TERRAGRUNT_TFPATH=$(which tofu) terragrunt'
alias cleartf='rm -rf .terraform* .terragrunt-cache'

# python
alias svenv='source .venv/bin/activate'

# docker
alias dc='docker-compose'