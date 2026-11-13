# 战斗占位 — 程序接线

假定 Godot 工程根是 `game/`，因此这些路径是 `res://assets/...`。

美术拥有本文件夹。**不要** 用这些替换运行时玩家/敌人控制器场景。把视觉作为子节点实例化。

## 实例

```
Player (CharacterBody3D)          # combat_actor.gd — has hit_on() / hit_off() / …
└─ Visual                         # instance res://assets/characters/player_knight_visual.tscn
   └─ AnimationPlayer             # library already assigned; method tracks → ../.. (the actor)

Enemy (CharacterBody3D)
└─ Visual                         # instance res://assets/characters/enemy_knight_visual.tscn
   └─ AnimationPlayer
```

打包场景内根名：`PlayerKnightVisual`、`EnemyKnightVisual`。

朝向：yaw 0 时 **+Z** 向前（与 `combat_actor.get_forward` 一致）。剑在 **+X**。缩放 1。玩家视觉约 1.80 m。敌人视觉约 1.95 m，更宽，**红左肩甲**。实例化本视觉后隐藏或替换程序的胶囊网格，避免颜色混在一起。

当前脚手架在角色上自建 `AnimationPlayer`，用 **帧计数器** 发七个事件。命中窗口继续用它。用 `Visual/AnimationPlayer` 去 `play("Sweep")` 等播姿势。**不要** 让方法轨和计数器 **双触发**。

## AnimationPlayer

默认库（空字符串键）已赋在视觉上：

- 玩家：`res://assets/animation/player_combat.tres`
- 敌人：`res://assets/animation/enemy_combat.tres`

片段名与冻结状态一致。方法轨调用 `NodePath("../..")`（若 Visual 是其子节点，即战斗角色）。

**不要改名** `hit_on`、`hit_off`、`iframe_on`、`iframe_off`、`hyperarmor_on`、`hyperarmor_off`、`can_buffer`。

Slam 地面圆 **不** 在 Slam 片段里。在 Slam **f8** 于 `Visual/Vfx_Feet` 生成 `res://assets/vfx/slam_floor_circle.tscn`。

播放示例：

| 状态 | 片段 |
| --- | --- |
| Light1 | `Light1` |
| Heavy | `Heavy` |
| 蓄力维持 | `ChargedHeavy_Charge`（HOLD 最后姿势；`hyperarmor_on` 在 f12） |
| 蓄力释放 | `ChargedHeavy_Release`（释放时时钟 = 0） |
| 翻滚 | `DodgeRoll` |
| 敌人连段 | `Sweep` / `Thrust` / `Slam` / `DoubleSlash` |
| 或拆 DS | `DoubleSlash1` 然后 `DoubleSlash2` |
| 跪 | `StanceBroken`（90 f HOLD） |

`can_buffer` 在窗口开始触发一次；标志保持 true 直到状态退出。

## 挂点（从视觉根）

| 挂点 | 路径 |
| --- | --- |
| 胸 | `Vfx_Chest` |
| 脚 | `Vfx_Feet` |
| 刃 | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Blade` |
| 尖 | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Tip` |
| 红光 | `…/WeaponPivot/TelegraphGlow` |
| 黄光 | `…/WeaponPivot/ActiveGlow` |
| 绿光 | `…/WeaponPivot/PunishGlow` |
| 敌人肩甲 | `Hip/Torso/ShoulderL/Pauldron` |

武器网格：`…/WeaponPivot/Weapon`

片段已为敌人攻击和玩家判定切换三个发光网格。也可由七个事件驱动。

## 要生成的特效场景

| 内容 | 场景 | 何时 |
| --- | --- | --- |
| Slam 地面圆 **r=1.6 m 红** | `res://assets/vfx/slam_floor_circle.tscn` | 敌人 Slam **f8**。父节点 `Vfx_Feet`。自动播 `Pulse`。在 `hit_on` 或 `hit_off` 释放/隐藏。 |
| 受击火花 | `res://assets/vfx/hit_spark.tscn` | 命中连接时。`restart()`。 |
| 架势击破火花 | `res://assets/vfx/stance_break_spark.tscn` | 进入 StanceBroken。`restart()`。 |
| 受击闪白 | 材质 `hurt_flash_white.tres` 对所有 `Hip` 网格 1 帧，**或** `vfx/hurt_flash.tscn` 在 `Vfx_Chest` 播 `Flash` |
| 挥砍 | `vfx/slash_arc.tscn` 在 `Vfx_Blade`（在 `hit_off` 切断） |
| 突刺直线 | `vfx/thrust_line.tscn` 在 `Vfx_Tip` |

## 受击闪白（首选）

命中时（非干净格挡）：

1. 对 `Visual/Hip`（以及敌人 `Pauldron`）下每个 `MeshInstance3D`：`material_override = preload("res://assets/materials/hurt_flash_white.tres")`
2. 下一帧（1/60）：`material_override = null`

## Debug 着色

- I-frame：`res://assets/materials/iframe_debug_blue.tres`
- Hyperarmor：`res://assets/materials/hyperarmor_debug_orange.tres`

随 HUD 开关。世界预警 telegraph 红/黄/绿在 HUD 关时仍可见。

## 根运动

`docs/art/animation-timeline.md` 里的距离是 CharacterBody3D 上的 **代码**。视觉 `Hip` 位置键只为可读 — 若会让角色双移动就关掉物理（`callback_mode_process` / 忽略 Hip 平移，或让 Hip 静止只动身体）。

## Hitbox

不要把这些网格当判定体积。用设计胶囊。美术剑是长剑条，不是 2.8 m Thrust 胶囊。

## 竞技场地面材质（可选）

`res://assets/materials/arena_floor.tres` — 冷灰，让 `#E03030` 跳出来。若你拥有竞技场网格再指定。

## 帧换算

`t = (frame - 1) / 60`。方法键已打好。若战斗由帧计数器驱动而不是 AnimationPlayer 方法，抄 `docs/art/animation-timeline.md` 的表 — 不要改计数。

重新生成占位（可选）：`py -3 game/assets/_generate.py`，若生成器仍写 `".."`，再把方法轨路径改回 `../..`。
