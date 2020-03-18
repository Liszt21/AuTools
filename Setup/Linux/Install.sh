#!/bin/sh

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

if [ $APP_HOME ];then
    ENTRY=true
fi

if [[ $(command -v yum) ]]; then
	CMD="yum"
fi

APP_HOME=${APP_HOME:-~/Apps}


# Default settings
VIA_GITEE=true
IS_ME=false
IN_WSL=false

ALL_INSTALLED=false
ZSH_INSTALLED=false
PYENV_INSTALLED=false
NVM_INSTALLED=false
DOCKER_INSTALLED=false
EMACS_INSTALLED=false

PROXY=false

setentry() {
    echo "Setting entry"
    if [ -z "$shell" ]; then
        shell="$(ps c -p "$PPID" -o 'ucomm=' 2>/dev/null || true)"
        shell="${shell##-}"
        shell="${shell%% *}"
        shell="$(basename "${shell:-$SHELL}")"
    fi

    echo "APP_HOME=\${APP_HOME:-~/Apps}" > $APP_HOME/entry
    echo "export APP_HOME" >> $APP_HOME/entry

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

    echo "source \$APP_HOME/pyenv/entry" >> $APP_HOME/entry
    echo "source \$APP_HOME/nvm/entry" >> $APP_HOME/entry
    echo "export PATH=\"\$PATH:\$APP_HOME/emacs/bin\"" >> $APP_HOME/entry
}

setproxy() {
    echo "------Setting proxy"
    PROXY_HOST=127.0.0.1
    if $IN_WSL;then
        PROXY_HOST=$WIN_HOST
    fi
    export ALL_PROXY=socks5://$PROXY_HOST:1080
    git config --global http.proxy socks5://$PROXY_HOST:1080
    git config --global https.proxy socks5://$PROXY_HOST:1080
    echo "\n"
}

setwsl() {
    if [ ! -f $APP_HOME/wsl ];then
        echo source \$APP_HOME/wsl >> $APP_HOME/entry
        echo export WIN_HOST="\`ipconfig.exe | grep -n4 WSL  | tail -n 1 | awk -F\":\" '{ print \$2 }'  | sed 's/^[ \\\r\\\n\\\t]*//;s/[ \\\r\\\n\\\t]*$//\`" > $APP_HOME/wsl
    fi
}

config() {
    if [ "liszt" = "$USER" ];then
        IS_ME=true
    fi
    if [ ! -d "$APP_HOME" ];then
        mkdir "$APP_HOME"
    fi
    if [ ! -d "$APP_HOME/cache" ];then
        mkdir "$APP_HOME/cache"
    fi
    if [ ! $ENTRY ];then
        setentry
    fi
}

check() {
    echo "Checking, please wait"
    if [ -f ~/.zshrc ];then
        ZSH_INSTALLED=true
    fi
    if [ -d "$APP_HOME/emacs" ];then
        EMACS_INSTALLED=true
    fi
    if command -v pyenv 1>/dev/null 2>&1;then
        PYENV_INSTALLED=true
    fi
    if command -v nvm 1>/dev/null 2>&1;then
        NVM_INSTALLED=true
    fi
    if command -v docker 1>/dev/null 2>&1;then
        DOCKER_INSTALLED=true
    fi
    if $ZSH_INSTALLED && $NVM_INSTALLED && $PYENV_INSTALLED && $DOCKER_INSTALLED && $EMACS_INSTALLED;then
        ALL_INSTALLED=true
    fi
    if [ $WSL_DISTRO_NAME ];then
        IN_WSL=true
        setwsl
    fi
    ping -w 1 github.com >/dev/null
    if [  $? -eq 0  ];then
        VIA_GITEE=false
    fi
}

menu() {
    echo "System auto setup --- Linux"
    echo "Commands:(default 0)"
    echo "  0: Install badic & exit"
    echo "  1: Install zsh            Installed:"$ZSH_INSTALLED
    echo "  2: Install pyenv          Installed:"$PYENV_INSTALLED
    echo "  3: Install nvm            Installed:"$NVM_INSTALLED
    echo "  4: Install emacs          Installed:"$EMACS_INSTALLED
    echo "  5: Install docker         Installed:"$DOCKER_INSTALLED
    echo "  8: Set proxy"
    echo "  9: Exit\n"
}

install_essential() {
    echo "------Install essential"
    if [ "$CMD" = "yum" ]; then
        sudo yum update -y
        sudo yum install git wget curl vim screen -y
    else
        sudo apt-get update
        sudo apt-get install git wget curl vim screen -y
    fi
    echo "\n"
}

install_zsh() {
    echo "------Installing zsh & oh-my-zsh"
    echo "Remember to exit from zsh to continue"
    if [ "$CMD" = "yum" ]; then
        sudo yum install zsh -y
    else
        sudo apt-get install zsh -y
    fi
    if $VIA_GITEE;then
        export REMOTE=https://gitee.com/mirrors/oh-my-zsh.git
    fi
    export RUNZSH=no
    sh -c "$(curl -fsSL https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh)"
    echo "source $APP_HOME/entry" >> ~/.zshrc
    echo "Zsh install finished\n"
}

install_pyenv() {
    echo "Installing pyenv"
    if $VIA_GITEE;then
        PYENV_REPO_ROOT=https://gitee.com/mirrors
    else
        PYENV_REPO_ROOT=https://github.com/pyenv
    fi
    failed_checkout() {
        echo "Failed to git clone $1"
        exit -1
    }
    checkout() {
        [ -d "$2" ] || git clone --depth 1 "$1" "$2" || failed_checkout "$1"
    }
    checkout "$PYENV_REPO_ROOT/pyenv.git"            "$APP_HOME/pyenv"
    if ! $VIA_GITEE;then
        checkout "$PYENV_REPO_ROOT/pyenv-doctor.git"     "$APP_HOME/pyenv/plugins/pyenv-doctor"
        checkout "$PYENV_REPO_ROOT/pyenv-installer.git"  "$APP_HOME/pyenv/plugins/pyenv-installer"
        checkout "$PYENV_REPO_ROOT/pyenv-update.git"     "$APP_HOME/pyenv/plugins/pyenv-update"
        checkout "$PYENV_REPO_ROOT/pyenv-virtualenv.git" "$APP_HOME/pyenv/plugins/pyenv-virtualenv"
        checkout "$PYENV_REPO_ROOT/pyenv-which-ext.git"  "$APP_HOME/pyenv/plugins/pyenv-which-ext"
    fi
    if [ "$CMD" = "yum" ]; then
        sudo yum install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel -y

    else
        sudo apt-get install zlibc zlib1g zlib1g-dev libffi-dev libssl-dev libbz2-dev libreadline-dev libsqlite3-dev tk-dev -y
    fi

    export PYENV_ROOT="$APP_HOME/pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    #Setup entry
    echo "export PYENV_ROOT=\"\$APP_HOME/pyenv\"" > $APP_HOME/pyenv/entry
    echo "export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> $APP_HOME/pyenv/entry
    echo "eval \"\$(pyenv init -)\"" >> $APP_HOME/pyenv/entry
    # echo "eval \"\$(pyenv virtualenv-init -)\"" >> $APP_HOME/pyenv/entry
    echo "Pyenv install finished\n"
}

install_nvm() {
    echo "Installing nvm"
    if [ ! -d "$APP_HOME/nvm" ];then
        git clone https://gitee.com/mirrors/nvm.git $APP_HOME/nvm
    fi
    # Setup entry
    echo "export NVM_DIR=\$APP_HOME/nvm" > $APP_HOME/nvm/entry
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # This loads nvm" >> $APP_HOME/nvm/entry
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> $APP_HOME/nvm/entry

    export NVM_DIR=/home/liszt/Apps/nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    echo "Nvm install finished\n"
}

install_docker() {
    echo "Installing docker"
    sudo sh -c "$(curl -fsSL https://get.docker.com)"
    sudo usermod -aG docker $USER
    echo "Docker install finished\n"
}

install_emacs() {
    if $VIA_GITEE;then
        SPACEMACS_REPO=https://gitee.com/mirrors/spacemacs.git
        SPACEMACS_CONF_REPO=https://gitee.com/Liszt21/MySpacemacs.git
    else
        SPACEMACS_REPO=https://github.com/syl20bnr/spacemacs.git
        SPACEMACS_CONF_REPO=https://github.com/Liszt21/.spacemacs.d.git
    fi
    echo "Installing emacs"
    if [ ! -d "$APP_HOME/cache/emacs" ];then
        echo "Downloading source"
        cd $APP_HOME/cache
        wget http://mirrors.ustc.edu.cn/gnu/emacs/emacs-26.3.tar.gz
        tar -xvzf emacs-26.3.tar.gz
        mv ./emacs-26.3 emacs
    fi
    # Install dependencies

    if [ "$CMD" = "yum" ]; then
        sudo yum -y groupinstall “Development Tools”
        sudo yum -y install gtk+-devel gtk2-devel
        sudo yum -y install libXpm-devel
        sudo yum -y install libpng-devel
        sudo yum -y install giflib-devel
        sudo yum -y install libtiff-devel libjpeg-devel
        sudo yum -y install ncurses-devel
        sudo yum -y install gpm-devel dbus-devel dbus-glib-devel dbus-python
        sudo yum -y install GConf2-devel pkgconfig
        sudo yum -y install libXft-devel
    else
        sudo apt-get update
        sudo apt-get install autoconf -y
        sudo apt-get install build-essential automake texinfo libjpeg-dev libncurses5-dev libtiff5-dev libgif-dev libpng-dev libxpm-dev libgtk-3-dev libgnutls28-dev -y
    fi

    
    # Compile
    echo "Compiling Emacs"
    cd $APP_HOME/cache/emacs
    ./autogen.sh
    ./configure --prefix="$APP_HOME/emacs" --with-mailutils --with-modules
    make
    
    make install
    if [ ! -e ~/.emacs.d/spacemacs.mk ];then
        rm -rf ~/.emacs.d
        git clone -b develop $SPACEMACS_REPO ~/.emacs.d
    fi
    if $IS_ME;then
        if [ ! -d ~/.spacemacs.d/layers/liszt ];then
            rm -rf ~/.spacemacs.d
            if $IN_WSL;then
                ln -s /mnt/c/Users/liszt/AppData/Roaming/.spacemacs.d ~/.spacemacs.d
            else
                git clone $SPACEMACS_CONF_REPO ~/.spacemacs.d
            fi
        fi
    fi
    echo "Emacs install finished\n"
}

main() {
    config
    check
    install_essential >> $APP_HOME/log
    while true
    do
        menu
        INSTALL_ALL=false
        INSTALL_ZSH=false
        INSTALL_PYENV=false
        INSTALL_NVM=false
        INSTALL_EMACS=false
        INSTALL_DOCKER=false
        read option
        case "$option" in
            "1" )
                INSTALL_ZSH=true
                ;;
            "2" )
                INSTALL_PYENV=true
                ;;
            "3" )
                INSTALL_NVM=true
                ;;
            "4" )
                INSTALL_EMACS=true
                ;;
            "5" )
                INSTALL_DOCKER=true
                ;;
            "8" )
                PROXY=true
                setproxy
                ;;
            "9" )
                exit
                ;;
            * )
                INSTALL_ALL=true
                ;;
        esac
        if $ALL_INSTALLED;then
            echo $ALL_INSTALLED
            echo "All installed, exit"
            break
        fi
        if $INSTALL_ALL || $INSTALL_ZSH;then
            if ! $ZSH_INSTALLED;then
                install_zsh
            else
                echo "Zsh is already installed!"
            fi
        fi
        if $INSTALL_ALL || $INSTALL_PYENV;then
            if ! $PYENV_INSTALLED;then
                install_pyenv
            else
                echo "Pyenv is already installed!"
            fi
        fi
        if $INSTALL_ALL || $INSTALL_NVM;then
            if ! $NVM_INSTALLED;then
                install_nvm
            else
                echo "Nvm is already installed!"
            fi
        fi
        if $INSTALL_ALL || $INSTALL_EMACS;then
            if ! $EMACS_INSTALLED;then
                install_emacs
            else
                echo "Emacs is already installed!"
            fi
        fi
        if $INSTALL_ALL || $INSTALL_DOCKER;then
            if ! $DOCKER_INSTALLED;then
                install_docker
            else
                echo "Docker is already installed!"
            fi
        fi
        check
        if $ALL_INSTALLED;then
            echo "All apps were installed"
            break
        fi
    done
    if $IS_ME;then
        pyenv install 3.8.1
        pyenv global 3.8.1
        pyenv rehash

        pip install --upgrade pip
        pip install jupyterlab requests numpy scipy wakatime scapy scrapy bs4 flask
        
        nvm install 13

        if [ "$CMD" = "yum" ]; then
            curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
            sudo yum install yarn -y
        else
            curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
            echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
            sudo apt-get update && sudo apt-get install yarn -y
            sudo rm /etc/apt/sources.list.d/yarn.list
        fi

        yarn global add @vue/cli
    fi
}

main