#Requires -Version 7.0
<#
.SYNOPSIS
    dsh-startup-secret 安装器（PowerShell 版）

.DESCRIPTION
    把本仓库作为 DSH 插件装进指定 profile。

    与上游 安装.cmd 的区别：
      * 可在 pwsh 里直接调用，能被自动化脚本串起来；
      * 会先检测旧版 dsh-startup-screen 是否共存（两者抢同一组路由 / 同一份
        配置 / 同一个 settings.section id，同时启用会重复注册报错）；
      * 幂等：重复执行不会重复插入 bundles 条目。

.PARAMETER Profile
    DSH profile 名。桌面端用 desktop（默认），浏览器端用 web。

.PARAMETER Force
    检测到旧版 dsh-startup-screen 时自动摘除（默认只报警并退出）。

.PARAMETER SkipInstall
    只改 profile 配置，不跑包管理器安装。

.EXAMPLE
    pwsh -File .\install.ps1

.EXAMPLE
    pwsh -File .\install.ps1 -Force -Profile web
#>
[CmdletBinding()]
param(
    [string]$Profile = 'desktop',
    [switch]$Force,
    [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
$PackageName = 'dsh-startup-secret'
$LegacyName  = 'dsh-startup-screen'   # 上游旧版：与本插件互斥
$RepoRoot    = $PSScriptRoot

function Say  ($m) { Write-Host "[*] $m" }
function Good ($m) { Write-Host "[ok] $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "[!] $m"  -ForegroundColor Yellow }
function Die  ($m) { Write-Host "[x] $m"   -ForegroundColor Red; exit 1 }

# ── 1. 定位 DSH ─────────────────────────────────────────────────────────
$DshHome = $env:DSH_HOME
if (-not $DshHome) { $DshHome = Join-Path $env:USERPROFILE '.dsh' }
if (-not (Test-Path $DshHome)) { Die "找不到 DSH 目录：$DshHome（先装 DeepSeek Harness 再说）" }
Say "DSH_HOME = $DshHome"

$ProfileDir = Join-Path $DshHome "profiles\$Profile"
if (-not (Test-Path $ProfileDir)) {
    $avail = Get-ChildItem (Join-Path $DshHome 'profiles') -Directory -ErrorAction SilentlyContinue |
             Select-Object -ExpandProperty Name
    Die "profile '$Profile' 不存在。现有：$($avail -join ', ')"
}
$PkgJson = Join-Path $ProfileDir 'package.json'
if (-not (Test-Path $PkgJson)) { Die "profile 缺少 package.json：$PkgJson" }
Say "profile 目录 = $ProfileDir"

# ── 2. Node 版本检查（插件 engines 要求 >=20）─────────────────────────────
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeMajor = [int]((& node -p 'process.versions.node.split(".")[0]'))
    if ($nodeMajor -lt 20) { Die "Node 版本过低：$(node -v)（要求 >= 20）" }
    Good "Node $(node -v)"
} else {
    Warn 'PATH 里没有 node；如果走 -SkipInstall 则无影响'
}

# ── 3. 旧插件共存检测 ───────────────────────────────────────────────────
$pkg = Get-Content $PkgJson -Raw | ConvertFrom-Json
$bundles = @($pkg.dsh.profile.bundles)
$deps    = $pkg.dependencies

$legacyInBundles = $bundles -contains $LegacyName
$legacyInDeps    = $null -ne $deps.$LegacyName

# 磁盘存在性：只有「联接点」或「真装过的包（有 package.json）」才算共存。
# 空壳目录（例如上次 -Force 摘除时留下的残留）不会被 bundle loader 加载，
# 不该拦着安装流程。
$legacyPath = Join-Path $ProfileDir "node_modules\$LegacyName"
$legacyOnDisk = $false
if (Test-Path $legacyPath) {
    $legacyItem = Get-Item $legacyPath -Force
    if ($legacyItem.LinkType) { $legacyOnDisk = $true }
    elseif (Test-Path (Join-Path $legacyPath 'package.json')) { $legacyOnDisk = $true }
    else {
        Warn "$legacyPath 是空壳目录（无 package.json、非联接点），已清理"
        Remove-Item $legacyPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($legacyInBundles -or $legacyInDeps -or $legacyOnDisk) {
    Warn "检测到旧版 $LegacyName（bundles=$legacyInBundles deps=$legacyInDeps disk=$legacyOnDisk）"
    Warn "两者抢同一组 /dsh-startup/* 路由、同一份 ~/.dsh/dsh-startup.json、同一个 settings.section id。"
    if (-not $Force) {
        Write-Host ''
        Warn '同时启用会重复注册并互相覆盖配置。加 -Force 自动摘除旧版后继续：'
        Warn "  pwsh -File .\install.ps1 -Force"
        exit 2
    }
    Say "摘除旧版 $LegacyName ..."

    $pkg.dependencies.PSObject.Properties.Remove($LegacyName) | Out-Null
    $pkg.dsh.profile.bundles = @($bundles | Where-Object { $_ -ne $LegacyName })

    $junction = Join-Path $ProfileDir "node_modules\$LegacyName"
    if (Test-Path $junction) {
        $item = Get-Item $junction -Force
        if ($item.LinkType) { $item.Delete(); Good "已删除联接点 $junction" }
        else { Warn "$junction 是实体目录（不是联接点），未自动删除；确认没用后手动删" }
    }
    $pkg | ConvertTo-Json -Depth 64 | Set-Content $PkgJson -Encoding utf8
    Good "已从 profile 配置中移除 $LegacyName"
    $pkg = Get-Content $PkgJson -Raw | ConvertFrom-Json
}

# ── 4. 写配置：dependencies + bundles ───────────────────────────────────
$linkSpec = 'link:' + ($RepoRoot -replace '\\', '/')
if ($null -eq $pkg.dependencies.$PackageName) {
    $pkg.dependencies | Add-Member -NotePropertyName $PackageName -NotePropertyValue $linkSpec -Force
    Say "dependencies += $PackageName ($linkSpec)"
} else {
    $pkg.dependencies.$PackageName = $linkSpec
    Say "dependencies 已更新 $PackageName"
}

$cur = @($pkg.dsh.profile.bundles)
if ($cur -notcontains $PackageName) {
    # 紧跟 @deepseek-ai/dsh-web-app 之后插入，保证在客户端 UI 层之前选好挂载点
    $idx = [Array]::IndexOf($cur, '@deepseek-ai/dsh-web-app')
    if ($idx -lt 0) {
        $pkg.dsh.profile.bundles = @($cur + $PackageName)
    } else {
        $pkg.dsh.profile.bundles = @($cur[0..$idx]) + $PackageName + @($cur[($idx + 1)..($cur.Count - 1)])
    }
    Good "bundles += $PackageName"
} else {
    Say "bundles 里已存在 $PackageName，跳过"
}

$pkg | ConvertTo-Json -Depth 64 | Set-Content $PkgJson -Encoding utf8
Good "已写入 $PkgJson"

# ── 5. 建立 node_modules 联接点 ─────────────────────────────────────────
$nm   = Join-Path $ProfileDir 'node_modules'
$link = Join-Path $nm $PackageName
if (-not (Test-Path $nm)) { New-Item -ItemType Directory -Force $nm | Out-Null }

if (Test-Path $link) {
    $item = Get-Item $link -Force
    if ($item.LinkType) {
        # 联接点：目标与本次要装的一致就保留，不一致才删了重建
        $curTarget = $null
        try { $curTarget = (Resolve-Path $item.Target -ErrorAction Stop).Path } catch { $curTarget = $null }
        $wantTarget = (Resolve-Path $RepoRoot -ErrorAction Stop).Path
        if ($curTarget -ne $wantTarget) {
            $item.Delete(); Say "旧联接点指向 $curTarget，已删除重建"
        } else {
            Say "联接点已指向本仓库，无需重建"
        }
    } else {
        Die "$link 是实体目录（不是联接点）。先删掉它再装，否则会用到旧副本。"
    }
}
if (-not (Test-Path $link)) {
    cmd /c mklink /J "$link" "$RepoRoot" | Out-Null
    if ($LASTEXITCODE -ne 0) { Die "创建联接点失败：$link -> $RepoRoot" }
    Good "联接点 node_modules\$PackageName -> $RepoRoot"
}

# ── 6. 包管理器安装（可选）──────────────────────────────────────────────
if (-not $SkipInstall) {
    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if ($pnpm) {
        Say 'pnpm install --lockfile-only（校验 lockfile 一致性）...'
        Push-Location $ProfileDir
        try {
            $env:pnpm_config_minimum_release_age = '0'
            & pnpm install --lockfile-only --ignore-scripts 2>&1 | Select-Object -Last 5 | ForEach-Object { "    $_" }
        } finally { Pop-Location }
        Good 'lockfile 校验完成'
    } else {
        Warn '未找到 pnpm，跳过 lockfile 校验（不影响运行）'
    }
}

# ── 7. 收尾 ─────────────────────────────────────────────────────────────
Write-Host ''
Good '安装完成。'
Write-Host ''
Write-Host '下一步：' -ForegroundColor Cyan
Write-Host '  1. 完全退出 DSH（关窗口 + 确认进程退干净），再重新启动'
Write-Host '  2. 刷新页面，应看到：黑幕 → 标识 → 过曝洗白 → 授权序列 → 揭幕'
Write-Host "  3. 设置页多出「启动动画」分组（order 26），可改身份名/音色/文案"
Write-Host ''
Write-Host '验证路由已注册（未带 token 返回 401 即为正常，404 才是没装上）：' -ForegroundColor Cyan
Write-Host '  curl.exe -s -o NUL -w "%{http_code}\n" http://127.0.0.1:PORT/dsh-startup/splash.js'
Write-Host ''
Write-Host '配置落盘：' -ForegroundColor Cyan
Write-Host "  $DshHome\dsh-startup.json"
Write-Host ''
Write-Host '二次开发定制 · QQ 2363984977' -ForegroundColor Magenta
