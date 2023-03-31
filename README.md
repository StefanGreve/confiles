# Windows Dotfiles Repository

Configuration files for various utility programs geared towards Windows 10 developers.

## Consume Settings

```powershell
# clone confiles as bare repository to destop/repos
$confiles = New-Item -ItemType Directory "$HOME/Desktop/repos/confiles" -Force
git clone --bare git@github.com:StefanGreve/confiles.git $confiles.FullName

# temporarily define config alias in current shell session
function Update-Configuration { git --git-dir=$($confiles.FullName) --work-tree=$HOME $Args }
Set-Alias -Name config -Value Update-Configuration

# hide untracked files in home directory
config config --local status.showUntrackedFiles no

# update settings
config pull
```
