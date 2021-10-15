#region Global Variables

$global:psrc = "$HOME\Documents\WindowsPowerShell\profile.ps1"
$global:vsrc = "$HOME\AppData\Roaming\Code\User\settings.json"
$global:wtrc = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$global:wgrc = "$HOME\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

#endregion

#region Environment Variables

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

#endregion

#region PowerShell Macros

function Invoke-Anonfile {
    python -m anonfile.__init__ $Args
}

function Get-RepositoryDirectory {
    return $(Join-Path -Path $([Environment]::GetFolderPath("Desktop")) -ChildPath "repos")
}

function Update-Configuration {
    git --git-dir="$HOME\Desktop\repos\confiles" --work-tree=$HOME $Args
}

function Get-RemoteBranches {
    if (Test-Path .git) {
        foreach ($branch in $(git branch -r | Select-String -Pattern "origin/master" -NotMatch)) {
            $branch = $branch.ToString().Split('/')[1].Trim()
            git branch --track $branch "origin/$branch"
        }
    }
    else {
        Write-Host "ERROR: Not a Git Repository" -ForegroundColor Red
    }
}

function Get-Repository {
    param(
        [Parameter(Position = 0)]
        [string]$RepositoryName
    )

    git clone "git@github.com:$(git config --global user.name)/$RepositoryName.git"
}

function Get-AllRepositories {
    $Response = Invoke-RestMethod -Uri "https://api.github.com/users/$(git config --global user.name)/repos"
    $Response | ForEach-Object {
        git clone "git@github.com:$($_.full_name).git" "$(Get-RepositoryDirectory)\$($_.name)"
    }
}

function Export-Icon {
    param(
        [Parameter(Position = 0)]
        [string]$Path
    )

    $Size = 1024
    $File = Get-Item $Path

    if ($File.Extension -eq ".svg") {
        while ($Size -gt 16) {
            inkscape $Path -w $Size -h $Size -o "$($Size)x$($Size)-$($File.BaseName).png"
            $Size = $Size / 2
        }
    }
    else {
        Write-Host "ERROR: Not a SVG file." -ForegroundColor Red
    }
}

function Get-FileCount {
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path
    )

    $Total = 0
    Get-ChildItem -Path $Path -Recurse -File | Group-Object Extension -NoElement | Sort-Object Count -Descending | ForEach-Object {
        $Total += $_.Count
    }

    Write-Host "Total File Count: " -NoNewline
    Write-Host $Total -ForegroundColor Yellow
}

function Get-FileSize {
    param(
        [Parameter(Position = 0)]
        [string]$Path,

        [Parameter(Position = 1)]
        [ValidateSet('B', 'KB', 'MB', 'GB', 'TB')]
        [string]$Unit = 'B'
    )

    $Length = (Get-item $Path).Length

    switch ($Unit) {
        B { Write-Host $Length B }
        KB { Write-Host ($Length / 1KB) KB }
        MB { Write-Host ($Length / 1MB) MB }
        GB { Write-Host ($Length / 1GB) GB }
        TB { Write-Host ($Length / 1TB) TB }
    }
}

#endregion

#region Aliases

Set-Alias -Name anonfile -Value Invoke-Anonfile
Set-Alias -Name config -Value Update-Configuration
Set-Alias -Name grepo -Value Get-Repository
Set-Alias -Name grepo-all -Value Get-AllRepositories
Set-Alias -Name export -Value Export-Icon
Set-Alias -Name activate -Value ./venv/Scripts/Activate.ps1
Set-Alias -Name count -Value Get-FileCount

#endregion

#region Command Prompt

function Write-BranchName {
    try {
        $branch = git rev-parse --abbrev-ref HEAD

        if ($branch -eq "HEAD") {
            $branch = git rev-parse --short HEAD
            Write-Host " ($branch)" -ForegroundColor "red" -NoNewline
        }
        else {
            Write-Host " ($branch)" -ForegroundColor "blue" -NoNewline
        }
    }
    catch {
        Write-Host " (no branches yet)" -ForegroundColor "yellow" -NoNewline
    }
}

function prompt {
    Write-Host '[' -NoNewline
    Write-Host $env:UserName -NoNewline -ForegroundColor Cyan
    Write-Host "@$env:ComputerName " -NoNewline
    $path = "$($executionContext.SessionState.Path.CurrentLocation)"
    $userPrompt = "`n$('>' * ($nestedPromptLevel + 1)) "

    Write-Host $path -NoNewline -ForegroundColor Green
    Write-Host ']' -NoNewline

    if (Test-Path .git) {
        Write-BranchName
    }

    if ($env:VIRTUAL_ENV) {
        $VenvPrompt = ([System.IO.Path]::GetFileName($env:VIRTUAL_ENV))
        Write-Host " ($VenvPrompt)" -NoNewline -ForegroundColor Yellow
    }

    return $userPrompt
}

#endregion
