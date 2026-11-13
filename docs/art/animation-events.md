# 动画事件 — v1 冻结名称

**禁止改名。禁止加第四对。禁止加 `can_buffer_off`。**

这七个名称是本 demo 仅有的动画事件（`docs/design/combat-gdd.md` §4.1，验收 Q）。Godot AnimationPlayer 的 **方法轨** 在战斗角色（视觉的父节点）上调用同一标识符。在片段真正播放前，程序可用帧计数器触发它们 — 名称保持相同。

帧约定：**60 FPS**，从 1 起算。事件在该帧 **开始** 时触发。  
Godot 时间：`t = (frame - 1) / 60`。

`hit_off` 是最后一个判定帧的 **下一帧**（设计规则）。包含 6 帧判定、起手 10 ⇒ `hit_on` f11，`hit_off` f17。

---

## 七个事件

| 事件 | 含义 | 画面（美术） | 逻辑（程序） |
| --- | --- | --- | --- |
| `hit_on` | 开启 **本招** 的 hitbox。 | 打击体积显示判定黄 `#F0D030`。隐藏预警 telegraph 红。 | 打开该招 hitbox。每个实例对每个目标只打一次。 |
| `hit_off` | 关闭该 hitbox。 | 立刻关掉黄。 | Hitbox 关。不要带到后摇。 |
| `iframe_on` | 玩家忽略 hurtbox 重叠。 | 可选胶囊着色 `#40A0FF`。网格 **保持可见**。 | 跳过对玩家的 hurtbox 检测。 |
| `iframe_off` | I-frame 结束。 | 去掉蓝着色。 | Hurtbox 检测恢复。翻滚后摇仍可被打。 |
| `hyperarmor_on` | 该角色不能被硬直打断。 | 可选描边 `#E07020`。姿势不变。 | HP 仍结算；不要因 Light/Heavy/Slam 类进入 Hitstun。死亡与敌人 StanceBroken 仍覆盖。 |
| `hyperarmor_off` | Hyperarmor 结束。 | 去掉橙。 | 硬直规则恢复。 |
| `can_buffer` | 后摇尾开始；缓冲可消耗。 | 不要求额外特效。 | 将缓冲消耗设为 true，直到状态退出。**窗口开始时一次性。** 没有 `can_buffer_off` 事件。 |

敌人 **从不** 使用 `iframe_on` / `iframe_off`。不要打在敌人片段上。

敌人 **从不** 使用 `can_buffer`（AI 不缓冲）。不要打在敌人片段上。

---

## 谁用什么

### 玩家

| 招式 / 状态 | `hit_on` | `hit_off` | `iframe_on` | `iframe_off` | `hyperarmor_on` | `hyperarmor_off` | `can_buffer` |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Idle / Walk / Run | — | — | — | — | — | — | n/a（始终接受） |
| Light1 | **11** | **17** | — | — | — | — | 后摇 **11**（绝对 **27**） |
| Light2 | **12** | **18** | — | — | — | — | 后摇 **13**（绝对 **30**） |
| Light3 | **15** | **23** | — | — | — | — | 后摇 **19**（绝对 **41**） |
| Heavy | **23** | **31** | — | — | **16** | **31** | 后摇 **23**（绝对 **53**） |
| ChargedHeavy | 释放 **+7** | 释放 **+17** | — | — | 蓄力 **12** | 释放 **+17** | 后摇 **25**（释放绝对 **41**） |
| Jump（无攻击） | — | — | — | — | — | — | — |
| JumpAttack | 按下 **+13** | 按下 **+21** | — | — | — | — | 落地后摇 **17**（按下绝对 **37**） |
| RunningAttack | **14** | **22** | — | — | — | — | 后摇 **17**（绝对 **38**） |
| DodgeRoll | — | — | **4** | **17** | — | — | 绝对 **25** |
| Guard 举起 / 维持 | — | — | — | — | — | — | 维持时 n/a |
| Guard 放下 | — | — | — | — | — | — | 8 f 放下的最后 **4 f**（不要求命名事件；程序可将放下 f5 当缓冲） |
| GuardHit | — | — | — | — | — | — | — |
| GuardBreak | — | — | — | — | — | — | — |
| Exhaust | — | — | — | — | — | — | 最后 **8 f** 可暂存 Guard/Walk — 程序标志；**不要** 发 `can_buffer`，以免让攻击起手。优先用代码标志，不用本事件。 |
| Riposte | **17** | **21** | — | — | **1** | **结束**（状态退出 / f48） | 后摇 **21**（绝对 **41**） |
| Hitstun / Death | — | — | — | — | — | — | — |

抄自 `player-moveset.md` 事件速查。绝对帧 = 起手 + 后摇内偏移，记录在 `animation-timeline.md`。

### 敌人

| 招式 | `hit_on` | `hit_off` | `iframe_*` | `hyperarmor_on` | `hyperarmor_off` | `can_buffer` |
| --- | --- | --- | --- | --- | --- | --- |
| Sweep | **23** | **33** | — | — | — | — |
| Thrust | **19** | **27** | — | — | — | — |
| Slam | **33** | **41** | — | 预警 **12** | **41** | — |
| DoubleSlash1 | **17** | **24** | — | — | — | — |
| DoubleSlash2 | 间隙结束 **+1** | 该帧 **+8** | — | — | — | — |
| StanceBroken / Wakeup / Idle / Walk / Hitstun / Death | — | — | — | Wakeup：hyperarmor **贯穿全部 24 f**（代码；可选 `hyperarmor_on` f1 / `hyperarmor_off` 在 Wakeup 结束） | — | — |

DoubleSlash2 若片段 **从 10 f 间隙起算**：`hit_on` **11**，`hit_off` **19**。若用一条完整连段片段：`hit_on` **34**，`hit_off` **42**。见时间轴。

Wakeup 的 hyperarmor 是 GDD 规则（`enemy-knight.md` 架势击破）。它不在敌人速查表里。美术可在 Wakeup f1 放 `hyperarmor_on`，在 Wakeup 结束（f24 / 状态退出）放 `hyperarmor_off`。程序也可由状态驱动。**不要发明新事件名。**

---

## Godot 接线

`game/assets/animation/` 里片段的方法轨路径：`NodePath("../..")`。

假定树（视觉是战斗角色的子节点，角色已有 `hit_on` / `hit_off` / …）：

```text
Player (CharacterBody3D, combat script)
└─ Visual          ← instance res://assets/characters/player_knight_visual.tscn
   └─ AnimationPlayer   # method tracks call ../../  → Player
```

敌人同结构。

若程序仍以 **帧计数器** 为真相源（当前脚手架如此），这些片段只播 **姿势**，不要再消费方法轨 — 否则会双触发。若切到动画驱动事件，关掉计数器的事件发射。

若他们把 `add_animation_library` 加到作为角色 **直接** 子节点的 AnimationPlayer 上，把方法轨改指向 `NodePath(".")`。不要改方法名。

片段名与冻结状态名一致（`Light1`、`Sweep`、`DodgeRoll`、…）。ChargedHeavy 拆开：`ChargedHeavy_Charge`（`hyperarmor_on` 在 f12；**不要** 循环该片段，否则事件会再触发 — 暂停 / HOLD 举起姿势）+ `ChargedHeavy_Release`（事件相对释放起算）。

---

## 明确不是事件

不要加：`telegraph_on`、`impact`、`footstep`、`whoosh`、`riposte_cam`、`can_buffer_off`、作为新名字的 `hit_on_2`。DoubleSlash 第二击是同一对 `hit_on` / `hit_off` 名称的第二次，放在片段更后面或 `DoubleSlash2` 上。
