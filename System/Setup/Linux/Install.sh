#!/bin/sh

set -e

APP_HOME=${APP_HOME:-~/Apps}
IS_ME=false
# Check
if [ "liszt" = "$USER" ];then
    IS_ME=true
fi
if [ ! -d "$APP_HOME" ];then
    mkdir "$APP_HOME"
fi
if [ ! -d "$APP_HOME/cache" ];then
    mkdir "$APP_HOME/cache"
fi

setupenv() {
    echo "Setting environment"

}

installspacemacs() {
    echo "Installing Emacs"
    # Check
    if [ ! -d "$APP_HOME/emacs" ];then
        if [ ! -d "$APP_HOME/cache/emacs" ];then
            echo "Downloading source"
            cd $APP_HOME/cache
            wget -O emacs.tar.gz http://mirrors.ustc.edu.cn/gnu/emacs/emacs-26.3.tar.gz
            tar -xvzf emacs.tar.gz
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
    if [ ! -f "~/.emacs.d/spacemacs.mk" ];then
        rm -rf ~/emacs.d
        # git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
        git clone -b develop https://gitee.com/mirrors/spacemacs ~/.emacs.d
        if [ "$IS_ME" ];then
            rm -rf ~/.spacemacs.d
            git clone https://github.com/Liszt21/.spacemacs.d.git ~/.spacemacs.d
        fi
    fi
}

installpython() {
    echo "Installing Python"

}

installdocker() {
    echo "Installing Docker"
}

installnvm() {
    echo "Installing Nvm"
}

finishsetup() {
    echo "Finishing"
    
}

main() {
    echo "System auto setup --- Linux"
    setupenv

    installspacemacs
    installnvm
    installpython
    installdocker

    finishsetup
}

main
