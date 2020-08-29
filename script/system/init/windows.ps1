# 安装scoop
Set-ExecutionPolicy RemoteSigned -scope CurrentUser

if ($ENV:USERNAME -eq 'liszt'){
    $ISME = $true
}else{
    $ISME = $false
}

if ($ISME) {
    $env:SCOOP='C:\Liszt\scoop'
    [environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
}

Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')

# Scoop basic setting
scoop install git
scoop bucket add extras

if ($ISME){
    scoop bucket add java nerd-fonts

    scoop install sudo ln
    scoop install googlechrome anki bandizip mobaxterm porplayer sumatrapdf snipaste v2ray v2rayn flux dismplusplus
    scoop install vscode atom emacs github julia vcxsrv
    scoop install steam uplay

    scoop install firacode 

    git clone https://github.com/Liszt21/Dragon C:\Liszt\Projects\Dragon
    sudo ln -s C:\Liszt\Projects\Dragon C:\Liszt\Scoop\buckets\dragon
    scoop install lemacs autools
    lemacs
}