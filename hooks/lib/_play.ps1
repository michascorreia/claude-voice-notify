# claude-voice-notify — headless audio player for Windows.
# Usage: powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -File _play.ps1 <path>
# Uses WPF System.Windows.Media.MediaPlayer (plays .m4a/.mp3 headless on Win10+).
# Requires -STA and a dispatcher frame so the async WPF media pipeline can run.

param([Parameter(Mandatory = $true, Position = 0)][string]$Path)

$ErrorActionPreference = 'SilentlyContinue'

if (-not (Test-Path -LiteralPath $Path)) { exit 0 }
$full = (Resolve-Path -LiteralPath $Path).Path

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$uri    = [System.Uri]$full
$player = New-Object System.Windows.Media.MediaPlayer
$frame  = New-Object System.Windows.Threading.DispatcherFrame

$player.add_MediaOpened({ $player.Play() })
$player.add_MediaEnded({  $frame.Continue = $false })
$player.add_MediaFailed({ $frame.Continue = $false })

# Safety cap: bail out after 30s even if MediaEnded never fires.
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(30)
$timer.add_Tick({ $frame.Continue = $false })
$timer.Start()

$player.Open($uri)
[System.Windows.Threading.Dispatcher]::PushFrame($frame)

$timer.Stop()
$player.Close()
exit 0
