---
description: "从被挂载的核心命令的自然语言输入里找出 JIRA ticket（SHDRP-<number>），拉取其 description 作为上下文；这是一个通用命令，可以挂载在 spec-kit 任意 before_*/after_* 生命周期事件上"
scripts:
  sh: ../../scripts/bash/read-jira-ticket.sh
---

# 读取 JIRA Ticket

从 `https://disneyexperiences.atlassian.net` 拉取某个 JIRA ticket 的
`description` 字段，并渲染成纯文本（保留段落换行；不做 Markdown 格式化；
表格/列表不做特殊渲染）。

这是一个**通用命令**：既可以手动直接调用，也可以挂载在 spec-kit **任意**
`before_*`/`after_*` 生命周期事件上，作为该事件的 JIRA 门槛使用（见下方
"作为 Hook 调用"）。目前 `extension.yml` 把它挂在了全部 18 个核心生命周期
事件上，但这个命令本身不依赖那份清单——`extension.yml` 里以后新增/减少
挂载的事件，都不需要改这个文件。

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

## 作为 Hook 调用（通用门槛）

作为 hook 触发时（不是用户直接调用这个命令本身），核心引擎不会把任何
参数传给它——触发它的 hook 消息里会写明是哪个事件（例如"Hooks
available for event 'before_plan'"）。按下面的步骤处理：

### 1. 确定事件名和方向

从触发这次调用的 hook 消息里读出事件名，形如 `before_<phase>` 或
`after_<phase>`。

### 2. 推导被挂载的核心命令和重新调用它的 token

**不要用写死的表格去查**——按下面的规则从事件名直接推导（这样这个命令
可以挂在任何 `before_*`/`after_*` 事件上，不需要为新事件更新这个文件）：

- 去掉事件名开头的 `before_` 或 `after_` 前缀，剩下的部分是"阶段名"
  （例如 `before_taskstoissues` → 阶段名 `taskstoissues`）。
- 对应的核心命令是 `speckit.<阶段名>`（例如 `speckit.taskstoissues`）。
- 用于重新调用该命令的 token 是
  `__SPECKIT_COMMAND_<阶段名大写>__`（例如
  `__SPECKIT_COMMAND_TASKSTOISSUES__`）。

当前 `extension.yml` 里挂载的 9 个阶段，供参考：

| 阶段名 | 核心命令 | token |
|---|---|---|
| `constitution` | `/speckit.constitution` | `__SPECKIT_COMMAND_CONSTITUTION__` |
| `specify` | `/speckit.specify` | `__SPECKIT_COMMAND_SPECIFY__` |
| `clarify` | `/speckit.clarify` | `__SPECKIT_COMMAND_CLARIFY__` |
| `plan` | `/speckit.plan` | `__SPECKIT_COMMAND_PLAN__` |
| `tasks` | `/speckit.tasks` | `__SPECKIT_COMMAND_TASKS__` |
| `implement` | `/speckit.implement` | `__SPECKIT_COMMAND_IMPLEMENT__` |
| `checklist` | `/speckit.checklist` | `__SPECKIT_COMMAND_CHECKLIST__` |
| `analyze` | `/speckit.analyze` | `__SPECKIT_COMMAND_ANALYZE__` |
| `taskstoissues` | `/speckit.taskstoissues` | `__SPECKIT_COMMAND_TASKSTOISSUES__` |

### 3. 读取该事件的配置

打开
`.specify/extensions/de-speckit-extension/de-speckit-extension-config.yml`，
读取 `jira_gate.<event>.enabled`（用完整事件名，如
`jira_gate.before_plan.enabled`；缺省时回退到 `jira_gate.default`）。

### 4. 在相关的核心命令输入里找 ticket

- **`before_<phase>` 事件**：查看用户即将/刚刚触发的那次
  `/speckit.<phase>` 调用，取其**完整参数文本**。
- **`after_<phase>` 事件**：`/speckit.<phase>` 已经执行完了，查看它
  **当初被调用时**的完整参数文本。

在这段文本的**任意位置**（不限定在开头）搜索是否存在匹配
`SHDRP-[0-9]+` 的子串。

### 5. 没找到 ticket 时

- 如果第 3 步读到的 `enabled` 为 `true`：
  - `before_<phase>`：**停止**，不要运行对应的 `__SPECKIT_COMMAND_*__`
    token（也就是不放行 `/speckit.<phase>` 本身执行）。
  - `after_<phase>`：`/speckit.<phase>` 本身已经执行完，不回滚它；但
    **阻断下一步**——不要继续执行同一事件里排在后面的其他 hook，也
    不要让用户接下来触发的下一个生命周期命令继续。
  - 两种情况都要告诉用户：这个环节要求相关命令的输入里带一个 JIRA
    ticket 引用，格式为 `SHDRP-<digits>`（例如 `SHDRP-437322`）。
- 如果 `enabled` 为 `false`：不阻断任何东西，流程照常继续（`before_*`
  就正常放行目标命令；`after_*` 就正常往下走），不做任何注入/交付。

### 6. 找到 ticket 时

不管第 3 步的 `enabled` 是 `true` 还是 `false`，只要输入里出现了合法
格式的 ticket key，都要执行这一步：用该 ticket key 运行脚本（见下方
"执行"）。

### 7. 脚本执行结果处理

- 如果脚本以**任何**原因非零退出（凭证错误、网络错误、ticket 不存在、
  description 为空等）：**停止**——`before_<phase>` 不放行目标命令；
  `after_<phase>` 阻断下一步。把脚本的 stderr 信息原样展示给用户。这
  一条不受第 3 步的 `enabled` 开关影响——一旦发现了 ticket 引用，它就
  必须是真实有效的。
- 如果脚本执行成功，取其 stdout（作为纯文本的 ticket description）：
  - `before_<phase>`：作为附加上下文放在用户原始参数之前，一并用于
    运行对应的 `__SPECKIT_COMMAND_*__` token。
  - `after_<phase>`：不重新调用已经跑完的命令；把这段 description 作为
    上下文，交付给后续步骤（同事件里排在后面的下一个 hook，或者用户
    接下来要触发的下一个生命周期命令），供其在需要时使用。

## 执行

- **Bash**：`.specify/extensions/de-speckit-extension/scripts/bash/read-jira-ticket.sh <TICKET-KEY>`

需要在环境变量里配置 `ATLASSIAN_EMAIL` 和 `ATLASSIAN_API_TOKEN`（这个
组织已经统一配好了）。如有需要，`ATLASSIAN_BASE_URL` 可以覆盖默认的
`https://disneyexperiences.atlassian.net`。

## 优雅降级

分两种情况：

- **输入里根本没有 ticket 引用**：是否阻断由该事件在
  `de-speckit-extension-config.yml` 里的 `jira_gate.<event>.enabled`
  决定（见上方"作为 Hook 调用"第 5 步）。`before_*` 阻断的是目标命令
  本身；`after_*` 阻断的是"下一步"，因为目标命令已经执行完了。这是
  唯一存在优雅降级的地方。
- **输入里有格式合法的 ticket key，但校验/拉取失败**（ticket 不存在、
  认证失败、网络错误、description 为空等）：没有优雅降级，一律硬
  阻断，向用户展示明确的错误信息。既然已经声明了要关联某个 ticket，
  它就必须是真实有效的。
