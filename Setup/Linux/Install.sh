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
    if ! $ENTRY ;then
        echo APP_HOME=\${APP_HOME:-~/Apps} > $APP_HOME/entry
        echo export APP_HOME >> $APP_HOME/entry
        echo source \$APP_HOME/pyenv/entry >> $APP_HOME/entry
        echo source \$APP_HOME/nvm/entry >> $APP_HOME/entry

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
}

setupenv() {
    echo "Setting environment"
    sudo apt-get install git wget curl vim screen -y
}

installzsh() {
    echo "Install zsh & oh-my-zsh"
    if [ ! -f ~/.zshrc ];then
        echo "Remember to exit from zsh to continue"
        sudo apt-get install zsh -y
        sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"
        echo "source $APP_HOME/entry" >> ~/.zshrc
    fi
}

installemacs() {
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

    if ! command -v emacs 1>/dev/null 2>&1;then
        echo "Adding emacs to PATH"
        echo "export PATH=\"$APP_HOME/emacs/bin:\$PATH\"" >> $APP_HOME/entry
    fi
}

installpyenv() {
    echo "Installing python"
    if ! command -v pyenv 1>/dev/null 2>&1;then
        if [ ! -d "$APP_HOME/pyenv" ];then
            # curl https://pyenv.run | bash
            failed_checkout() {
                echo "Failed to git clone $1"
                exit -1
            }
            checkout() {
                [ -d "$2" ] || git clone --depth 1 "$1" "$2" || failed_checkout "$1"
            }

            checkout "https://github.com/pyenv/pyenv.git"            "$APP_HOME/pyenv"
            checkout "https://github.com/pyenv/pyenv-doctor.git"     "$APP_HOME/pyenv/plugins/pyenv-doctor"
            checkout "https://github.com/pyenv/pyenv-installer.git"  "$APP_HOME/pyenv/plugins/pyenv-installer"
            checkout "https://github.com/pyenv/pyenv-update.git"     "$APP_HOME/pyenv/plugins/pyenv-update"
            checkout "https://github.com/pyenv/pyenv-virtualenv.git" "$APP_HOME/pyenv/plugins/pyenv-virtualenv"
            checkout "https://github.com/pyenv/pyenv-which-ext.git"  "$APP_HOME/pyenv/plugins/pyenv-which-ext"

            sudo apt-get install zlibc zlib1g zlib1g-dev libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev tk-dev -y

            export PYENV_ROOT="$APP_HOME/pyenv"
            export PATH="$PYENV_ROOT/bin:$PATH"
            eval "$(pyenv init -)"
            
        fi
        echo "export PYENV_ROOT=\"\$APP_HOME/pyenv\"" > $APP_HOME/pyenv/entry
        echo "export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> $APP_HOME/pyenv/entry
        echo "eval \"\$(pyenv init -)\"" >> $APP_HOME/pyenv/entry
        # echo "eval \"\$(pyenv virtualenv-init -)\"" >> $APP_HOME/pyenv/entry
    else
        echo "Pyenv is already installed"
    fi
}

installdocker() {
    echo "Installing docker"
    if ! command -v docker 1>/dev/null 2>&1;then
        sudo sh -c "$(curl -fsSL https://get.docker.com)"
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
    if [ "$IS_ME" ];then
        if [ ! -d ~/.spacemacs.d/layers/liszt/ ];then
            rm -rf ~/.spacemacs.d
            git clone https://github.com/Liszt21/.spacemacs.d.git ~/.spacemacs.d
        fi
        pyenv install 3.8.1
        pyenv global 3.8.1
        pyenv rehash

        pip install jupyterlab requests numpy scipy wakatime scapy scrapy bs4 flask
        
        nvm install 13

        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        sudo apt-get update && sudo apt-get install yarn -y
        sudo rm /etc/apt/sources.list.d/yarn.list

        yarn global add @vue/cli
    fi
    echo "Using 'source $APP_HOME/entry' to reload"
}

main() {
    echo "System auto setup --- Linux"
    check
    setupenv
    
    installzsh || echo "Install zsh failed!!!\n"
    installemacs || echo "Install emacs failed!!!\n"
    installpyenv || echo "Install pyenv failed!!!\n"
    installnvm || echo "Install nvm failed!!!\n"
    installdocker || echo "Install docker failed!!!\n"

    finishsetup
}

main
