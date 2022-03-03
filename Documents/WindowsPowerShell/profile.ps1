#region Global Profile Variables

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$global:PSRC = "$HOME\Documents\WindowsPowerShell\profile.ps1"
$global:VSRC = "$env:APPDATA\Code\User\settings.json"
$global:WTRC = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$global:WGRC = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

#endregion Global Profile Variables

#region Environment Variables

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

#endregion Environment Variables

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
        foreach ($Branch in $(git branch -r | Select-String -Pattern "origin/master|origin/HEAD" -NotMatch)) {
            $Branch = ($Branch -Split '/', 2).Trim()[1]
            if (-not $(git show-ref refs/heads/$Branch)) {
                git branch --track $Branch "origin/${Branch}"
            }
        }
    }
    else {
        Write-Error "Not a Git Repository" -Category ObjectNotFound -ErrorAction Stop
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
    param(
        [Parameter()]
        [string]$ReposDirectory = $(Get-RepositoryDirectory),

        [Parameter()]
        [string]$UserName = $(git config --global user.name),

        [Parameter()]
        [ValidateSet("SSH", "HTTPS")]
        [string] $Protocol = "SSH"
    )

    begin {
        $Hostname = if ($Protocol -eq "SSH") { "git@github.com:" } else { "https://github.com/" }
        $Response = Invoke-RestMethod -Uri "https://api.github.com/users/${UserName}/repos"
        $Count = $Response.Count
    }
    process {
        for ($i = 0; $i -le $Response.Count - 1; $i++) {
            Write-Progress -Activity "Git Clone" -PercentComplete ($i * 100 / $Count) -Status "$(([System.Math]::Round((($i) / $Count * 100), 0)))%" -CurrentOperation $Response[$i].name
            git clone --quiet "${Hostname}$($Response[$i].full_name).git" $(Join-Path -Path $ReposDirectory -ChildPath $Response[$i].name)
        }
    }
    end {}
}

function Export-Icon {
    param(
        [Parameter(Mandatory = $True)]
        [string]$Path
    )

    begin {
        $Size = 1024
        $File = Get-Item $Path
    }
    process {
        if ($File.Extension -eq ".svg") {
            while ($Size -gt 16) {
                inkscape $Path -w $Size -h $Size -o "$($Size)x$($Size)-$($File.BaseName).png"
                $Size = $Size / 2
            }
        }
        else {
            Write-Error "Not a SVG file." -Category InvalidArgument -ErrorAction Stop
        }
    }
    end {}
}

function Get-FileCount {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Path
    )

    process {
        foreach ($p in $Path) {
            $Count = $(Get-ChildItem -Path $p -File -Recurse | Measure-Object).Count
            [PSCustomObject]@{ Count = $Count; Path = $(Resolve-Path $p -Relative); } | Write-Output
        }
    }
}

function Get-FileSize {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Path,

        [Parameter()]
        [ValidateSet('B', 'KB', 'MB', 'GB', 'TB')]
        [string]$Unit = 'B'
    )

    process {
        foreach ($p in $Path) {
            $Size = switch ($Unit) {
                B { (Get-item $Path).Length }
                KB { (Get-item $Path).Length / 1KB }
                MB { (Get-item $Path).Length / 1MB }
                GB { (Get-item $Path).Length / 1GB }
                TB { (Get-item $Path).Length / 1TB }
            }

            [PSCustomObject]@{ Size = $Size; Unit = $Unit; Path = $(Resolve-Path $Path -Relative ) } | Write-Output
        }
    }
}

function Get-StringHash {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$String,

        [Parameter()]
        [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'MD5'
    )

    process {
        $StringAsStream = [System.IO.MemoryStream]::new()

        foreach ($s in $String) {
            $Writer = [System.IO.StreamWriter]::new($StringAsStream)
            $Writer.write($s)
            $Writer.Flush()
            $StringAsStream.Position = 0
            $HashObject = Get-FileHash -InputStream $StringAsStream -Algorithm $Algorithm
            [PSCustomObject]@{Hash = $HashObject.Hash; String = $s; Algorithm = $Algorithm } | Write-Output
        }
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

    begin {
        Add-Type -AssemblyName "System.Speech"
        $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    }
    process {
        $SpeechSynthesizer.Rate = $Rate
        $SpeechSynthesizer.Volume = $Volume
        $SpeechSynthesizer.SelectVoice($Voice)
        $SpeechSynthesizer.Speak($String)
    }
    end {}
}

function Get-WorldClock {
    $TimeZoneIds = @("Mountain Standard Time", "Paraguay Standard Time", "W. Europe Standard Time", "Russian Standard Time", "Tokyo Standard Time")

    $WorldClock = $TimeZoneIds | ForEach-Object {
        New-Object PSObject -Property @{
            DateTime    = [System.TimeZoneInfo]::ConvertTimeFromUtc((Get-Date).ToUniversalTime(), [System.TimeZoneInfo]::FindSystemTimeZoneById($_))
            Id          = $_
            DisplayName = [System.TimeZoneInfo]::FindSystemTimeZoneById($_)
        }
    }

    Write-Output $WorldClock | Sort-Object -Property DisplayName.BaseUtcOffset | Select-Object DateTime, Id, DisplayName
}

function ConvertTo-Pdf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string[]] $Path
    )

    begin {
        Add-Type -AssemblyName "Microsoft.Office.Interop.Word"
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $False
        $SaveFormat = [Microsoft.Office.Interop.Word.WdSaveFormat]::wdFormatPDF
    }
    process {
        try {
            $Path | ForEach-Object {
                $File = Get-ChildItem $_

                if ($File.Extension -like ".doc?") {
                    $Document = $Word.Documents.Open($File.FullName, $False, $True)
                    Write-Verbose "Processing $File . . ."
                    $Document.SaveAs([ref][System.Object]$File.FullName.Replace("docx", "pdf"), [ref]$SaveFormat)
                    $Document.close($False)
                }
            }
        }
        catch {
            Write-Error $Error[0] -Category InvalidArgument -ErrorAction Stop
        }
    }
    end {
        $Word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Word) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Start-Lesson {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string] $ReposDirectory = $(Get-RepositoryDirectory),

        [Parameter()]
        [ValidateSet("SSH", "HTTPS")]
        [string] $Protocol = "SSH"
    )

    begin {
        $RepoName = "nexus"
        $ClassRoom = $(Join-Path -Path $ReposDirectory -ChildPath $RepoName)
        $Uri = ([System.Uri](Get-Item $ClassRoom).FullName).AbsoluteUri -Replace ".*///"
        $Hostname = if ($Protocol -eq "SSH") { "git@github.com:" } else { "https://github.com/" }
    }
    process {
        try {
            if (-Not (Test-Path $ClassRoom)) {
                Write-Verbose "Creating a new classroom . . ."
                git clone "${Hostname}StefanGreve/${RepoName}.git" $ClassRoom
            }

            git --git-dir=$(Join-Path -Path $ClassRoom -ChildPath ".git") pull
            Start-Process obsidian://open?path=$Uri -Wait -WindowStyle Maximized
        }
        catch {
            Write-Error "You're not enrolled in this class." -Category PermissionDenied -ErrorAction Stop
        }
    }
    end {}
}

function Get-Calendar {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("Day", "Week", "Month", "Year")]
        [string] $Span = "Day"
    )
    begin {
        Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook"
        $Outlook = New-Object -ComObject Outlook.Application
        $NameSpace = $Outlook.GetNameSpace("MAPI")
        $Calendar = $NameSpace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderCalendar)
    }
    process {
        $Today = Get-Date
        $Days = switch ($Span) {
            Day { 1 }
            Week { 7 }
            Month { [DateTime]::DaysInMonth($Today.Year, $Today.Month) }
            Year { 365 }
        }

        $Events = $Calendar.Items
        $Events.IncludeRecurrences = $true
        $Events.Sort("[Start]")
        $Filter = "[MessageClass]='IPM.Appointment' AND [Start] > '$($Today.AddDays(-1).ToShortDateString()) 00:00' AND [End] < '$($Today.AddDays($Days).ToShortDateString()) 00:00'"
        $FilteredEvents = $Events.Restrict($Filter)
        $FilteredEvents | Select-Object -Property Subject, Start, Duration, Location, Organizer, RequiredAttendees, IsOnlineMeeting, IsRecurring | Write-Output
    }
    end {
        $Outlook.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Outlook) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Get-HardwareInfo {
    begin {
        $CIM_ComputerSystem = Get-CimInstance -ClassName CIM_ComputerSystem
        $CIM_BIOSElement = Get-CimInstance -ClassName CIM_BIOSElement
        $CIM_OperatingSystem = Get-CimInstance -ClassName CIM_OperatingSystem
        $CIM_Processor = Get-CimInstance -ClassName CIM_Processor
        $CIM_LogicalDisk = Get-CimInstance -ClassName CIM_LogicalDisk | Where-Object { $_.Name -eq $CIM_OperatingSystem.SystemDrive }
    }
    process {
        #TODO: Improve implementation
        Write-Output $(New-Object PSObject -Property @{
                LocalComputerName          = $env:COMPUTERNAME
                Manufacturer               = $CIM_ComputerSystem.Manufacturer
                Model                      = $CIM_ComputerSystem.Model
                SerialNumber               = $CIM_BIOSElement.SerialNumber
                CPU                        = $CIM_Processor.Name
                SysDriveCapacity           = '{0:N2}' -f ($CIM_LogicalDisk.Size / 1GB)
                SysDriveFreeSpace          = '{0:N2}' -f ($CIM_LogicalDisk.FreeSpace / 1GB)
                SysDriveFreeSpacePercent   = '{0:N0}' -f ($CIM_LogicalDisk.FreeSpace / $CIM_LogicalDisk.Size * 100)
                RAM                        = '{0:N2}' -f ($CIM_ComputerSystem.TotalPhysicalMemory / 1GB)
                OperatingSystemName        = $CIM_OperatingSystem.Caption
                OperatingSystemVersion     = $CIM_OperatingSystem.Version
                OperatingSystemBuildNumber = $CIM_OperatingSystem.BuildNumber
                OperatingSystemServicePack = $CIM_OperatingSystem.ServicePackMajorVersion
                CurrentUser                = $CIM_ComputerSystem.UserName
                LastBootUpTime             = $CIM_OperatingSystem.LastBootUpTime
            })
    }
    end {}
}

function Get-Uptime {
    Write-Output $((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)
}

function Start-Greeting {
    if ($PSVersionTable.PSVersion.Major -le 5) {
        $File = switch ($(Get-Date -Format HH)) {
            { $_ -lt 12 } { "morning.txt"; Break }
            { $_ -lt 17 } { "back.txt"; Break }
            Default { "evening.txt"; Break }
        }

        Invoke-SpeechSynthesizer -String $(Get-Content $HOME\Settings\$File | Get-Random) -Rate 1 -Voice "Microsoft Haruka Desktop"
    }
}

function Start-Timer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Hours")]
        [int] $Hours,

        [Parameter(Mandatory = $true, ParameterSetName = "Minutes")]
        [int] $Minutes,

        [Parameter(Mandatory = $true, ParameterSetName = "Seconds")]
        [int] $Seconds,

        [Parameter()]
        [switch] $SendKeySequence
    )
    begin {
        $WindowsShell = New-Object -ComObject "WScript.Shell"
        $CountDown = if ($Hours) { $Hours * 3600 } elseif ($Minutes) { $Minutes * 60 } else { $Seconds }
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $s = 0
    }
    process {
        while ($s -le $CountDown) {
            Write-Progress -Activity "Timer" -PercentComplete ($s * 100 / $CountDown) -Status "$(([System.Math]::Round((($s) / $CountDown * 100), 0)))%" -SecondsRemaining ($CountDown - $s)
            if ($SendKeySequence) { $WindowsShell.SendKeys("{SCROLLLOCK}") }
            $s = $StopWatch.Elapsed.TotalSeconds
        }
    }
    end {
        $StopWatch.Stop()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$WindowsShell) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        while ($true) {
            for ($i = 37; $i -le 32767; $i += 10) {
                [Console]::Beep($i, 300 + $i)
            }
        }
    }
}

function Get-Covid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Country
    )

    $Response = foreach ($c in $Country) {
        Invoke-RestMethod -Uri "https://api.covid19api.com/dayone/country/${c}/status/confirmed" | Write-Output | Select-Object -Last 7

    }

    $Response | Select-Object -Property Country, Cases, Status, Date | Write-Output
}

function Measure-Performance {
    [Alias("time")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Once", Position = 0)]
        [switch] $Once,

        [Parameter(Mandatory = $true, ParameterSetName = "Loop", Position = 0)]
        [int] $Loop,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Command
    )
    begin {
        $watch = [System.Diagnostics.Stopwatch]::new()
    }
    process {
        if ($Once) {
            $watch.Start()
            Invoke-Expression $Command
            $watch.Stop()
            Write-Output $watch.Elapsed.TotalSeconds
        }
        else {
            $Results = 1..$Loop | ForEach-Object { $watch.Restart(); Invoke-Expression $Command | Out-Null; Write-Output $watch.Elapsed.TotalSeconds }
            $Results | Measure-Object -Minimum -Maximum -Average | Select-Object Minimum, Maximum, Average | Write-Output
        }
    }
    end {}
}

function Get-Message {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Filter,

        [Parameter(Position = 1)]
        [int] $First = 0,

        [Parameter(Position = 2)]
        [switch] $Unread
    )
    begin {
        Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook"
        $Outlook = New-Object -ComObject Outlook.Application
        $NameSpace = $Outlook.GetNameSpace("MAPI")
        $Inbox = $NameSpace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderInbox)
    }
    process {
        $Mails = $Inbox.Items.Restrict("[Unread] = ${Unread}")
        $Mails.Sort("ReceivedTime", $true)

        if ($Filter) {
            $Mails = $Mails | Where-Object { $_.Subject -Match $Filter -or $_.Body -Match $Filter }
        }

        if ($First) {
            $Mails = $Mails | Select-Object -First $First
        }

        $Mails | Select-Object -Property SenderName, Subject, ReceivedTime, Body | Write-Output
    }
    end {
        $Outlook.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$Outlook) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Set-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Key = "PATH",

        [Parameter(Position = 1, Mandatory = $true)]
        [string] $Value,

        [Parameter(Position = 2)]
        [ValidateSet("User", "Machine")]
        [string] $Scope = "User"
    )

    $EnvironmentVariableTarget = if ($Scope -eq "User") { [System.EnvironmentVariableTarget]::User } else { [System.EnvironmentVariableTarget]::Machine }
    $NewValue = [Environment]::GetEnvironmentVariable($Key, $EnvironmentVariableTarget) + ";${Value}"
    [Environment]::SetEnvironmentVariable($Key, $NewValue, $EnvironmentVariableTarget)
}

function Get-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Key = "PATH",

        [Parameter(Position = 1)]
        [ValidateSet("User, Machine")]
        [string] $Scope = "User"
    )

    $EnvironmentVariableTarget = if ($Scope -eq "User") { [System.EnvironmentVariableTarget]::User } else { [System.EnvironmentVariableTarget]::Machine }
    $EnvironmentVariables = [Environment]::GetEnvironmentVariable($Key, $EnvironmentVariableTarget)
    Write-Output $EnvironmentVariables
}

#endregion PowerShell Macros

#region Aliases

Set-Alias -Name anonfile -Value Invoke-Anonfile
Set-Alias -Name config -Value Update-Configuration
Set-Alias -Name grepo -Value Get-Repository
Set-Alias -Name grepo-all -Value Get-AllRepositories
Set-Alias -Name export -Value Export-Icon
Set-Alias -Name activate -Value .\venv\Scripts\Activate.ps1
Set-Alias -Name count -Value Get-FileCount
Set-Alias -Name touch -Value New-Item

#endregion Aliases

#region Command Prompt

function prompt {
    Write-Host '[' -NoNewline
    Write-Host $env:UserName -NoNewline -ForegroundColor Cyan
    Write-Host "@$env:ComputerName " -NoNewline
    $Path = (Get-Item "$($executionContext.SessionState.Path.CurrentLocation)").BaseName

    Write-Host $Path -NoNewline -ForegroundColor Green
    Write-Host ']' -NoNewline

    if (Test-Path .git) {
        Write-Host " ($(git rev-parse --abbrev-ref HEAD))" -ForegroundColor Blue -NoNewline
    }

    if ($env:VIRTUAL_ENV) {
        Write-Host " ($([System.IO.Path]::GetFileName($env:VIRTUAL_ENV)))" -NoNewline -ForegroundColor Yellow
    }

    return "`n$('>' * ($NestedPromptLevel + 1)) "
}

#endregion Command Prompt
