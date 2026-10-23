## 本版更新（1.5.0）

### GitHub 一键安装

现在可以直接从 GitHub 安装插件，无需先下载或解压 `.tgz`：

```bash
dsh plugin --profile web add github:huzhengcai471-crypto/dsh-startup-secret
```

桌面端将 `web` 替换为 `desktop`。安装后重启 DSH 即可。

### 安装文档重整

- 明确当前 DSH 会在 `plugin add` 后自动登记 `dsh.profile.bundles`
- 将旧版 DSH 需要手工补写 bundle 的内容改为故障排查步骤
- 保留离线 `.tgz` 安装脚本和不用 pnpm 的手工安装方式

### 验证

- 现有测试全部通过
- 本机 DSH web profile 实际安装并显示启动动画
- 本机 DSH desktop profile 完成依赖安装与 bundle 登记
