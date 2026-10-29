# 优化清单 · OPTIMIZATIONS

> 全部改动均为**工程/交付层修复**，不触碰设计、文案、动画分镜与音视频素材。
> 视觉与听觉表现与上游 `dsh-startup-secret@1.5.2` 完全一致。

---

## 1. `.gitattributes`：把源码钉死为 LF（核心修复）

### 问题

上游 `.gitattributes` 只约束了 `*.cmd / *.bat / *.sh` 和二进制，其余文件交给 `core.autocrlf` 决定。
在 Windows 上 `core.autocrlf=true`（Git for Windows 安装默认值之一，也是本机实测值）时：

```
git clone → lib/splash.js 从 2086976 字节变成 2088823 字节（+1847 个 \r）
```

浏览器能跑（JS 引擎容忍 CRLF），但

- `test/new-options.mjs` 里那条按字节精确匹配的正则断言会挂；
- 拿到手的源码与发布 tarball 不再逐字节一致，出问题无法用 SHA256 对账。

### 修复

```gitattributes
*.js   text eol=lf
*.mjs  text eol=lf
*.json text eol=lf
*.yml  text eol=lf
*.md   text eol=lf
*.css  text eol=lf
*.html text eol=lf
*.ps1  text eol=lf
*.txt  text eol=lf
```

`.cmd/.bat` 的 `-text` 保持原样（GBK + CRLF 是作者刻意设计，动了就乱码，见 `.gitattributes` 注释）。

### 验证

```
修复前：git clone → node test/new-options.mjs → 通过 74 / 失败 1
修复后：git clone → node test/new-options.mjs → 通过 75 / 失败 0
        且 lib/splash.js SHA256 与 dsh-startup-secret-1.5.2.tgz 内文件完全一致
```

---

## 2. `.editorconfig`：编辑器层统一 LF

`.gitattributes` 只管 Git 侧。在 Windows 上用 VS Code / Notepad++ 手改 `lib/index.js` 再存盘，
默认仍会写成 CRLF。`.editorconfig` 把编辑器也钉到 LF，并给 `.cmd/.bat` 单独声明 `crlf`。

---

## 3. `install.ps1` / `uninstall.ps1`：PowerShell 安装器

上游只提供 `安装.cmd`（GBK 批处理，双击可用）和 `install.sh`（Bash）。缺一个能在
PowerShell 里直接跑、可被自动化脚本调用的安装器。

`install.ps1` 做四件事：

1. **定位 DSH** —— 依次尝试 `dsh` 命令、`DSH_HOME`、`~/.dsh`，找不到就报明确原因；
2. **选 profile** —— 默认 `desktop`（桌面端），`-Profile web` 可切；
3. **旧插件共存检测** —— 扫 `dsh.profile.bundles` 与 `node_modules`，发现 `dsh-startup-screen`
   就停下来提示，因为两者抢同一组 `/dsh-startup/*` 路由、同一份 `~/.dsh/dsh-startup.json`、
   同一个 `settings.section` id，同时启用会重复注册报错。`-Force` 可自动摘除旧插件；
4. **写配置** —— `dependencies` 加 `link:`，`dsh.profile.bundles` 追加包名，幂等（重复跑不会重复插入）。

`uninstall.ps1` 反向操作，并保留 `~/.dsh/dsh-startup.json`（不删用户配置）。

```powershell
# 安装（桌面端）
pwsh -File .\install.ps1

# 安装并自动摘掉旧版 dsh-startup-screen
pwsh -File .\install.ps1 -Force

# 装到 web profile
pwsh -File .\install.ps1 -Profile web

# 卸载（保留配置）
pwsh -File .\uninstall.ps1
```

---

## 4. `test/run-all.mjs`：一键跑全部测试

上游 `npm test` 是四条 `node ... && node ...` 串联，任一条挂了看不到完整报告，
也不知道总共多少断言。`run-all.mjs` 逐条跑、逐条汇总：

```
$ node test/run-all.mjs
  smoke-host.mjs          通过 62 / 失败 0   (1.2s)
  smoke-splash.mjs        通过 60 / 失败 0   (0.8s)
  smoke-client.mjs        通过 43 / 失败 0   (0.6s)
  smoke-desktop-boot.mjs  通过 46 / 失败 0   (0.9s)
  new-options.mjs         通过 75 / 失败 0   (0.7s)
  verify-password.mjs     ...
  ─────────────────────────────────────────
  合计 286 项断言，失败 0
```

`verify-password.mjs` 单独归类（它需要交互输入，默认跳过，`--all` 强制跑）。

---

## 5. `docs/LF-FAQ.md`

把上面第 1 条的排查路径写成 FAQ：怎么判断自己 clone 下来的是不是 CRLF、
怎么用一行命令修好已有工作副本、为什么 `.cmd` 不能改成 LF。

---

## 6. README 顶部转载区块

在 README 最前面插入上游链接、作者、基线 commit、优化摘要与定制 QQ，
避免有人 clone 之后误以为是原创仓库。

---

## 未改动清单（明确声明）

以下内容与上游 **逐字节一致**，本仓库没有做任何修改：

- `lib/splash.js`（2086976 字节）、`lib/splash.css`（46763 字节）
- `lib/asset-data.js`（2134646 字节，44 段内联音频）
- `lib/client.js`（40865 字节，设置面板）
- `lib/index.js`（20842 字节，Host 路由与首屏注入）
- `lib/assets/*.mp3`（7 款音色 × 6 句 + 2 个界面音效）
- `preview/index.html`
- 全部 `RELEASE-NOTES-*.md`
- `package.json` 的 `version` / `dsh` / `exports` / `files` 语义字段（只追加了 `scripts.test:all`）

可用以下命令自查：

```powershell
node -e "const c=require('crypto'),f=require('fs');for(const p of ['lib/splash.js','lib/index.js','lib/client.js','lib/asset-data.js'])console.log(p,c.createHash('sha256').update(f.readFileSync(p)).digest('hex').slice(0,16))"
```

与上游同命令输出对比即可。
