# 变更日志

本项目所有值得关注的变更都会记录在这个文件里。

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
