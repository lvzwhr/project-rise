# 验收 — 战斗演示 v1

在竞技场里玩，除非某条写明关掉 HUD，否则 **Debug HUD 开**。除非某条另说，否则使用 lock-on。只有**你本人**做过该操作才能勾选，子代理说通过了不算。

引擎：Godot 4.7.2。键盘或手柄。

---

## A. 启动与呈现

- [ ] 竞技场加载：平坦地面、玩家骑士、敌人骑士，双方存活。
- [ ] Debug HUD 显示玩家 HP 1000、stamina 100，敌人 HP 900、stance 100。
- [ ] HUD 显示玩家状态、敌人状态/攻击名、iframe、hyperarmor、can_buffer、lock-on 距离。
- [ ] hitbox/hurtbox 线框可以开关。
- [ ] 玩家和敌人轮廓在 12 m 可读（玩家更冷的钢色，敌人更深 + 红色点缀）。

---

## B. lock-on 与行走

- [ ] 切换 lock-on 锁上骑士。相机把对方留在画面内。
- [ ] 锁定 Walk 在 Mid 距离（2.2–3.5 m）两个方向绕圈。
- [ ] 锁定 Walk 后撤，不会切成后撤步招式。
- [ ] Run 比 Walk 快，并在 20f 后消耗 stamina（12/s）。
- [ ] 超过 16 m 丢失锁定；14 m 内可重新获取。

---

## C. 轻击连段

- [ ] 从 Idle 按 Light：起手 startup 10f，HUD 上出现 `hit_on`，80 伤害，18 stance。
- [ ] 在 Light1 的 `can_buffer` 内按 Light → Light2（85 伤害，20 stance）。
- [ ] 在 Light2 的 `can_buffer` 内按 Light → Light3（110 伤害，26 stance）。
- [ ] 没有 Light4；Light3 之后多按的会等到 Idle。
- [ ] 若等完 Light1 的 recovery，下一记 Light 仍是 Light1（连段掉了）。
- [ ] Light1+2+3 消耗 42 stamina。

---

## D. Heavy 与蓄力重击

- [ ] 点按 Heavy：22f startup，155 伤害，36 stance，hyperarmor f16–31。
- [ ] 按住 Heavy < 20f，松开：仍是未蓄力 Heavy，不是 ChargedHeavy。
- [ ] 按住 Heavy ≥ 20f，松开：ChargedHeavy，250 伤害，58 stance，36 stamina。
- [ ] 蓄力 48f 时自动松开打出 ChargedHeavy。
- [ ] 在 hyperarmor 期间用 Heavy 与敌人 Sweep 对撞：吃 HP，打完这记 Heavy。

---

## E. 跳跃与奔跑攻击

- [ ] 从 Idle 跳跃：无 i-frame（空中的 Sweep 会打中你）。
- [ ] 跳跃中按 Light/Heavy：JumpAttack，140 伤害，32 stance，落地后 24f 地面 recovery。
- [ ] Walk 中按 Light：Light1，不是 RunningAttack。
- [ ] Run ≥ 8f 后按 Light：RunningAttack，120 伤害，18 stamina，1.2 m 突进。

---

## F. 翻滚与 i-frame

- [ ] 翻滚消耗 20 stamina，持续 32f。
- [ ] HUD：iframe 在 f4 开，f17 关（13 帧）。
- [ ] 翻滚方向：相对 lock-on 的前 / 后 / 左 / 右都能用。
- [ ] 卡帧翻滚穿过 Slam 的 active：0 伤害，然后可以打绿色 recovery。
- [ ] 过早翻滚（i-frame 在 Slam `hit_on` 前结束）：被打中吃 210。
- [ ] Light1 的 startup 期间翻滚**不会**取消这记轻击。
- [ ] iframe_off 之后，翻滚 recovery 里仍可能被打中。

---

## G. stamina 失败状态

- [ ] 从满 stamina 翻滚五次清空条。
- [ ] 第 6 次在 0 stamina 时 Roll → Exhaust 48f（HUD 状态），敌人能用轻击 / DoubleSlash 打中你。
- [ ] stamina 为 0 时按攻击键 → Exhaust，不是白嫖一挥。
- [ ] 冲刺到 0 → 12f 趔趄，**不是** 48f Exhaust。
- [ ] stamina 回复只在上次消耗后的 18f 延迟之后开始。

---

## H. 格挡

- [ ] 4f 举盾。正面 Sweep：0 HP，−22 stamina，GuardHit 10f。
- [ ] 格挡时背后 Sweep：你吃 130 HP（仅 180°）。
- [ ] 被格挡的 Sweep 不会让敌人硬直；他们按正常 recovery。
- [ ] 点按或按住都不会出现弹反。
- [ ] 以 < 48 stamina 格挡 Slam → GuardBreak 50f，可被罚。
- [ ] 从 Guard 翻滚：短暂收盾然后正常翻滚（仍是 20 stamina）。

---

## I. 敌人：Sweep（格挡或翻滚）

- [ ] 预警 ≥ 22f，红色武器，向右水平蓄力。
- [ ] 判定黄色，打中则 130 伤害。
- [ ] 可从正面格挡。
- [ ] 可以翻滚。
- [ ] 关掉 HUD：仍能认成宽幅横斩。

---

## J. 敌人：Thrust（侧步 / recovery 惩罚）

- [ ] 预警 18f，枪尖姿势；追踪在预警 f10 后停止。
- [ ] 侧步离开直线 → 0 伤害。
- [ ] 侧步之后，Light1 打进 34f recovery（绿色）。
- [ ] 格挡可以，但花费 32 stamina（通过不强制去挡，但必须能用）。
- [ ] 关掉 HUD：读得出是直线攻击，不是横斩。

---

## K. 敌人：Slam（翻滚惩罚）

- [ ] 预警 32f，双手举起，**f8 红色地面圈**。
- [ ] 从预警 f12 起 hyperarmor：你的 Light 不能取消它。
- [ ] 判定 8f，210 伤害，打中则 Slam Hitstun。
- [ ] 翻滚过冲击，然后在 40f 绿色 recovery 里至少打出 Light1+Light2。
- [ ] 关掉 HUD：仍然明显是「出去 / 现在滚」。

---

## L. 敌人：DoubleSlash（可格挡）

- [ ] 两下，先 90 再 100，两下都可格挡（22+22 stamina）。
- [ ] 两下之间的间隙从正面不是完整连段可罚。
- [ ] 第 2 下 recovery 之后，Light1 能接上。
- [ ] 若你在 Close 按住 Guard，AI 更常使用这招。

---

## M. stance 击破与 Riposte

- [ ] 每次玩家命中按表扣 stance，HUD 会掉。
- [ ] 强制击破（例如 ChargedHeavy + 轻击连段）。敌人跪地 90f，绿色。
- [ ] 走进 ≤ 2.2 m，Light 或 Heavy → Riposte，380 伤害，0 stamina 消耗。
- [ ] 从 > 2.2 m 做 Riposte 会打出 Light1/Heavy。
- [ ] 若你不 Riposte，Wakeup 24f，stance 回到 **40**，不是 100。
- [ ] 可选相机推近可以有；勾本条不要求。

---

## N. 承诺感与 buffer

- [ ] `can_buffer` 只在列出的 recovery 尾段打开，HUD 上看得见。
- [ ] 在 `can_buffer` 前约 6f 按的 Light 仍能衔接；提前约 12f 按的不能。
- [ ] Light/Heavy 的 startup 期间不能格挡。
- [ ] Hitstun 会取消无 hyperarmor 的攻击；状态按等级变成 Hitstun，持续 18/26/34f。

---

## O. 致死与重置

- [ ] 玩家大约吃 7 记 Sweep 死亡；一记 Sweep 打不死。
- [ ] 敌人在单局里死于连段 / Heavy / 一次 Riposte 的混合（打得好大约 45–90 s）。
- [ ] 任一方死亡后约 2 s，双方在出生点重置，满 HP/stamina，敌人 stance 100。
- [ ] Debug 重置键（若有）不经过死亡也能做到同样效果。

---

## P. 关掉 HUD 的可读性（战斗支柱仍看得见）

- [ ] Debug HUD **关** 时，只靠预警颜色 + 姿势躲开 Slam。
- [ ] 关掉 HUD，在 active 之前分辨 Sweep / Thrust / Slam。
- [ ] 受击闪白是被打中者 1 帧白色。
- [ ] 黄色只在 hitbox 生效时存在。

---

## Q. 范围外（必须保持不存在）

- [ ] 无背包、道具、血瓶或菜单配装。
- [ ] 无弹反、战技、魔法、状态图标或第二名敌人生成。
- [ ] 无跳跃 i-frame，无额外闪避技能。
- [ ] 用到的动画事件只有：`hit_on`、`hit_off`、`iframe_on`、`iframe_off`、`hyperarmor_on`、`hyperarmor_off`、`can_buffer`。

---

## 未通过时

写下：哪些 ID 失败、当前数字、建议数字。设计师先改表；程序对齐；仅当成片长度撑不住这些帧时美术才介入。
