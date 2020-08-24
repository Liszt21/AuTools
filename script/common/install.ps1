if (Get-Command scoop) {
    Write-Output "Scoop is already installed! Skipping..."
}else {
    Write-Output "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -scope CurrentUser
    if ($env:USERNAME -eq "liszt"){
        Write-Output "Personal settings..."
        $env:SCOOP='C:\Liszt\scoop'
        [environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
    }
    Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')
    scoop install git
    scoop bucket add extras
    scoop bucket add dragon https://github.com/Liszt21/Dragon
    scoop install autools
}
