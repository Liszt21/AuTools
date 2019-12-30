#!/bin/sh

set -e

APP_HOME=${APP_HOME:-~/Apps}
ENTRY=${ENTRY:-false}
IS_ME=false

# get shell
shell="$1"
if [ -z "$shell" ]; then
  shell="$(ps c -p "$PPID" -o 'ucomm=' 2>/dev/null || true)"
  shell="${shell##-}"
  shell="${shell%% *}"
  shell="$(basename "${shell:-$SHELL}")"
fi

check() {
    # Checking
    if [ "liszt" = "$USER" ];then
        IS_ME=true
    fi
    if [ ! -d "$APP_HOME" ];then
        mkdir "$APP_HOME"
    fi
    if [ ! -d "$APP_HOME/cache" ];then
        mkdir "$APP_HOME/cache"
    fi
    if [ ! -f "$APP_HOME/entry" ];then
        touch $APP_HOME/entry
        echo APP_HOME=${APP_HOME:-~/Apps} >> $APP_HOME/entry
        echo ENTRY
        echo export APP_HOME >> $APP_HOME/entry
        echo source $APP_HOME/pyenv/entry >> $APP_HOME/entry
        echo source $APP_HOME/nvm/entry >> $APP_HOME/entry
        
        if ! $ENTRY ;then
            case "$shell" in
            bash )
                profile=~/.bashrc
                ;;
            zsh )
                profile=~/.zshrc
                ;;
            ksh )
                profile=~/.profile
                ;;
            fish )
                profile=~/.config/fish/config.fish
                ;;
            * )
                profile=~/.bashrc
                ;;
            esac
            echo "source $APP_HOME/entry" >> $profile
            echo export ENTRY=true >> $profile
        fi
    fi
}

setupenv() {
    echo "Setting environment"
    sudo apt-get install git wget curl vim
}

installzsh() {
    echo "Install zsh & oh-my-zsh"
    if [ ! -f ~/.zshrc ];then
        echo "Remember to exit from zsh to continue"
        sudo apt-get install zsh
        sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"
        echo "source $APP_HOME/entry" >> ~/.zshrc
    fi
}

installspacemacs() {
    echo "Installing Emacs"
    # Check
    if [ ! -d "$APP_HOME/emacs" ];then
        if [ ! -d "$APP_HOME/cache/emacs" ];then
            echo "Downloading source"
            cd $APP_HOME/cache
            wget http://mirrors.ustc.edu.cn/gnu/emacs/emacs-26.3.tar.gz
            tar -xvzf emacs-26.3.tar.gz
            mv ./emacs-26.3 emacs
        fi
        # Install dependencies
        sudo apt-get update
        sudo apt-get install autoconf -y
        sudo apt-get install build-essential automake texinfo libjpeg-dev libncurses5-dev libtiff5-dev libgif-dev libpng-dev libxpm-dev libgtk-3-dev libgnutls28-dev -y
        # Compile
        echo "Compiling Emacs"
        cd $APP_HOME/cache/emacs
        ./autogen.sh
        ./configure --prefix="$APP_HOME/emacs" --with-mailutils --with-modules
        make
        # Install emacs
        make install
    else
        echo "Emacs is installed"
    fi
    echo "Install spacemacs"
    if [ ! -e ~/.emacs.d/spacemacs.mk ];then
        rm -rf ~/.emacs.d
        # git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
        git clone -b develop https://gitee.com/mirrors/spacemacs ~/.emacs.d
    fi
    if [ "$IS_ME" ];then
        if [ ! -d ~/.spacemacs.d/layers/liszt/ ];then
            rm -rf ~/.spacemacs.d
            git clone https://github.com/Liszt21/.spacemacs.d.git ~/.spacemacs.d
        fi
    fi

    if ! command -v emacs 1>/dev/null 2>&1;then
        echo "Adding emacs to PATH"
        echo "export PATH=\"$APP_HOME/emacs/bin:\$PATH\"" >> $APP_HOME/entry
    fi
}

installpython() {
    echo "Installing python"
    if ! command -v pyenv 1>/dev/null 2>&1;then
        if [ ! -d "$APP_HOME/pyenv" ];then
            curl https://pyenv.run | bash
            sudo apt-get install zlibc zlib1g zlib1g-dev libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev tk-dev -y
            mv ~/.pyenv $APP_HOME/pyenv

            export PYENV_ROOT="$APP_HOME/pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            eval "$(pyenv init -)"
            # init 
            pyenv install 3.8.1
            pyenv global 3.8.1
            pyenv rehash
        fi
        PYENV_ROOT="$APP_HOME/pyenv"
        echo "export PATH=\"$PYENV_ROOT/bin:\$PATH\"" > $APP_HOME/pyenv/entry
        echo "eval \"\$(pyenv init -)\"" >> $APP_HOME/pyenv/entry
        echo "eval \"\$(pyenv virtualenv-init -)\"" >> $APP_HOME/pyenv/entry
    else
        echo "Pyenv is already installed"
    fi
}

installdocker() {
    echo "Installing docker"
    # sh -c "$(curl -fsSL https://get.docker.com)"
    # sudo usermod -aG docker $USER
    if ! command -v docker 1>/dev/null 2>&1;then
        sudo apt-get remove docker docker-engine docker.io 
        sudo apt-get update
        sudo apt-get install \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg-agent \
            software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository \
            "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) \
            stable"
        sudo apt-get install docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
    else
        echo "Docker is already installed"
    fi
}

installnvm() {
    echo "Installing nvm"
    if ! command -v nvm 1>/dev/null 2>&1;then
        if [ ! -d "$APP_HOME/nvm" ];then
            git clone https://gitee.com/mirrors/nvm.git $APP_HOME/nvm
        fi
        NVM_DIR=$APP_HOME/nvm
        echo export NVM_DIR=$APP_HOME/nvm > $APP_HOME/nvm/entry
        echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # This loads nvm" >> $APP_HOME/nvm/entry
        echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> $APP_HOME/nvm/entry

        export NVM_DIR=/home/liszt/Apps/nvm
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    fi
}

finishsetup() {
    echo "Finishing"
}

main() {
    echo "System auto setup --- Linux"
    check
    setupenv

    installzsh
    installspacemacs
    installnvm
    installpython
    installdocker

    finishsetup
}

main
