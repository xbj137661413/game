"""
Procedural ancient Chinese courtyard props for Blender 4/5.
Run:
  blender --background --python tools/blender_build_models.py
Exports .glb into assets/models/
"""

from __future__ import annotations

import math
import os
import traceback

import bpy

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SCRIPT_DIR)
OUT_DIR = os.path.join(ROOT, "assets", "models")


def ensure_out() -> None:
    for sub in ("architecture", "props", "characters"):
        os.makedirs(os.path.join(OUT_DIR, sub), exist_ok=True)


def clear_scene() -> None:
    # Safer than factory reset: keep Blender session, wipe data blocks
    if bpy.context.object and bpy.context.object.mode != "OBJECT":
        bpy.ops.object.mode_set(mode="OBJECT")
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for item in list(block):
            block.remove(item)


def make_mat(name: str, color, roughness=0.75, metallic=0.0, emission=None, emission_strength=0.0):
    m = bpy.data.materials.new(name=name)
    m.use_nodes = True
    nt = m.node_tree
    nodes = nt.nodes
    links = nt.links
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    bsdf.location = (0, 0)
    out.location = (250, 0)
    bsdf.inputs["Base Color"].default_value = (float(color[0]), float(color[1]), float(color[2]), 1.0)
    bsdf.inputs["Roughness"].default_value = float(roughness)
    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = float(metallic)
    if emission is not None and emission_strength > 0.0:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = (
                float(emission[0]),
                float(emission[1]),
                float(emission[2]),
                1.0,
            )
            bsdf.inputs["Emission Strength"].default_value = float(emission_strength)
        elif "Emission" in bsdf.inputs:
            bsdf.inputs["Emission"].default_value = (
                float(emission[0]),
                float(emission[1]),
                float(emission[2]),
                1.0,
            )
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return m


def palette():
    return {
        "wood": make_mat("Wood", (0.42, 0.26, 0.12), 0.85),
        "dark_wood": make_mat("DarkWood", (0.22, 0.12, 0.06), 0.9),
        "tile": make_mat("RoofTile", (0.28, 0.12, 0.10), 0.7),
        "plaster": make_mat("Plaster", (0.90, 0.86, 0.78), 0.95),
        "stone": make_mat("Stone", (0.55, 0.52, 0.48), 0.9),
        "red": make_mat("RedLacquer", (0.55, 0.12, 0.12), 0.55),
        "gold": make_mat("Gold", (0.82, 0.66, 0.24), 0.35, 0.75),
        "paper": make_mat("LanternPaper", (0.96, 0.88, 0.68), 0.55, 0.0, (1.0, 0.7, 0.3), 1.2),
        "cloth": make_mat("ClothRed", (0.6, 0.12, 0.12), 0.8),
        "leaf": make_mat("Leaf", (0.22, 0.42, 0.20), 0.85),
        "leaf2": make_mat("Leaf2", (0.28, 0.48, 0.24), 0.85),
        "bark": make_mat("Bark", (0.28, 0.16, 0.08), 0.95),
        "jade": make_mat("Jade", (0.4, 0.85, 0.55), 0.25, 0.1, (0.3, 0.9, 0.4), 0.5),
        "scroll": make_mat("Scroll", (0.78, 0.68, 0.42), 0.7, 0.0, (0.9, 0.75, 0.3), 0.3),
        "steel": make_mat("Steel", (0.75, 0.78, 0.82), 0.3, 0.8),
        "skin": make_mat("Skin", (0.78, 0.58, 0.45), 0.7),
        "hat": make_mat("Hat", (0.12, 0.1, 0.08), 0.9),
        "bandit": make_mat("BanditCloth", (0.35, 0.18, 0.16), 0.85),
    }


def assign_mat(obj, material):
    if material is None:
        return obj
    if obj.data.materials:
        obj.data.materials[0] = material
    else:
        obj.data.materials.append(material)
    return obj


def apply_tr(obj, location=False, rotation=True, scale=True):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=location, rotation=rotation, scale=scale)
    return obj


def box(name, size, loc=(0.0, 0.0, 0.0), rot=(0.0, 0.0, 0.0), material=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    obj.rotation_euler = rot
    apply_tr(obj)
    assign_mat(obj, material)
    return obj


def cylinder(name, radius, depth, loc=(0.0, 0.0, 0.0), vertices=16, material=None):
    bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc, vertices=vertices)
    obj = bpy.context.active_object
    obj.name = name
    assign_mat(obj, material)
    return obj


def cone(name, radius1, radius2, depth, loc=(0.0, 0.0, 0.0), vertices=16, material=None):
    bpy.ops.mesh.primitive_cone_add(
        radius1=radius1, radius2=radius2, depth=depth, location=loc, vertices=vertices
    )
    obj = bpy.context.active_object
    obj.name = name
    assign_mat(obj, material)
    return obj


def sphere(name, radius, loc=(0.0, 0.0, 0.0), material=None):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=loc, segments=20, ring_count=12)
    obj = bpy.context.active_object
    obj.name = name
    assign_mat(obj, material)
    return obj


def select_only(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]


def join_selected(name):
    bpy.ops.object.join()
    obj = bpy.context.active_object
    obj.name = name
    return obj


def origin_to_bottom(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    zs = [(obj.matrix_world @ v.co).z for v in obj.data.vertices]
    min_z = min(zs)
    obj.location.z -= min_z
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)


def export_glb(rel_parts, objects):
    path = os.path.join(OUT_DIR, *rel_parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    select_only(objects)
    bpy.ops.export_scene.gltf(
        filepath=path,
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
    )
    print("Exported:", path)
    return path


def build_and_export(name, rel_parts, builder):
    clear_scene()
    P = palette()
    obj = builder(P)
    if obj is None:
        raise RuntimeError(f"{name} returned None")
    origin_to_bottom(obj)
    export_glb(rel_parts, [obj])


# ---------------- builders return single joined object ----------------

def build_lantern(P):
    parts = [
        cylinder("Pole", 0.06, 1.5, loc=(0, 0, 0.75), material=P["dark_wood"]),
        box("Base", (0.18, 0.18, 0.08), loc=(0, 0, 0.04), material=P["stone"]),
        box("Paper", (0.55, 0.55, 0.7), loc=(0, 0, 1.75), material=P["paper"]),
        box("Top", (0.7, 0.7, 0.08), loc=(0, 0, 2.15), material=P["wood"]),
        box("Bottom", (0.7, 0.7, 0.08), loc=(0, 0, 1.35), material=P["wood"]),
        cone("Knob", 0.08, 0.02, 0.15, loc=(0, 0, 2.3), material=P["gold"]),
    ]
    select_only(parts)
    return join_selected("lantern")


def build_pillar(P):
    parts = [
        box("Base", (0.7, 0.7, 0.25), loc=(0, 0, 0.125), material=P["stone"]),
        cylinder("Shaft", 0.22, 3.6, loc=(0, 0, 2.05), vertices=20, material=P["dark_wood"]),
        box("Capital", (0.55, 0.55, 0.2), loc=(0, 0, 3.95), material=P["wood"]),
    ]
    select_only(parts)
    return join_selected("pillar")


def build_gate(P):
    parts = []
    for x in (-2.0, 2.0):
        parts.append(cylinder(f"Post_{x}", 0.28, 4.2, loc=(x, 0, 2.1), material=P["dark_wood"]))
        parts.append(box(f"Base_{x}", (0.7, 0.7, 0.3), loc=(x, 0, 0.15), material=P["stone"]))
        parts.append(box(f"Banner_{x}", (0.12, 0.05, 1.6), loc=(x, -0.35, 3.0), material=P["cloth"]))
    parts += [
        box("Beam", (5.2, 0.45, 0.45), loc=(0, 0, 4.0), material=P["red"]),
        box("Roof", (5.8, 1.4, 0.35), loc=(0, 0, 4.45), material=P["tile"]),
        box("Ridge", (5.6, 0.25, 0.2), loc=(0, 0, 4.75), material=P["dark_wood"]),
        box("Plaque", (1.6, 0.12, 0.55), loc=(0, 0.35, 3.6), material=P["red"]),
    ]
    select_only(parts)
    return join_selected("gate")


def build_stone_lion(P):
    parts = [
        box("Base", (1.1, 1.1, 0.35), loc=(0, 0, 0.175), material=P["stone"]),
        box("Body", (0.75, 0.55, 0.85), loc=(0, 0, 0.85), material=P["stone"]),
        box("Head", (0.55, 0.55, 0.5), loc=(0, 0.25, 1.45), material=P["stone"]),
        box("Snout", (0.28, 0.35, 0.22), loc=(0, 0.5, 1.3), material=P["stone"]),
        box("EarL", (0.12, 0.1, 0.18), loc=(-0.18, 0.15, 1.75), material=P["stone"]),
        box("EarR", (0.12, 0.1, 0.18), loc=(0.18, 0.15, 1.75), material=P["stone"]),
    ]
    select_only(parts)
    return join_selected("stone_lion")


def build_stele(P):
    parts = [
        box("Body", (1.2, 0.32, 1.8), loc=(0, 0, 1.05), material=P["stone"]),
        box("Top", (1.4, 0.4, 0.22), loc=(0, 0, 2.05), material=P["stone"]),
        box("Base", (1.5, 0.55, 0.25), loc=(0, 0, 0.125), material=P["stone"]),
    ]
    select_only(parts)
    return join_selected("stele")


def build_tree(P):
    parts = [
        cylinder("Trunk", 0.22, 3.2, loc=(0, 0, 1.6), vertices=12, material=P["bark"]),
        cone("Canopy1", 1.6, 0.4, 1.4, loc=(0, 0, 3.6), vertices=12, material=P["leaf"]),
        cone("Canopy2", 1.2, 0.25, 1.1, loc=(0.2, 0.15, 4.4), vertices=12, material=P["leaf2"]),
        cone("Canopy3", 0.9, 0.1, 0.9, loc=(-0.15, -0.1, 5.0), vertices=12, material=P["leaf"]),
    ]
    select_only(parts)
    return join_selected("tree")


def build_scroll(P):
    body = box("Scroll", (0.45, 0.12, 0.08), loc=(0, 0, 0.04), material=P["scroll"])
    left = cylinder("RollL", 0.05, 0.14, loc=(-0.25, 0, 0.04), material=P["wood"])
    left.rotation_euler = (math.radians(90), 0, 0)
    apply_tr(left)
    right = cylinder("RollR", 0.05, 0.14, loc=(0.25, 0, 0.04), material=P["wood"])
    right.rotation_euler = (math.radians(90), 0, 0)
    apply_tr(right)
    select_only([body, left, right])
    return join_selected("scroll")


def build_jade(P):
    return sphere("jade", 0.14, loc=(0, 0, 0.14), material=P["jade"])


def build_sword(P):
    blade = box("Blade", (0.05, 0.9, 0.02), loc=(0, 0.55, 0), material=P["steel"])
    guard = box("Guard", (0.22, 0.04, 0.05), loc=(0, 0.12, 0), material=P["gold"])
    handle = cylinder("Handle", 0.03, 0.28, loc=(0, -0.05, 0), material=P["dark_wood"])
    handle.rotation_euler = (math.radians(90), 0, 0)
    apply_tr(handle)
    pommel = cone("Pommel", 0.04, 0.02, 0.06, loc=(0, -0.22, 0), material=P["gold"])
    select_only([blade, guard, handle, pommel])
    return join_selected("sword")


def build_pavilion(P):
    parts = []
    for x in (-1.4, 1.4):
        for y in (-1.4, 1.4):
            parts.append(cylinder(f"Post_{x}_{y}", 0.12, 2.4, loc=(x, y, 1.35), material=P["dark_wood"]))
            parts.append(box(f"Base_{x}_{y}", (0.35, 0.35, 0.15), loc=(x, y, 0.08), material=P["stone"]))
    parts += [
        box("Floor", (3.2, 3.2, 0.15), loc=(0, 0, 0.2), material=P["stone"]),
        box("Deck", (3.0, 3.0, 0.12), loc=(0, 0, 2.55), material=P["wood"]),
        box("Roof", (3.6, 3.6, 0.18), loc=(0, 0, 2.85), material=P["tile"]),
        cone("Finial", 0.25, 0.02, 0.45, loc=(0, 0, 3.2), material=P["gold"]),
        box("RailY1", (2.8, 0.08, 0.08), loc=(0, -1.4, 1.0), material=P["wood"]),
        box("RailY2", (2.8, 0.08, 0.08), loc=(0, 1.4, 1.0), material=P["wood"]),
        box("RailX1", (0.08, 2.8, 0.08), loc=(-1.4, 0, 1.0), material=P["wood"]),
        box("RailX2", (0.08, 2.8, 0.08), loc=(1.4, 0, 1.0), material=P["wood"]),
    ]
    select_only(parts)
    return join_selected("pavilion")


def build_main_hall(P):
    parts = [box("Platform", (10, 6.5, 0.4), loc=(0, 0, 0.2), material=P["stone"])]
    for x in (-3.5, -1.2, 1.2, 3.5):
        for y in (-2.2, 2.2):
            parts.append(cylinder(f"P_{x}_{y}", 0.22, 3.6, loc=(x, y, 2.2), material=P["dark_wood"]))
            parts.append(box(f"B_{x}_{y}", (0.5, 0.5, 0.2), loc=(x, y, 0.5), material=P["stone"]))
    parts += [
        box("BackWall", (8.5, 0.3, 2.8), loc=(0, -2.5, 1.9), material=P["plaster"]),
        box("LeftWall", (0.3, 5.0, 2.8), loc=(-4.3, 0, 1.9), material=P["plaster"]),
        box("RightWall", (0.3, 5.0, 2.8), loc=(4.3, 0, 1.9), material=P["plaster"]),
        box("BeamF", (9.0, 0.35, 0.3), loc=(0, 2.4, 3.9), material=P["red"]),
        box("BeamB", (9.0, 0.35, 0.3), loc=(0, -2.4, 3.9), material=P["red"]),
        box("RoofBase", (10.5, 7.2, 0.28), loc=(0, 0, 4.3), material=P["tile"]),
        box("Ridge", (10.0, 0.4, 0.3), loc=(0, 0, 5.25), material=P["dark_wood"]),
        box("DoorL", (0.18, 0.18, 2.4), loc=(-1.0, 2.55, 1.6), material=P["dark_wood"]),
        box("DoorR", (0.18, 0.18, 2.4), loc=(1.0, 2.55, 1.6), material=P["dark_wood"]),
        box("Door", (1.8, 0.1, 2.3), loc=(0, 2.5, 1.55), material=P["wood"]),
        box("Altar", (2.6, 0.8, 0.7), loc=(0, -1.8, 0.85), material=P["wood"]),
        box("Offering", (0.4, 0.4, 0.5), loc=(0, -1.8, 1.45), material=P["gold"]),
    ]
    # roof slopes
    r1 = box("RoofSlope1", (10.8, 3.6, 0.2), loc=(0, -1.8, 4.7), rot=(math.radians(18), 0, 0), material=P["tile"])
    r2 = box("RoofSlope2", (10.8, 3.6, 0.2), loc=(0, 1.8, 4.7), rot=(math.radians(-18), 0, 0), material=P["tile"])
    parts += [r1, r2]
    select_only(parts)
    return join_selected("main_hall")


def build_elder(P):
    parts = [
        cylinder("Body", 0.28, 1.1, loc=(0, 0, 0.85), material=P["red"]),
        cylinder("Torso", 0.24, 0.5, loc=(0, 0, 1.45), material=P["cloth"]),
        cylinder("Head", 0.16, 0.28, loc=(0, 0, 1.9), material=P["skin"]),
        cone("Hat", 0.28, 0.04, 0.18, loc=(0, 0, 2.15), material=P["hat"]),
        cylinder("Staff", 0.035, 1.5, loc=(0.35, 0.1, 0.9), material=P["wood"]),
    ]
    select_only(parts)
    return join_selected("npc_elder")


def build_bandit(P):
    parts = [
        cylinder("Body", 0.28, 1.2, loc=(0, 0, 0.9), material=P["bandit"]),
        cylinder("Head", 0.16, 0.28, loc=(0, 0, 1.7), material=P["skin"]),
        cone("Hat", 0.22, 0.08, 0.2, loc=(0, 0, 1.95), material=P["hat"]),
        box("Blade", (0.05, 0.7, 0.04), loc=(0.4, 0.2, 1.0), material=P["steel"]),
    ]
    select_only(parts)
    return join_selected("enemy_bandit")


def build_wall_segment(P):
    parts = [
        box("Wall", (4.0, 0.45, 3.2), loc=(0, 0, 1.6), material=P["plaster"]),
        box("RedBand", (4.0, 0.48, 0.7), loc=(0, 0, 0.35), material=P["red"]),
        box("TileTop", (4.2, 0.7, 0.3), loc=(0, 0, 3.35), material=P["tile"]),
    ]
    select_only(parts)
    return join_selected("wall_segment")


def build_roof_module(P):
    # low poly curved-looking roof tile plate
    parts = [
        box("Plate", (2.0, 1.2, 0.12), loc=(0, 0, 0.1), material=P["tile"]),
        box("Ridge", (2.1, 0.18, 0.12), loc=(0, 0, 0.22), material=P["dark_wood"]),
    ]
    select_only(parts)
    return join_selected("roof_module")


MODELS = [
    ("lantern", ("props", "lantern.glb"), build_lantern),
    ("pillar", ("architecture", "pillar.glb"), build_pillar),
    ("roof_module", ("architecture", "roof_module.glb"), build_roof_module),
    ("gate", ("architecture", "gate.glb"), build_gate),
    ("stone_lion", ("props", "stone_lion.glb"), build_stone_lion),
    ("stele", ("props", "stele.glb"), build_stele),
    ("tree", ("props", "tree.glb"), build_tree),
    ("scroll", ("props", "scroll.glb"), build_scroll),
    ("jade", ("props", "jade.glb"), build_jade),
    ("sword", ("props", "sword.glb"), build_sword),
    ("pavilion", ("architecture", "pavilion.glb"), build_pavilion),
    ("main_hall", ("architecture", "main_hall.glb"), build_main_hall),
    ("npc_elder", ("characters", "npc_elder.glb"), build_elder),
    ("enemy_bandit", ("characters", "enemy_bandit.glb"), build_bandit),
    ("wall_segment", ("architecture", "wall_segment.glb"), build_wall_segment),
]


def main():
    ensure_out()
    print("OUT:", OUT_DIR)
    ok = 0
    for name, rel, fn in MODELS:
        print("==>", name)
        try:
            build_and_export(name, rel, fn)
            ok += 1
        except Exception as e:
            print("FAILED", name, e)
            traceback.print_exc()
    print(f"Done. {ok}/{len(MODELS)} exported.")


if __name__ == "__main__":
    main()
