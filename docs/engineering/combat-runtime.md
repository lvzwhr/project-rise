# 战斗运行时

Godot **4.7.2** GDScript 沙盒。数值以 `docs/design/` 为准，不要在代码里私自改手感。

## 怎么运行

指定引擎：

```
D:\godot\Godot_v4.7.2-stable_win64.exe --path D:\project\project-rise\game
```

或在 Godot 里 Import `game/project.godot`。主场景：`res://scenes/arena.tscn`。

无头冒烟（本机若还没有 `.godot/` 缓存，先 `--import` 一次）：

```
D:\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\project\project-rise\game --quit-after 1
```

第一次在没缓存的机器上打开：先 `--import`，让全局类（`AttackData`、`PlayerKnight` 等）注册。

物理 60 FPS。进入游戏会捕获鼠标。**Esc** / **Tab** 释放。

## 目录

| 路径 | 作用 |
| --- | --- |
| `game/scripts/attack_data.gd` + `move_db.gd` | 冻结的 v1 `AttackData` |
| `game/scripts/combat_actor.gd` | HP、七个事件、命中检测、美术 Visual 挂接 |
| `game/scripts/player.gd` | 玩家状态机、stamina、lock-on、buffer |
| `game/scripts/enemy_knight.gd` | 敌人状态机 + AI |
| `game/scripts/arena.gd` | CSG 竞技场、出生点、死亡 2s 重置 |
| `game/scripts/debug_hud.gd` | 默认开启的 Debug HUD |
| `game/assets/` | 美术所有。作为 `Visual` 子节点实例化，程序不覆盖 |

战斗时机由**帧计数器**调用 `hit_on` / `hit_off` / `iframe_on` / `iframe_off` / `hyperarmor_on` / `hyperarmor_off` / `can_buffer`。美术 clip 只播姿势。方法轨被接到 sink，避免和计数器双发。

## 输入

开机时在 `boot.gd` 注册。动作名与 `player-moveset.md` 一致。

| 动作 | 键盘 | 手柄 |
| --- | --- | --- |
| 移动 | WASD | 左摇杆 |
| Light | LMB | 西键（X / Square） |
| Heavy | RMB | 北键（Y / Triangle） |
| Roll | Space | 东键（B）点按 |
| Run | 按住 Shift，或摇杆向前 ≥ 0.85 持续 10f | 东键长按（点按翻滚那一帧之后） |
| Guard | Ctrl 或 Q | LT / L2 |
| Jump | V | 南键（A / Cross） |
| lock-on | 中键或 C | R3 |
| 相机（未锁定） | 鼠标 | 右摇杆 |

蓄力 Heavy = 按住 Heavy ≥ 20f（48f 自动放出）。RunningAttack = 在 `Run` 里 ≥ 8f 后按 Light 或 Heavy。Riposte = 敌人处于 `StanceBroken` 且平面距离 ≤ 2.2 m 时按 Light 或 Heavy。

## 玩家状态（GDD 4.2）

`Idle`、`Walk`、`Run`、`Light1`、`Light2`、`Light3`、`Heavy`、`ChargedHeavy`、`Jump`、`JumpAttack`、`RunningAttack`、`DodgeRoll`、`Guard`、`GuardHit`、`GuardBreak`、`Exhaust`、`Hitstun`、`Riposte`、`Death`

startup / active 不能取消成翻滚或格挡。buffer（记忆 10f）只在 `can_buffer` 为真时消耗。Idle / Walk 始终收输入。Light3 的 buffer 不会循环回 Light1，要等回 Idle。

## 敌人状态（GDD 4.3）

`Idle`、`Walk`、`Sweep`、`Thrust`、`Slam`、`DoubleSlash1`、`DoubleSlash2`、`Hitstun`、`StanceBroken`、`Wakeup`、`Death`

AI：距离 > 5 m 走近；一套结束后 45f 喘息；加权选招；Slam CD 180f，Thrust 90f，DoubleSlash 90f；同一招连放会重抽（Sweep 可重复）。Wakeup 后 stance 回到 **40**，不是 100。

## 层级

1 世界 · 2 玩家身体 · 3 敌人身体 · 4 玩家 hit · 5 敌人 hit · 6 玩家 hurt · 7 敌人 hurt

判定体积来自 `AttackData`（弧 / 胶囊 / 圆柱），只在 `hit_on` 到 `hit_off` 之间启用。每次攻击对同一目标只打中一次。i-frame 期间完全跳过命中。

## Debug 键

HUD 默认 **开**。线框默认 **开**。

| 键 | 作用 |
| --- | --- |
| **F1** | 开关 Debug HUD |
| **F2** | 开关 hitbox / hurtbox 线框 |
| **F3** 或 **R** | 双方回出生点（满 HP / stamina / stance 100） |
| **Esc** / **Tab** | 开关鼠标捕获 |

HUD — 玩家：HP、stamina、回能延迟帧、状态、阶段、本地帧、iframe、hyperarmor、can_buffer、lock-on 距离。  
HUD — 敌人：HP、stance、状态/招式、阶段、帧、hyperarmor、StanceBroken 剩余、距离带、Slam/Thrust/DoubleSlash CD。  
底部：上次伤害 / stance / 是否格挡、线框开关。

## 竞技场

约 20 m 宽（半径 10 m），围栏，玩家出生 `z=+5.2`，敌人 `z=-5.2`。任一方死亡 → 2s → 双方在出生点回满。没有菜单。

## 调手感

先改 `docs/design/`，再改 `move_db.gd` / `combat_consts.gd` 里对应字段。不要加弹反、道具、菜单、第二个敌人、玩家 stance 条、跳跃 i-frame。
