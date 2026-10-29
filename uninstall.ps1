#Requires -Version 7.0
<#
.SYNOPSIS
    卸载 dsh-startup-secret（保留用户配置）

.DESCRIPTION
    从指定 profile 的 dependencies / dsh.profile.bundles / node_modules 联接点中移除本插件。
    默认**不删除** ~/.dsh/dsh-startup.json —— 重装后身份名、音色、文案都还在。
    加 -PurgeConfig 才删配置。

.PARAMETER Profile
    DSH profile 名，默认 desktop。

.PARAMETER PurgeConfig
    同时删除 ~/.dsh/dsh-startup.json。

.EXAMPLE
    pwsh -File .\uninstall.ps1 -Profile desktop
#>
[CmdletBinding()]
param(
    [string]$Profile = 'desktop',
    [switch]$PurgeConfig
)

$ErrorActionPreference = 'Stop'
$PackageName = 'dsh-startup-secret'

function Say  ($m) { Write-Host "[*] $m" }
function Good ($m) { Write-Host "[ok] $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "[!] $m"  -ForegroundColor Yellow }

$DshHome = $env:DSH_HOME
if (-not $DshHome) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }

$ProfileDir = Join-Path $DshHome "profiles\$Profile"
$PkgJson    = Join-Path $ProfileDir 'package.json'
if (-not (Test-Path $PkgJson)) { Warn "profile 不存在：$ProfileDir"; exit 1 }

$pkg = Get-Content $PkgJson -Raw | ConvertFrom-Json

if ($null -ne $pkg.dependencies.$PackageName) {
    $pkg.dependencies.PSObject.Properties.Remove($PackageName) | Out-Null
    Good "dependencies 已移除 $PackageName"
} else { Say "dependencies 里没有 $PackageName" }

$cur = @($pkg.dsh.profile.bundles)
if ($cur -contains $PackageName) {
    $pkg.dsh.profile.bundles = @($cur | Where-Object { $_ -ne $PackageName })
    Good "bundles 已移除 $PackageName"
} else { Say "bundles 里没有 $PackageName" }

$pkg | ConvertTo-Json -Depth 64 | Set-Content $PkgJson -Encoding utf8
Good "已写入 $PkgJson"

$link = Join-Path $ProfileDir "node_modules\$PackageName"
if (Test-Path $link) {
    $item = Get-Item $link -Force
    if ($item.LinkType) { $item.Delete(); Good "已删除联接点 $link" }
    else { Warn "$link 是实体目录，未自动删除" }
}

$cfg = Join-Path $DshHome 'dsh-startup.json'
if ($PurgeConfig -and (Test-Path $cfg)) {
    $bak = "$cfg.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Move-Item $cfg $bak -Force
    Good "配置已归档到 $bak"
} elseif (Test-Path $cfg) {
    Say "配置保留：$cfg（加 -PurgeConfig 才删）"
}

Write-Host ''
Good '卸载完成。重启 DSH 生效。'
Write-Host '二次开发定制 · QQ 2363984977' -ForegroundColor Magenta
