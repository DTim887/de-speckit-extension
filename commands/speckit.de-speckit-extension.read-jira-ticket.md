---
description: "拉取 JIRA ticket 的 description 并作为 /speckit.specify 的上下文；同时作为强制的 before_specify 门槛挂载"
scripts:
  sh: ../../scripts/bash/read-jira-ticket.sh
---

# 读取 JIRA Ticket

从 `https://disneyexperiences.atlassian.net` 拉取某个 JIRA ticket 的
`description` 字段，并渲染成纯文本（保留段落换行；不做 Markdown 格式化；
表格/列表不做特殊渲染）。

## 用户输入

$ARGUMENTS

## 手动调用

直接带 ticket key 调用：

```text
/speckit.de-speckit-extension.read-jira-ticket SHDRP-437322
```

- `$ARGUMENTS` 必须是一个匹配 `^SHDRP-[0-9]+$` 的单一 ticket key
  （例如 `SHDRP-437322`）。其他任何形式都算校验错误 —— 停下并报错，
  不要去调用脚本。

## 作为 Hook 调用（强制 `before_specify` 门槛）

这个命令同时注册在 `before_specify` hook 上，`optional: false`（见
`extension.yml`），所以每次触发 `/speckit.specify` 时都会自动、无条件
地运行 —— 每份 spec 都必须落在一个真实的 JIRA ticket 上。

作为 hook 触发时（不是用户直接调用），没有 hook 传入的参数，所以：

1. 查看用户最近一次的 `__SPECKIT_COMMAND_SPECIFY__` 调用，取其参数里
   **第一个以空白分隔的 token** 作为候选 ticket key。
2. 用 `^SHDRP-[0-9]+$` 校验它。
   - 如果缺失或格式不对：**停止**。不要运行
     `__SPECKIT_COMMAND_SPECIFY__`。告诉用户 `/speckit.specify` 需要
     一个开头的 JIRA ticket key，格式为 `SHDRP-<数字>`（例如
     `SHDRP-437322`）。
3. 用校验通过的 ticket key 运行脚本（见下方"执行"）。
4. 如果脚本以**任何**原因非零退出（凭证错误、网络错误、ticket 不存在、
   description 为空等）：**停止**。不要运行
   `__SPECKIT_COMMAND_SPECIFY__`。把脚本的 stderr 信息原样展示给用户。
5. 如果脚本执行成功，取其 stdout（作为纯文本的 ticket description），
   作为附加上下文用于运行 `__SPECKIT_COMMAND_SPECIFY__` —— 把它放在
   用户原始参数之前，让生成 spec 时能看到真实的 ticket 内容。

## 执行

- **Bash**：`.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY>`

需要在环境变量里配置 `ATLASSIAN_EMAIL` 和 `ATLASSIAN_API_TOKEN`（这个
组织已经统一配好了）。如有需要，`ATLASSIAN_BASE_URL` 可以覆盖默认的
`https://disneyexperiences.atlassian.net`。

## 优雅降级

没有 —— 这是故意的。这个命令支撑的是一条强制策略：没有 JIRA ticket，
就没有 spec。任何失败 —— ticket key 格式不对、凭证缺失、网络/认证错误、
ticket 不存在，或 description 为空 —— 都必须阻断 `/speckit.specify`
继续执行，并向用户展示明确的错误信息。
