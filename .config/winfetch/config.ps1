# ===== WINFETCH CONFIGURATION =====

$ascii = $true

function info_custom_time {
    return @{
        title = "Date"
        content = [System.DateTime]::Now
    }
}

# available values: text, bar, textbar, bartext
$cpustyle = 'bar'
$memorystyle = 'textbar'
$diskstyle = 'textbar'
$batterystyle = 'text'

@(
    "title"
    "dashes"
    "os"
    "computer"
    "kernel"
    "motherboard"
    "uptime"
    "ps_pkgs"
    "pwsh"
    "resolution"
    "terminal"
    "cpu"
    "gpu"
    "memory"
    "disk"
    "battery"
    "custom_time"
    "blank"
    "colorbar"
)
