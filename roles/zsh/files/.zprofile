eval "$(/opt/homebrew/bin/brew shellenv)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# Add .NET Core SDK tools
export PATH="$PATH:/Users/george/.dotnet/tools"

eval "$(zoxide init zsh)"
eval "$(fzf --zsh)"

if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/M365Princess.omp.json)"
fi

export GOPATH="/Users/george/go"

# Created by `pipx` on 2024-07-14 01:11:06
export PATH="$PATH:/Users/george/.local/bin"

export PATH="$PATH:/Users/george/.cargo/bin"

PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
PATH="/opt/homebrew/Cellar/john-jumbo/1.9.0_1/share/john:$PATH"
PATH="$GOPATH/bin:$PATH"

alias ll='ls -lGa'
alias lg='lazygit'
alias k='kubectl'
alias ns='/opt/homebrew/bin/netcat'

export JAVA_HOME="/opt/homebrew/opt/openjdk@17/bin"
export ANDROID_HOME="/Users/george/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"