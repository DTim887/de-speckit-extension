# de-speckit-extension

DE 的组织级 Spec Kit 扩展。它的存在是为了让 DE 特有的约定和治理检查
能够随标准 spec-kit 工作流自动运行，不需要每个团队自己在项目里重新定义
一遍。

一个 [Spec Kit](https://github.com/github/spec-kit) 扩展。

## 命令

| 命令 | 说明 |
|------|------|
| `speckit.de-speckit-extension.read-jira-ticket` | 拉取 JIRA ticket（`SHDRP-<number>`）的 description 作为纯文本；同时把 `/speckit.specify` 挂在一个合法 ticket 引用上作为门槛 |
| `speckit.de-speckit-extension.figma-implement-design` | 通过 Figma MCP 服务器，把 Figma 设计稿转换成与设计 1:1 还原的可用代码 |

## Hooks

`before_specify` 挂在 `speckit.de-speckit-extension.read-jira-ticket` 上，
`optional: false`（见 `extension.yml`）—— 每次运行 `/speckit.specify`
都必须带一个开头的 `SHDRP-<number>` ticket key，否则会被阻断。完整行为
见对应命令文件。

## 配置

目前没有可配置项。`config-template.yml` 是留给这个扩展以后新增命令用的
stub；现在没有任何东西会读它。

## 安装

内部扩展 —— 直接从我们内部 Git host 上的 release 归档安装（没有在官方
Spec Kit catalog 上架）：

```bash
specify extension add de-speckit-extension \
  --from https://github.com/DTim887/de-speckit-extension/archive/refs/tags/v0.3.0.zip
```

针对本仓库的本地检出做本地开发：

```bash
specify extension add de-speckit-extension --dev /path/to/de-speckit-extension
```

## 禁用

```bash
specify extension disable de-speckit-extension
specify extension enable de-speckit-extension
```

## 优雅降级

没有 —— 这是故意的。`speckit.de-speckit-extension.read-jira-ticket` 是一个
强制门槛：ticket key 缺失/格式不对、凭证缺失，或任何 Jira API 调用失败，
都会用明确的错误信息阻断 `/speckit.specify`，而不是悄悄跳过。详见对应
命令文件里的"优雅降级"章节。

## 发布新版本

1. 在 `extension.yml` 里升级 `version`（遵循 semver），并在
   `CHANGELOG.md` 里加一条记录。
2. 打 tag 并推送：`git tag vX.Y.Z && git push --tags`。
3. 给这个 tag 创建一个 release —— `specify extension add ... --from <url>`
   指向的就是这个 release 归档的 zip URL。
