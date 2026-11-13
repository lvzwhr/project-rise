# 开工战斗 demo

以制作人身份启动 Project Rise。

1. 先读 `docs/PROJECT.md` 和 `docs/TEAM.md`。
2. 先派给 `combat-designer`：把最小可玩的法环式战斗规格写进 `docs/design/`（玩家招式表、stamina / stance / i-frame、一名骑士敌人、验收清单）。60 FPS 帧数。不要开放世界和养成。文档用中文，事件名和状态名保留英文。
3. 这些文件齐了之后并行分派：
   - `combat-programmer`：在 `game/` 搭 Godot 4 3D、状态机、hitbox、lock-on、Debug HUD，对齐设计表。工程说明用中文。
   - `combat-artist`：风格规范、动画事件名、逐招时间轴、占位网格，对齐同一套事件。`docs/art/` 用中文。
4. 回报：现在能玩什么、卡在什么、下一步改哪条手感。

不要自己做这三条线，除非子代理不可用。
