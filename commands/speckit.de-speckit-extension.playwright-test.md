---
description: "对当前 feature（.specify/feature.json 记录的那一个）已完成的实现，调用 Playwright Test Agents 的 Planner/Generator 自动生成并执行端到端测试，输出测试计划、测试代码与测试报告的路径；要求本机已安装 Playwright Test Agents，且 implement 全部任务已完成"
---

# Playwright 自动化测试

对当前已完成实现的 feature，调用 [Playwright Test Agents](https://playwright.dev/docs/test-agents)
的 Planner 和 Generator 两个 sub agent，自动生成一份测试计划、把它转成可执行的
Playwright 测试代码，再实际跑一遍，产出测试报告。定位是"针对这个 feature
自动跑一轮端到端测试"，依赖本机已经装好 Playwright Test Agents（`.claude/agents/playwright-test-planner.md`
/ `playwright-test-generator.md`），本命令不负责安装它们，也不调用 Healer 做自动修复。

## 用户输入

$ARGUMENTS

本命令**不消费** `$ARGUMENTS`——无论用户输入什么，一律忽略，恒定只处理当前
feature（见下方"第 1 步"）。不支持通过参数指定其他 feature；要为别的 feature
跑，先切到那个 feature（更新 `.specify/feature.json`/`SPECIFY_FEATURE`），再
调用本命令。

## 命令边界

- 只做手动调用，不挂载任何 `before_*`/`after_*` 生命周期 hook——不会自动
  触发，需要在 implement 完成后自己调用。
- 忽略任何输入参数，只针对"当前 feature"执行，不支持一次调用指定其他 feature。
- 要求 implement **全部**任务已完成（`tasks.md` 里不存在任何 `[ ]`）才会执行；
  只要有一个任务还没完成，就整体硬阻断，不做部分处理。
- 要求本机已经通过 `npx playwright init-agents --loop=claude`（或等价方式）
  装好 Playwright Test Agents；没装就终止报错，不负责代为安装。
- 只编排 Planner → Generator → 实际执行测试这一条链路，不调用 Healer，
  生成的测试代码里有 bug 不会自动修复。
- 测试计划、测试代码、测试报告统一按当前 feature 的目录隔离存放（见第 4-6
  步），不用 Playwright 官方默认的项目根级路径，避免和别的 feature、和
  spec-kit 自己的 `specs/<slug>/` 混在一起。

## 手动调用

```text
/speckit.de-speckit-extension.playwright-test
```

不接受、也不解析任何参数——即使用户在命令后附带了文本，也按无参数处理。

## 执行步骤

### 第 1 步：定位 feature 目录，确认 implement 已全部完成

从项目根目录运行：

```bash
.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks
```

解析出 `FEATURE_DIR`（绝对路径），记 `FEATURE_SLUG=$(basename "$FEATURE_DIR")`
（如 `003-category-nav-menu`）。这个脚本内部读取 `SPECIFY_FEATURE`/
`.specify/feature.json` 确定"当前 feature"，本命令不自己解析 `feature.json`，
也不提供覆盖当前 feature 的方式。

- 脚本因为 `tasks.md` 不存在（`--require-tasks`）或其他原因非零退出：
  停止，原样展示脚本的错误信息。
- 读 `<FEATURE_DIR>/tasks.md` 里的全部任务行。只要存在任意一条 `[ ]`
  未完成任务，就说明 implement 还没跑完：**停止**，提示用户"这个
  feature 还有未完成的任务，请先跑完 speckit-implement 的全部任务再运行
  本命令"——不生成任何文件，不做部分处理。

### 第 2 步：确认 Playwright Test Agents 环境就绪

依次检查，任一条件不满足都**立即终止**，不进入后续步骤：

- `.claude/agents/playwright-test-planner.md` 是否存在（相对项目根目录）。不存在：报错
  "未检测到 Playwright Test Agents 的 planner，请先运行
  `npx playwright init-agents --loop=claude` 完成安装"，终止。
- `.claude/agents/playwright-test-generator.md` 是否存在。不存在：报错提示同上，终止。
- 运行 `npx playwright --version`。非零退出：报错"`npx playwright`
  无法运行，请检查 Playwright 是否已正确安装"，终止。

三项全部通过后才进入第 3 步。

### 第 3 步：读取并提炼测试上下文

从 `<FEATURE_DIR>` 和项目源码里提炼一份喂给 Planner 的上下文，不是原文照搬
整篇文档：

- **`spec.md`**（不存在则跳过，不阻断）：提炼验收场景（Acceptance
  Scenarios）、User Story、边界条件——这些直接对应 Planner 要探索的用户
  行为路径。
- **`plan.md`**（不存在则跳过，不阻断）：提炼技术栈、涉及的页面/路由/
  关键组件、对外部服务的依赖——帮 Planner 判断去哪探索、要不要 mock 什么。
- **项目根 `.specify/memory/constitution.md`**（不存在则跳过，不阻断）：
  只挑其中跟测试相关的项目级规范（如果有的话），跟测试无关的内容不需要
  纳入。
- **`tasks.md`**：从每条已完成任务的描述里提取精确文件路径，作为"这个
  feature 改了哪些文件"的唯一权威来源——**不用** `git diff`/`git log`
  （目标项目不一定是 git 仓库，即使是也保持行为一致）。任务没有清晰列出
  文件路径的，跳过，不凭空猜测。
- 对上一步收集到的文件逐一读取实际代码，重点看 UI 组件、路由、API
  contract——这是 Planner 探索"应用该怎么跑起来"最直接的依据。

### 第 4 步：调用 Planner，生成测试计划

用 Task/Agent 工具，以 `.claude/agents/playwright-test-planner.md` 里定义的 agent 名称
（通常是 `playwright-test-planner`）作为 subagent 分派任务，输入是第 3 步提炼出的上下文，
并**明确指示**：把生成的测试计划写到

```
<FEATURE_DIR>/playwright/test-plan.md
```

而不是 Playwright 官方默认的项目根级 `specs/<场景名>.md`——这是为了不跟
spec-kit 自己的 `specs/<slug>/` 混在一起。

Planner 执行异常/失败：原样展示错误信息，**终止**，不调用 Generator。

### 第 5 步：调用 Generator，生成测试代码

Planner 成功产出 `<FEATURE_DIR>/playwright/test-plan.md` 后，自动用 Task/
Agent 工具以 `.claude/agents/playwright-test-generator.md` 里定义的 agent 名称（通常是
`playwright-test-generator`）分派任务，输入是第 4 步产出的测试计划文件，并**明确指示**：
把生成的测试代码写到

```
tests/<FEATURE_SLUG>/
```

而不是 Playwright 官方默认的项目根级 `tests/`——同一个项目里多个 feature
分别跑本命令时，各自的测试代码不会互相覆盖。

Generator 执行异常/失败：原样展示错误信息，**终止**，不执行测试。

### 第 6 步：执行测试，产出报告

只跑刚生成的这个 feature 的测试，不跑项目里其他已有的 Playwright 测试：

```bash
PLAYWRIGHT_HTML_REPORT="<FEATURE_DIR>/playwright/report" \
  npx playwright test "tests/${FEATURE_SLUG}/" \
  --reporter=html \
  --output="<FEATURE_DIR>/playwright/report/artifacts"
```

**退出码非零不等于命令失败**——`npx playwright test` 只要有用例没通过就会
非零退出，这属于正常的测试结果，不是硬阻断条件，继续走到第 7 步正常展示。

只有当报告本身没能生成（`<FEATURE_DIR>/playwright/report` 目录没有产出，
比如生成的测试代码有语法错误、配置错误导致 Playwright 直接跑不起来）时，
才当成真正的执行失败：原样展示 stderr，**终止**。

### 第 7 步：收尾报告

汇总展示给用户：

- 测试计划路径：`<FEATURE_DIR>/playwright/test-plan.md`
- 生成的测试代码路径：`tests/<FEATURE_SLUG>/`
- 测试报告路径：`<FEATURE_DIR>/playwright/report/`
- 本次执行的通过/失败用例数（从第 6 步的输出里提取）

## 执行

- **Bash**：
  - `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks`
  - `npx playwright --version`
  - `PLAYWRIGHT_HTML_REPORT="<FEATURE_DIR>/playwright/report" npx playwright test "tests/<FEATURE_SLUG>/" --reporter=html --output="<FEATURE_DIR>/playwright/report/artifacts"`
- **Agent/Task 调用**：
  - Planner（agent 名称取自 `.claude/agents/playwright-test-planner.md`）
  - Generator（agent 名称取自 `.claude/agents/playwright-test-generator.md`）

## 优雅降级

- `tasks.md` 里存在任意 `[ ]` 未完成任务：停止，提示先跑完
  `speckit-implement` 的全部任务——这是硬阻断，没有优雅降级。
- `.claude/agents/playwright-test-planner.md` 或 `.claude/agents/playwright-test-generator.md` 缺失、或
  `npx playwright` 跑不起来：停止，提示用户先完成 Playwright Test Agents
  的安装/环境配置——没有优雅降级，本命令不代为安装。
- `spec.md`/`plan.md`/项目 `constitution.md` 不存在：不阻断——第 3 步跳过
  对应文档的提炼，只用能拿到的信息继续执行。
- 已完成任务列出的文件本身不存在（比如后来被删除/改名）：跳过该文件，
  不中断整个流程。
- Planner 或 Generator 执行异常/失败：没有优雅降级，原样展示错误信息，
  终止，不进入下一步。
- `npx playwright test` 跑到报告都没能生成（脚本层面的失败，比如生成的
  测试代码语法错误）：没有优雅降级，原样展示 stderr，终止。
- `npx playwright test` 正常跑完但存在失败用例：**不阻断**——当成正常的
  测试结果，连同报告路径一起展示给用户，不是命令执行失败。
