# 特效表 — 占位

用途：**读招**，不是装饰。拖尾随 `hit_off` 消失。禁止满屏。

场景：`game/assets/vfx/`。材质：`game/assets/materials/`。  
挂点在视觉场景上（`player_knight_visual.tscn`、`enemy_knight_visual.tscn`）。

---

## 挂点（冻结节点名）

路径从视觉根起（`PlayerKnightVisual` / `EnemyKnightVisual`）。

| 挂点 | 路径 | 用途 |
| --- | --- | --- |
| 胸 | `Vfx_Chest` | 受击闪白中心、架势击破火花、hyperarmor debug 描边原点 |
| 脚 / 地面 | `Vfx_Feet` | **Slam 地面圆**（角色空间 Y ≈ 0.02 m，贴地） |
| 武器刃中 | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Blade` | 挥砍弧、Sweep 扇面、DoubleSlash 斩、玩家轻/重击 |
| 武器尖 | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Tip` | Thrust 直线、RunningAttack、Riposte 刺 |
| 武器发光网格 | `…/WeaponPivot/TelegraphGlow`、`…/WeaponPivot/ActiveGlow`、`…/WeaponPivot/PunishGlow` | 红 / 黄 / 绿武器状态（可见性轨，不是新事件） |
| 武器网格 | `…/WeaponPivot/Weapon` | 长剑条；不是 hitbox |
| 肩甲（敌人） | `Hip/Torso/ShoulderL/Pauldron` | 仅身份；不是特效生成点 |

程序：把特效实例为这些挂点的子节点，或在挂点全局原点生成世界空间副本。**Slam 圆** 应挂到敌人角色（跟随 0.4 m 步进），本地平移 `(0, 0.02, 0)`，不要挂到挥动的骨骼。

---

## 1. 预警 telegraph（武器红）

| | |
| --- | --- |
| 场景 | `vfx/telegraph_weapon.tscn`（也烘焙为武器上的 `TelegraphGlow`） |
| 颜色 | `#E03030` unshaded，轻度 emission |
| 何时 | 敌人 **Sweep / Thrust / DoubleSlash** 从预警 telegraph f1。**Slam** 武器红从 f1 **且** 地面圆从 f8。 |
| 关 | 在 `hit_on`（切到判定黄）。DoubleSlash 间隙 **保持红** 直到第二击 `hit_on`。 |
| 挂点 | `Weapon/TelegraphGlow`（相对剑条缩放约 1.08） |
| 不要 | 让全身脉动。不要把这红用在玩家自己的起手上。 |

---

## 2. Slam 地面圆（必须）

| | |
| --- | --- |
| 场景 | `vfx/slam_floor_circle.tscn` |
| 颜色 | 预警 telegraph 红 `#E03030` |
| 半径 | **1.6 m**（设计）。网格圆柱半径 1.6，高 0.03。同半径细环。 |
| 出现 | Slam 预警 telegraph **f8**（`t = 7/60`）。程序：该帧 `show()` / `restart()`。 |
| 存活 | 脉动到 **落地**（`hit_on` f33）。然后隐藏，或仅在判定中 1–2 f 黄印。 |
| 挂点 | **敌人** 视觉上的 `Vfx_Feet` |
| 读法 | HUD 关、Mid 距离必须明显：「出去 / 现在翻滚。」 |

不要把圆缩放到 1.8 m 命中圆柱。这个错位是设计的；上报，不要「修」。

脉动：albedo alpha 0.35–0.55，2 Hz，缩放不超过 1.6 m。

---

## 3. 判定黄

| | |
| --- | --- |
| 场景 | 武器子节点 `ActiveGlow` / `vfx/active_flash.tscn` |
| 颜色 | `#F0D030` |
| 何时 | 仅 `hit_on` → `hit_off` |
| Slam | 可选黄打在 **低圆柱** 体积上（不是满屏）。高度保持 1.2 m 以下。 |
| 关 | `hit_off` 同一帧，不要有超过窗口的淡出 |

---

## 4. 挥砍弧

| | |
| --- | --- |
| 场景 | `vfx/slash_arc.tscn` |
| 颜色 | 玩家冷白钢；敌人略暖，但判定中 **黄优先** |
| 寿命 | ≤ 判定长度。在 `hit_off` 硬切。 |
| 挂点 | `Vfx_Blade` |
| 形状 | Light1 / Sweep：水平扇。Light3 / Slam / ChargedHeavy：竖直。Thrust / Riposte / RunningAttack：从胸穿过 `Vfx_Tip` 的 **直线**，不是扇。DoubleSlash：两段短斩带顿挫，**不要** 拖尾穿过 10 f 间隙。 |

占位网格：薄圆环扇 / 拉长盒，unshaded，additive，约 8 f 或直到 `hit_off`，取较短者。

---

## 5. 受击火花

| | |
| --- | --- |
| 场景 | `vfx/hit_spark.tscn` |
| 颜色 | 白 / 浅金火花，很小 |
| 寿命 | **约 8 f**（0.13 s），一次性 |
| 数量 | 8–16 粒子，无烟 |
| 挂点 | 在接触点生成。回退：防守方 `Vfx_Chest` |
| 同时 | 防守方网格 **1 帧白色受击闪** |

格挡命中不要生成看起来像扣 HP 的火花。格挡 = 可选前臂小环（v1 不要求）。

---

## 6. 受击闪白（1 帧）

| | |
| --- | --- |
| 材质 | `materials/hurt_flash_white.tres` |
| 时长 | **1 帧**（1/60 s）。不是 2。不是淡出。 |
| 做法 | 对 `Hip`（以及 `Pauldron`）下每个 `MeshInstance3D` 设 `material_override` 一物理/视觉帧，然后 `null`。 |
| 场景辅助 | `vfx/hurt_flash.tscn` — 1 帧 AnimationPlayer，在覆盖接线未就绪时于 `Vfx_Chest` 显示白色 unshaded 复制胶囊。优先材质覆盖，让轮廓仍是真实身体。 |

---

## 7. 可罚绿

| | |
| --- | --- |
| 网格 | `Weapon/PunishGlow` + 可选躯干浅描边 |
| 颜色 | `#30C060` |
| Sweep | 从后摇 f8 |
| Thrust | 从后摇 f6 |
| Slam | **整段** 后摇 f41–80 |
| DoubleSlash | 第二击后摇 f8 起 |
| StanceBroken | 满 90 f，身体 + 武器 |

保持描边 / 武器发光。不要绿色爆炸。

---

## 8. 架势击破火花

| | |
| --- | --- |
| 场景 | `vfx/stance_break_spark.tscn` |
| 何时 | 架势打到 0 / 进入 `StanceBroken` 的那一帧 |
| 颜色 | 金爆 + 绿跪接管 |
| 寿命 | 约 12 f 爆发后消失。跪姿承担剩余 90 f。 |
| 挂点 | 敌人 `Vfx_Chest`（再向膝部几点火花） |
| 跪 | 动画片段 `StanceBroken`，不是特效。必须从 Mid 可读：武器放下、胯落、胸口敞开。 |

---

## 9. Debug 着色（可随 HUD 开关）

| 着色 | Hex | 对象 | 窗口 |
| --- | --- | --- | --- |
| I-frame | `#40A0FF` | 玩家胶囊 | DodgeRoll f4–16 |
| Hyperarmor | `#E07020` | 角色胶囊 / 描边 | 玩家 Heavy f16–31；ChargedHeavy 蓄力 f12 直到释放 `hit_off`；敌人 Slam 预警 f12–`hit_off`；Riposte 整招；Wakeup 24 f |

材质：`iframe_debug_blue.tres`、`hyperarmor_debug_orange.tres`。程序相乘或叠加；HUD 关时发货镜头不要留着 — **世界预警 telegraph 色保留**；debug 着色可随 HUD 隐藏。

---

## 10. Riposte

- 玩家：从 `Vfx_Tip` 的突刺直线。
- 敌人：保持绿跪；刺中 `hit_on` **1 帧白**。
- 镜头推进可选，程序拥有（≤ 20 f）。这些特效场景不写慢动作轨。

---

## 程序生成速查

| 信号 / 帧 | 实例 | 父节点 |
| --- | --- | --- |
| 敌人攻击进入（Sweep、Thrust、DoubleSlash、Slam） | 显示 `TelegraphGlow` | Weapon |
| Slam **f8** | `slam_floor_circle.tscn` 播 `Pulse` | 敌人 `Vfx_Feet` |
| 任意 `hit_on` | 隐藏预警 telegraph；显示 `ActiveGlow`；生成 `slash_arc.tscn` | 按招用 Blade 或 Tip |
| 任意 `hit_off` | 隐藏 `ActiveGlow` 与挥砍 | — |
| 后摇绿帧（时间轴） | 显示 `PunishGlow` | Weapon |
| 伤害结算（且非完全格挡） | 白覆盖 1 f + `hit_spark.tscn` | 防守方 |
| 架势 0 | `stance_break_spark.tscn` + 播 `StanceBroken` | 敌人胸 |
| `iframe_on` / `off` | 蓝叠加 | 玩家视觉 |
| `hyperarmor_on` / `off` | 橙叠加 | 该角色 |

无额外事件名。订阅七个方法以及 Slam f8 帧计数器。
