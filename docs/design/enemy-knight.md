# 敌人骑士 — v1 冻结

**数量：** 1 个原型，竞技场里 1 个实例。  
**职责：** 可读的人型重击手。与玩家同尺度，更重的轮廓，更慢的 recovery。  
**FPS：** 60。  
**攻击：** 4。无格挡、无翻滚、无战技。

| 资源 | 上限 | 备注 |
| --- | --- | --- |
| HP | **900** | 死亡后竞技场重置 |
| Stamina | — | 不格挡、不闪避 |
| Stance | **100** | 0 → `StanceBroken` 90f → `Wakeup` 24f → stance **40** |

招式覆盖三项必答题：

| 攻击 | 玩家的预期应对 | 满足的要求 |
| --- | --- | --- |
| DoubleSlash | 格挡（stamina 压力） | 可格挡连段 |
| Slam | 翻滚过冲击，罚 40f recovery | 可翻滚惩罚 |
| Thrust | 侧步（或等 34f recovery） | 侧步 / 后摇惩罚 |
| Sweep | 格挡 **或** 翻滚；默认可读挥砍 | 通用来回 |

---

## 身份与可读性

- 更深的铠甲、红布 / 肩甲，肩膀比玩家更厚。
- 行走 3.0 m/s，无冲刺。Idle/Walk/预警时转向 180°/s；**active 期间转向 0°/s**。
- 受击闪白：1 帧白色。
- 预警姿势 + 武器红 `#E03030`（以及 Slam 地面圈）。判定中武器黄 `#F0D030`。长后摇 / StanceBroken 绿 `#30C060`。
- 玩家必须能从轮廓**不看** Debug HUD 就叫出即将到来的攻击。

距离段（平面距离，玩家胶囊到敌人胶囊）：

| 段 | 距离 | 用途 |
| --- | --- | --- |
| Close | 0–2.2 m | Slam、DoubleSlash、Riposte 距离 |
| Mid | 2.2–3.5 m | Sweep 默认 |
| Far | 3.5–5.0 m | Thrust 默认 |
| Out | > 5.0 m | 走进来，不出招 |

---

## 攻击 1 — Sweep（横斩）

**目的：** 默认中距挥砍。可读、可格挡、翻滚公平。

| 字段 | 数值 |
| --- | --- |
| 预警 | **22f**。剑收到右肩，躯干蓄力。武器从 f1 起为红。 |
| 判定 active | **10f**。`hit_on` f23，`hit_off` f33。 |
| 后摇 recovery | **28f**。刀锋向左挥尽，胸口敞开。从 recovery f8 起为绿。 |
| 合计 | 60 |
| 判定形状 | 水平 180° 弧，**2.2 m**，高度 0.8–1.6 m |
| 伤害 | 130 |
| Hitstun | Light（18f） |
| hyperarmor | 无 |
| 格挡 | **可以**，22 玩家 stamina |
| 闪避 | 翻滚穿过或后滚，使 i-frame 覆盖 f23–32。侧滚也可以。 |
| 可罚 | 成功翻滚后，Light1 或 Light1+2 能塞进 28f recovery。 |
| `can_buffer` | 不适用（AI 不 buffer） |

**AI 选择：** 玩家在 Mid 且不在 i-frame 时权重 **40**。若 Slam 在冷却，Close 时权重 **20**。绝不从 Out 使用。

---

## 攻击 2 — Thrust（突刺）

**目的：** 直线承诺。**侧步或罚 recovery。** 过早慌乱翻滚若仍停在线上会被刮到。

| 字段 | 数值 |
| --- | --- |
| 预警 | **18f**。枪尖、肩膀摆正、一步。从 f1 起为红。朝向在**预警 f10 锁定**（f1–10 轻微追踪，然后锁定直线）。 |
| 判定 active | **8f**。`hit_on` f19，`hit_off` f27。突进 1.4 m。 |
| 后摇 recovery | **34f**。过度前倾，从 recovery f6 起为绿。 |
| 合计 | 60 |
| 判定形状 | 胶囊长 **2.8 m**，半径 **0.45 m**，约 30° — 是一条线，不是横斩 |
| 伤害 | 150 |
| Hitstun | Heavy（26f） |
| hyperarmor | 无 |
| 格挡 | 允许但**不是**预期应对（32 stamina）。 |
| 闪避 | **侧步**（lock-on 绕圈）离开直线，然后惩罚。偏轴的晚滚也可以。在 active 期间沿直线**向前翻滚**是玩家失误。 |
| 可罚 | 34f recovery：若你已经站在身侧，Light1+2 或 Heavy 的 startup 能接上。 |

**AI 选择：** 玩家在 Far 时权重 **35**。若玩家上次 `DodgeRoll` 结束 ≤ 20f（抓爱滚的走位）权重 **25**。Mid 时权重 **10**。若玩家在敌人背后，Close 时绝不使用。

---

## 攻击 3 — Slam（砸地）

**目的：** 带 hyperarmor 的慢过顶。**翻滚过判定，罚长 recovery。** 若 stamina 只剩一半，格挡是陷阱。

| 字段 | 数值 |
| --- | --- |
| 预警 | **32f**。双手举起。**地面圈**为红，半径 1.6 m，在 **f8** 出现，脉冲直到落地。 |
| 判定 active | **8f**。`hit_on` f33，`hit_off` f41。略向前 0.4 m。 |
| 后摇 recovery | **40f**。从地面拔起，屈膝，**整段 recovery** 为绿。 |
| 合计 | 80 |
| 判定形状 | 绕敌人的圆柱，半径 **1.8 m**，高度 0–1.2 m（偏低，因此后滚出半径也可以） |
| 伤害 | 210 |
| Hitstun | Slam 级（34f + 8f 起身） |
| hyperarmor | **有** — 预警 **f12** `hyperarmor_on`，`hit_off` 时 `hyperarmor_off`。玩家轻击不能取消 Slam。 |
| 格挡 | 技术上可以，**48** stamina — 若玩家已经挡过一下，很可能 GuardBreak。不是预期应对。 |
| 闪避 | 翻滚使 i-frame 覆盖 f33–40，**或**离开圆柱。然后惩罚。 |
| 可罚 | 40f recovery：完整 Light1–2–3（玩家合计 34+11+14 注意：Light1 是 34，但你只需要每招的 startup 接上即可）。Slam `hit_off` 之后，玩家可以打出 3 下连段或一次 Heavy。这是翻滚惩罚教学。 |

**AI 选择：** Close 时权重 **30**。若玩家处于 `Guard` 或攻击 recovery，Close 时权重 **45**。Mid 时权重 **15**。使用后冷却 **180f**，避免循环。

美术：预警必须读得出 ≥ 32f。若成片更短，加持帧 — 不要悄悄缩短表。

---

## 攻击 4 — DoubleSlash（连续斩）

**目的：** **可格挡**的两下压力。教 stamina：两下都挡花费 44。滚过第一下然后贪刀，会被 Thrust/Sweep 抓到。

| 字段 | 数值 |
| --- | --- |
| 第 1 下预警 | **16f**，红，从右上斜斩 |
| 第 1 下判定 active | **7f**。`hit_on` f17，`hit_off` f24 |
| 间隙 | **10f**（仍在连段中；除非你已经在背后，否则不可罚） |
| 第 2 下预警 | 这 10f 间隙是唯一警告 — 小顿挫，然后左→右。保持红色直到第 2 下 `hit_on`。 |
| 第 2 下判定 active | **8f**。`hit_on` 间隙结束+1，`hit_off` +8 |
| 后摇 recovery | 第 2 下之后 **26f**，从 recovery f8 起为绿 |
| 判定形状 | 各：90° 弧，**2.0 m** |
| 伤害 | 先 90 再 100 |
| Hitstun | 各 Light（18f） |
| hyperarmor | 无 |
| 格挡 | **可以**，22 + 22 stamina。若玩家已经在格挡，这是预期应对。 |
| 闪避 | 翻滚第 1 下，后走或再滚躲第 2 下。不要把间隙当成完整可罚，除非你在背后弧。 |
| 可罚 | 第 2 下 recovery（26f）之后：Light1+2。 |

**AI 选择：** 若玩家在 Close/Mid 处于 `Guard`，权重 **40**。否则 Close 时权重 **25**。Far/Out 时权重 **0**。

---

## AI 循环（确定到足以测试）

60 Hz 心跳。不要加第二套大脑。

1. 若 `Death` 或 `StanceBroken` 或 `Hitstun` 或 `Wakeup`：不选攻击。
2. 若玩家距离 > 5 m：`Walk` 走向玩家。
3. 若处于某次攻击的 recovery：打完它。
4. 否则若距上次 recovery 结束 < **45f**：`Walk` / Idle（给玩家行动的换气空间）。
5. 否则：按上表在合法攻击中加权抽取。若同一攻击连续打出两次则重抽一次（Sweep 可以重复除外）。
6. Slam 冷却 180f。Thrust 冷却 90f。DoubleSlash 冷却 90f。Sweep 无冷却。

玩家死亡：回到出生点 Idle。不要对尸体嘲讽。

---

## stance 击破

| 字段 | 数值 |
| --- | --- |
| 触发 | stance 因玩家 stance 伤害降到 0 |
| 状态 | `StanceBroken`，**90f** |
| 姿势 | 跪地，武器放下，**绿色**描边，击破那一帧金色闪光 |
| hurtbox | 仍然存在（额外命中扣 HP 但不会延长这 90f） |
| Riposte | 玩家在 2.2 m 内按 Light/Heavy → 玩家 `Riposte`（380 伤害） |
| 超时 | `Wakeup` 24f，Wakeup 期间有 hyperarmor，stance 设为 **40**，然后 Idle |
| 美术 | 跪地必须从中距读得出「进去打」。击破时可选火花。 |

---

## 事件放置速查（敌人）

| 招式 | hit_on | hit_off | hyperarmor_on | hyperarmor_off | can_buffer |
| --- | --- | --- | --- | --- | --- |
| Sweep | 23 | 33 | — | — | — |
| Thrust | 19 | 27 | — | — | — |
| Slam | 33 | 41 | tel 12 | 41 | — |
| DoubleSlash1 | 17 | 24 | — | — | — |
| DoubleSlash2 | after 10f gap | +8 | — | — | — |

敌人从不使用 `iframe_*`。不要给骑士翻滚。

---

## Debug

显示：攻击名、阶段、本地帧、stance、hyperarmor、Slam/Thrust/DoubleSlash 的剩余冷却、距离段。

---

## 不要自行发挥

- 不要第 5 招、不要抓取、不要盾击、不要增益嘶吼、不要投射物。
- 不要敌人 i-frame，不要敌人格挡。
- 不要在预警 f10 之后继续追踪 Thrust。
- 不要把 Slam 预警缩短到 32f 以下。
- 不要跳过 Slam 的红色地面圈。
- 不要在 Wakeup 时把 stance 回满到 100。
