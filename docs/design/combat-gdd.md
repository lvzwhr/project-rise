# 战斗 GDD — v1 冻结

**状态：** 已冻结，供第一版可玩。先改这里的数值，再改代码或动画。  
**引擎：** Godot 4.7.2，GDScript，3D，**60 FPS**。1 帧 = 1/60 s。  
**演示：** 一座竞技场、一名玩家骑士、一名敌人骑士、Debug HUD。  
**手感参考：** 《艾尔登法环》近战 — 承诺感、stamina 消耗、翻滚 i-frame、lock-on 走位、可读预警、stance 击破、重击上的 hyperarmor。

这是战斗验证沙盒，不是完整游戏。不要为了掩盖没调好的数值去加系统。

---

## 1. 范围

### 范围内

- 竞技场（平坦圆形或方形，约 20 m 宽，有围栏以免掉出对战区）
- 玩家骑士 + 敌人骑士
- lock-on 近战
- 攻击 / 翻滚 / 奔跑 / 格挡共用同一条 stamina
- 翻滚 i-frame
- 格挡（无弹反）
- 敌人 stance 条 → 击破 → Riposte
- 玩家 Heavy / ChargedHeavy 以及敌人 Slam 上的 hyperarmor
- 后摇上的输入 buffer（`can_buffer`）
- 占位网格、占位 VFX、Debug HUD

### 范围外

开放世界、剧情、背包、养成、多人、坐骑、召唤、战技树、状态异常、法术栏、双持、蹲下/后撤步作为独立招式、弹反、跳跃 i-frame、第二类敌人、制作、升级。

v1 玩家招式仅限 `player-moveset.md` 所列。v1 敌人攻击仅限 `enemy-knight.md` 所列。

---

## 2. 支柱 → 数据（不是形容词）

| 支柱 | 玩家能感知到什么 | 失败会长什么样 | Debug 必须显示 |
| --- | --- | --- | --- |
| 承诺感 | 每招都有 startup / active / recovery。startup 或 active 期间不能取消到格挡、攻击或翻滚。 | Light3 打空会被打中。 | 状态名 + 阶段 + 帧 |
| stamina 经济 | 攻击、翻滚、奔跑和被格挡的命中共用一条条。慌乱翻滚和打空会把你掏空。 | 5 次翻滚清空条；第 6 次尝试 = Exhaust，敌人用轻击罚你。 | stamina 当前/上限、回复延迟、Exhaust 标志 |
| i-frame | 只有翻滚有 i-frame，13 帧，从第 4 帧开始。 | 过早翻滚进 Slam 仍会被打中。 | `iframe` 开/关 + 剩余帧 |
| lock-on 走位 | lock-on 是默认近战方式。绕圈、后滚、侧滚都能用。 | 未锁定相机时朝向不可靠；锁定后绕圈必须能在中距画圈。 | lock-on 目标 id、距离 |
| 可读性 | 敌人攻击能从动作 + 颜色读出来。玩家靠看躲，而不是靠背招式 ID。 | 关掉 HUD 后，Sweep / Thrust / Slam 仍可区分。 | 攻击名（仅 Debug）；场景中的预警/判定/可罚颜色 |
| stance 击破 | 打空敌人 stance 条 → 跪地窗口 → 走上前 Riposte。 | 整场打不出跪地，或跪地窗口短到走不进去。 | 敌人 stance 当前/上限、`StanceBroken` 计时 |
| hyperarmor | Heavy / 蓄力重击（以及敌人 Slam）在 hyperarmor 窗口内不会被轻击打断。 | 玩家 Heavy 与 Sweep 对撞仍能打完。 | `hyperarmor` 开/关 |
| buffer | 后摇尾段会存下下一个动作。在窗口内按下才能连段，不是「感觉能接」。 | 在窗口内连按 Light 总能打出 3 下；等到后摇结束再按会掉连段。 | `can_buffer` 开/关 |

---

## 3. 系统关系

```text
Input → 状态机（startup/active 期间不能离开，除非 Hitstun、Death，或已经开始的 i-frame 翻滚）
         ├─ stamina 门槛（没有消耗就无法起招；0 + 攻击/翻滚 = Exhaust）
         ├─ lock-on（朝向 + 绕圈基准 + 相机）
         └─ buffer（存储 10f；仅在 can_buffer 时消耗）

hit_on → hurtbox 检测（目标 iframe 则跳过）
         ├─ 若目标 Guard 且命中在前方 180° → stamina 削减，无 HP（除非 GuardBreak）
         ├─ 否则 HP 伤害 + Hitstun（目标 hyperarmor 则跳过）
         └─ 若目标是敌人 → stance 伤害；stance 0 → StanceBroken

StanceBroken → 玩家在范围内按 Light/Heavy 则 Riposte；否则敌人 Wakeup
```

### 3.1 stamina

一条条。每次消耗都会启动 **18 帧回复延迟**。延迟结束后，在 Idle、Walk 或 Guard 中以 **40/s** 回复（攻击、翻滚、奔跑、Exhaust、GuardBreak、Hitstun、Riposte 期间不回复）。

奔跑（冲刺）在进入 Run 的前 20 帧之后以 **12/s** 消耗。冲刺到 0 会取消 Run，进入 12 帧趔趄，然后 Walk；**不会**套用 48 帧 Exhaust。

Exhaust（48 帧，完全可罚）发生在：

1. 玩家在 stamina 为 0 时按下 Light / Heavy / Roll / JumpAttack / RunningAttack，或
2. 一次被格挡的命中会把 stamina 减到 0 以下（GuardBreak，50 帧 — 略长于 Exhaust）。

Walk 始终允许。空 stamina 必须看得见：条变灰，角色在 Exhaust/GuardBreak 时喘气。

### 3.2 格挡

按住 Guard。前方 180° 格挡。v1 无削 HP。被格挡的命中消耗 stamina（见 player-moveset）。攻击者**不会**因格挡而硬直；他们走完自己的 recovery。防御方播放 GuardHit（10f），但仍可继续按住。

没有弹反。不要加。

### 3.3 i-frame

只有 `DodgeRoll`。`iframe_on` 第 4 帧，`iframe_off` 第 17 帧（第 4–16 帧含两端 = **13 帧**）。Jump、Hitstun、Riposte 和奔跑没有 i-frame。

### 3.4 lock-on

切换。默认打法。锁定时：相对指向敌人的连线做 8 向绕圈，相机把敌人留在画面内。未锁定：由相机/摇杆自由朝向，仍能打，但走位测试一律在**锁定**下进行。

lock-on 距离：获取 ≤ 14 m，丢失 > 16 m 或目标 Death。同时只有一个目标。

### 3.5 玩家打断 vs 敌人 stance

- **玩家没有 stance 条。** 打断规则：若 `hyperarmor` 开着，扣 HP 但不离开当前攻击。若关着，任何命中、未被格挡、非 i-frame 的攻击施加 Hitstun 并取消该招。
- **敌人有 stance 条（100）。** stance 伤害写在每个玩家招式上。到 0：`StanceBroken` 持续 90 帧（跪地，绿色可罚姿势）。玩家可以 Riposte。超时：`Wakeup` 24f，stance 回复到 **40**（不是满条）。
- 敌人 Slam 使用 hyperarmor，因此玩家轻击不能取消它。Slam 仍会吃 HP 和 stance 伤害。

不要给玩家再发明一套架势击破演出。

### 3.6 Hitstun 等级

| 等级 | 时长 | 用于 |
| --- | --- | --- |
| Light | 18f | 玩家轻击、敌人 Sweep、DoubleSlash 各段 |
| Heavy | 26f | 玩家 Heavy / 奔跑 / 跳跃，敌人 Thrust |
| Slam | 34f + 8f 起身 | 敌人 Slam、玩家蓄力重击 |
| Exhaust | 48f | 玩家 stamina 失败 |
| GuardBreak | 50f | 玩家在 0 stamina 时格挡命中 |
| StanceBroken | 90f | 仅敌人 |

hyperarmor 忽略 Light / Heavy / Slam 打断。Death 和 StanceBroken 仍会覆盖。

### 3.7 输入 buffer

- 记忆：最近一次合格输入保留 **10 帧**。
- 消耗：仅在当前状态的 `can_buffer` 开着时。
- 合格输入：Light、Heavy、Roll、Guard（后摇结束后举盾）、Jump。
- 连段：Light1 的 buffer 期间按 Light → Light2；Light2 的 buffer 期间按 Light → Light3。Light3 的 buffer 期间按 Light **不会**循环；等到 Idle 再出 Light1。
- 不能从 startup 或 active 里 buffer 出去。这就是承诺感支柱。

---

## 4. 冻结名称

### 4.1 动画事件（不要改名）

| 事件 | 含义 |
| --- | --- |
| `hit_on` | 开启本招 hitbox |
| `hit_off` | 关闭本招 hitbox |
| `iframe_on` | 玩家忽略 hurtbox 重叠 |
| `iframe_off` | i-frame 结束 |
| `hyperarmor_on` | 该角色不可被硬直取消 |
| `hyperarmor_off` | hyperarmor 结束 |
| `can_buffer` | 后摇尾段；buffer 可以消耗 |

把这些事件按招式表 / 敌人表里的帧放到动画时间轴上。在没有成片之前，程序用帧计数驱动同一套名称。

### 4.2 玩家状态

`Idle`, `Walk`, `Run`, `Light1`, `Light2`, `Light3`, `Heavy`, `ChargedHeavy`, `Jump`, `JumpAttack`, `RunningAttack`, `DodgeRoll`, `Guard`, `GuardHit`, `GuardBreak`, `Exhaust`, `Hitstun`, `Riposte`, `Death`

### 4.3 敌人状态

`Idle`, `Walk`, `Sweep`, `Thrust`, `Slam`, `DoubleSlash1`, `DoubleSlash2`, `Hitstun`, `StanceBroken`, `Wakeup`, `Death`

---

## 5. 资源数值

| 角色 | HP | Stamina | Stance |
| --- | --- | --- | --- |
| 玩家骑士 | **1000** | **100** | — |
| 敌人骑士 | **900** | —（不格挡、不翻滚） | **100** |

战斗预算（设计意图，不是掉落表）：

- 玩家若不回复（没有回复），大约 7 次 Sweep 或大约 4 次 Slam 会死。
- 敌人大约 3 套完整轻击连段再加几下，或大约 6 次 Heavy，或 2 次 Riposte 加剩余补刀会死。
- 一局打得好的 45–90 s 里，stance 大约破一次（蓄力重击 + 连段，或两次 Heavy + 轻击）。

---

## 6. 竞技场规则

- 重置：任一方死亡后 2 s，敌我 HP/stamina/stance 回满，同一出生标记。不需要菜单。Debug 键也可以重置。
- 无道具、无雾门、无赐福。
- 地面可走；墙壁阻挡；没有会挡住预警的掩体几何。

---

## 7. Debug HUD（程序必须交付）

始终可开关（演示默认 **开**）。

玩家：HP、stamina、回复延迟帧、状态、阶段（startup/active/recovery）、本地帧、`iframe`、`hyperarmor`、`can_buffer`、lock-on 距离。  
敌人：HP、stance、状态/攻击名、`hyperarmor`、StanceBroken 剩余。  
场景：hitbox/hurtbox 线框、上次造成的伤害和 stance。

如果某条支柱既不能在此 HUD 上看到，也不能从轮廓/颜色看到，就不算完成。

---

## 8. 美术约定（仅占位）

| 含义 | 场景颜色 |
| --- | --- |
| 预警 / 起手 | 红 `#E03030` |
| 判定命中 | 黄 `#F0D030` |
| 可罚 / 长后摇 / StanceBroken | 绿 `#30C060` |
| i-frame Debug | 蓝 `#40A0FF` |
| hyperarmor Debug | 橙 `#E07020` |

- 玩家：冷钢 / 蓝灰轮廓，略瘦。
- 敌人：更深的铠甲、红布或肩甲，更重的外轮廓，12 m 处可读。
- 受击闪白：网格 **1 帧** 变白。
- 不要求最终模型、PBR 或过场相机，除了可选的轻微 Riposte 推近（可选，≤ 20f）。

---

## 9. 成功标准

演示成功的条件：玩家在 Debug HUD **开** 时能在竞技场里做完 `acceptance.md` 的每一条，并且同样的走位/预警测试在 HUD **关** 时仍成立（颜色和动作承担阅读）。

调参时要守住的手感数字：`feel-targets.md`。若某项目标失败，改设计表里列出的字段 — 不要加新系统。

---

## 10. 不要自行发挥

程序和美术不得：

- 给七个动画事件改名
- 加入弹反、后撤步、战技、第二把武器、魔法、状态异常或第二名敌人
- 给跳跃或奔跑 i-frame
- 允许攻击在 startup/active 期间取消到翻滚或格挡
- 在未改设计表的情况下改 HP / stamina / stance / 帧数
- 隐藏表里写明已开启的 hitbox，或把它们延长到 `hit_off` 之后
- 跳过敌人攻击的预警颜色
- 在 Wakeup 时把敌人 stance 回满到 100（应是 40）
- 给玩家 stance 条，或让玩家对自己做 stance 击破 Riposte
