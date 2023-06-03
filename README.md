# Windows Dotfiles Repository

Configuration files for various utility programs geared towards Windows 10 power users.

## Prerequisites

The git configuration uses `git-delta` as a diff tool which can be installed with cargo.
(See also: https://github.com/dandavison/delta/issues/1409):

```powershell
winget install --id rustlang.rustup
cargo install --git https://github.com/dandavison/delta.git
```

Install [`vim-plug`](https://github.com/junegunn/vim-plug):

```powershell
Invoke-WebRequest -UseBasicParsing https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim | New-Item $env:LOCALAPPDATA/nvim/autoload/plug.vim -Force
```

Conduct initial plugin installation:

```powershell
nvim +'PlugInstall --sync' +qa
```

Depending how you have installed `pwsh`, you may need to set this symbolic so that
the Windows Terminal can find the PowerShell Core executable where it expect it to be:

```powershell
$Pwsh = "C:\Program Files\WindowsApps\Microsoft.PowerShell_7.3.4.0_x64__8wekyb3d8bbwe\pwsh.exe"
New-Item -Path "C:\Program Files\PowerShell\7\pwsh.exe" -ItemType SymbolicLink -Value $Pwsh
```

## Bootstrapping

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

## Custom Settings

If you also want to use GPG signing, override my default settings using your key:

```powershell
gpg --import <key>.asc
git config --global user.signingkey = <key_id>
```

To disable GPG signing on all commits, run:

```powershell
git config --global commit.gpgsign false
```
