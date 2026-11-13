# 与 acceptance.md 的缺口

`game/` 在 Godot 4.7.2 下无头启动成功（`--quit-after 1`）。下面的勾选**还没**在竞技场里由人打过。制作人/设计师仍需按 `acceptance.md` 实机过一遍。

## A–P（缺的是试玩，不是系统）

冻结 GDD 要求的 v1 系统都已实现：lock-on、三连 Light、Heavy / ChargedHeavy、跳跃 + JumpAttack、RunningAttack、翻滚 i-frame f4–16、stamina / Exhaust / 冲刺踉跄、格挡 180° / GuardHit / GuardBreak、敌人 Sweep / Thrust / Slam（预警 f8 地面红圈）/ DoubleSlash、stance 击破 90f + Riposte 380、Wakeup stance 40、死亡 2s 重置、Debug HUD。

在有人按清单打完之前，A–P 视为**未验证**，不是没做。

## 已知占位 / 偏差

| 项 | 说明 |
| --- | --- |
| 美术 AnimationPlayer 方法轨 | 战斗用帧计数器。clip 只播姿势。方法轨接到 sink，避免双发。 |
| 方法轨加载报错 | 实例化 Visual 时，同一时刻放了两个 method key 的 clip 会打 `track_set_key_transition` 越界日志（Heavy 的 `hit_off`+`hyperarmor_off`、ChargedHeavy_Release、Slam）。非致命。美术可以把同一时刻拆开 1 tick；不要改设计表帧数。 |
| 击退距离 | 设计表没写。运行时只有很小的推挤，方便测间距。 |
| 跳跃高度 | 帧数冻结；高度由重力 50 和 10f 起跳得到（约 0.7 m）。 |
| Riposte 相机 | Riposte 时弹簧臂轻微推进（≤ 可选 20f）。验收不要求。 |
| Exhaust「喘气」 | Exhaust / GuardBreak 只有姿势。没有额外 VFX 或音效。 |
| 未锁定时的手柄相机 | 加了右摇杆看向，方便手柄不 lock-on 也能打。不是新招式。 |
| 判定线框 | 按设计形状画的 debug 网格 + F2。不只靠 Godot 编辑器碰撞视图。 |
| 根运动 | 美术 Hip 键只服务姿势。位移由 CharacterBody3D 走（翻滚 4.2 m、突刺、垫步）。 |

## 需要人打的验收

优先对照手感目标 F-ID（括号内）：

- C / F41–F42 — Light 连段只走 `can_buffer`；10f 记忆
- D / F5、F21 — 点按 vs 蓄力；Heavy 在 hyperarmor 期间和 Sweep 对撞
- F / F8–F11 — i-frame 窗口对 Slam
- G / F12、F16 — 5 次翻滚 → Exhaust；冲刺耗尽是 12f 踉跄
- H / F18–F19 — 正面格挡、背后仍挨打、进攻方不被格挡硬直
- K — Slam 预警 f8 红圈，绿色后摇可罚
- M / F28–F32 — stance 表、90f 跪地、Riposte 距离、Wakeup 40
- P — HUD 关掉后，颜色 + 轮廓仍可读

## 范围外（必须继续没有）— Q

无背包、弹反、战技、法术、状态异常、第二个敌人、跳跃 i-frame、额外闪避。动画事件只有冻结的那七个名字。

## 仍归设计 / 美术

- 最终网格 / PBR — 美术占位在 `game/assets/`
- clip 方法轨同一时刻双 key — 美术
- 任何数值改动 — 先改 `docs/design/`
