#!/bin/sh

set -e

setproxy(){
    echo "Setting proxy!"
    if [ ! $http_proxy ];then
        export http_proxy=http://127.0.0.1:1087;
        export http_proxy=http://127.0.0.1:1087;
    fi
}

installzsh() {
    echo "Installing oh-my-zsh"
    if [ ! -f ~/.zshrc ];then
        brew install git
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        echo export http_proxy=http://127.0.0.1:1087; >> ~/.zshrc
        echo export https_proxy=http://127.0.0.1:1087; >> ~/.zshrc
        source ~/.zshrc
    fi
}

installbrew() {
    echo "Installing Homebrew"
    if ! command -v brew 1>/dev/null 2>&1;then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi
}

installenv() {
    echo "Installing programing environment"
    if ! command -v pyenv 1>/dev/null 2>&1;then
        brew install pyenv
        echo "export PYENV_ROOT=/usr/local/var/pyenv" >> ~/.zshrc
        echo "if which pyenv > /dev/null; then eval \"\$(pyenv init -)\"; fi" >> ~/.zshrc
    fi
    if ! command -v nvm 1>/dev/null 2>&1;then
        brew install nvm
        echo "source /usr/local/opt/nvm/nvm.sh" >> ~/.zshrc
    fi

    brew cask install visual-studio-code atom emacs pycharm-ce intellij-idea-ce julia java docker
}

finish() {
    echo "Finishing setup"
    if [ "liszt" = "$USER" ];then
        echo "Personal setting"
        echo "Install spacemacs"
        if [ ! -e ~/.emacs.d/spacemacs.mk ];then
            rm -rf ~/.emacs.d
            # git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d
            git clone -b develop https://gitee.com/mirrors/spacemacs ~/.emacs.d
        fi
        if [ ! -d ~/.spacemacs.d/layers/liszt/ ];then
            rm -rf ~/.spacemacs.d
            git clone https://github.com/Liszt21/.spacemacs.d.git ~/.spacemacs.d
        fi
        pyenv install 3.8.1
        pyenv global 3.8.1
        pyenv rehash

        if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
        pip install jupyterlab requests numpy scipy wakatime scapy scrapy bs4 flask
        
        nvm install 13
        brew install yarn
        yarn global add @vue/cli
    fi
}

main() {
    echo "System auto setup --- Mac"
    setproxy
    installbrew || echo "Install homebrew failes!!!"
    installzsh
    installenv
    finish
}

main