# 转载版 v1.5.2-r1

> 上游：<https://github.com/huzhengcai471-crypto/dsh-startup-secret> @ `c03017be`（v1.5.2）
> 原作者：[@huzhengcai471-crypto](https://github.com/huzhengcai471-crypto)
>
> **本版不包含任何设计、文案、动画分镜、音视频素材的改动。**
> `lib/splash.js`、`lib/splash.css`、`lib/index.js`、`lib/client.js`、`lib/asset-data.js`、
> `preview/index.html`、`lib/assets/*.mp3` 全部与上游 v1.5.2 **逐字节一致**（SHA256 已比对）。

## 修复

### 1. `.gitattributes` 补源码 LF 约束（核心）

上游只钉了 `*.cmd / *.sh` 和二进制，`lib/**` 交给 `core.autocrlf` 决定。
Windows 上 `core.autocrlf=true` 时 clone 会把 `lib/splash.js` 从 2086976 字节变成 2088823 字节
（多 1847 个 `\r`），导致按字节精确匹配的 `test/new-options.mjs` 挂掉 1 项断言。

现在 `*.js / *.mjs / *.json / *.yml / *.md / *.css / *.html / *.ps1` 全部 `text eol=lf`，
clone 即得与发布 tarball 逐字节一致的源码。

### 2. 历史遗留 CRLF 文本归一

仓库里 `README.md`、`INSTALL.md`、`DESKTOP.md`、`AUDIO-FIELDS.md`、`preview/index.html`、
`test/smoke-{client,splash}.mjs` 原本以 CRLF 提交（281 / 187 / 144 / 121 / 567 / 216 / 324 个 CR）。
本次统一成 LF —— **纯换行符变更，内容零改动**，可用 `git diff --ignore-cr-at-eol` 自查。

### 3. 新增 `.editorconfig`

`.gitattributes` 只管 Git 侧；编辑器保存时仍会写 CRLF。`.editorconfig` 把编辑器也钉到 LF，
并给 `.cmd/.bat` 单独声明 GBK + CRLF（这两个文件必须是 GBK+CRLF，改了就乱码）。

### 4. 新增 `install.ps1` / `uninstall.ps1`

- 定位 `DSH_HOME` / profile，找不到就说清缺什么；
- 自动写 `dependencies` + `dsh.profile.bundles`（上游要手动改 JSON，最容易漏）；
- **旧版 `dsh-startup-screen` 共存检测**：两者抢同一组 `/dsh-startup/*` 路由、
  同一份 `~/.dsh/dsh-startup.json`、同一个 `settings.section` id，同时启用会重复注册。
  检测到就停下并提示 `-Force` 自动摘除；
- 幂等：重复执行不重复插入 bundles，联接点指向一致则不重建。

### 5. 新增 `test/run-all.mjs`

上游 `npm test` 是 `node a && node b && ...` 串联，任一条挂了看不到汇总。
现在 `node test/run-all.mjs` 逐条跑并汇总断言数，`verify-password.mjs`（需交互）默认跳过。

### 6. 新增 `docs/LF-FAQ.md`

CRLF 问题的排查三步法、修复命令、以及为什么 `.cmd` 不能改成 LF。

## 验证

```
node test/run-all.mjs
  smoke-host.mjs          通过 62 / 失败 0
  smoke-splash.mjs        通过 60 / 失败 0
  smoke-client.mjs        通过 43 / 失败 0
  smoke-desktop-boot.mjs  通过 46 / 失败 0
  new-options.mjs         通过 75 / 失败 0
  ─────────────────────────────────
  合计：通过 286 项断言，失败 0 项
```

## 安装

```powershell
git clone https://github.com/TomCatV/dsh-startup-secret.git
cd dsh-startup-secret
pwsh -File .\install.ps1            # 若装有旧版 dsh-startup-screen，加 -Force
```

或双击仓库里的 `安装.cmd`（GBK + CRLF，保持上游原样）。

## 二次开发定制

改文案、换立绘、加音色、改分镜、企业内网适配 → **QQ 2363984977**
