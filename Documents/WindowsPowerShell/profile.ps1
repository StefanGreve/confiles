#region Global Profile Variables

chcp 932 | Out-Null
$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$global:PSRC = "$HOME\Documents\WindowsPowerShell\profile.ps1"
$global:VSRC = "$env:APPDATA\Code\User\settings.json"
$global:VIRC = "$env:LOCALAPPDATA\nvim\init.vim"
$global:WTRC = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$global:WGRC = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"

$global:Desktop = [Environment]::GetFolderPath("Desktop")
$global:Natural = { [Regex]::Replace($_.Name, '\d+', { $Args[0].Value.PadLeft(20) }) }

$global:ForegroundColors = [PSCustomObject]@{
    Black         = "$([char]0x1b)[30m"
    Red           = "$([char]0x1b)[31m"
    Green         = "$([char]0x1b)[32m"
    Yellow        = "$([char]0x1b)[33m"
    Blue          = "$([char]0x1b)[34m"
    Magenta       = "$([char]0x1b)[35m"
    Cyan          = "$([char]0x1b)[36m"
    White         = "$([char]0x1b)[37m"
    BrightBlack   = "$([char]0x1b)[90m"
    BrightRed     = "$([char]0x1b)[91m"
    BrightGreen   = "$([char]0x1b)[92m"
    BrightYellow  = "$([char]0x1b)[93m"
    BrightBlue    = "$([char]0x1b)[94m"
    BrightMagenta = "$([char]0x1b)[95m"
    BrightCyan    = "$([char]0x1b)[96m"
    BrightWhite   = "$([char]0x1b)[97m"
}

$global:BackgroundColors = [PSCustomObject]@{
    Black         = "$([char]0x1b)[40m"
    Red           = "$([char]0x1b)[41m"
    Green         = "$([char]0x1b)[42m"
    Yellow        = "$([char]0x1b)[43m"
    Blue          = "$([char]0x1b)[44m"
    Magenta       = "$([char]0x1b)[45m"
    Cyan          = "$([char]0x1b)[46m"
    White         = "$([char]0x1b)[47m"
    BrightBlack   = "$([char]0x1b)[100m"
    BrightRed     = "$([char]0x1b)[101m"
    BrightGreen   = "$([char]0x1b)[102m"
    BrightYellow  = "$([char]0x1b)[103m"
    BrightBlue    = "$([char]0x1b)[104m"
    BrightMagenta = "$([char]0x1b)[105m"
    BrightCyan    = "$([char]0x1b)[106m"
    BrightWhite   = "$([char]0x1b)[107m"
}

#endregion Global Profile Variables

#region Environment Variables

$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

if ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -ge 2) {
    $PSStyle.Progress.View = "Classic"
    $Host.PrivateData.ProgressBackgroundColor = "Cyan"
    $Host.PrivateData.ProgressForegroundColor = "Yellow"
}

#endregion Environment Variables

#region PowerShell Macros

function Update-Configuration {
    git --git-dir="$HOME\Desktop\repos\confiles" --work-tree=$HOME $Args
}

function Export-Icon {
    param(
        [Parameter(Mandatory)]
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
        [Parameter(Mandatory, ValueFromPipeline)]
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
        [Parameter(Mandatory, ValueFromPipeline)]
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
        [Parameter(Mandatory, ValueFromPipeline)]
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

function New-Password {
    param(
        [Parameter(Position = 0)]
        [int] $Length = 64,

        [Parameter(Position = 1)]
        [int] $NumberOfNonAlphanumericCharacters = 16
    )

    Add-Type -AssemblyName System.Web
    $Password = [System.Web.Security.Membership]::GeneratePassword($Length, $NumberOfAlphanumericCharacters)
    Write-Output $Password
}

function Get-InstalledVoices {
    Add-Type -AssemblyName System.Speech
    $SpeechSynthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    Write-Output $SpeechSynthesizer.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo }
}

function Invoke-SpeechSynthesizer {
    param(
        [Parameter(Mandatory)]
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
        Add-Type -AssemblyName System.Speech
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
        [Parameter(Mandatory)]
        [string[]] $Path
    )

    begin {
        Add-Type -AssemblyName Microsoft.Office.Interop.Word
        $Word = New-Object -ComObject Word.Application
        $Word.Visible = $false
        $SaveFormat = [Microsoft.Office.Interop.Word.WdSaveFormat]::wdFormatPDF
    }
    process {
        try {
            $Path | ForEach-Object {
                $File = Get-ChildItem $_

                if ($File.Extension -like ".doc?") {
                    $Document = $Word.Documents.Open($File.FullName, $false, $true)
                    Write-Verbose "Processing $File . . ."
                    $Document.SaveAs([ref][System.Object]$File.FullName.Replace("docx", "pdf"), [ref]$SaveFormat)
                    $Document.close($false)
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

function Convert-ImageToPdf {
    <# NOTE: Requires PSWritePDF module from PS Gallery #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Path = $PWD,

        [Parameter(Mandatory)]
        [string] $OutFile,

        [switch] $Show
    )

    $Images = Get-ChildItem -Path $Path\* -Include "*.jpg","*.jpeg","*.png" | Sort-Object $Natural

    $Destination = Join-Path -Path $Path -ChildPath $OutFile
    New-PDF -PageSize A4 {
        if ($Images.Count -ge 1) {
            $Images | Foreach-Object {
                New-PDFPage {
                    New-PDFImage -ImagePath $_.FullName
                    Write-Verbose "Converting $($_.FullName)"
                }
            }
        }
        else {
            Write-Error "There are no images in '$Path'. Aborting operation." -ErrorAction Stop
        }
    } -FilePath $Destination

    if ($Show) {
        Invoke-Item $Destination
    }

    $Document = Get-PDF -FilePath $Destination
    Get-PDFDetails -Document $Document
    Close-PDF -Document $Document
}

function Stop-Work {
    $Work = @("TEAMS", "LYNC", "OUTLOOK")
    Get-Process | Where-Object { $Work.Contains($_.Name.ToUpper()) } | Stop-Process -Force
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
        Add-Type -AssemblyName Microsoft.Office.Interop.Outlook
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
    $ComputerInfo = Get-ComputerInfo
    $CIM_ComputerSystem = Get-CimInstance -ClassName CIM_ComputerSystem
    $CIM_LogicalDisk = Get-CimInstance -ClassName CIM_LogicalDisk | Where-Object { $_.Name -eq $ComputerInfo.OsSystemDrive }

    [PSCustomObject]@{
        CurrentUser                = $env:USERNAME
        LocalComputerName          = $env:COMPUTERNAME
        Manufacturer               = $ComputerInfo.CsManufacturer
        Model                      = $ComputerInfo.CsModel
        SerialNumber               = $ComputerInfo.OsSerialNumber
        OperatingSystemName        = $ComputerInfo.WindowsProductName
        OperatingSystemVersion     = $ComputerInfo.OsVersion
        OperatingSystemBuildNumber = $ComputerInfo.OsBuildNumber
        CPU                        = $ComputerInfo.CsProcessors.Name
        RAM                        = '{0:N2}' -f ($CIM_ComputerSystem.TotalPhysicalMemory / 1GB)
        SysDriveCapacity           = '{0:N2}' -f ($CIM_LogicalDisk.Size / 1GB)
        SysDriveFreeSpace          = '{0:N2}' -f ($CIM_LogicalDisk.FreeSpace / 1GB)
        SysDriveFreeSpacePercent   = '{0:N0}' -f ($CIM_LogicalDisk.FreeSpace / $CIM_LogicalDisk.Size * 100)
        LastBootUpTime             = $ComputerInfo.OsLastBootUpTime
    }
}

function Get-Uptime {
    Write-Output $((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)
}

function Set-PowerState {
    [CmdletBinding()]
    param(
        [ValidateSet("Hibernate", "Suspend")]
        [Parameter(Position = 0)]
        [string] $State = "Suspend",

        [switch] $Force,

        [switch] $DisableWake
    )
    begin{
        Add-Type -AssemblyName System.Windows.Forms
        $PowerState = if ($State -eq "Hibernate") { [System.Windows.Forms.PowerState]::Hibernate } else { [System.Windows.Forms.PowerState]::Suspend }
    }
    process {
        [System.Windows.Forms.Application]::SetSuspendState($PowerState, $Force, $DisableWake)
    }
}

function Start-Greeting {
    if ($PSVersionTable.PSVersion.Major -le 5) {
        $File = switch ($(Get-Date -Format HH)) {
            { $_ -lt 12 } { "morning.txt"; Break }
            { $_ -lt 17 } { "back.txt"; Break }
            Default { "evening.txt"; Break }
        }

        Invoke-SpeechSynthesizer -String $(Get-Content "$HOME\Settings\$File" | Get-Random) -Rate 1 -Voice "Microsoft Haruka Desktop"
    }
}

function Start-Timer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = "Hours")]
        [int] $Hours,

        [Parameter(Mandatory, ParameterSetName = "Minutes")]
        [int] $Minutes,

        [Parameter(Mandatory, ParameterSetName = "Seconds")]
        [int] $Seconds,

        [Parameter()]
        [switch] $SendKeySequence
    )
    begin {
        $WindowsShell = New-Object -ComObject WScript.Shell
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
        [Parameter(Mandatory)]
        [string[]] $Country
    )

    $Response = foreach ($c in $Country) {
        Invoke-RestMethod -Uri "https://api.covid19api.com/dayone/country/${c}/status/confirmed" | Write-Output | Select-Object -Last 7

    }

    $Response | Select-Object -Property Country, Cases, Status, Date | Write-Output
}

function Get-XKCD {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = "Num", Position = 0, ValueFromPipeline)]
        [int[]] $Num,

        [Parameter(Mandatory, ParameterSetName = "All")]
        [switch] $All
    )
    begin {
        function Get-Extension ([string]$Uri) { ($Uri | Split-Path -Leaf).Split(".")[1] | Write-Output }
    }
    process {
        if ($Num) {
            foreach ($i in $Num) {
                $Response = Invoke-RestMethod -Uri "https://xkcd.com/$i/info.0.json"
                Invoke-WebRequest -Uri $Response.Img -OutFile "$i.$(Get-Extension($Response.Img))"
            }
        }
        if ($All) {
            $WebClient = New-Object -TypeName Net.WebClient
            $LastNum = (Invoke-RestMethod -Uri "https://xkcd.com/info.0.json").Num

            for ($i = 1; $i -le $LastNum; $i++) {
                Write-Progress -Activity "Download XKCD $i" -PercentComplete ($i * 100 / $LastNum) -Status "$(([System.Math]::Round((($i) / $LastNum * 100), 0)))%"
                $Response = Invoke-RestMethod -Uri "https://xkcd.com/$i/info.0.json"
                $WebClient.DownloadFile($Response.Img, $(Join-Path -Path $PWD -ChildPath "$($Response.Num).$(Get-Extension($Response.Img))"))
            }
        }
    }
}

function Measure-Performance {
    [Alias("time")]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName = "Once", Position = 0)]
        [switch] $Once,

        [Parameter(Mandatory, ParameterSetName = "Loop", Position = 0)]
        [int] $Loop,

        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Command
    )
    begin {
        $Watch = [System.Diagnostics.Stopwatch]::new()
    }
    process {
        if ($Once) {
            $watch.Start()
            Invoke-Expression $Command
            $Watch.Stop()
            Write-Output $Watch.Elapsed.TotalSeconds
        }
        else {
            $Results = 1..$Loop | ForEach-Object { $Watch.Restart(); Invoke-Expression $Command | Out-Null; Write-Output $Watch.Elapsed.TotalSeconds }
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
        Add-Type -AssemblyName Microsoft.Office.Interop.Outlook
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

function New-DotnetProject {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [string] $Path = $PWD,

        [ValidateSet("console", "classlib", "wpf", "winforms", "page", "blazorserver", "blazorwasm", "web", "mvc", "razor", "webapi")]
        [string] $Template = "console",

        [ValidateSet("C#", "F#", "VB")]
        [string] $Language = "C#"
    )

    $OutputDirectory = Join-Path -Path $Path -ChildPath $Name
    $RootDirectory = New-Item -ItemType Directory -Path $(Join-Path -Path $OutputDirectory -ChildPath $Name)
    Set-Location $OutputDirectory

    dotnet new sln
    dotnet new $Template --name $Name --language $Language --output $RootDirectory
    dotnet new gitignore --output $OutputDirectory
    dotnet new editorconfig --output $OutputDirectory
    dotnet sln add $Name
    dotnet restore $OutputDirectory
    dotnet build $OutputDirectory

    git init
    git add --all
    git commit -m "Init commit"
}

function Publish-DotnetProject {
    param(
        [string] $Path = $PWD,

        [ValidateSet("Debug", "Release")]
        [string] $Mode = "Release",

        [ValidateSet("win-x64", "win-x86", "win-arm", "win-arm64", "linux-x64", "linux-musl-x64", "linux-arm", "linux-arm64", "osx-x64")]
        [string] $Runtime = "win-x64",

        [string] $OutputDirectory = [Environment]::GetFolderPath("Desktop")
    )

    dotnet build $Path

    $Parameters = switch ($Mode) {
        "Debug" {
            @(
                "--configuration", $Mode
                "--runtime", $Runtime
                "--self-contained", $true
            )
        }
        "Release" {
            @(
                "--configuration", $Mode
                "--runtime", $Runtime
                "--self-contained", $true
                "--output", $OutputDirectory
                "-p:PublishSingleFile=true"
                "-p:PublishTrimmed=true"
                "-p:IncludeNativeLibrariesForSelfExtract=true"
                "-p:TrimMode=Link"
                "-p:DebugType=None"
                "-p:DebugSymbols=false"
                "--output", $OutputDirectory
            )
        }
    }

    dotnet publish $Path $Parameters
}

function Publish-CustomModule {
    <#
        .SYNOPSIS
        Test and publish PowerShell modules.

        .DESCRIPTION
        Test and optionally publish custom PowerShell modules. Run this Cmdlet at least once without the ApiKey parameter
        to ensure that the preliminary tests run through. This Cmdlet requires the PSScriptAnalyzer module.
    #>
    [Alias("publish")]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param(
        [Parameter()]
        [string] $ApiKey
    )

    begin {
        $Step = 0
        $Steps = 5
        $ModulePath = $env:PSMODULEPATH -Split ";" | Select-Object -First 1
        $ProjectRootDirectory = Join-Path -Path $PWD -ChildPath "src"
        $Name = $(Get-ChildItem -Path $ProjectRootDirectory -Filter "*.psd1").BaseName
        $ManifestPath = Join-Path -Path $ProjectRootDirectory -ChildPath "${Name}.psd1"
        $Manifest = Import-PowerShellDataFile -Path $ManifestPath
        $Version = $Manifest.ModuleVersion
    }
    process {
        $Step++
        Write-Host "(${Step}/${Steps}) Test module manifest" -ForegroundColor Green
        Test-ModuleManifest $ManifestPath

        $Step++
        Write-Host "(${Step}/${Steps}) Import module dependencies" -ForegroundColor Green
        Import-Module PSScriptAnalyzer
        if ($Manifest.RequiredModules) { Import-Module $Manifest.RequiredModules }

        $Step++
        Write-Host "(${Step}/${Steps}) Run PSScriptAnalyzer" -ForegroundColor Green
        Invoke-ScriptAnalyzer -Path $ManifestPath -Recurse -Severity Warning

        $Step++
        Write-Host "(${Step}/${Steps}) Import main module" -ForegroundColor Green
        Import-Module $ManifestPath -Force

        $Step++
        Write-Host "(${Step}/${Steps}) Copy items to module directory" -ForegroundColor Green
        $Destination = New-Item -ItemType Directory -Path $ModulePath -Name $Name -Force
        Remove-Item -Path $Destination -Recurse -Force
        Copy-Item $ProjectRootDirectory -Destination $Destination.FullName -Recurse -Force

        if ($ApiKey -and $PSCmdlet.ShouldProcess($ManifestPath, "Publish ${Name} (version ${Version}) to PSGallery")) {
            Publish-Module -Name $Name -NuGetApiKey $ApiKey -RequiredVersion $Version -Verbose
        }
    }
    end {
        if ($ApiKey) {
            $UriBuilder = New-Object System.UriBuilder
            $UriBuilder.Scheme =  "https"
            $UriBuilder.Host = "www.powershellgallery.com"
            $UriBuilder.Path = @("packages", $Name, $Version -join '/')
            Start-Process $UriBuilder.ToString()
        }
    }
}

function Restart-Job {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ParameterSetName = "Name", Mandatory)]
        [string] $Name,

        [Parameter(Position = 0, ParameterSetName = "Id", Mandatory)]
        [int] $Id
    )
    begin {
        $Job = if ($Name) { Get-Job -Name $Name } else { Get-Job -Id $Id }
    }
    process {
        Start-Job -Name $Name -ScriptBlock ([scriptblock]::Create($Job.Command))
    }
    end {
        Remove-Job -Id $Job.Id
    }
}

function Set-EnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $Key = "PATH",

        [Parameter(Position = 1, Mandatory)]
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
        [ValidateSet("User", "Machine")]
        [string] $Scope = "User"
    )

    $EnvironmentVariableTarget = if ($Scope -eq "User") { [System.EnvironmentVariableTarget]::User } else { [System.EnvironmentVariableTarget]::Machine }
    $EnvironmentVariables = [Environment]::GetEnvironmentVariable($Key, $EnvironmentVariableTarget) -Split ";"
    Write-Output $EnvironmentVariables
}

function Remove-EnvironmentVariable {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param(
        [Parameter(Position = 0, Mandatory)]
        [string] $Key,

        [Parameter()]
        [string] $Value,

        [ValidateSet("User", "Machine")]
        [string] $Scope = "User"
    )
    $EnvironmentVariableTarget = if ($Scope -eq "User") { [System.EnvironmentVariableTarget]::User } else { [System.EnvironmentVariableTarget]::Machine }
    $RemoveValue = if ($Key -eq "PATH") { ([Environment]::GetEnvironmentVariable("PATH", $EnvironmentVariableTarget) -Split ";" | Where-Object { $_ -ne $Value }) -join ";" } else { $null }
    $ExampleOutput = if ($Key -eq "PATH") { "`n`nNEW PATH VALUE`n==============`n`n$($RemoveValue -split ";" -join "`n")`n`n" } else { $null }

    if ($PSCmdlet.ShouldProcess("Removing value '$Value' from environment variable '$Key'", "Are you sure you want to remove '$Value' from the environment variable '$Key'?$ExampleOutput", "Remove '$Value' from '$Key'")) {
        [Environment]::SetEnvironmentVariable($Key, $RemoveValue, $EnvironmentVariableTarget)
    }
}

function Start-ElevatedConsole {
    Start-Process (Get-Process -Id $PID).Path -Verb RunAs -ArgumentList @("-NoExit", "-Command", "Set-Location '$($PWD.Path)'")
}

#endregion PowerShell Macros

#region Aliases

Set-Alias -Name config -Value Update-Configuration
Set-Alias -Name activate -Value .\venv\Scripts\Activate.ps1
Set-Alias -Name count -Value Get-FileCount
Set-Alias -Name touch -Value New-Item
Set-Alias -Name elevate -Value Start-ElevatedConsole
Set-Alias -Name ^ -Value Select-Object
Set-Alias -Name man -Value Get-Help -Option AllScope
Set-Alias -Name help -Value Get-Help -Option AllScope
Set-Alias -Name np -Value notepad.exe
Set-Alias -Name exp -Value explorer.exe
Set-Alias -Name bye -Value Stop-Work

#endregion Aliases

#region Command Prompt

function Get-ExecutionTime {
    $History = Get-History
    $ExecTime = if ($History) { $History[-1].EndExecutionTime - $History[-1].StartExecutionTime } else { New-TimeSpan }
    Write-Output $ExecTime
}

function prompt {
    $ExecTime = Get-ExecutionTime
    $Path = (Get-Item "$($ExecutionContext.SessionState.Path.CurrentLocation)").BaseName

    git rev-parse --is-inside-work-tree 2>&1 | Out-Null

    $Branch = if ($?) {
        $ForegroundColors.Blue + " ($(git rev-parse --abbrev-ref HEAD))" + $ForegroundColors.White
    }

    $Venv = if ($env:VIRTUAL_ENV) {
        $ForegroundColors.Yellow + " ($([System.IO.Path]::GetFileName($env:VIRTUAL_ENV))" + $ForegroundColors.White
    }

    $Time = " ($($ExecTime.Hours.ToString('D2')):$($ExecTime.Minutes.ToString('D2')):$($ExecTime.Seconds.ToString('D2')):$($ExecTime.Milliseconds.ToString('D3')))"

    return @(
        '[',
        $ForegroundColors.BrightCyan + $env:USERNAME + $ForegroundColors.White,
        '@',
        $env:COMPUTERNAME,
        ' ',
        $ForegroundColors.Green + $Path + $ForegroundColors.White,
        ']'
        $Branch,
        $Venv,
        $ForegroundColors.BrightYellow + $Time + $ForegroundColors.White,
        "`n",
        "$('>' * ($NestedPromptLevel + 1)) "
    ) -join ''
}

#endregion Command Prompt
