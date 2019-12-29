#!/bin/sh

set -e

APP_HOME=${APP_HOME:-~/Apps}
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
        echo export APP_HOME >> $APP_HOME/entry
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
    fi
}

setupenv() {
    echo "Setting environment"
    sudo apt-get install git wget curl vim
}

installzsh() {
    echo "Install zsh & oh-my-zsh"

}

installspacemacs() {
    echo "Installing Emacs"
    # Check
    if [ ! -d "$APP_HOME/emacs" ];then
        if [ ! -d "$APP_HOME/cache/emacs" ];then
            echo "Downloading source"
            cd $APP_HOME/cache
            wget http://mirrors.ustc.edu.cn/gnu/emacs/emacs-26.3.tar.gz
            tar -xvzf emacs.tar.gz
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

}

installdocker() {
    echo "Installing docker"
}

installnvm() {
    echo "Installing nvm"
}

finishsetup() {
    echo "Finishing"
    touch ~/.entry
}

main() {
    echo "System auto setup --- Linux"
    check
    setupenv

    installspacemacs
    installnvm
    installpython
    installdocker

    finishsetup
}

main
