# 变更日志

本项目所有值得关注的变更都会记录在这个文件里。

## [0.4.0] - 2026-08-24

### 变更

- 把 `speckit.de-speckit-extension.read-jira-ticket` 从只挂在
  `before_specify` 上，扩展成一个真正通用的 JIRA 门槛：命令文件内部
  不再用写死的"事件 → 核心命令 → token"表格，改成从事件名（去掉
  `before_`/`after_` 前缀）直接推导对应的核心命令和
  `__SPECKIT_COMMAND_*__` token，因此可以挂载在 spec-kit 任意
  `before_*`/`after_*` 事件上，不需要为新事件改这个文件。
- `extension.yml` 相应地把它挂到了全部 18 个核心生命周期事件上（9 个
  阶段 × before/after：constitution、specify、clarify、plan、tasks、
  implement、checklist、analyze、taskstoissues）。`before_X` 在 `X`
  执行前拦截并注入 ticket description；`after_X` 时 `X` 已执行完，
  改为把 description 交付给后续步骤（同事件下一个 hook，或用户接下来
  要跑的下一个生命周期命令）作为上下文，找不到 ticket 时阻断的是
  "下一步"而不是已完成的 `X`。
- 新增 `config-template.yml` 里的 `jira_gate.<event>.enabled` 开关：
  每个事件可以单独控制"找不到 ticket 时是否阻断"，模式参考官方
  `git` 扩展的 `auto_commit` 配置。ticket 一旦被找到，其校验/拉取
  失败仍然一律硬阻断，不受这个开关影响。

## [0.3.1] - 2026-08-24

### 变更

- 新增项目规则（`CLAUDE.md`）：本仓库所有输出文档一律使用中文撰写，
  YAML 结构字段名、命令名、文件路径等技术标识符除外。
- 按这条规则，把 `README.md`、`CHANGELOG.md`、`extension.yml` /
  `config-template.yml` 里的注释和 `description` 类字段值，以及两个
  命令文件的正文，全部翻译成中文。

## [0.3.0] - 2026-08-21

### 新增

- 新增 `speckit.de-speckit-extension.figma-implement-design`：通过 Figma
  MCP 服务器，把 Figma 设计稿转换成与设计 1:1 还原的可用代码。

## [0.2.0] - 2026-08-19

### 变更

- 移除了通用的 `speckit.de-speckit-extension.hook` 脚手架命令（及其
  bash/PowerShell 脚本），原本它挂在所有 `before_*`/`after_*` 生命周期
  事件上。
- 新增 `speckit.de-speckit-extension.read-jira-ticket`：拉取 JIRA
  ticket（`SHDRP-<number>`，来自公司的 Jira Cloud 实例）的 description，
  并把 `/speckit.specify` 挂在一个合法 ticket 引用上作为门槛 ——
  强制执行（`optional: false`），失败时不做优雅降级。
- 把 `config-template.yml` 简化成一个 stub；随着按事件启用/禁用的旧
  脚手架被移除，现在已经没有可配置项了。

## [0.1.0] - 2026-08-16

### 新增

- 初始扩展脚手架：`extension.yml`、配置模板，以及挂在所有
  `before_*`/`after_*` 生命周期事件上的共享 hook 命令。
