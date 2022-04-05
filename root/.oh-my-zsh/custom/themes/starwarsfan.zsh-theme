local return_code="%(?..%{$fg[red]%}%? %{$reset_color%})"

#PROMPT='%{$fg[yellow]%}%n@%m { %c } \
PROMPT='%(!.%{$fg[red]%}%n%{$fg[reset_color]%}.%{$fg[yellow]%}%n%{$fg[reset_color]%})%{$fg[yellow]%}@%m { %c } \
%{$fg[green]%}$(  git rev-parse --abbrev-ref HEAD 2> /dev/null || echo ""  )%{$reset_color%} \
%{$fg[red]%}%(!.#.»)%{$reset_color%} '

PROMPT2='%{$fg[red]%}\ %{$reset_color%}'

RPS1='%{$fg[yellow]%}%~%{$reset_color%} ${return_code} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}:: %{$fg[yellow]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}*%{$fg[yellow]%}"