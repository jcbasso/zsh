# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.
bindkey -M menuselect '^[[Z' reverse-menu-complete # Adding <Shift><Tab> for backwards complete 

# Plugins 
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
