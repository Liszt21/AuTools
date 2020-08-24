# 安装scoop
Set-ExecutionPolicy RemoteSigned -scope CurrentUser
$env:SCOOP='C:\Liszt\scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')

# Scoop basic setting
scoop install git
scoop bucket add extras

# Install basic applications
scoop install eamcs vim shadowsocks vscode listary 