# 转载声明 · CREDITS

## 上游原作者

本仓库是**二次转载 + 二次优化版**，全部原始创意、视觉设计、文案与音视频素材的著作权归原作者所有。

| 项目 | 上游仓库 | 上游作者 |
|---|---|---|
| 启动动画插件 `dsh-startup-secret` | <https://github.com/huzhengcai471-crypto/dsh-startup-secret> | [@huzhengcai471-crypto](https://github.com/huzhengcai471-crypto) |
| 上游上游（原始 `dsh-startup-screen` 系列） | <https://github.com/6shenhonghong9/dsh-startup-screen> | 沈宏宏（package.json `author` 字段署名） |

本仓库锁定的上游基线：

```
repo    huzhengcai471-crypto/dsh-startup-secret
branch  main
commit  c03017be5fed09c56b67f07e93beb109fdfa402a
subject fix: 修复 README 与安装脚本的中文乱码
date    2026-10-29 13:22:34 +0800
version dsh-startup-secret@1.5.2
```

## 我做了什么

**只做工程修复，不改设计、不改文案、不改素材、不加功能。**
视觉风格、徽章/立绘图案、7 款真声音色、全部 mp3 与内联音频数据、动画分镜与文案，均与上游 1.5.2 完全一致，逐字节未改动。

详细对比见 [OPTIMIZATIONS.md](./OPTIMIZATIONS.md)，摘要：

| # | 修复项 | 类型 |
|---|---|---|
| 1 | 补 `lib/**` 等文本文件的 `eol=lf` 属性，防止 CRLF 污染源码 | 跨平台 |
| 2 | 新增 `.editorconfig`，编辑器统一 LF | 跨平台 |
| 3 | 新增 `install.ps1` / `uninstall.ps1`（PowerShell 安装器，含旧插件共存检测） | 安装体验 |
| 4 | 新增 `test/run-all.mjs` 一键跑全部测试并汇总 | 测试 |
| 5 | 新增 `docs/LF-FAQ.md` 说明换行符问题 | 文档 |
| 6 | README 顶部加转载与优化说明区块 | 文档 |

## 二次开发定制

需要改文案、换立绘、加音色、改分镜、做企业内网定制、或把这套启动动画接到别的宿主上：

> **QQ：2363984977**

## 许可

上游为 MIT。本仓库继续以 MIT 发布，见 [LICENSE](./LICENSE)。
MIT 允许再分发与修改，唯一硬性要求是保留原始版权声明 —— 本仓库的 `LICENSE` 与本节声明即为此保留。

## 素材权利

徽章标识、人物立绘、语音素材与界面音效的相关权利归各自原权利人所有。
本仓库**仅随包随发**，不单独抽取分发；如需商用请自行取得授权。
