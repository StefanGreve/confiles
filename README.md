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
vim pluginstall from command line
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
