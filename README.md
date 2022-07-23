# Windows Dotfiles Repository

Use at your own risk. I don't offer any support for issues arising from using this
repository. Don't copy-paste other people's code if you don't know what you're doing.
You have been warned.

## Consume Settings

```powershell
# clone confiles as bare repository to destop/repos
$confiles = New-Item -ItemType Directory "$HOME/Desktop/repos/confiles" -Force
git clone --bare git@github.com:StefanGreve/confiles.git $confiles.FullName

# temporarily define config alias in current shell session
function Update-Configuration { git --git-dir=$confiles.FullName --work-tree=$HOME $Args }
Set-Alias -Name config -Value Update-Configuration

# hide untracked files in home directory
config config --local status.showUntrackedFiles no

# initialize submodule
config submodule update --init --recursive

# scope: CurrentUserAllHosts
$ProfileDirectory = "$HOME\Documents\PowerShell"
$ProfilePath = "$ProfileDirectory\profile.ps1"
New-Item -ItemType Directory -Path $ProfileDirectory -Force

# create symlink and dot-source profile for pwsh
New-Item -ItemType SymbolicLink -Path $ProfilePath -Target "$ProfileDirectory\profile\profile.ps1"
. $ProfilePath

# update settings
config pull

# update profile
config submodule update --remote --merge
```
