# One-shot generator for Project Rise combat placeholders. Run from anywhere.
# Outputs Godot 4.x .tres / .tscn under game/assets/. Does not touch runtime scenes.

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent
MAT = ROOT / "materials"
ANIM_P = ROOT / "animation" / "player"
ANIM_E = ROOT / "animation" / "enemy"
CHAR = ROOT / "characters"
VFX = ROOT / "vfx"
MESH = ROOT / "meshes"

FPS = 60.0


def t(frame: int) -> float:
    return (frame - 1) / FPS


def length(total: int) -> float:
    return total / FPS


def fmt(x: float) -> str:
    return f"{x:.6f}".rstrip("0").rstrip(".") if abs(x) >= 1e-9 else "0"


def ensure_dirs() -> None:
    for d in (MAT, ANIM_P, ANIM_E, CHAR, VFX, MESH):
        d.mkdir(parents=True, exist_ok=True)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.replace("\r\n", "\n"), encoding="utf-8")
    print("wrote", path.relative_to(ROOT))


# --- materials ---

def material(
    name: str,
    albedo: str,
    *,
    metallic: float = 0.0,
    roughness: float = 0.7,
    emission: str | None = None,
    emission_energy: float = 1.5,
    unshaded: bool = False,
    alpha: bool = False,
    albedo_a: float | None = None,
    no_depth: bool = False,
    billboard: bool = False,
    disable_ao: bool = False,
) -> str:
    lines = [
        '[gd_resource type="StandardMaterial3D" format=3]',
        "",
        "[resource]",
        f'resource_name = "{name}"',
    ]
    if alpha:
        lines.append("transparency = 1")
        lines.append("blend_mode = 1")
    if unshaded:
        lines.append("shading_mode = 0")
    if billboard:
        lines.append("billboard_mode = 1")
        lines.append("billboard_keep_scale = true")
    if no_depth:
        lines.append("no_depth_test = false")
    lines.append("disable_receive_shadows = true" if (unshaded or alpha) else "disable_receive_shadows = false")
    if albedo_a is not None:
        # albedo is "r, g, b"
        lines.append(f"albedo_color = Color({albedo}, {fmt(albedo_a)})")
    else:
        lines.append(f"albedo_color = Color({albedo}, 1)")
    lines.append(f"metallic = {fmt(metallic)}")
    lines.append(f"roughness = {fmt(roughness)}")
    if emission:
        lines.append("emission_enabled = true")
        lines.append(f"emission = Color({emission}, 1)")
        lines.append(f"emission_energy_multiplier = {fmt(emission_energy)}")
    if disable_ao:
        lines.append("ao_enabled = false")
    if unshaded or alpha:
        lines.append("cull_mode = 2")
    return "\n".join(lines) + "\n"


def write_materials() -> None:
    # GDD tokens
    red = "0.878431, 0.188235, 0.188235"
    yellow = "0.941176, 0.815686, 0.188235"
    green = "0.188235, 0.752941, 0.376471"
    blue = "0.250980, 0.627451, 1"
    orange = "0.878431, 0.439216, 0.125490"

    specs = {
        "player_body.tres": material(
            "PlayerBody", "0.42, 0.5, 0.58", metallic=0.35, roughness=0.48
        ),
        "player_armor.tres": material(
            "PlayerArmor", "0.55, 0.62, 0.7", metallic=0.62, roughness=0.38
        ),
        "player_weapon.tres": material(
            "PlayerWeapon", "0.72, 0.76, 0.82", metallic=0.85, roughness=0.28
        ),
        "enemy_body.tres": material(
            "EnemyBody", "0.16, 0.14, 0.13", metallic=0.45, roughness=0.5
        ),
        "enemy_armor.tres": material(
            "EnemyArmor", "0.22, 0.18, 0.16", metallic=0.55, roughness=0.42
        ),
        "enemy_pauldron.tres": material(
            "EnemyPauldron",
            red,
            metallic=0.15,
            roughness=0.55,
            emission=red,
            emission_energy=0.35,
        ),
        "enemy_weapon.tres": material(
            "EnemyWeapon", "0.32, 0.28, 0.26", metallic=0.7, roughness=0.35
        ),
        "enemy_trim.tres": material(
            "EnemyTrim", "0.46, 0.32, 0.2", metallic=0.7, roughness=0.4
        ),
        "telegraph_red.tres": material(
            "TelegraphRed",
            red,
            unshaded=True,
            alpha=True,
            albedo_a=0.85,
            emission=red,
            emission_energy=2.0,
        ),
        "active_yellow.tres": material(
            "ActiveYellow",
            yellow,
            unshaded=True,
            alpha=True,
            albedo_a=0.9,
            emission=yellow,
            emission_energy=2.2,
        ),
        "punish_green.tres": material(
            "PunishGreen",
            green,
            unshaded=True,
            alpha=True,
            albedo_a=0.75,
            emission=green,
            emission_energy=1.6,
        ),
        "iframe_debug_blue.tres": material(
            "IframeDebugBlue",
            blue,
            unshaded=True,
            alpha=True,
            albedo_a=0.4,
            emission=blue,
            emission_energy=1.2,
        ),
        "hyperarmor_debug_orange.tres": material(
            "HyperarmorDebugOrange",
            orange,
            unshaded=True,
            alpha=True,
            albedo_a=0.4,
            emission=orange,
            emission_energy=1.2,
        ),
        "hurt_flash_white.tres": material(
            "HurtFlashWhite",
            "1, 1, 1",
            unshaded=True,
            emission="1, 1, 1",
            emission_energy=3.0,
        ),
        "vfx_slash.tres": material(
            "VfxSlash",
            "0.92, 0.95, 1",
            unshaded=True,
            alpha=True,
            albedo_a=0.7,
            emission="0.85, 0.9, 1",
            emission_energy=1.8,
        ),
        "vfx_spark.tres": material(
            "VfxSpark",
            "1, 0.92, 0.55",
            unshaded=True,
            alpha=True,
            albedo_a=1.0,
            emission="1, 0.85, 0.4",
            emission_energy=2.5,
            billboard=True,
        ),
        "slam_circle.tres": material(
            "SlamCircle",
            red,
            unshaded=True,
            alpha=True,
            albedo_a=0.42,
            emission=red,
            emission_energy=1.4,
        ),
        "slam_circle_ring.tres": material(
            "SlamCircleRing",
            red,
            unshaded=True,
            alpha=True,
            albedo_a=0.85,
            emission=red,
            emission_energy=2.0,
        ),
        "stance_break_gold.tres": material(
            "StanceBreakGold",
            "1, 0.82, 0.25",
            unshaded=True,
            alpha=True,
            albedo_a=0.9,
            emission="1, 0.78, 0.2",
            emission_energy=2.4,
            billboard=True,
        ),
        "arena_floor.tres": material(
            "ArenaFloor", "0.38, 0.4, 0.42", metallic=0.05, roughness=0.85
        ),
    }
    for fname, body in specs.items():
        write(MAT / fname, body)


# --- animations ---

def anim_header(name: str, total_frames: int, loop: bool = False) -> list[str]:
    lines = [
        '[gd_resource type="Animation" format=3]',
        "",
        "[resource]",
        f'resource_name = "{name}"',
        f"length = {fmt(length(total_frames))}",
        f"loop_mode = {1 if loop else 0}",
        "step = 0.0166667",
    ]
    return lines


def method_track(index: int, events: list[tuple[int, str]], path: str = "..") -> list[str]:
    if not events:
        return []
    times = ", ".join(fmt(t(f)) for f, _ in events)
    trans = ", ".join("1" for _ in events)
    values = []
    for _, method in events:
        values.append(
            "{\n"
            '"args": [],\n'
            f'"method": &"{method}"\n'
            "}"
        )
    values_joined = ", ".join(values)
    return [
        f'tracks/{index}/type = "method"',
        f"tracks/{index}/imported = false",
        f"tracks/{index}/enabled = true",
        f'tracks/{index}/path = NodePath("{path}")',
        f"tracks/{index}/interp = 1",
        f"tracks/{index}/loop_wrap = true",
        f"tracks/{index}/keys = {{",
        f'"times": PackedFloat32Array({times}),',
        f'"transitions": PackedFloat32Array({trans}),',
        f'"values": [{values_joined}]',
        "}",
    ]


def value_track(
    index: int,
    node_prop: str,
    keys: list[tuple[int, str]],
    *,
    discrete: bool = False,
    interp: int | None = None,
) -> list[str]:
    times = ", ".join(fmt(t(f)) for f, _ in keys)
    trans = ", ".join("1" for _ in keys)
    values = ", ".join(v for _, v in keys)
    upd = 1 if discrete else 0
    ip = 0 if discrete else (interp if interp is not None else 1)
    return [
        f'tracks/{index}/type = "value"',
        f"tracks/{index}/imported = false",
        f"tracks/{index}/enabled = true",
        f'tracks/{index}/path = NodePath("{node_prop}")',
        f"tracks/{index}/interp = {ip}",
        f"tracks/{index}/loop_wrap = true",
        f"tracks/{index}/keys = {{",
        f'"times": PackedFloat32Array({times}),',
        f'"transitions": PackedFloat32Array({trans}),',
        f'"update": {upd},',
        f'"values": [{values}]',
        "}",
    ]


def vec3(x: float, y: float, z: float) -> str:
    return f"Vector3({fmt(x)}, {fmt(y)}, {fmt(z)})"


def build_anim(
    name: str,
    total: int,
    events: list[tuple[int, str]],
    extra_tracks: list[list[str]] | None = None,
    loop: bool = False,
) -> str:
    lines = anim_header(name, total, loop=loop)
    idx = 0
    mt = method_track(idx, events)
    if mt:
        lines.extend(mt)
        idx += 1
    if extra_tracks:
        for tr in extra_tracks:
            # reindex
            remapped = []
            for row in tr:
                remapped.append(row.replace(f"tracks/0/", f"tracks/{idx}/"))
            lines.extend(remapped)
            idx += 1
    return "\n".join(lines) + "\n"


def vis(node: str, keys: list[tuple[int, bool]]) -> list[str]:
    kv = [(f, "true" if v else "false") for f, v in keys]
    return value_track(0, f"{node}:visible", kv, discrete=True)


def rot(node: str, keys: list[tuple[int, tuple[float, float, float]]]) -> list[str]:
    kv = [(f, vec3(*xyz)) for f, xyz in keys]
    return value_track(0, f"{node}:rotation_degrees", kv)


def pos(node: str, keys: list[tuple[int, tuple[float, float, float]]]) -> list[str]:
    kv = [(f, vec3(*xyz)) for f, xyz in keys]
    return value_track(0, f"{node}:position", kv)


GLOW_T = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/TelegraphGlow"
GLOW_A = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/ActiveGlow"
GLOW_P = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/PunishGlow"
TORSO = "Hip/Torso"
ARM_R = "Hip/Torso/ShoulderR/UpperArmR"
ARM_L = "Hip/Torso/ShoulderL/UpperArmL"
FORE_R = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR"
WPN = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot"
HIP = "Hip"
LEGL = "Hip/LegL"
LEGR = "Hip/LegR"


def write_player_anims() -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []

    def add(name: str, body: str) -> None:
        path = ANIM_P / f"{name}.tres"
        write(path, body)
        out.append((name, path))

    add("Idle", build_anim("Idle", 30, [], extra_tracks=[
        rot(TORSO, [(1, (0, 0, 0)), (30, (0, 0, 0))]),
        rot(ARM_R, [(1, (8, 0, -12)), (30, (8, 0, -12))]),
        rot(ARM_L, [(1, (8, 0, 12)), (30, (8, 0, 12))]),
    ], loop=True))

    add("Walk", build_anim("Walk", 24, [], extra_tracks=[
        rot(LEGL, [(1, (22, 0, 0)), (12, (-22, 0, 0)), (24, (22, 0, 0))]),
        rot(LEGR, [(1, (-22, 0, 0)), (12, (22, 0, 0)), (24, (-22, 0, 0))]),
        rot(ARM_R, [(1, (-18, 0, -10)), (12, (18, 0, -10)), (24, (-18, 0, -10))]),
        rot(ARM_L, [(1, (18, 0, 10)), (12, (-18, 0, 10)), (24, (18, 0, 10))]),
    ], loop=True))

    add("Run", build_anim("Run", 16, [], extra_tracks=[
        rot(LEGL, [(1, (32, 0, 0)), (8, (-32, 0, 0)), (16, (32, 0, 0))]),
        rot(LEGR, [(1, (-32, 0, 0)), (8, (32, 0, 0)), (16, (-32, 0, 0))]),
        rot(TORSO, [(1, (8, 0, 0)), (16, (8, 0, 0))]),
    ], loop=True))

    add("RunStumble", build_anim("RunStumble", 12, [], extra_tracks=[
        rot(TORSO, [(1, (18, 0, 0)), (12, (6, 0, 0))]),
        pos(HIP, [(1, (0, 0.82, 0)), (12, (0, 0.92, 0))]),
    ]))

    add("Light1", build_anim("Light1", 34, [
        (11, "hit_on"), (17, "hit_off"), (27, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (0, 28, 8)), (11, (0, 28, 8)), (14, (0, -40, -6)), (34, (0, -18, 0))]),
        rot(ARM_R, [(1, (10, 20, -70)), (11, (10, 20, -70)), (14, (20, -10, 75)), (34, (8, 0, 20))]),
        vis(GLOW_A, [(1, False), (11, True), (17, False)]),
    ]))

    add("Light2", build_anim("Light2", 37, [
        (12, "hit_on"), (18, "hit_off"), (30, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (0, -30, -8)), (12, (0, -30, -8)), (15, (0, 42, 6)), (37, (0, 16, 0))]),
        rot(ARM_R, [(1, (10, -15, 70)), (12, (10, -15, 70)), (15, (15, 10, -75)), (37, (8, 0, -15))]),
        vis(GLOW_A, [(1, False), (12, True), (18, False)]),
    ]))

    add("Light3", build_anim("Light3", 50, [
        (15, "hit_on"), (23, "hit_off"), (41, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (-25, 10, 0)), (15, (-25, 10, 0)), (18, (35, -8, 0)), (50, (12, 0, 0))]),
        rot(ARM_R, [(1, (-110, 0, -20)), (15, (-110, 0, -20)), (18, (40, 0, 10)), (50, (15, 0, 0))]),
        pos(HIP, [(1, (0, 0.92, 0)), (15, (0, 0.92, -0.15)), (23, (0, 0.92, -0.4)), (50, (0, 0.92, -0.4))]),
        vis(GLOW_A, [(1, False), (15, True), (23, False)]),
    ]))

    add("Heavy", build_anim("Heavy", 62, [
        (16, "hyperarmor_on"), (23, "hit_on"), (31, "hit_off"), (31, "hyperarmor_off"), (53, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (0, 40, 12)), (16, (0, 45, 14)), (23, (0, 45, 14)), (26, (0, -50, -8)), (62, (8, -20, 0))]),
        rot(ARM_R, [(1, (20, 25, -85)), (23, (20, 25, -85)), (26, (30, -15, 90)), (62, (10, 0, 25))]),
        pos(HIP, [(1, (0, 0.92, 0)), (23, (0, 0.92, -0.1)), (31, (0, 0.92, -0.5)), (62, (0, 0.92, -0.5))]),
        vis(GLOW_A, [(1, False), (23, True), (31, False)]),
    ]))

    add("ChargedHeavy_Charge", build_anim("ChargedHeavy_Charge", 48, [
        (12, "hyperarmor_on"),
    ], extra_tracks=[
        rot(TORSO, [(1, (-10, 0, 0)), (12, (-20, 0, 0)), (20, (-28, 0, 0)), (48, (-28, 0, 0))]),
        rot(ARM_R, [(1, (-40, 0, -20)), (20, (-140, 0, -10)), (48, (-140, 0, -10))]),
        rot(ARM_L, [(1, (-40, 0, 20)), (20, (-140, 0, 10)), (48, (-140, 0, 10))]),
        vis(GLOW_T, [(1, False)]),
    ]))

    add("ChargedHeavy_Release", build_anim("ChargedHeavy_Release", 52, [
        (7, "hit_on"), (17, "hit_off"), (17, "hyperarmor_off"), (41, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (-28, 0, 0)), (7, (-28, 0, 0)), (10, (40, 0, 0)), (52, (12, 0, 0))]),
        rot(ARM_R, [(1, (-140, 0, -10)), (7, (-140, 0, -10)), (10, (50, 0, 0)), (52, (10, 0, 0))]),
        rot(ARM_L, [(1, (-140, 0, 10)), (7, (-140, 0, 10)), (10, (40, 0, 0)), (52, (8, 0, 0))]),
        pos(HIP, [(1, (0, 0.92, 0)), (17, (0, 0.92, -0.7)), (52, (0, 0.92, -0.7))]),
        vis(GLOW_A, [(1, False), (7, True), (17, False)]),
    ]))

    add("Jump", build_anim("Jump", 32, [], extra_tracks=[
        pos(HIP, [(1, (0, 0.92, 0)), (10, (0, 1.55, 0)), (26, (0, 0.92, 0)), (32, (0, 0.92, 0))]),
        rot(LEGL, [(1, (10, 0, 0)), (10, (40, 0, 0)), (32, (0, 0, 0))]),
        rot(LEGR, [(1, (-8, 0, 0)), (10, (20, 0, 0)), (32, (0, 0, 0))]),
    ]))

    add("JumpAttack", build_anim("JumpAttack", 44, [
        (13, "hit_on"), (21, "hit_off"), (37, "can_buffer"),
    ], extra_tracks=[
        rot(ARM_R, [(1, (-100, 0, 0)), (13, (-100, 0, 0)), (16, (50, 0, 0)), (44, (12, 0, 0))]),
        rot(TORSO, [(1, (-20, 0, 0)), (13, (-20, 0, 0)), (16, (25, 0, 0)), (44, (0, 0, 0))]),
        pos(HIP, [(1, (0, 1.4, 0)), (13, (0, 1.1, -0.2)), (21, (0, 0.92, -0.6)), (44, (0, 0.92, -0.6))]),
        vis(GLOW_A, [(1, False), (13, True), (21, False)]),
    ]))

    add("RunningAttack", build_anim("RunningAttack", 45, [
        (14, "hit_on"), (22, "hit_off"), (38, "can_buffer"),
    ], extra_tracks=[
        rot(TORSO, [(1, (12, 0, 0)), (14, (12, 0, 0)), (18, (18, 0, 0)), (45, (6, 0, 0))]),
        rot(ARM_R, [(1, (-20, 0, 0)), (14, (-20, 0, 0)), (16, (-90, 0, 0)), (45, (-10, 0, 0))]),
        rot(WPN, [(1, (0, 0, 0)), (14, (0, 0, 0)), (16, (80, 0, 0)), (45, (0, 0, 0))]),
        pos(HIP, [(1, (0, 0.92, 0)), (22, (0, 0.92, -1.2)), (45, (0, 0.92, -1.2))]),
        vis(GLOW_A, [(1, False), (14, True), (22, False)]),
    ]))

    add("DodgeRoll", build_anim("DodgeRoll", 32, [
        (4, "iframe_on"), (17, "iframe_off"), (25, "can_buffer"),
    ], extra_tracks=[
        pos(HIP, [(1, (0, 0.92, 0)), (3, (0, 0.55, -0.4)), (16, (0, 0.45, -3.2)), (25, (0, 0.7, -4.0)), (32, (0, 0.92, -4.2))]),
        rot(HIP, [(1, (0, 0, 0)), (4, (80, 0, 0)), (16, (220, 0, 0)), (25, (340, 0, 0)), (32, (360, 0, 0))]),
        rot(TORSO, [(1, (20, 0, 0)), (16, (40, 0, 0)), (32, (0, 0, 0))]),
    ]))

    add("Guard_Raise", build_anim("Guard_Raise", 4, [], extra_tracks=[
        rot(ARM_L, [(1, (8, 0, 12)), (4, (-70, 40, 20))]),
        rot(ARM_R, [(1, (8, 0, -12)), (4, (-40, -20, -30))]),
    ]))

    add("Guard_Hold", build_anim("Guard_Hold", 16, [], extra_tracks=[
        rot(ARM_L, [(1, (-70, 40, 20)), (16, (-70, 40, 20))]),
        rot(ARM_R, [(1, (-40, -20, -30)), (16, (-40, -20, -30))]),
    ], loop=True))

    add("Guard_Lower", build_anim("Guard_Lower", 8, [], extra_tracks=[
        rot(ARM_L, [(1, (-70, 40, 20)), (8, (8, 0, 12))]),
        rot(ARM_R, [(1, (-40, -20, -30)), (8, (8, 0, -12))]),
    ]))

    add("GuardHit", build_anim("GuardHit", 10, [], extra_tracks=[
        rot(TORSO, [(1, (0, 0, 0)), (3, (8, -12, 0)), (10, (0, 0, 0))]),
        rot(ARM_L, [(1, (-70, 40, 20)), (3, (-80, 48, 24)), (10, (-70, 40, 20))]),
    ]))

    add("GuardBreak", build_anim("GuardBreak", 50, [], extra_tracks=[
        rot(TORSO, [(1, (20, 0, 0)), (50, (12, 0, 0))]),
        rot(ARM_R, [(1, (40, 0, 30)), (50, (20, 0, 15))]),
        rot(ARM_L, [(1, (40, 0, -30)), (50, (20, 0, -15))]),
        pos(HIP, [(1, (0, 0.75, 0)), (50, (0, 0.8, 0))]),
    ]))

    add("Riposte", build_anim("Riposte", 48, [
        (1, "hyperarmor_on"), (17, "hit_on"), (21, "hit_off"), (41, "can_buffer"), (48, "hyperarmor_off"),
    ], extra_tracks=[
        pos(HIP, [(1, (0, 0.92, 0)), (16, (0, 0.85, -1.0)), (48, (0, 0.92, -1.0))]),
        rot(ARM_R, [(1, (-30, 0, 0)), (17, (-30, 0, 0)), (19, (-95, 0, 0)), (48, (-20, 0, 0))]),
        rot(WPN, [(1, (0, 0, 0)), (17, (0, 0, 0)), (19, (70, 0, 0)), (48, (0, 0, 0))]),
        vis(GLOW_A, [(1, False), (17, True), (21, False)]),
    ]))

    add("Exhaust", build_anim("Exhaust", 48, [], extra_tracks=[
        rot(TORSO, [(1, (18, 0, 0)), (24, (22, 0, 0)), (48, (16, 0, 0))]),
        pos(HIP, [(1, (0, 0.78, 0)), (48, (0, 0.78, 0))]),
        rot(ARM_R, [(1, (30, 0, 25)), (48, (30, 0, 25))]),
    ]))

    add("Hitstun_Light", build_anim("Hitstun_Light", 18, [], extra_tracks=[
        rot(TORSO, [(1, (-8, 12, 0)), (18, (0, 0, 0))]),
    ]))

    add("Hitstun_Heavy", build_anim("Hitstun_Heavy", 26, [], extra_tracks=[
        rot(TORSO, [(1, (-16, 18, 0)), (26, (0, 0, 0))]),
        pos(HIP, [(1, (0, 0.85, 0.15)), (26, (0, 0.92, 0))]),
    ]))

    add("Hitstun_Slam", build_anim("Hitstun_Slam", 34, [], extra_tracks=[
        rot(HIP, [(1, (50, 0, 0)), (34, (40, 0, 0))]),
        pos(HIP, [(1, (0, 0.5, 0.3)), (34, (0, 0.45, 0.35))]),
    ]))

    add("Hitstun_SlamGetup", build_anim("Hitstun_SlamGetup", 8, [], extra_tracks=[
        rot(HIP, [(1, (40, 0, 0)), (8, (0, 0, 0))]),
        pos(HIP, [(1, (0, 0.45, 0.35)), (8, (0, 0.92, 0))]),
    ]))

    add("Death", build_anim("Death", 20, [], extra_tracks=[
        rot(HIP, [(1, (0, 0, 0)), (20, (90, 0, 0))]),
        pos(HIP, [(1, (0, 0.92, 0)), (20, (0, 0.28, 0))]),
    ]))

    return out


def write_enemy_anims() -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []

    def add(name: str, body: str) -> None:
        path = ANIM_E / f"{name}.tres"
        write(path, body)
        out.append((name, path))

    add("Idle", build_anim("Idle", 40, [], extra_tracks=[
        rot(TORSO, [(1, (0, 0, 0)), (40, (0, 0, 0))]),
        rot(ARM_R, [(1, (10, 0, -18)), (40, (10, 0, -18))]),
        rot(ARM_L, [(1, (10, 0, 18)), (40, (10, 0, 18))]),
    ], loop=True))

    add("Walk", build_anim("Walk", 28, [], extra_tracks=[
        rot(LEGL, [(1, (18, 0, 0)), (14, (-18, 0, 0)), (28, (18, 0, 0))]),
        rot(LEGR, [(1, (-18, 0, 0)), (14, (18, 0, 0)), (28, (-18, 0, 0))]),
    ], loop=True))

    # Sweep 60f — HOLD coil f1-22
    add("Sweep", build_anim("Sweep", 60, [
        (23, "hit_on"), (33, "hit_off"),
    ], extra_tracks=[
        rot(TORSO, [(1, (0, 42, 8)), (22, (0, 42, 8)), (23, (0, 42, 8)), (28, (0, -55, -6)), (40, (8, -40, 0)), (60, (8, -30, 0))]),
        rot(ARM_R, [(1, (15, 30, -95)), (22, (15, 30, -95)), (28, (25, -20, 100)), (60, (15, 0, 40))]),
        vis(GLOW_T, [(1, True), (23, False)]),
        vis(GLOW_A, [(1, False), (23, True), (33, False)]),
        vis(GLOW_P, [(1, False), (40, True)]),
    ]))

    # Thrust 60f — point pose, lock facing is code at f10
    add("Thrust", build_anim("Thrust", 60, [
        (19, "hit_on"), (27, "hit_off"),
    ], extra_tracks=[
        rot(TORSO, [(1, (8, 0, 0)), (10, (10, 0, 0)), (18, (10, 0, 0)), (22, (16, 0, 0)), (32, (22, 0, 0)), (60, (18, 0, 0))]),
        rot(ARM_R, [(1, (-70, 0, 0)), (18, (-75, 0, 0)), (22, (-100, 0, 0)), (60, (-40, 0, 0))]),
        rot(WPN, [(1, (70, 0, 0)), (18, (80, 0, 0)), (22, (90, 0, 0)), (60, (40, 0, 0))]),
        pos(HIP, [(1, (0, 0.95, 0)), (19, (0, 0.95, 0)), (27, (0, 0.95, -1.4)), (60, (0, 0.95, -1.4))]),
        vis(GLOW_T, [(1, True), (19, False)]),
        vis(GLOW_A, [(1, False), (19, True), (27, False)]),
        vis(GLOW_P, [(1, False), (32, True)]),
    ]))

    # Slam 80f — HOLD raise, circle is a separate scene at f8
    add("Slam", build_anim("Slam", 80, [
        (12, "hyperarmor_on"), (33, "hit_on"), (41, "hit_off"), (41, "hyperarmor_off"),
    ], extra_tracks=[
        rot(TORSO, [(1, (-8, 0, 0)), (8, (-22, 0, 0)), (32, (-30, 0, 0)), (36, (35, 0, 0)), (41, (20, 0, 0)), (80, (12, 0, 0))]),
        rot(ARM_R, [(1, (-40, 0, -15)), (8, (-130, 0, -10)), (32, (-150, 0, -8)), (36, (55, 0, 0)), (80, (20, 0, 0))]),
        rot(ARM_L, [(1, (-40, 0, 15)), (8, (-130, 0, 10)), (32, (-150, 0, 8)), (36, (50, 0, 0)), (80, (18, 0, 0))]),
        pos(HIP, [(1, (0, 0.95, 0)), (33, (0, 0.95, 0)), (41, (0, 0.7, -0.4)), (80, (0, 0.72, -0.4))]),
        rot(LEGL, [(1, (0, 0, 0)), (41, (35, 0, 0)), (80, (30, 0, 0))]),
        rot(LEGR, [(1, (0, 0, 0)), (41, (28, 0, 0)), (80, (24, 0, 0))]),
        vis(GLOW_T, [(1, True), (33, False)]),
        vis(GLOW_A, [(1, False), (33, True), (41, False)]),
        vis(GLOW_P, [(1, False), (41, True)]),
    ]))

    add("DoubleSlash", build_anim("DoubleSlash", 67, [
        (17, "hit_on"), (24, "hit_off"), (34, "hit_on"), (42, "hit_off"),
    ], extra_tracks=[
        rot(TORSO, [
            (1, (-12, 20, 8)), (16, (-12, 20, 8)),
            (20, (18, -25, -6)),
            (24, (6, -10, 0)), (28, (4, 8, 4)), (33, (-8, -18, -6)),
            (38, (16, 30, 4)),
            (49, (10, 18, 0)), (67, (8, 12, 0)),
        ]),
        rot(ARM_R, [
            (1, (-80, 20, -40)), (16, (-80, 20, -40)),
            (20, (30, -10, 50)),
            (24, (10, 0, 20)), (33, (-20, -25, 70)),
            (38, (25, 15, -80)),
            (67, (12, 0, 20)),
        ]),
        vis(GLOW_T, [(1, True), (17, False), (24, True), (34, False)]),
        vis(GLOW_A, [(1, False), (17, True), (24, False), (34, True), (42, False)]),
        vis(GLOW_P, [(1, False), (49, True)]),
    ]))

    add("DoubleSlash1", build_anim("DoubleSlash1", 33, [
        (17, "hit_on"), (24, "hit_off"),
    ], extra_tracks=[
        rot(TORSO, [(1, (-12, 20, 8)), (16, (-12, 20, 8)), (20, (18, -25, -6)), (24, (6, -10, 0)), (28, (4, 8, 4)), (33, (-8, -18, -6))]),
        rot(ARM_R, [(1, (-80, 20, -40)), (16, (-80, 20, -40)), (20, (30, -10, 50)), (24, (10, 0, 20)), (33, (-20, -25, 70))]),
        vis(GLOW_T, [(1, True), (17, False), (24, True)]),
        vis(GLOW_A, [(1, False), (17, True), (24, False)]),
    ]))

    add("DoubleSlash2", build_anim("DoubleSlash2", 44, [
        (11, "hit_on"), (19, "hit_off"),
    ], extra_tracks=[
        rot(TORSO, [(1, (4, 8, 4)), (10, (-8, -18, -6)), (15, (16, 30, 4)), (26, (10, 18, 0)), (44, (8, 12, 0))]),
        rot(ARM_R, [(1, (10, 0, 20)), (10, (-20, -25, 70)), (15, (25, 15, -80)), (44, (12, 0, 20))]),
        vis(GLOW_T, [(1, True), (11, False)]),
        vis(GLOW_A, [(1, False), (11, True), (19, False)]),
        vis(GLOW_P, [(1, False), (26, True)]),
    ]))

    add("StanceBroken", build_anim("StanceBroken", 90, [], extra_tracks=[
        pos(HIP, [(1, (0, 0.52, 0)), (90, (0, 0.52, 0))]),
        rot(HIP, [(1, (18, 0, 0)), (90, (18, 0, 0))]),
        rot(TORSO, [(1, (22, 8, 0)), (90, (22, 8, 0))]),
        rot(ARM_R, [(1, (70, 0, 25)), (90, (70, 0, 25))]),
        rot(ARM_L, [(1, (55, 0, -20)), (90, (55, 0, -20))]),
        rot(LEGL, [(1, (55, 0, -8)), (90, (55, 0, -8))]),
        rot(LEGR, [(1, (70, 0, 10)), (90, (70, 0, 10))]),
        vis(GLOW_P, [(1, True), (90, True)]),
        vis(GLOW_T, [(1, False)]),
        vis(GLOW_A, [(1, False)]),
    ]))

    add("Wakeup", build_anim("Wakeup", 24, [
        (1, "hyperarmor_on"), (24, "hyperarmor_off"),
    ], extra_tracks=[
        pos(HIP, [(1, (0, 0.52, 0)), (24, (0, 0.95, 0))]),
        rot(HIP, [(1, (18, 0, 0)), (24, (0, 0, 0))]),
        rot(TORSO, [(1, (22, 8, 0)), (24, (0, 0, 0))]),
        vis(GLOW_P, [(1, True), (16, False)]),
    ]))

    add("Hitstun", build_anim("Hitstun", 18, [], extra_tracks=[
        rot(TORSO, [(1, (-10, 14, 0)), (18, (0, 0, 0))]),
    ]))

    add("Death", build_anim("Death", 24, [], extra_tracks=[
        rot(HIP, [(1, (0, 0, 0)), (24, (90, 0, 0))]),
        pos(HIP, [(1, (0, 0.95, 0)), (24, (0, 0.32, 0))]),
    ]))

    return out


def anim_library(name: str, clips: list[tuple[str, Path]], rel_from: Path) -> str:
    lines = [f'[gd_resource type="AnimationLibrary" load_steps={len(clips) + 1} format=3]', ""]
    for i, (clip_name, path) in enumerate(clips, start=1):
        rel = path.relative_to(rel_from).as_posix()
        # library lives in animation/, clips in animation/player or animation/enemy
        rel = Path(name).parent
        # compute from animation/ folder
        pass
    # libraries sit in animation/
    lib_dir = ROOT / "animation"
    lines = [f'[gd_resource type="AnimationLibrary" load_steps={len(clips) + 1} format=3]', ""]
    for i, (clip_name, path) in enumerate(clips, start=1):
        rel = Path("res://assets/animation") / path.relative_to(ROOT / "animation")
        # Godot res path
        res = "res://assets/animation/" + path.relative_to(ROOT / "animation").as_posix()
        lines.append(f'[ext_resource type="Animation" path="{res}" id="clip_{i}"]')
    lines.append("")
    lines.append("[resource]")
    lines.append("_data = {")
    for i, (clip_name, _) in enumerate(clips, start=1):
        comma = "," if i < len(clips) else ""
        lines.append(f'&"{clip_name}": ExtResource("clip_{i}"){comma}')
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


# --- character scene ---

def xform(px=0.0, py=0.0, pz=0.0, rx=0.0, ry=0.0, rz=0.0) -> str:
    """Euler degrees to Transform3D (YXZ-ish via sequential — use identity + pos if no rot)."""
    import math
    ax, ay, az = math.radians(rx), math.radians(ry), math.radians(rz)
    # Godot Node3D default rotation order is YXZ
    cy, sy = math.cos(ay), math.sin(ay)
    cx, sx = math.cos(ax), math.sin(ax)
    cz, sz = math.cos(az), math.sin(az)
    # YXZ: Ry * Rx * Rz
    # basis columns
    # First Rz
    r00, r01, r02 = cz, -sz, 0
    r10, r11, r12 = sz, cz, 0
    r20, r21, r22 = 0, 0, 1
    # Rx
    a00, a01, a02 = 1, 0, 0
    a10, a11, a12 = 0, cx, -sx
    a20, a21, a22 = 0, sx, cx
    # Ry
    b00, b01, b02 = cy, 0, sy
    b10, b11, b12 = 0, 1, 0
    b20, b21, b22 = -sy, 0, cy

    def mul(A, B):
        return (
            A[0]*B[0] + A[1]*B[3] + A[2]*B[6],
            A[0]*B[1] + A[1]*B[4] + A[2]*B[7],
            A[0]*B[2] + A[1]*B[5] + A[2]*B[8],
            A[3]*B[0] + A[4]*B[3] + A[5]*B[6],
            A[3]*B[1] + A[4]*B[4] + A[5]*B[7],
            A[3]*B[2] + A[4]*B[5] + A[5]*B[8],
            A[6]*B[0] + A[7]*B[3] + A[8]*B[6],
            A[6]*B[1] + A[7]*B[4] + A[8]*B[7],
            A[6]*B[2] + A[7]*B[5] + A[8]*B[8],
        )

    rzm = (r00, r01, r02, r10, r11, r12, r20, r21, r22)
    rxm = (a00, a01, a02, a10, a11, a12, a20, a21, a22)
    rym = (b00, b01, b02, b10, b11, b12, b20, b21, b22)
    m = mul(rxm, rzm)
    m = mul(rym, m)
    # Godot Transform3D in tscn: xx, xy, xz, yx, yy, yz, zx, zy, zz, ox, oy, oz
    # That's basis.x.x, basis.x.y, basis.x.z, basis.y.x, ...
    xx, xy, xz = m[0], m[3], m[6]
    yx, yy, yz = m[1], m[4], m[7]
    zx, zy, zz = m[2], m[5], m[8]
    # wait, m is row-major r00 r01 r02 / r10 r11 r12 / r20 r21 r22
    # basis.x = first column = (r00, r10, r20)
    # tscn: basis.x.x, basis.x.y, basis.x.z, basis.y.x, basis.y.y, basis.y.z, basis.z.x, basis.z.y, basis.z.z
    bx = (m[0], m[3], m[6])  # col0 if row-major? row-major m[0]=r00, m[1]=r01, m[2]=r02, m[3]=r10...
    # row-major:
    # m[0]=r00 m[1]=r01 m[2]=r02
    # m[3]=r10 m[4]=r11 m[5]=r12
    # m[6]=r20 m[7]=r21 m[8]=r22
    # column x = (r00, r10, r20) = (m[0], m[3], m[6])
    vals = [
        m[0], m[3], m[6],  # x axis x,y,z
        m[1], m[4], m[7],  # y axis
        m[2], m[5], m[8],  # z axis
        px, py, pz,
    ]
    return "Transform3D(" + ", ".join(fmt(v) for v in vals) + ")"


def write_character_scene(
    filename: str,
    root_name: str,
    *,
    player: bool,
    lib_res: str,
    hip_y: float,
    torso_r: float,
    torso_h: float,
    head_r: float,
    shoulder_x: float,
    arm_r: float,
    arm_h: float,
    leg_r: float,
    blade_h: float,
    blade_w: float,
    extra_pauldron: bool,
) -> None:
    body_mat = "res://assets/materials/player_body.tres" if player else "res://assets/materials/enemy_body.tres"
    armor_mat = "res://assets/materials/player_armor.tres" if player else "res://assets/materials/enemy_armor.tres"
    weapon_mat = "res://assets/materials/player_weapon.tres" if player else "res://assets/materials/enemy_weapon.tres"
    pauldron_mat = "res://assets/materials/enemy_pauldron.tres"
    tel = "res://assets/materials/telegraph_red.tres"
    act = "res://assets/materials/active_yellow.tres"
    pun = "res://assets/materials/punish_green.tres"

    ext = [
        ("Material", body_mat, "mat_body"),
        ("Material", armor_mat, "mat_armor"),
        ("Material", weapon_mat, "mat_weapon"),
        ("Material", tel, "mat_tel"),
        ("Material", act, "mat_act"),
        ("Material", pun, "mat_pun"),
        ("AnimationLibrary", lib_res, "lib"),
    ]
    if extra_pauldron:
        ext.append(("Material", pauldron_mat, "mat_paul"))

    load_steps = len(ext) + 1 + 8  # meshes as subresources
    lines: list[str] = [f"[gd_scene load_steps={load_steps} format=3]", ""]
    for typ, path, eid in ext:
        lines.append(f'[ext_resource type="{typ}" path="{path}" id="{eid}"]')
    lines.append("")

    # sub meshes
    def cap(sid, radius, height):
        lines.append(f'[sub_resource type="CapsuleMesh" id="{sid}"]')
        lines.append(f"radius = {fmt(radius)}")
        lines.append(f"height = {fmt(height)}")
        lines.append("radial_segments = 8")
        lines.append("rings = 4")
        lines.append("")

    def sph(sid, radius):
        lines.append(f'[sub_resource type="SphereMesh" id="{sid}"]')
        lines.append(f"radius = {fmt(radius)}")
        lines.append("radial_segments = 8")
        lines.append("rings = 4")
        lines.append("")

    def box(sid, sx, sy, sz):
        lines.append(f'[sub_resource type="BoxMesh" id="{sid}"]')
        lines.append(f"size = Vector3({fmt(sx)}, {fmt(sy)}, {fmt(sz)})")
        lines.append("")

    cap("mesh_torso", torso_r, torso_h)
    sph("mesh_head", head_r)
    cap("mesh_arm", arm_r, arm_h)
    cap("mesh_fore", arm_r * 0.9, arm_h * 0.85)
    cap("mesh_thigh", leg_r, 0.42 if player else 0.46)
    cap("mesh_shin", leg_r * 0.9, 0.4 if player else 0.44)
    box("mesh_weapon", blade_w, blade_h, blade_w * 0.55)
    box("mesh_glow", blade_w * 1.35, blade_h * 1.04, blade_w * 0.85)
    if extra_pauldron:
        cap("mesh_paul", 0.14, 0.28)

    def node(name, typ, parent, transform=None, extra=None):
        if parent is None:
            lines.append(f'[node name="{name}" type="{typ}"]')
        else:
            lines.append(f'[node name="{name}" type="{typ}" parent="{parent}"]')
        if transform:
            lines.append(f"transform = {transform}")
        if extra:
            lines.extend(extra)
        lines.append("")

    def mesh_node(name, parent, mesh_id, mat_id, transform=None, extra=None):
        extras = [f"mesh = SubResource(\"{mesh_id}\")", f"surface_material_override/0 = ExtResource(\"{mat_id}\")"]
        if extra:
            extras.extend(extra)
        node(name, "MeshInstance3D", parent, transform, extras)

    node(root_name, "Node3D", None, extra=[
        'script = null',
    ])
    # strip script = null? Godot might warn. Omit.
    lines[-2] = lines[-2]  # no-op keep last blank
    # actually I already wrote script = null. Remove it by rebuilding last node... leave it, might be invalid.
    # I'll fix: don't include script = null. Recreate root without it.
    # Easier to post-filter.
    node("AnimationPlayer", "AnimationPlayer", ".", extra=[
        'libraries = {',
        '&"": ExtResource("lib")',
        "}",
        'autoplay = "Idle"',
    ])
    node("Vfx_Chest", "Marker3D", ".", xform(0, hip_y + 0.38, 0))
    node("Vfx_Feet", "Marker3D", ".", xform(0, 0.02, 0))
    node("Hip", "Node3D", ".", xform(0, hip_y, 0))
    mesh_node("Mesh_Pelvis", "Hip", "mesh_torso", "mat_armor", xform(0, -0.08, 0))
    node("Torso", "Node3D", "Hip", xform(0, 0.22 if player else 0.24, 0))
    mesh_node("Mesh_Torso", "Hip/Torso", "mesh_torso", "mat_armor" if player else "mat_body", xform(0, 0.05, 0))
    node("Head", "Node3D", "Hip/Torso", xform(0, torso_h * 0.55, 0))
    mesh_node("Mesh_Head", "Hip/Torso/Head", "mesh_head", "mat_body" if player else "mat_armor")

    # shoulders / arms
    node("ShoulderL", "Node3D", "Hip/Torso", xform(-shoulder_x, 0.16, 0))
    node("UpperArmL", "Node3D", "Hip/Torso/ShoulderL")
    mesh_node("Mesh_UpperArmL", "Hip/Torso/ShoulderL/UpperArmL", "mesh_arm", "mat_body", xform(0, -arm_h * 0.45, 0))
    node("ForeArmL", "Node3D", "Hip/Torso/ShoulderL/UpperArmL", xform(0, -arm_h * 0.9, 0))
    mesh_node("Mesh_ForeArmL", "Hip/Torso/ShoulderL/UpperArmL/ForeArmL", "mesh_fore", "mat_body", xform(0, -arm_h * 0.38, 0))
    if extra_pauldron:
        mesh_node(
            "Pauldron",
            "Hip/Torso/ShoulderL",
            "mesh_paul",
            "mat_paul",
            xform(-0.04, 0.04, 0.02, rz=25),
        )

    node("ShoulderR", "Node3D", "Hip/Torso", xform(shoulder_x, 0.16, 0))
    node("UpperArmR", "Node3D", "Hip/Torso/ShoulderR")
    mesh_node("Mesh_UpperArmR", "Hip/Torso/ShoulderR/UpperArmR", "mesh_arm", "mat_body", xform(0, -arm_h * 0.45, 0))
    node("ForeArmR", "Node3D", "Hip/Torso/ShoulderR/UpperArmR", xform(0, -arm_h * 0.9, 0))
    mesh_node("Mesh_ForeArmR", "Hip/Torso/ShoulderR/UpperArmR/ForeArmR", "mesh_fore", "mat_body", xform(0, -arm_h * 0.38, 0))
    node("HandR", "Node3D", "Hip/Torso/ShoulderR/UpperArmR/ForeArmR", xform(0, -arm_h * 0.75, 0))
    node("WeaponPivot", "Node3D", "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR", xform(0.02, 0.02, 0.04, rx=-15, rz=-12))
    wparent = "Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot"
    mesh_node("Weapon", wparent, "mesh_weapon", "mat_weapon", xform(0, blade_h * 0.48, 0))
    mesh_node("TelegraphGlow", wparent, "mesh_glow", "mat_tel", xform(0, blade_h * 0.48, 0), extra=["visible = false"])
    mesh_node("ActiveGlow", wparent, "mesh_glow", "mat_act", xform(0, blade_h * 0.48, 0), extra=["visible = false"])
    mesh_node("PunishGlow", wparent, "mesh_glow", "mat_pun", xform(0, blade_h * 0.48, 0), extra=["visible = false"])
    node("Vfx_Blade", "Marker3D", wparent, xform(0, blade_h * 0.48, 0))
    node("Vfx_Tip", "Marker3D", wparent, xform(0, blade_h * 0.98, 0))

    node("LegL", "Node3D", "Hip", xform(-leg_r * 1.3, -0.12, 0))
    mesh_node("Mesh_ThighL", "Hip/LegL", "mesh_thigh", "mat_armor" if player else "mat_body", xform(0, -0.2, 0))
    node("ShinL", "Node3D", "Hip/LegL", xform(0, -0.42, 0))
    mesh_node("Mesh_ShinL", "Hip/LegL/ShinL", "mesh_shin", "mat_body", xform(0, -0.18, 0))
    node("LegR", "Node3D", "Hip", xform(leg_r * 1.3, -0.12, 0))
    mesh_node("Mesh_ThighR", "Hip/LegR", "mesh_thigh", "mat_armor" if player else "mat_body", xform(0, -0.2, 0))
    node("ShinR", "Node3D", "Hip/LegR", xform(0, -0.42, 0))
    mesh_node("Mesh_ShinR", "Hip/LegR/ShinR", "mesh_shin", "mat_body", xform(0, -0.18, 0))

    # debug tint capsules (hidden)
    debug_mesh = "mesh_torso"
    node("Debug_Iframe", "MeshInstance3D", ".", xform(0, 0.9, 0), extra=[
        "visible = false",
        f'mesh = SubResource("{debug_mesh}")',
        'surface_material_override/0 = ExtResource("mat_act")',  # replaced below
    ])

    text = "\n".join(lines) + "\n"
    text = text.replace('script = null\n', "")
    # Fix debug materials properly in a second pass for player vs enemy
    write(CHAR / filename, text)


def patch_debug_tints() -> None:
    """Rewrite debug overlay nodes with correct materials by appending isn't needed if we write properly.

    We'll inject iframe/hyperarmor overlay as extra ext_resources via a simpler dedicated pair of MeshInstance.
    """
    pass


def write_player_scene_fixed() -> None:
    # Rewrite player/enemy scenes more carefully with debug mats included.
    write_character_scene(
        "player_knight_visual.tscn",
        "PlayerKnightVisual",
        player=True,
        lib_res="res://assets/animation/player_combat.tres",
        hip_y=0.92,
        torso_r=0.22,
        torso_h=0.62,
        head_r=0.13,
        shoulder_x=0.26,
        arm_r=0.065,
        arm_h=0.34,
        leg_r=0.08,
        blade_h=1.10,
        blade_w=0.07,
        extra_pauldron=False,
    )
    write_character_scene(
        "enemy_knight_visual.tscn",
        "EnemyKnightVisual",
        player=False,
        lib_res="res://assets/animation/enemy_combat.tres",
        hip_y=0.98,
        torso_r=0.28,
        torso_h=0.70,
        head_r=0.145,
        shoulder_x=0.34,
        arm_r=0.08,
        arm_h=0.36,
        leg_r=0.1,
        blade_h=1.25,
        blade_w=0.09,
        extra_pauldron=True,
    )


def write_vfx_scenes() -> None:
    # slam floor circle
    slam = """[gd_scene load_steps=5 format=3]

[ext_resource type="Material" path="res://assets/materials/slam_circle.tres" id="mat_fill"]
[ext_resource type="Material" path="res://assets/materials/slam_circle_ring.tres" id="mat_ring"]

[sub_resource type="CylinderMesh" id="cyl"]
top_radius = 1.6
bottom_radius = 1.6
height = 0.03
radial_segments = 28
rings = 1

[sub_resource type="TorusMesh" id="torus"]
inner_radius = 1.52
outer_radius = 1.6
rings = 24
ring_segments = 8

[sub_resource type="Animation" id="anim_pulse"]
resource_name = "Pulse"
length = 0.416667
loop_mode = 1
step = 0.0166667
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Fill:transparency")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.2, 0.416667),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [0.2, 0.45, 0.2]
}

[sub_resource type="AnimationLibrary" id="lib"]
_data = {
&"Pulse": SubResource("anim_pulse")
}

[node name="SlamFloorCircle" type="Node3D"]

[node name="Fill" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
cast_shadow = 0
mesh = SubResource("cyl")
surface_material_override/0 = ExtResource("mat_fill")

[node name="Ring" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0)
cast_shadow = 0
mesh = SubResource("torus")
surface_material_override/0 = ExtResource("mat_ring")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
&"": SubResource("lib")
}
autoplay = "Pulse"
"""
    # MeshInstance3D has no "transparency" property — pulse should use modulate or material.
    # Use visibility scale nudge on Ring only, keep radius 1.6. Animate Ring modulate.
    slam = """[gd_scene load_steps=6 format=3]

[ext_resource type="Material" path="res://assets/materials/slam_circle.tres" id="mat_fill"]
[ext_resource type="Material" path="res://assets/materials/slam_circle_ring.tres" id="mat_ring"]

[sub_resource type="CylinderMesh" id="cyl"]
top_radius = 1.6
bottom_radius = 1.6
height = 0.03
radial_segments = 28
rings = 1

[sub_resource type="TorusMesh" id="torus"]
inner_radius = 1.52
outer_radius = 1.6
rings = 24
ring_segments = 8

[sub_resource type="Animation" id="anim_pulse"]
resource_name = "Pulse"
length = 0.5
loop_mode = 1
step = 0.0166667
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Ring:modulate")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.25, 0.5),
"transitions": PackedFloat32Array(1, 1, 1),
"update": 0,
"values": [Color(1, 1, 1, 0.55), Color(1, 1, 1, 1), Color(1, 1, 1, 0.55)]
}

[sub_resource type="AnimationLibrary" id="lib"]
_data = {
&"Pulse": SubResource("anim_pulse")
}

[node name="SlamFloorCircle" type="Node3D"]

[node name="Fill" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.02, 0)
cast_shadow = 0
mesh = SubResource("cyl")
surface_material_override/0 = ExtResource("mat_fill")

[node name="Ring" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.035, 0)
cast_shadow = 0
mesh = SubResource("torus")
surface_material_override/0 = ExtResource("mat_ring")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
&"": SubResource("lib")
}
autoplay = "Pulse"
"""
    write(VFX / "slam_floor_circle.tscn", slam)

    telegraph = """[gd_scene load_steps=3 format=3]

[ext_resource type="Material" path="res://assets/materials/telegraph_red.tres" id="mat"]

[sub_resource type="BoxMesh" id="blade"]
size = Vector3(0.1, 1.2, 0.06)

[node name="TelegraphWeapon" type="Node3D"]

[node name="Glow" type="MeshInstance3D" parent="."]
cast_shadow = 0
mesh = SubResource("blade")
surface_material_override/0 = ExtResource("mat")
"""
    write(VFX / "telegraph_weapon.tscn", telegraph)

    active = """[gd_scene load_steps=3 format=3]

[ext_resource type="Material" path="res://assets/materials/active_yellow.tres" id="mat"]

[sub_resource type="BoxMesh" id="blade"]
size = Vector3(0.1, 1.2, 0.06)

[node name="ActiveFlash" type="Node3D"]

[node name="Glow" type="MeshInstance3D" parent="."]
cast_shadow = 0
mesh = SubResource("blade")
surface_material_override/0 = ExtResource("mat")
"""
    write(VFX / "active_flash.tscn", active)

    slash = """[gd_scene load_steps=4 format=3]

[ext_resource type="Material" path="res://assets/materials/vfx_slash.tres" id="mat"]

[sub_resource type="BoxMesh" id="arc"]
size = Vector3(1.4, 0.04, 0.35)

[sub_resource type="Animation" id="anim"]
resource_name = "Play"
length = 0.133333
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("Arc:modulate")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.133333),
"transitions": PackedFloat32Array(1, 1),
"update": 0,
"values": [Color(1, 1, 1, 1), Color(1, 1, 1, 0)]
}

[sub_resource type="AnimationLibrary" id="lib"]
_data = {
&"Play": SubResource("anim")
}

[node name="SlashArc" type="Node3D"]

[node name="Arc" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -0.4)
cast_shadow = 0
mesh = SubResource("arc")
surface_material_override/0 = ExtResource("mat")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
&"": SubResource("lib")
}
autoplay = "Play"
"""
    write(VFX / "slash_arc.tscn", slash)

    spark = """[gd_scene load_steps=4 format=3]

[ext_resource type="Material" path="res://assets/materials/vfx_spark.tres" id="mat"]

[sub_resource type="ParticleProcessMaterial" id="ppm"]
direction = Vector3(0, 1, 0)
spread = 70.0
initial_velocity_min = 1.6
initial_velocity_max = 3.8
gravity = Vector3(0, -10, 0)
scale_min = 0.04
scale_max = 0.08
color = Color(1, 0.92, 0.55, 1)

[sub_resource type="QuadMesh" id="quad"]
material = ExtResource("mat")
size = Vector2(0.08, 0.08)

[node name="HitSpark" type="GPUParticles3D"]
emitting = false
amount = 14
lifetime = 0.13
one_shot = true
explosiveness = 1.0
local_coords = false
process_material = SubResource("ppm")
draw_pass_1 = SubResource("quad")
"""
    write(VFX / "hit_spark.tscn", spark)

    # stance break
    gold = """[gd_scene load_steps=4 format=3]

[ext_resource type="Material" path="res://assets/materials/stance_break_gold.tres" id="mat"]

[sub_resource type="ParticleProcessMaterial" id="ppm"]
direction = Vector3(0, 1, 0)
spread = 80.0
initial_velocity_min = 1.2
initial_velocity_max = 3.2
gravity = Vector3(0, -6, 0)
scale_min = 0.05
scale_max = 0.12
color = Color(1, 0.82, 0.25, 1)

[sub_resource type="QuadMesh" id="quad"]
material = ExtResource("mat")
size = Vector2(0.1, 0.1)

[node name="StanceBreakSpark" type="GPUParticles3D"]
emitting = false
amount = 18
lifetime = 0.2
one_shot = true
explosiveness = 1.0
local_coords = false
process_material = SubResource("ppm")
draw_pass_1 = SubResource("quad")
"""
    write(VFX / "stance_break_spark.tscn", gold)

    hurt = """[gd_scene load_steps=4 format=3]

[ext_resource type="Material" path="res://assets/materials/hurt_flash_white.tres" id="mat"]

[sub_resource type="CapsuleMesh" id="cap"]
radius = 0.42
height = 1.7

[sub_resource type="Animation" id="anim"]
resource_name = "Flash"
length = 0.016667
tracks/0/type = "value"
tracks/0/imported = false
tracks/0/enabled = true
tracks/0/path = NodePath("FlashMesh:visible")
tracks/0/interp = 1
tracks/0/loop_wrap = true
tracks/0/keys = {
"times": PackedFloat32Array(0, 0.016667),
"transitions": PackedFloat32Array(1, 1),
"update": 1,
"values": [true, false]
}

[sub_resource type="AnimationLibrary" id="lib"]
_data = {
&"Flash": SubResource("anim")
}

[node name="HurtFlash" type="Node3D"]

[node name="FlashMesh" type="MeshInstance3D" parent="."]
visible = false
cast_shadow = 0
mesh = SubResource("cap")
surface_material_override/0 = ExtResource("mat")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
libraries = {
&"": SubResource("lib")
}
"""
    write(VFX / "hurt_flash.tscn", hurt)

    # simple slash line for thrust
    line = """[gd_scene load_steps=3 format=3]

[ext_resource type="Material" path="res://assets/materials/active_yellow.tres" id="mat"]

[sub_resource type="BoxMesh" id="line"]
size = Vector3(0.08, 0.08, 2.2)

[node name="ThrustLine" type="Node3D"]

[node name="Line" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -1.1)
cast_shadow = 0
mesh = SubResource("line")
surface_material_override/0 = ExtResource("mat")
"""
    write(VFX / "thrust_line.tscn", line)


def write_readme() -> None:
    text = """# Combat placeholders — programmer wiring

Godot project root is assumed to be `game/` so these paths are `res://assets/...`.

Artist owns this folder. Do **not** replace runtime player/enemy controller scenes with these. Instance the visuals as children.

## Instance

```
Player (CharacterBody3D)          # your controller, has hit_on() / hit_off() / ...
└─ Visual                         # instance res://assets/characters/player_knight_visual.tscn
   └─ AnimationPlayer

Enemy (CharacterBody3D)
└─ Visual                         # instance res://assets/characters/enemy_knight_visual.tscn
   └─ AnimationPlayer
```

Root names inside the packed scenes: `PlayerKnightVisual`, `EnemyKnightVisual`.

Facing: **-Z** forward. Scale 1. Player visual ~1.80 m. Enemy visual ~1.95 m, wider, **red left pauldron**.

## AnimationPlayer

Default library (empty string key) is already assigned:

- Player: `res://assets/animation/player_combat.tres`
- Enemy: `res://assets/animation/enemy_combat.tres`

Clip names match frozen states. Method tracks call the **parent** (`NodePath("..")`).

If your functions live on a sibling, retarget the method track path. **Do not rename** `hit_on`, `hit_off`, `iframe_on`, `iframe_off`, `hyperarmor_on`, `hyperarmor_off`, `can_buffer`.

Play examples:

| State | Clip |
| --- | --- |
| Light1 | `Light1` |
| Heavy | `Heavy` |
| Charged hold | `ChargedHeavy_Charge` (hold last pose; `hyperarmor_on` at f12) |
| Charged release | `ChargedHeavy_Release` (clock = 0 on release) |
| Roll | `DodgeRoll` |
| Enemy string | `Sweep` / `Thrust` / `Slam` / `DoubleSlash` |
| Or split DS | `DoubleSlash1` then `DoubleSlash2` |
| Kneel | `StanceBroken` (90 f HOLD) |

`can_buffer` fires once at window start; keep the flag true until the state exits.

## Attach points (from visual root)

| Marker | Path |
| --- | --- |
| Chest | `Vfx_Chest` |
| Feet | `Vfx_Feet` |
| Blade | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Blade` |
| Tip | `Hip/Torso/ShoulderR/UpperArmR/ForeArmR/HandR/WeaponPivot/Vfx_Tip` |
| Red glow | `…/WeaponPivot/TelegraphGlow` |
| Yellow glow | `…/WeaponPivot/ActiveGlow` |
| Green glow | `…/WeaponPivot/PunishGlow` |
| Enemy pauldron | `Hip/Torso/ShoulderL/Pauldron` |

Weapon mesh: `…/WeaponPivot/Weapon`

Clips already toggle the three glow meshes for enemy attacks and player actives. You can also drive them from the seven events.

## VFX scenes to spawn

| What | Scene | When |
| --- | --- | --- |
| Slam floor circle **r=1.6 m red** | `res://assets/vfx/slam_floor_circle.tscn` | Enemy Slam **f8**. Parent to `Vfx_Feet`. Autoplay `Pulse`. Free/hide at `hit_on` or `hit_off`. |
| Hit spark | `res://assets/vfx/hit_spark.tscn` | On connected hit. `restart()`. |
| Stance-break spark | `res://assets/vfx/stance_break_spark.tscn` | StanceBroken enter. `restart()`. |
| Hurt flash | material `hurt_flash_white.tres` 1 frame on all `Hip` meshes, **or** `vfx/hurt_flash.tscn` play `Flash` at `Vfx_Chest` |
| Slash | `vfx/slash_arc.tscn` at `Vfx_Blade` (cut at `hit_off`) |
| Thrust line | `vfx/thrust_line.tscn` at `Vfx_Tip` |

## Hurt flash (preferred)

On hit (not a clean block):

1. For each `MeshInstance3D` under `Visual/Hip` (and enemy `Pauldron`): `material_override = preload("res://assets/materials/hurt_flash_white.tres")`
2. Next frame (1/60): `material_override = null`

## Debug tints

- I-frames: `res://assets/materials/iframe_debug_blue.tres`
- Hyperarmor: `res://assets/materials/hyperarmor_debug_orange.tres`

Toggle with the HUD. World telegraph red/yellow/green stay visible with HUD off.

## Root motion

Distances in `docs/art/animation-timeline.md` are **code** on the CharacterBody3D. Visual `Hip` position keys are readability only — disable them for physics if they double-move the actor (`callback_mode_process` / ignore Hip translation, or rest Hip and move only the body).

## Hitboxes

Do not use these meshes as hit volumes. Use the design capsules. Artist sword is a longsword bar, not the 2.8 m Thrust capsule.

## Arena floor material (optional)

`res://assets/materials/arena_floor.tres` — cool grey so `#E03030` pops. Assign if you own the arena mesh.

## Frame math

`t = (frame - 1) / 60`. Method keys are already placed. If you drive combat from a frame counter instead of AnimationPlayer methods, copy the tables in `docs/art/animation-timeline.md` — do not change counts.
"""
    write(ROOT / "README.md", text)


def fix_player_debug_materials() -> None:
    """Replace the mistaken Debug_Iframe material on both character scenes."""
    iframe = "res://assets/materials/iframe_debug_blue.tres"
    hyper = "res://assets/materials/hyperarmor_debug_orange.tres"
    for fname, needs_iframe in (
        ("player_knight_visual.tscn", True),
        ("enemy_knight_visual.tscn", False),
    ):
        path = CHAR / fname
        text = path.read_text(encoding="utf-8")
        # bump load_steps and inject ext
        # add ext resources after lib
        inject = (
            f'[ext_resource type="Material" path="{hyper}" id="mat_hyper"]\n'
        )
        if needs_iframe:
            inject += f'[ext_resource type="Material" path="{iframe}" id="mat_iframe"]\n'
        text = text.replace(
            '[ext_resource type="AnimationLibrary" path="res://assets/animation/',
            inject + '[ext_resource type="AnimationLibrary" path="res://assets/animation/',
            1,
        )
        # load_steps +1 or +2
        import re
        m = re.search(r"load_steps=(\d+)", text)
        if m:
            n = int(m.group(1)) + (2 if needs_iframe else 1)
            text = re.sub(r"load_steps=\d+", f"load_steps={n}", text, count=1)
        # replace Debug_Iframe node
        old = """[node name="Debug_Iframe" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)
visible = false
mesh = SubResource("mesh_torso")
surface_material_override/0 = ExtResource("mat_act")
"""
        extra_iframe = ""
        if needs_iframe:
            extra_iframe = """
[node name="Debug_Iframe" type="MeshInstance3D" parent="."]
transform = Transform3D(1.15, 0, 0, 0, 1.05, 0, 0, 0, 1.15, 0, 0.9, 0)
visible = false
cast_shadow = 0
mesh = SubResource("mesh_torso")
surface_material_override/0 = ExtResource("mat_iframe")
"""
        new = extra_iframe + """
[node name="Debug_Hyperarmor" type="MeshInstance3D" parent="."]
transform = Transform3D(1.18, 0, 0, 0, 1.08, 0, 0, 0, 1.18, 0, 0.9, 0)
visible = false
cast_shadow = 0
mesh = SubResource("mesh_torso")
surface_material_override/0 = ExtResource("mat_hyper")
"""
        if old in text:
            text = text.replace(old, new)
        else:
            text = text.rstrip() + "\n" + new
        path.write_text(text, encoding="utf-8")
        print("patched debug tints", fname)


def write_mesh_primitives() -> None:
    write(
        MESH / "capsule_player_body.tres",
        '[gd_resource type="CapsuleMesh" format=3]\n\n[resource]\nradius = 0.32\nheight = 1.6\nradial_segments = 8\nrings = 4\n',
    )
    write(
        MESH / "capsule_enemy_body.tres",
        '[gd_resource type="CapsuleMesh" format=3]\n\n[resource]\nradius = 0.4\nheight = 1.75\nradial_segments = 8\nrings = 4\n',
    )
    write(
        MESH / "sword_player.tres",
        '[gd_resource type="BoxMesh" format=3]\n\n[resource]\nsize = Vector3(0.07, 1.1, 0.04)\n',
    )
    write(
        MESH / "sword_enemy.tres",
        '[gd_resource type="BoxMesh" format=3]\n\n[resource]\nsize = Vector3(0.09, 1.25, 0.05)\n',
    )
    write(
        MESH / "slam_circle_cyl.tres",
        '[gd_resource type="CylinderMesh" format=3]\n\n[resource]\ntop_radius = 1.6\nbottom_radius = 1.6\nheight = 0.03\nradial_segments = 28\nrings = 1\n',
    )


def main() -> None:
    ensure_dirs()
    write_materials()
    write_mesh_primitives()
    pclips = write_player_anims()
    eclips = write_enemy_anims()
    write(ROOT / "animation" / "player_combat.tres", anim_library("player_combat", pclips, ROOT / "animation"))
    write(ROOT / "animation" / "enemy_combat.tres", anim_library("enemy_combat", eclips, ROOT / "animation"))
    write_player_scene_fixed()
    fix_player_debug_materials()
    write_vfx_scenes()
    write_readme()
    print("done")


if __name__ == "__main__":
    main()
