# ============================================================
# Startup
# ============================================================

Clear-Host

# CommandNotFoundAction is the reliable hook here — a `trap` doesn't work
# for this because each line typed at the interactive prompt is its own
# top-level invocation, and a trap set during profile execution (a separate,
# earlier invocation) doesn't carry over to catch errors in later ones.
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $EventArgs)
    Write-Host "$CommandName not found" -ForegroundColor Red
    $EventArgs.StopSearch = $true
}

# ============================================================
# PSReadLine
# ============================================================

Set-PSReadLineOption -MaximumHistoryCount 10000
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

$HistoryFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
Set-PSReadLineOption -HistorySavePath $HistoryFilePath

# ============================================================
# ~ bang-history expansion (must load before `prompt`, which
# depends on Get-BangHistoryBuffer)
# ============================================================

. (Join-Path $HOME 'local\repos\Ps1BangHistory\BangHistory.ps1')

# ============================================================
# Prompt
# ============================================================

# Cache the cross-session history count so `prompt` (which fires after
# every command) doesn't re-parse the entire persisted history file on
# every render — only reads it once, then increments in memory.
$script:BangHistoryCachedCount = $null

function prompt {
    if ($null -eq $script:BangHistoryCachedCount) {
        $script:BangHistoryCachedCount = (Get-BangHistoryBuffer).Count
    }
    else {
        $script:BangHistoryCachedCount++
    }
    $id = $script:BangHistoryCachedCount

    $currentPath = $PWD.Path
    $homePath = $HOME
    $lambda = [System.Char]::ConvertFromUtf32(0x03BB)

    if ($currentPath.StartsWith($homePath)) {
        $relativePath = $currentPath.Substring($homePath.Length)
        if ($relativePath.StartsWith('\') -or $relativePath.StartsWith('/')) {
            $relativePath = $relativePath.Substring(1)
        }
        $loc = if ([string]::IsNullOrEmpty($relativePath)) { "~" } else { "~/$relativePath" -replace '\\', '/' }
    }
    else {
        $loc = Split-Path -Leaf $PWD
    }

    $time = Get-Date -Format 'HH:mm:ss'
    $gitBranch = git branch --show-current 2>$null
    $gitStatus = git status --porcelain 2>$null

    Write-Host "`n[$id]" -NoNewline -ForegroundColor Cyan
    Write-Host " $loc" -NoNewline -ForegroundColor Yellow
    if ($gitBranch) {
        $branchColor = if ($gitStatus) { "Red" } else { "Green" }
        Write-Host " ($gitBranch)" -NoNewline -ForegroundColor $branchColor
    }
    Write-Host " [$time]" -NoNewline -ForegroundColor DarkGray
    Write-Host "`n$lambda" -NoNewline -ForegroundColor Green
    " "
}

# ============================================================
# File listing (ls / l)
# ============================================================

function Format-FileSize {
    param ([long]$Size)
    if ($Size -gt 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -gt 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -gt 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
    return "$Size B"
}

Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
function ls {
    $originalLocation = Get-Location
    Get-ChildItem | ForEach-Object {
        $color = if ($_.PSIsContainer) {
            "Blue"
        }
        else {
            switch -Regex ($_.Name.ToLower()) {
                '\.(exe|bat|cmd|ps1)$'              { "Green" }
                '\.(txt|md|json|yml|yaml|xml|config)$' { "Yellow" }
                '\.(dll|pdb|obj|bin)$'              { "DarkGray" }
                '\.(cs|fs|cpp|h|hpp)$'               { "Magenta" }
                '\.(sln|csproj|fsproj)$'            { "Cyan" }
                '^\.'                                { "DarkCyan" }
                default                              { "White" }
            }
        }

        $timeStr = $_.LastWriteTime.ToString("MM/dd/yyyy HH:mm")
        $lengthStr = if ($_.PSIsContainer) { "".PadLeft(10) } else { (Format-FileSize $_.Length).PadLeft(10) }

        Write-Host ("{0,-7}" -f $_.Mode) -NoNewline
        Write-Host ("{0,-16}" -f $timeStr) -NoNewline
        Write-Host ("{0,10}  " -f $lengthStr) -NoNewline
        Write-Host $_.Name -ForegroundColor $color
    }
    Set-Location $originalLocation
}

function List-Files { ls }   # kept as an explicit-name alternative to `ls`

Remove-Item Alias:l  -Force -ErrorAction SilentlyContinue
Set-Alias   l  List-Files
Set-Alias   ll ls
Set-Alias   vi nvim
Set-Alias   grep rg

# ============================================================
# History (h) — cross-session, zero-based, via Get-BangHistoryBuffer.
# ============================================================

function MyHistory {
    Get-BangHistoryBuffer | ForEach-Object {
        Write-Host ("[{0}] " -f $_.Id) -ForegroundColor Yellow -NoNewline
        Write-Host $_.CommandLine -ForegroundColor White
    }
}

Remove-Item Alias:h -Force -ErrorAction SilentlyContinue
Set-Alias h MyHistory

# ============================================================
# Git shortcuts
# ============================================================

function gs { git status -s }

function gacp {
    param([Parameter(Mandatory, Position = 0)][string]$Message)
    git add -A
    git commit -m $Message
    if ($LASTEXITCODE -eq 0) { git push }
}

function gp  { git push }
function gll { git log --oneline --graph --decorate -20 }

# ============================================================
# Misc utilities
# ============================================================

function rmrf {
    Remove-Item -Recurse -Force $args
}

function cdr {
    cd ~\local\repos
}

function which {
    param([string]$Name)
    Get-Command $Name | Select-Object Name, CommandType, Source, Definition
}

# ============================================================
# Environment
# ============================================================

[Environment]::SetEnvironmentVariable(
    'PSModulePath',
    "$HOME\OneDrive\Documents\WindowsPowerShell\Modules;$env:PSModulePath",
    'User'
)
