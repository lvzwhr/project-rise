# 手感目标 — v1 冻结

所有检查在 **60 FPS**、Debug HUD 开启下进行。若某项目标失败，改 `player-moveset.md` / `enemy-knight.md` / `combat-gdd.md` 里的**具名字段**。不要加系统。

通过 = 一个人能在竞技场里坐下来复现它。

---

## 玩家武器时间

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F1 | Light1 起手 startup **≤ 12f** | 冻结为 **10f**。从 Idle 按 Light；不晚于第 11 帧出现 `hit_on`。 |
| F2 | 轻击连段是真正的 3 下，不是乱按搅拌器 | 在每个 `can_buffer` 内按 Light 时，三下都能打中站立木桩/敌人。Light1 后等到 Idle 再按，只有一挥。 |
| F3 | Light3 打空可被罚 | 在 Sweep 距离打空 Light3；敌人在你 recovery 时起手的 Sweep 能接上。 |
| F4 | Heavy 体感比 Light 慢 | Heavy 起手 startup **22f**（大约 2× Light1）。看得见蓄力。 |
| F5 | 蓄力重击是决策，不是点按 | 按住 Heavy < 20f 总是打出 Heavy（155 伤害），绝不是 ChargedHeavy（250）。按住 ≥ 20f 再松开打出 ChargedHeavy。 |
| F6 | 跳跃攻击没有 i-frame | 跳进 Sweep 的 active；玩家被打中。 |
| F7 | 奔跑攻击需要真正的跑 | 在 Walk 中按 Light 打出 Light1，不是 RunningAttack。必须 `Run` ≥ 8f。 |

---

## 翻滚与 i-frame

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F8 | 翻滚 i-frame **13f**，从 **第 4 帧** 开始 | HUD：`iframe_on` f4，`iframe_off` f17。计数为 13。 |
| F9 | 翻滚不是逃出 startup 的按钮 | Light1 的 startup 期间，Roll 被忽略直到 `can_buffer`。 |
| F10 | 晚滚胜过 Slam；早滚不行 | 翻滚使 i-frame 覆盖 Slam f33–40 → 无伤害。在落地前 16f 翻滚，使 i-frame 在 `hit_on` 前结束 → 吃 210。 |
| F11 | 翻滚有 recovery | `iframe_off` 之后，Sweep 的 active 若与翻滚 f17–24 重叠仍会打中。 |

---

## stamina 经济

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F12 | 慌乱翻滚会被收税 | 从 100 stamina 起，5 次翻滚清空条（5×20）。第 6 次在 0 时输入 Roll 播放 **Exhaust 48f**，而不是再滚一次。 |
| F13 | 空 stamina 可被轻击惩罚 | 玩家 Exhaust 期间，敌人（或第二名测试者）打出 Light 级命中 / DoubleSlash。48f ≥ Light1+Light2（37f）。 |
| F14 | 连段加一次翻滚合法；连段加两次翻滚很紧 | Light1+2+3 = 42。一次翻滚（20）仍可能。完整连段后再额外两次翻滚需要等回复。 |
| F15 | 回复救不了你连招中途 | 每次消耗后有 18f 回复延迟。不能靠「中间回一点」无可见停顿地连滚 5 次。 |
| F16 | 冲刺不是免费的 | 按住 Run：20f 之后条以 12/s 往下跳。到 0 时趔趄 12f，无 Exhaust。 |
| F17 | GuardBreak 比干净翻滚更糟 | 在 ≤ 47 stamina 时格挡 Slam → GuardBreak **50f**。卡好的翻滚本该换来免费输出。 |

---

## 格挡（无弹反）

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F18 | 前方格挡，背后命中 | 按住 Guard，敌人 Sweep 从正面来 → 0 HP，−22 stamina。同一记 Sweep 从背后 → 满额 130 HP。 |
| F19 | 格挡不会让攻击者硬直 | 格挡后敌人走完 Sweep 的 recovery；玩家不能从格挡里 Riposte。 |
| F20 | 四下轻击压力威胁盾 | 22×4 = 88。第 5 下轻击级格挡（或一记 32 的 Thrust）会在无回复间隙时从满条 GuardBreak。 |

---

## hyperarmor

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F21 | 玩家 Heavy 与 Sweep 对撞打完 | 起手 Heavy，使 hyperarmor（f16–31）与 Sweep 的 active 重叠。玩家吃 130，Heavy 仍打出 155。状态不会在挥砍中变成 Hitstun。 |
| F22 | 玩家轻击**没有** hyperarmor | 在 Light1 的 active 期间被打中 → Light 被取消，18f Hitstun。 |
| F23 | 蓄力重击的 hyperarmor 在蓄力期间开始 | 蓄力 f12 之后，一记 Sweep 打中；蓄力不被取消；松开仍会打出。 |
| F24 | Slam 的 hyperarmor | 玩家在 Slam 预警 f12 之后打出 Light1，不能取消 Slam。 |

---

## lock-on 与走位

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F25 | lock-on 是近战默认 | 锁定时，摇杆左右在 Mid 距离以 Walk 速度**绕圈**骑士，不会漂进朝向 bug。 |
| F26 | Thrust 靠侧步赢，不是靠盯着 | Thrust 预警 f10 之后用 lock-on 绕圈离开直线 → 0 伤害，然后 Light1 打进 34f recovery。 |
| F27 | 丢失锁定是明确的 | 走到 > 16 m：锁定解除。在 ≤ 14 m 用切换重新获取。 |

---

## stance 与 Riposte

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F28 | stance 看得见，打中会掉 | HUD 上 stance 在 Light1 掉 **18**，Heavy 掉 **36**，ChargedHeavy 掉 **58**。 |
| F29 | 击破窗口够走过去 | ChargedHeavy（58）+ Light1（18）+ Light2（20）= 96；Light3（26）击破。**90f** 跪地够 Walk 2 m 并 Riposte。 |
| F30 | 错过窗口不是完全重置 | 无视跪地：Wakeup 后 stance 是 **40**，不是 100。 |
| F31 | Riposte 伤害是一大块，不是拍一下 | 900 里的 380。若血还够，战斗继续。 |
| F32 | Riposte 不能隔着半场放 | > 2.2 m + 跪地期间按 Light = Light1，不是 380。 |

---

## 敌人可读性

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F33 | 关掉 HUD 仍可读 | Sweep vs Thrust vs Slam vs DoubleSlash 能在 Mid 距离从姿势 + 颜色叫出来。 |
| F34 | Sweep 预警 ≥ 18f | 冻结 **22f** 红。 |
| F35 | Slam 预警 ≥ 28f | 冻结 **32f** + f8 地面圈。 |
| F36 | 可罚是绿色 | Slam 的 recovery 和 StanceBroken 一眼读得出绿。 |
| F37 | 判定是黄色 | 只有 hitbox 开启时，武器 / 砸地体积才是黄。 |

---

## 战斗时长与致死

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F38 | 玩家能吃一次失误 | 1000 HP 对 130 Sweep → 扛得住 7 记生吃 Sweep。一下打不死。 |
| F39 | 玩家不能无视 Slam | 210 × 4 = 840。三记未应对的 Slam 再加削血就威胁击杀。 |
| F40 | 一局大约一分钟，不是 8 分钟决斗 | 合格操作（连段、1–2 次 Heavy、一次 Riposte 混合）大约 **45–90 s** 打掉 900 HP。若没死却打了 > 3 分钟，伤害太低 — 提高表里的伤害，不要加出血。 |

---

## buffer 诚实

| ID | 目标 | 通过条件 |
| --- | --- | --- |
| F41 | `can_buffer` 是唯一连段门闸 | HUD 标志在列出的 recovery 帧打开，不是在 `hit_on`。 |
| F42 | 10f 记忆 | 在 `can_buffer` 前 6f 按 Light；标志打开时仍出 Light2。提前 12f 按（记忆已过期）→ 没有 Light2。 |

---

## 手感不对时的调参顺序

1. 失败招式上的帧（startup / i-frame / 预警）。
2. stamina 消耗或回复延迟。
3. 伤害 / stance 数字。
4. AI 权重 / 冷却。

停。不要加弹反、状态异常、额外 i-frame 招式或新敌人来「修」v1。
