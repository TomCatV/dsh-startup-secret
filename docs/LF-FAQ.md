# 换行符 FAQ · LF-FAQ

## 为什么我 clone 下来测试挂了一条？

症状：

```
$ node test/new-options.mjs
  FAIL replay 走 replayLatest（先 refresh 再 injectSelf）
  通过 74 / 失败 1
```

先确认是不是换行符问题：

```powershell
node -e "const b=require('fs').readFileSync('lib/splash.js');let n=0;for(let i=0;i<b.length-1;i++)if(b[i]===13&&b[i+1]===10)n++;console.log('CRLF=',n,'bytes=',b.length)"
```

正常应该是：

```
CRLF= 0 bytes= 2086976
```

如果打出 `CRLF= 1847 bytes= 2088823`，就是 Git 把 LF 转成了 CRLF。

## 原因

`core.autocrlf=true`（Git for Windows 安装时常见的默认选项）会在 checkout 时
把所有文本文件的 LF 换成 CRLF。上游 `.gitattributes` 原先只钉了 `*.cmd / *.sh`，
`lib/*.js` 没有约束，于是被转成了 CRLF。

浏览器能跑（JS 引擎容忍 CRLF），但按字节精确匹配的断言会挂，
且源码与发布 tarball 不再逐字节一致，没法用 SHA256 对账。

## 修法一：本仓库已修（推荐）

本仓库 `.gitattributes` 已给 `*.js / *.mjs / *.json / *.yml / *.md / *.css / *.html / *.ps1` 加了
`text eol=lf`。**重新 clone 就是干净的 LF，不需要你做任何事。**

## 修法二：修好已有的工作副本

不想重新 clone：

```powershell
# 1. 让 Git 按新的 .gitattributes 重新落盘
git rm --cached -r . -q
git reset --hard -q
git checkout -- .

# 2. 复查
node -e "const b=require('fs').readFileSync('lib/splash.js');let n=0;for(let i=0;i<b.length-1;i++)if(b[i]===13&&b[i+1]===10)n++;console.log('CRLF=',n)"
```

## 修法三：关掉 autocrlf

```powershell
git config --global core.autocrlf false
```

注意这会**全局**生效，可能影响你其它仓库的行为，按需使用。

## 为什么 `.cmd` 不能一起改成 LF

`安装.cmd` 必须同时满足 GBK 编码 + CRLF 换行，两个条件少一个就会在别人的机器上静默失败：

- 纯 LF：`cmd.exe` 解析多行 `if (...)` / `for %%f in (...)` 块时会当成一行；
- UTF-8：`cmd.exe` 按字节数定位下一行时会丢同步，表现为 echo 被吞、变量被吃（`%PROFILE%` 消失）。

所以 `.gitattributes` 里对 `*.cmd / *.bat` 用的是 `-text`（禁止 Git 做任何转换），
这不是漏配，是刻意设计。改了就坏。

## 插件跑起来其实不受影响

CRLF 只影响源码级断言。浏览器加载 `splash.js` 时 JS 引擎会正常跳过 `\r`，
启动动画的表现与 LF 版本完全一致。只是为了保证「clone 下来即可信」，
本仓库才把它钉死。
