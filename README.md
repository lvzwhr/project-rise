# Project Rise

法环式 ARPG **战斗验证** demo。不做完整游戏。

引擎：本机 Godot **4.7.2**（`D:\godot\Godot_v4.7.2-stable_win64.exe`），GDScript。

## 团队

这个仓库里有三个专用子代理，主对话扮演制作人，负责分派和验收。

| 角色 | 子代理 | 负责 |
| --- | --- | --- |
| 设计师 | `combat-designer` | 战斗规则、招式表、数值、验收 |
| 程序员 | `combat-programmer` | Godot 战斗框架、判定、Debug |
| 美术 | `combat-artist` | 可读性、占位模型、动画时间轴、预警特效 |

怎么查看这三人、怎么下令、怎么盯进度和验收：见 `docs/WORKFLOW.md`。

## 怎么用

在 Cursor Agent 聊天里直接说，例如：

- `开工` 或 `/kickoff` — 先出设计，再并行程序和美术
- `让设计师出玩家招式表`
- `让程序把翻滚无敌帧接上`
- `让美术补敌人砸地的预警`

新开一个 Agent 会话后，制作人会按 `.cursor/rules/` 自动把活分给这三人。

## 目录

- `docs/PROJECT.md` — 范围和成功标准
- `docs/TEAM.md` — 分工和并行规则
- `.cursor/agents/` — 三人的角色提示词
