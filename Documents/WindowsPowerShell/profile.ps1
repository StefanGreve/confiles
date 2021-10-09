$global:psrc = "$Home\Documents\WindowsPowerShell\profile.ps1"

#region Aliases

function Invoke-Anonfile {
    python -m anonfile.__init__ $Args
}

Set-Alias -Name anonfile -Value Invoke-Anonfile

function Update-Configuration {
    git --git-dir="$HOME\Desktop\repos\confiles" --work-tree=$HOME $Args
}

Set-Alias -Name config -Value Update-Configuration

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

    return $userPrompt
}

#endregion
