#region Global Variables

$global:psrc = "$HOME\Documents\WindowsPowerShell\profile.ps1"
$global:vsrc = "$HOME\AppData\Roaming\Code\User\settings.json"
$global:wtrc = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$global:wgrc = "$HOME\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

#endregion

#region Environment Variables

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

#endregion

#region Aliases

function Invoke-Anonfile {
    python -m anonfile.__init__ $Args
}

Set-Alias -Name anonfile -Value Invoke-Anonfile

function Update-Configuration {
    git --git-dir="$HOME\Desktop\repos\confiles" --work-tree=$HOME $Args
}

Set-Alias -Name config -Value Update-Configuration

Set-Alias -Name activate -Value ./venv/Scripts/Activate.ps1

#endregion

#region PowerShell Macros

function Get-RemoteBranches {
    if (Test-Path .git) {
        foreach ($branch in $(git branch -r | Select-String -Pattern "origin/master" -NotMatch)) {
            git branch --track $branch.ToString().Split('/')[1].Trim()
        }
    }
    else {
        Write-Host "Error: Not a Git Repository" -ForegroundColor Red
    }
}

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
