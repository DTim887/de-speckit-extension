# de-speckit-extension

DE 的组织级 Spec Kit 扩展。它的存在是为了让 DE 特有的约定和治理检查
能够随标准 spec-kit 工作流自动运行，不需要每个团队自己在项目里重新定义
一遍。

一个 [Spec Kit](https://github.com/github/spec-kit) 扩展。

## 命令

| 命令 | 说明 |
|------|------|
| `speckit.de-speckit-extension.read-jira-ticket` | 通用 JIRA 门槛：从被挂载的核心命令的自然语言输入里找出 `SHDRP-<number>` 引用，拉取其 description 作为上下文；可挂载在 spec-kit 任意 `before_*`/`after_*` 生命周期事件上 |
| `speckit.de-speckit-extension.figma-implement-design` | 通过 Figma MCP 服务器，把 Figma 设计稿转换成与设计 1:1 还原的可用代码 |

## Hooks

`speckit.de-speckit-extension.read-jira-ticket` 是一个**通用命令**，挂在
全部 18 个核心生命周期事件上（9 个阶段 × `before_`/`after_`：
constitution、specify、clarify、plan、tasks、implement、checklist、
analyze、taskstoissues），全部 `optional: false`（见
`extension.yml`）——核心引擎始终会尝试触发它。它不依赖写死的事件列表，
`extension.yml` 挂载哪些事件都不需要改这个命令文件本身。

- `before_X`：在核心命令 `X` 执行前拦截，把 ticket description 注入其
  输入。
- `after_X`：`X` 已经执行完了，改为把 ticket description 交付给
  后续步骤（同事件的下一个 hook，或用户接下来要跑的下一个生命周期
  命令）作为上下文。

每个事件是否**强制**要求一个合法的 `SHDRP-<number>` 引用（找不到时
`before_X` 阻断 `X` 本身、`after_X` 阻断"下一步"），由
`de-speckit-extension-config.yml` 里 `jira_gate.<event>.enabled` 单独
控制；一旦输入里出现了 ticket 引用，无论开关状态如何，它都必须真实
有效。完整行为见对应命令文件。

## 配置

`config-template.yml` 里的 `jira_gate` 控制上述 18 个事件各自是否强制
要求 JIRA ticket，默认全部为 `true`（强制）。项目可以按需在
`.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`
里把某个事件改成 `false`，让它变成"有 ticket 就用，没有也放行"。

## 安装

内部扩展 —— 直接从我们内部 Git host 上的 release 归档安装（没有在官方
Spec Kit catalog 上架）：

```bash
specify extension add de-speckit-extension \
  --from https://github.com/DTim887/de-speckit-extension/archive/refs/tags/v0.3.1.zip
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

分两种情况：输入里完全没有 ticket 引用时，是否阻断由
`jira_gate.<event>.enabled` 决定；但只要输入里出现了格式合法的 ticket
key，它的校验/拉取失败（不存在、认证失败、网络错误、description 为空
等）就没有优雅降级，一律硬阻断。详见对应命令文件里的"优雅降级"章节。

## 发布新版本

1. 在 `extension.yml` 里升级 `version`（遵循 semver），并在
   `CHANGELOG.md` 里加一条记录。
2. 打 tag 并推送：`git tag vX.Y.Z && git push --tags`。
3. 给这个 tag 创建一个 release —— `specify extension add ... --from <url>`
   指向的就是这个 release 归档的 zip URL。
