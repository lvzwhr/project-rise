# 玩家招式表 — v1 冻结

**角色：** 玩家骑士，右手直剑，不需要盾牌模型（格挡是状态 + 手臂姿势）。  
**FPS：** 60。帧数含本阶段两端。`hit_on` 在第一帧 active 触发。`hit_off` 在最后一帧 active 的下一帧触发（因此 Active 6 ⇒ `hit_on` 在 Startup+1 帧，`hit_off` 在 Startup+1+6）。  
**朝向：** lock-on 使用敌人偏航角。未锁定使用相对相机的摇杆。

建议输入（程序可重映射，名称不变）：

| 动作 | 键盘 | 手柄 |
| --- | --- | --- |
| 移动 | WASD | 左摇杆 |
| Light | LMB | West（X / Square） |
| Heavy | RMB | North（Y / Triangle） |
| Roll | Space | East（B / Circle）轻点 |
| Run | Shift 按住，或摇杆满前推 10f | East 按住 |
| Guard | Ctrl 或 Q | LT / L2 |
| Jump | V | South（A / Cross） |
| lock-on | MMU / C | R3 |

ChargedHeavy = 按住 Heavy。RunningAttack = 在 `Run` 中 ≥ 8f 时按 Light 或 Heavy（一招，不是两招）。Riposte = 敌人处于 `StanceBroken` 且在范围内时按 Light 或 Heavy。

---

## 共用资源

| 资源 | 上限 | 备注 |
| --- | --- | --- |
| HP | 1000 | 无回复。死亡后竞技场重置。 |
| Stamina | 100 | 18f 延迟后以 40/s 回复。见 GDD。 |
| Stance | — | 玩家没有。 |

下列 stamina 消耗在**进入状态时**支付（ChargedHeavy 在**松手**时支付，不是按住开始时）。若消耗 > 当前且当前 > 0，招式仍启动，stamina 钳到 0。若当前为 0，该输入变成 `Exhaust`（48f）而不是该招。

武器触及除非另注：**1.6 m**，90° 挥砍弧，挂在武器骨骼上的胶囊。每个攻击实例对每个目标只命中一次。

---

## 移动

### Idle

| 字段 | 数值 |
| --- | --- |
| 输入 | 摇杆幅度 < 0.2，无攻击 |
| stamina | 0 |
| 起手 startup / 判定 active / 后摇 recovery | — |
| 伤害 / Stance | — |
| hyperarmor | 无 |
| 取消 | Walk、Run、任意战斗招式、Guard、Jump、lock-on 切换 |
| buffer | 不适用（始终接受输入） |

### Walk

| 字段 | 数值 |
| --- | --- |
| 输入 | 摇杆 ≥ 0.2，且不是 Run |
| 速度 | 3.2 m/s；lock-on = 8 向绕圈 |
| stamina | 0 |
| hyperarmor | 无 |
| 取消 | 同 Idle，外加满前推 10f 后进入 Run |

锁定时后撤是 Walk，不是新的后撤步招式。不要加点按后撤步。

### Run

| 字段 | 数值 |
| --- | --- |
| 输入 | 冲刺键按住，或摇杆向前 ≥ 0.85 持续 10f |
| 速度 | 6.2 m/s |
| stamina | 前 20f 为 0，然后 **12/s**。stamina 到 0 时停止 Run（12f 趔趄，不是 Exhaust） |
| hyperarmor | 无 |
| 取消 | 松手进 Walk/Idle；Roll；RunningAttack；Jump；Guard（停止 Run） |
| buffer | 不适用 |

无 i-frame。无 hitbox。

---

## 轻击连段（最多 3 下）

只能通过 `can_buffer` 衔接。允许连按；窗口仍是门闸。

### Light1

| 字段 | 数值 |
| --- | --- |
| 输入 | 从 Idle / Walk /（允许 Light 的其他招式的 buffer）按 Light |
| stamina | 13 |
| 起手 startup | **10** |
| 判定 active | **6**（`hit_on` f11，`hit_off` f17） |
| 后摇 recovery | **18** |
| 合计 | 34 |
| 伤害 | 80 |
| stance 伤害 | 18 |
| 造成 Hitstun | Light（18f） |
| hyperarmor | 无 |
| 弧线 | 右 → 左，1.6 m |
| `can_buffer` | 后摇 recovery f11–18（**8f**）。此前也可把 Light/Roll 存 10f。 |
| 取消窗口 | 仅 buffer → Light2 或 DodgeRoll 或举起 Guard |
| 备注 | startup/active 不能翻滚或格挡。 |

### Light2

| 字段 | 数值 |
| --- | --- |
| 输入 | 在 Light1 的 `can_buffer` 期间消耗 Light |
| stamina | 13 |
| 起手 startup | **11** |
| 判定 active | **6**（`hit_on` f12，`hit_off` f18） |
| 后摇 recovery | **20** |
| 合计 | 37 |
| 伤害 | 85 |
| stance 伤害 | 20 |
| 造成 Hitstun | Light（18f） |
| hyperarmor | 无 |
| 弧线 | 左 → 右，1.6 m |
| `can_buffer` | 后摇 recovery f13–20（**8f**） |
| 取消窗口 | 仅 buffer → Light3 或 DodgeRoll 或 Guard |

### Light3

| 字段 | 数值 |
| --- | --- |
| 输入 | 在 Light2 的 `can_buffer` 期间消耗 Light |
| stamina | 16 |
| 起手 startup | **14** |
| 判定 active | **8**（`hit_on` f15，`hit_off` f23） |
| 后摇 recovery | **28** |
| 合计 | 50 |
| 伤害 | 110 |
| stance 伤害 | 26 |
| 造成 Hitstun | Light（18f） |
| hyperarmor | 无 |
| 弧线 | 过顶斜斩，1.8 m（轻微步进 0.4 m） |
| `can_buffer` | 后摇 recovery f19–28（**10f**） |
| 取消窗口 | 仅 buffer → DodgeRoll 或 Guard。**无 Light4。不循环。** |
| 备注 | 打空是玩家可被罚的失误。敌人 Sweep（预警 22 + active）可以打中打空的 Light3。 |

完整连段 stamina：13+13+16 = **42**。剩余 58 — 仍够一次翻滚。

---

## Heavy

点按 Heavy。若 Heavy 按住 ≥ 20f，**不使用**本状态；见蓄力重击 ChargedHeavy。

| 字段 | 数值 |
| --- | --- |
| 输入 | Heavy 在蓄力 f20 之前松开，来自 Idle / Walk / buffer |
| stamina | 24 |
| 起手 startup | **22** |
| 判定 active | **8**（`hit_on` f23，`hit_off` f31） |
| 后摇 recovery | **32** |
| 合计 | 62 |
| 伤害 | 155 |
| stance 伤害 | 36 |
| 造成 Hitstun | Heavy（26f） |
| hyperarmor | **有** — `hyperarmor_on` f16，`hyperarmor_off` f31（startup 末段 + 全部 active） |
| 弧线 | 右 → 左重斩，1.7 m，小步进 0.5 m |
| `can_buffer` | 后摇 recovery f23–32（**10f**） |
| 取消窗口 | 仅 buffer → DodgeRoll 或 Guard 或 Light（不会连进 Light2；Heavy 之后的 Light 是 Light1） |

若 hyperarmor 开着，必须能与敌人 Sweep 对撞打完。f16–30 期间轻击打中玩家会扣伤害，但不会取消 Heavy。

---

## 蓄力重击 ChargedHeavy

| 字段 | 数值 |
| --- | --- |
| 输入 | 按住 Heavy ≥ 20f，松开（或 48f 时自动松开） |
| 蓄力 | 最短 20f 才算合格，最长 48f。不合格松开 = 改为 Heavy |
| stamina | **36**，在松开时支付 |
| 松手后起手 startup | **6** |
| 判定 active | **10**（`hit_on` 松开+7，`hit_off` 松开+17） |
| 后摇 recovery | **36** |
| 伤害 | 250 |
| stance 伤害 | 58 |
| 造成 Hitstun | Slam 级（34f + 8f 起身） |
| hyperarmor | **有** — 蓄力 f12 时 `hyperarmor_on`，`hit_off` 时 `hyperarmor_off` |
| 蓄力期间移动 | 以 90°/s 转向 lock-on，以 0.8 m/s 行走 |
| 弧线 | 双手过顶，1.8 m，步进 0.7 m |
| `can_buffer` | 后摇 recovery f25–36（**12f**） |
| 取消窗口 | 仅 buffer → Roll 或 Guard。**不能取消蓄力**，除了：lock-on 切换，以及进入 StanceBroken（不适用）或 Death。仅当 hyperarmor 关闭时才会被 Hitstun 取消（从蓄力 f12 起它是开着的）。 |
| 备注 | 一次蓄力（58）+ Light1+2（38）= 96 stance。再一下 Light3（26）即破。两次蓄力超过 100。 |

---

## 跳跃攻击

Jump 本身是移动状态；攻击是后续。Jump **没有 i-frame**。

### Jump（无攻击）

| 字段 | 数值 |
| --- | --- |
| 输入 | 从 Idle / Walk / Run 按 Jump |
| stamina | 8 |
| 空中 | 上升 10f，下落 16f，若无攻击则落地回复 6f（合计 32f） |
| hyperarmor | 无 |
| 取消 | 从跳跃 f8 起到落地前 2f，按 Light 或 Heavy 则 JumpAttack |

### JumpAttack

| 字段 | 数值 |
| --- | --- |
| 输入 | 跳跃期间按 Light 或 Heavy（一招） |
| stamina | +14（含跳跃合计 22），在进入 JumpAttack 时支付 |
| 起手 startup | 按下后 **12** |
| 判定 active | **8**（旨在与落地重叠；`hit_on` 按下+13） |
| 后摇 recovery | `hit_off` 之后地面 **24** |
| 伤害 | 140 |
| stance 伤害 | 32 |
| 造成 Hitstun | Heavy（26f） |
| hyperarmor | 无 |
| 弧线 | 下劈，1.6 m，略向前 0.6 m |
| `can_buffer` | 地面后摇 recovery f17–24（**8f**） |
| 取消窗口 | 仅 buffer → Roll、Guard、Light1、Heavy |

若玩家始终不按攻击，就只落地。不要自动攻击。

---

## 奔跑攻击

| 字段 | 数值 |
| --- | --- |
| 输入 | 在 `Run` 中 ≥ 8f 后按 Light **或** Heavy |
| stamina | 18（冲刺消耗已另行发生） |
| 起手 startup | **13** |
| 判定 active | **8**（`hit_on` f14，`hit_off` f22） |
| 后摇 recovery | **24** |
| 合计 | 45 |
| 伤害 | 120 |
| stance 伤害 | 24 |
| 造成 Hitstun | Heavy（26f） |
| hyperarmor | 无 |
| 位移 | 向前突进 1.2 m |
| 弧线 | 刺斩，1.9 m，窄 50° |
| `can_buffer` | 后摇 recovery f17–24（**8f**） |
| 取消窗口 | 仅 buffer → Roll、Guard、Light1、Heavy |

v1 不要拆成奔跑轻击和奔跑重击。

---

## 翻滚 DodgeRoll

| 字段 | 数值 |
| --- | --- |
| 输入 | Roll + 8 向；无方向 + lock-on = 远离敌人翻滚；无方向且未锁定 = 沿相机前方翻滚 |
| stamina | 20 |
| 总长 | **32** |
| 起手 startup（可被打） | f1–3 |
| i-frame | **13f**：`iframe_on` **f4**，`iframe_off` **f17**（f4–16 含两端） |
| 后摇 recovery | f17–32（16f，无 i-frame） |
| 距离 | 4.2 m |
| 伤害 / Stance | — |
| hyperarmor | 无（i-frame 不是 hyperarmor） |
| `can_buffer` | f25–32（**8f**）→ Light1、Heavy、Roll、Guard、Jump |
| 取消窗口 | `can_buffer` 之前没有。不能把攻击的 startup 取消进本招。 |
| 备注 | 5 次翻滚 = 100 stamina。第 6 次在 0 时输入 = Exhaust。过早翻滚进 Slam 的 active：若 i-frame 已结束仍会吃落地判定。 |

Debug：i-frame 开启时，胶囊可选蓝色染色。

---

## Guard

| 字段 | 数值 |
| --- | --- |
| 输入 | 按住 Guard |
| 举盾 | **4f** 直到格挡生效 |
| 维持 | 前方 **180°**。背后命中仍判定。 |
| 收盾 | 松开后 **8f**（不能格挡） |
| stamina（维持） | 0 |
| 格挡时 stamina | Sweep / DoubleSlash / 玩家等价轻击 **22**；Thrust **32**；Slam **48**；玩家 Heavy **28**；ChargedHeavy **40** |
| 格挡时 HP | 若 stamina 仍 ≥ 0 则为 0 |
| GuardHit | 10f；可继续按住；这 10f 内不能攻击 |
| GuardBreak | 若一次格挡会把 stamina 推到 < 0：**50f** 破防，无格挡，可被一套完整轻击连段惩罚 |
| hyperarmor | 无 |
| `can_buffer` | 按住时不适用；收盾时最后 4f 可 buffer Roll 或攻击 |
| 取消 | 从 Idle/Walk 进入举盾。从已列出的 buffer 窗口进入。从 Guard 翻滚：4f 收盾再 DodgeRoll（仍支付翻滚 stamina）。 |
| 备注 | **无弹反。无削 HP。无格挡反击。** |

被格挡的攻击不会让攻击者硬直。

---

## stance 击破 Riposte（处决）

| 字段 | 数值 |
| --- | --- |
| 输入 | Light **或** Heavy，敌人处于 `StanceBroken`，平面距离 ≤ **2.2 m** |
| stamina | 0 |
| 起手 startup | **16**（踏入） |
| 判定 active | **4**（`hit_on` f17，`hit_off` f21）— 演出刺击；若 `hit_on` 时仍在范围内则必定命中 |
| 后摇 recovery | **28** |
| 伤害 | **380** |
| stance 伤害 | 0（敌人已经破了） |
| hyperarmor | **有**，整招（`hyperarmor_on` f1，结束时 `hyperarmor_off`） |
| `can_buffer` | 后摇 recovery f21–28（**8f**） |
| 取消窗口 | buffer 之前没有（Death 仍优先） |
| 超出范围时 | 改为打出普通 Light1 / Heavy — 不要「打空的 Riposte」 |
| 相机 | 可选 20f 推近。验收不要求。 |
| 美术 | 敌人绿色跪地；玩家突刺；刺中时敌人 1 帧闪白 |

允许 Riposte 击杀（900 HP；380 若没死则把敌人留在可接补刀的处决距离）。同一局里两次 Riposte 只有在玩家于 Wakeup 后再破一次 stance 才可能（stance 40）。

---

## Exhaust（不是战斗招式，但是锁定状态）

| 字段 | 数值 |
| --- | --- |
| 触发 | stamina 为 0 时输入 Attack/Roll/JumpAttack/RunningAttack |
| 时长 | **48f** |
| hyperarmor | 无 |
| 可罚 | 容得下敌人的 Light1+Light2（37f）还有余量，或玩家当木桩：敌人 DoubleSlash 完整连段 |
| `can_buffer` | 最后 8f 可存储 Guard 或 Walk；不能存攻击 |

---

## 事件放置速查（玩家）

| 招式 | hit_on | hit_off | iframe_on | iframe_off | hyperarmor_on | hyperarmor_off | can_buffer |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Light1 | 11 | 17 | — | — | — | — | rec 11 |
| Light2 | 12 | 18 | — | — | — | — | rec 13 |
| Light3 | 15 | 23 | — | — | — | — | rec 19 |
| Heavy | 23 | 31 | — | — | 16 | 31 | rec 23 |
| ChargedHeavy | rel+7 | rel+17 | — | — | charge 12 | rel+17 | rec 25 |
| JumpAttack | press+13 | press+21 | — | — | — | — | g-rec 17 |
| RunningAttack | 14 | 22 | — | — | — | — | rec 17 |
| DodgeRoll | — | — | 4 | 17 | — | — | 25 |
| Riposte | 17 | 21 | — | — | 1 | end | rec 21 |

`rec N` = 后摇 recovery 的第 N 帧。美术：把上述命名关键帧放到这些帧上；不要发明额外事件名。

---

## v1 明确不做

弹反、后撤步、蹲下、踢击、跳跃重击与跳跃轻击拆分、奔跑重击拆分、蓄力轻击、格挡反击、战技、道具使用、作为机制变化的双手切换、双持、骑马。
