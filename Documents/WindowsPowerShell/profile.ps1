#region Global Profile Variables

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$global:PSRC = "$HOME\Documents\WindowsPowerShell\profile.ps1"
$global:VSRC = "$HOME\AppData\Roaming\Code\User\settings.json"
$global:WTRC = "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$global:WGRC = "$HOME\AppData\Local\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

#endregion

#region Environment Variables

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

#endregion

#region PowerShell Macros

function Invoke-Anonfile {
    python -m anonfile.__init__ $Args
}

function Get-RepositoryDirectory {
    Write-Output $(Join-Path -Path $([Environment]::GetFolderPath("Desktop")) -ChildPath "repos")
}

function Update-Configuration {
    git --git-dir="$HOME\Desktop\repos\confiles" --work-tree=$HOME $Args
}

function Get-RemoteBranches {
    if (Test-Path .git) {
        foreach ($Branch in $(git branch -r | Select-String -Pattern "origin/master" -NotMatch)) {
            $Branch = $Branch.ToString().Split('/')[1].Trim()
            git branch --track $Branch "origin/$Branch"
        }
    }
    else {
        Write-Error "Not a Git Repository" -Category ObjectNotFound
    }
}

function Get-Repository {
    param(
        [Parameter(Mandatory = $True)]
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
        [Parameter(Mandatory = $True)]
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
        Write-Error "Not a SVG file." -Category InvalidArgument
    }
}

function Get-FileCount {
    param(
        [Parameter()]
        [string]$Path = (Get-Location).Path
    )

    $Total = 0
    Get-ChildItem -Path $Path -Recurse -File | Group-Object Extension -NoElement | Sort-Object Count -Descending | ForEach-Object {
        $Total += $_.Count
    }

    Write-Output "Total File Count: $Total"
}

function Get-FileSize {
    param(
        [Parameter(Mandatory = $True)]
        [string]$Path,

        [Parameter()]
        [ValidateSet('B', 'KB', 'MB', 'GB', 'TB')]
        [string]$Unit = 'B'
    )

    $Length = (Get-item $Path).Length

    switch ($Unit) {
        B { Write-Output $Length B }
        KB { Write-Output ($Length / 1KB) KB }
        MB { Write-Output ($Length / 1MB) MB }
        GB { Write-Output ($Length / 1GB) GB }
        TB { Write-Output ($Length / 1TB) TB }
    }
}

function Get-InstalledVoices {
    Add-Type -AssemblyName System.Speech
    $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    Write-Output $SpeechSynthesizer.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo }
}

function Invoke-SpeechSynthesizer {
    param(
        [Parameter(Mandatory = $True)]
        [string]$String,

        [Parameter()]
        [ValidateRange(-10, 10)]
        [int]$Rate = 2,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$Volume = 50,

        [Parameter()]
        [string]$Voice = "Microsoft Zira Desktop"
    )
    Add-Type -AssemblyName System.Speech
    $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $SpeechSynthesizer.Rate = $Rate
    $SpeechSynthesizer.Volume = $Volume
    $SpeechSynthesizer.SelectVoice($Voice)
    $SpeechSynthesizer.Speak($String)
}

#endregion

#region Aliases

Set-Alias -Name anonfile -Value Invoke-Anonfile
Set-Alias -Name config -Value Update-Configuration
Set-Alias -Name grepo -Value Get-Repository
Set-Alias -Name grepo-all -Value Get-AllRepositories
Set-Alias -Name export -Value Export-Icon
Set-Alias -Name activate -Value .\venv\Scripts\Activate.ps1
Set-Alias -Name count -Value Get-FileCount

#endregion

#region Command Prompt

function Write-BranchName {
    try {
        $Branch = git rev-parse --abbrev-ref HEAD

        if ($Branch -eq "HEAD") {
            $Branch = git rev-parse --short HEAD
            Write-Host " ($Branch)" -ForegroundColor "red" -NoNewline
        }
        else {
            Write-Host " ($Branch)" -ForegroundColor "blue" -NoNewline
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
    $Path = "$($executionContext.SessionState.Path.CurrentLocation)"
    $UserPrompt = "`n$('>' * ($NestedPromptLevel + 1)) "

    Write-Host $Path -NoNewline -ForegroundColor Green
    Write-Host ']' -NoNewline

    if (Test-Path .git) {
        Write-BranchName
    }

    if ($env:VIRTUAL_ENV) {
        $VenvPrompt = ([System.IO.Path]::GetFileName($env:VIRTUAL_ENV))
        Write-Host " ($VenvPrompt)" -NoNewline -ForegroundColor Yellow
    }

    return $UserPrompt
}

#endregion
