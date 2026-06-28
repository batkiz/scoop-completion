# This source code is licensed under the MIT License
# Project URL - https://github.com/Moeologist/scoop-completion
# Thanks to Posh-Git - https://github.com/dahlbyk/posh-git

#Requires -Version 5.0

# -----------------------------------------------------------------------------
# Configuration helpers (see scoop/lib/core.ps1)
# -----------------------------------------------------------------------------
function script:load_cfg($file) {
    if (!(Test-Path $file)) {
        return $null
    }
    try {
        return (Get-Content $file -Raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch { }
}

$script:configHome = @($env:XDG_CONFIG_HOME, "$env:USERPROFILE\.config") |
    Where-Object { -not [String]::IsNullOrWhiteSpace($_) } |
    Select-Object -First 1
$script:configFile = "$script:configHome\scoop\config.json"
$script:scoopConfig = load_cfg $script:configFile

function script:get_config($name, $default) {
    if ($null -eq $scoopConfig.$name -and $null -ne $default) {
        return $default
    }
    return $scoopConfig.$name
}

# -----------------------------------------------------------------------------
# Resolve Scoop directories
# -----------------------------------------------------------------------------
try {
    $script:scoopdir = @($env:SCOOP, (get_config 'root_path'), "$env:USERPROFILE\scoop") |
        Where-Object { -not [String]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1
    $script:globaldir = @($env:SCOOP_GLOBAL, (get_config 'global_path'), "$env:ProgramData\scoop") |
        Where-Object { -not [String]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1
    $script:cachedir = @($env:SCOOP_CACHE, (get_config 'cache_path'), "$script:scoopdir\cache") |
        Where-Object { -not [String]::IsNullOrWhiteSpace($_) } |
        Select-Object -First 1
    $script:bucketsdir = "$script:scoopdir\buckets"
    $script:scoopRepoDir = "$script:scoopdir\apps\scoop\current"
}
catch { Write-Warning 'No scoop installed!' }

$script:aliasMap = get_config 'alias'

# -----------------------------------------------------------------------------
# Completion data (based on Scoop 0.5.3 libexec scripts)
# -----------------------------------------------------------------------------
$script:ScoopCommands = @(
    'alias',
    'bucket',
    'cache',
    'cat',
    'checkup',
    'cleanup',
    'config',
    'create',
    'depends',
    'download',
    'export',
    'help',
    'hold',
    'home',
    'import',
    'info',
    'install',
    'list',
    'prefix',
    'reset',
    'search',
    'shim',
    'status',
    'unhold',
    'uninstall',
    'update',
    'virustotal',
    'which'
)

$script:ScoopSubcommands = @{
    alias  = 'add list rm'
    bucket = 'add list known rm'
    cache  = 'rm show'
    shim   = 'add list rm info alter'
}

# Config rm completion needs the full parameter list
$script:ScoopConfigParams = @(
    'use_external_7zip',
    'use_lessmsi',
    'use_sqlite_cache',
    'no_junction',
    'scoop_repo',
    'scoop_branch',
    'proxy',
    'autostash_on_conflict',
    'default_architecture',
    'debug',
    'force_update',
    'show_update_log',
    'show_manifest',
    'shim',
    'root_path',
    'global_path',
    'cache_path',
    'gh_token',
    'virustotal_api_key',
    'cat_style',
    'ignore_running_processes',
    'private_hosts',
    'hold_update_until',
    'update_nightly',
    'use_isolated_path',
    'aria2-enabled',
    'aria2-warning-enabled',
    'aria2-retry-wait',
    'aria2-split',
    'aria2-max-connection-per-server',
    'aria2-min-split-size',
    'aria2-options'
)

$script:ScoopSubcommands['config'] = (@('rm') + $script:ScoopConfigParams) -join ' '

$script:ScoopShortParams = @{
    install    = 'g i k s u a'
    uninstall  = 'g p'
    cleanup    = 'a g k'
    virustotal = 'a s n u p'
    update     = 'f g i k s q a'
    shim       = 'g'
    download   = 'f s u a'
    status     = 'l'
    hold       = 'g'
    unhold     = 'g'
    info       = 'v'
    alias      = 'v'
    reset      = 'a'
    export     = 'c'
}

$script:ScoopLongParams = @{
    install    = 'global independent no-cache skip-hash-check no-update-scoop arch'
    uninstall  = 'global purge'
    cleanup    = 'all global cache'
    virustotal = 'all scan no-depends no-update-scoop passthru'
    update     = 'force global independent no-cache skip-hash-check quiet all'
    shim       = 'global'
    download   = 'force skip-hash-check no-update-scoop arch'
    status     = 'local'
    hold       = 'global'
    unhold     = 'global'
    info       = 'verbose'
    alias      = 'verbose'
    reset      = 'all'
    export     = 'config'
}

$script:ScoopParamValues = @{
    install  = @{
        a    = '32bit 64bit arm64'
        arch = '32bit 64bit arm64'
    }
    download = @{
        a    = '32bit 64bit arm64'
        arch = '32bit 64bit arm64'
    }
}

$script:ScoopConfigParamValues = @{
    use_external_7zip          = 'true false'
    use_lessmsi                = 'true false'
    use_sqlite_cache           = 'true false'
    no_junction                = 'true false'
    scoop_branch               = 'master develop'
    autostash_on_conflict      = 'true false'
    default_architecture       = '32bit 64bit arm64'
    debug                      = 'true false'
    force_update               = 'true false'
    show_update_log            = 'true false'
    show_manifest              = 'true false'
    shim                       = 'kiennq scoopcs 71'
    cat_style                  = 'default auto full plain changes header header-filename header-filesize grid rule numbers snip'
    ignore_running_processes   = 'true false'
    update_nightly             = 'true false'
    use_isolated_path          = 'true false'
    'aria2-enabled'            = 'true false'
    'aria2-warning-enabled'    = 'true false'
}

$script:ScoopCommandsWithLongParams = $ScoopLongParams.Keys -join '|'
$script:ScoopCommandsWithShortParams = $ScoopShortParams.Keys -join '|'
$script:ScoopCommandsWithParamValues = $ScoopParamValues.Keys -join '|'

# Package token used in regexes: allows bucket/app and app@version forms,
# but disallows a leading hyphen so that options (--foo / -foo) are not mistaken for packages.
$script:PackageToken = "[a-zA-Z0-9_.][a-zA-Z0-9-_.]*(?:\/[a-zA-Z0-9-_.]+)?(?:@[^ \t]*)?"

# -----------------------------------------------------------------------------
# Cached completion sources (dramatically improves performance)
# -----------------------------------------------------------------------------
$script:CompletionCache = @{}

function script:Get-CompletionCache($Name, $TTLSeconds, [scriptblock]$Refresh) {
    $now = [DateTime]::Now
    $entry = $script:CompletionCache[$Name]
    if ($entry -and ($null -ne $entry.Value) -and ($now - $entry.Timestamp).TotalSeconds -lt $entry.TTLSeconds) {
        return $entry.Value
    }

    $value = & $Refresh
    $script:CompletionCache[$Name] = [pscustomobject]@{
        Value      = $value
        Timestamp  = $now
        TTLSeconds = $TTLSeconds
    }
    return $value
}

function script:Update-RemotePackageCache {
    $pkgs = [System.Collections.Generic.List[string]]::new()
    if (!(Test-Path $script:bucketsdir)) { return @() }

    try {
        foreach ($bucketDir in [System.IO.Directory]::EnumerateDirectories($script:bucketsdir)) {
            $bucket = [System.IO.Path]::GetFileName($bucketDir)
            $manifestDir = Join-Path $bucketDir 'bucket'
            if (!(Test-Path $manifestDir)) { $manifestDir = $bucketDir }

            if (Test-Path $manifestDir) {
                foreach ($file in [System.IO.Directory]::EnumerateFiles($manifestDir, '*.json', [System.IO.SearchOption]::AllDirectories)) {
                    $app = [System.IO.Path]::GetFileNameWithoutExtension($file)
                    $pkgs.Add("$bucket/$app")
                }
            }
        }
    }
    catch { }

    return ($pkgs | Sort-Object -Unique)
}

function script:Update-LocalPackageCache {
    $apps = [System.Collections.Generic.List[string]]::new()
    $appsDir = "$script:scoopdir\apps"
    if (!(Test-Path $appsDir)) { return @() }

    try {
        foreach ($dir in [System.IO.Directory]::EnumerateDirectories($appsDir)) {
            $name = [System.IO.Path]::GetFileName($dir)
            if ($name -ne 'scoop') { $apps.Add($name) }
        }
    }
    catch { }

    return ($apps | Sort-Object)
}

function script:Update-LocalBucketCache {
    $buckets = [System.Collections.Generic.List[string]]::new()
    if (!(Test-Path $script:bucketsdir)) { return @() }

    try {
        foreach ($dir in [System.IO.Directory]::EnumerateDirectories($script:bucketsdir)) {
            $buckets.Add([System.IO.Path]::GetFileName($dir))
        }
    }
    catch { }

    return ($buckets | Sort-Object)
}

function script:Update-KnownBucketCache {
    $paths = @(
        "$script:scoopRepoDir\buckets.json",
        "$script:scoopdir\buckets.json"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $json = load_cfg $path
            if ($json) {
                return ($json.PSObject.Properties.Name | Sort-Object)
            }
        }
    }

    # Fallback to the native command when the JSON file cannot be located
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        return (& scoop bucket known | Sort-Object)
    }
    return @()
}

function script:Update-CacheNameCache {
    $names = [System.Collections.Generic.List[string]]::new()
    if (!(Test-Path $script:cachedir)) { return @() }

    try {
        foreach ($file in [System.IO.Directory]::EnumerateFiles($script:cachedir)) {
            $name = [System.IO.Path]::GetFileName($file)
            if ($name -match '^([^#]+)#') { $names.Add($Matches[1]) }
        }
    }
    catch { }

    return ($names | Sort-Object -Unique)
}

function script:Update-ShimCache {
    $shims = [System.Collections.Generic.List[string]]::new()
    $dirs = @("$script:scoopdir\shims", "$script:globaldir\shims")

    foreach ($dir in $dirs) {
        if (!(Test-Path $dir)) { continue }
        try {
            foreach ($file in [System.IO.Directory]::EnumerateFiles($dir, '*.shim')) {
                $shims.Add([System.IO.Path]::GetFileNameWithoutExtension($file))
            }
            foreach ($file in [System.IO.Directory]::EnumerateFiles($dir, '*.ps1')) {
                $shims.Add([System.IO.Path]::GetFileNameWithoutExtension($file))
            }
        }
        catch { }
    }

    return ($shims | Sort-Object -Unique)
}

function script:Update-AliasCache {
    if ($null -eq $script:aliasMap) { return @() }
    return ($script:aliasMap.PSObject.Properties.Name | Sort-Object)
}

# -----------------------------------------------------------------------------
# Completion expansion helpers
# -----------------------------------------------------------------------------
function script:ScoopAlias($filter) {
    $aliases = Get-CompletionCache 'Aliases' 60 { Update-AliasCache }
    return $aliases | Where-Object { $_ -like "$filter*" }
}

function script:ScoopExpandCmdParams($commands, $command, $filter) {
    $commands.$command -split ' ' | Where-Object { $_ -like "$filter*" }
}

function script:ScoopExpandCmd($filter, $includeAliases) {
    $cmdList = [System.Collections.Generic.List[string]]::new()
    $cmdList.AddRange([string[]]$ScoopCommands)
    if ($includeAliases) {
        $aliases = ScoopAlias $filter | Where-Object { $_ }
        if ($aliases) {
            $cmdList.AddRange([string[]]$aliases)
        }
    }
    return $cmdList | Where-Object { $_ -like "$filter*" } | Sort-Object -Unique
}

function script:ScoopLocalPackages($filter) {
    $packages = Get-CompletionCache 'LocalPackages' 30 { Update-LocalPackageCache }
    return $packages | Where-Object { $_ -like "$filter*" }
}

function script:ScoopRemotePackages($filter) {
    $packages = Get-CompletionCache 'RemotePackages' 120 { Update-RemotePackageCache }

    if ($filter -match '/') {
        return $packages | Where-Object { $_ -like "$filter*" }
    }

    $baseFilter = ($filter -split '@')[0]
    return $packages |
        ForEach-Object { ($_ -split '/')[1] } |
        Where-Object { $_ -like "$baseFilter*" } |
        Sort-Object -Unique
}

function script:ScoopLocalBuckets($filter) {
    $buckets = Get-CompletionCache 'LocalBuckets' 60 { Update-LocalBucketCache }
    return $buckets | Where-Object { $_ -like "$filter*" }
}

function script:ScoopRemoteBuckets($filter) {
    $buckets = Get-CompletionCache 'KnownBuckets' 3600 { Update-KnownBucketCache }
    return $buckets | Where-Object { $_ -like "$filter*" }
}

function script:ScoopLocalCaches($filter) {
    $caches = Get-CompletionCache 'CacheNames' 30 { Update-CacheNameCache }
    return $caches | Where-Object { $_ -like "$filter*" }
}

function script:ScoopShims($filter) {
    $shims = Get-CompletionCache 'Shims' 60 { Update-ShimCache }
    return $shims | Where-Object { $_ -like "$filter*" }
}

function script:ScoopConfigParamsFilter($filter) {
    return $ScoopConfigParams -like "$filter*"
}

function script:ScoopExpandConfigParamValues($param, $filter) {
    if ($ScoopConfigParamValues[$param]) {
        return $ScoopConfigParamValues[$param] -split ' ' |
            Where-Object { $_ -like "$filter*" } |
            Sort-Object
    }
    return @()
}

function script:ScoopExpandLongParams($cmd, $filter) {
    return $ScoopLongParams[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { "--$_" }
}

function script:ScoopExpandShortParams($cmd, $filter) {
    return $ScoopShortParams[$cmd] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object |
        ForEach-Object { "-$_" }
}

function script:ScoopExpandParamValues($cmd, $param, $filter) {
    return $ScoopParamValues[$cmd][$param] -split ' ' |
        Where-Object { $_ -like "$filter*" } |
        Sort-Object
}

# -----------------------------------------------------------------------------
# Tab expansion logic
# -----------------------------------------------------------------------------
function script:ScoopTabExpansion($lastBlock) {

    switch -regex ($lastBlock) {
        # Handles Scoop <cmd> --<param> <value>
        "^(?<cmd>$ScoopCommandsWithParamValues).* --(?<param>.+) (?<value>\w*)$" {
            if ($ScoopParamValues[$matches['cmd']][$matches['param']]) {
                return ScoopExpandParamValues $matches['cmd'] $matches['param'] $matches['value']
            }
        }

        # Handles Scoop <cmd> -<shortparam> <value>
        "^(?<cmd>$ScoopCommandsWithParamValues).* -(?<param>.+) (?<value>\w*)$" {
            if ($ScoopParamValues[$matches['cmd']][$matches['param']]) {
                return ScoopExpandParamValues $matches['cmd'] $matches['param'] $matches['value']
            }
        }

        # Handles installed app names
        "^(uninstall|cleanup|virustotal|update|prefix|reset|hold|unhold)\s+(?:.+\s+)?(?<package>$PackageToken)?$" {
            return ScoopLocalPackages $matches['package']
        }

        # Handles download and cat package names
        "^(download|cat)\s+(?:.+\s+)?(?<package>$PackageToken)?$" {
            return (ScoopRemotePackages $matches['package']) + (ScoopLocalPackages $matches['package'])
        }

        # Handles config param names
        "^config rm\s+(?:.+\s+)?(?<param>[a-zA-Z0-9_.-]*)?$" {
            return ScoopConfigParamsFilter $matches['param']
        }

        # Handles Scoop config <param>
        "^config\s+(?<param>[a-zA-Z0-9_.-]*)$" {
            return ScoopConfigParamsFilter $matches['param']
        }

        # Handles install/info/home/depends package names
        "^(install|info|home|depends)\s+(?:.+\s+)?(?<package>$PackageToken)?$" {
            return ScoopRemotePackages $matches['package']
        }

        # Handles cache (rm/show) cache names
        "^cache (rm|show)\s+(?:.+\s+)?(?<cache>[a-zA-Z0-9_.-]*)?$" {
            return ScoopLocalCaches $matches['cache']
        }

        # Handles bucket rm bucket names
        "^bucket rm\s+(?:.+\s+)?(?<bucket>[a-zA-Z0-9_.-]*)?$" {
            return ScoopLocalBuckets $matches['bucket']
        }

        # Handles bucket add bucket names
        "^bucket add\s+(?:.+\s+)?(?<bucket>[a-zA-Z0-9_.-]*)?$" {
            return ScoopRemoteBuckets $matches['bucket']
        }

        # Handles alias rm alias names
        "^alias rm\s+(?:.+\s+)?(?<alias>[a-zA-Z0-9_.-]*)?$" {
            return ScoopAlias $matches['alias']
        }

        # Handles shim rm/info/alter shim names
        "^shim (rm|info|alter)\s+(?:.+\s+)?(?<shim>[a-zA-Z0-9_.-]*)?$" {
            return ScoopShims $matches['shim']
        }

        # Handles scoop which <command>
        "^which\s+(?:.+\s+)?(?<command>[a-zA-Z0-9_.-]*)?$" {
            return ScoopShims $matches['command']
        }

        # Handles Scoop help <cmd>
        "^help (?<cmd>\S*)$" {
            return ScoopExpandCmd $matches['cmd'] $false
        }

        # Handles Scoop <cmd> <subcmd>
        # The op must not look like an option so that flags such as '-v' or '--global' fall
        # through to the parameter completion rules below.
        "^(?<cmd>$($ScoopSubcommands.Keys -join '|'))\s+(?<op>[^-]\S*)?$" {
            return ScoopExpandCmdParams $ScoopSubcommands $matches['cmd'] $matches['op']
        }

        # Handles Scoop config <param> <value>
        "^config (?<param>[a-zA-Z0-9_.-]+)\s+(?<value>\w*)$" {
            return ScoopExpandConfigParamValues $matches['param'] $matches['value']
        }

        # Handles Scoop <cmd>
        "^(?<cmd>\S*)$" {
            return ScoopExpandCmd $matches['cmd'] $true
        }

        # Handles Scoop <cmd> --<param>
        "^(?<cmd>$ScoopCommandsWithLongParams).* --(?<param>\S*)$" {
            return ScoopExpandLongParams $matches['cmd'] $matches['param']
        }

        # Handles Scoop <cmd> -<shortparam>
        "^(?<cmd>$ScoopCommandsWithShortParams).* -(?<shortparam>\S*)$" {
            return ScoopExpandShortParams $matches['cmd'] $matches['shortparam']
        }
    }
}

# -----------------------------------------------------------------------------
# Register argument completer for scoop and its aliases
# -----------------------------------------------------------------------------
function script:Get-AliasNames($exe) {
    @($exe, "$exe.ps1", "$exe.cmd") + @(Get-Alias | Where-Object { $_.Definition -eq $exe } | Select-Object -ExpandProperty Name)
}

Register-ArgumentCompleter -Native -CommandName (Get-AliasNames scoop) -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorColumn)

    $ownCommandLine = [string]$commandAst
    $ownCommandLine = $ownCommandLine.Substring(0, [Math]::Min($ownCommandLine.Length, $cursorColumn))
    $argList = (($ownCommandLine -replace '^\S+\s*') + ' ' * ($cursorColumn - $ownCommandLine.Length)).TrimStart()

    ScoopTabExpansion $argList
}
