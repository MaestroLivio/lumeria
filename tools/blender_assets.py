"""Genera gli asset low-poly di Lumeria con Blender (headless).

Uso:
    /Applications/Blender.app/Contents/MacOS/Blender -b --python tools/blender_assets.py

Gli asset finiscono in assets/models/*.glb, con origine a terra e fronte verso
+Y in Blender (che l'export glTF porta su -Z in Godot, il "forward" del motore).
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "models")

# ---------------------------------------------------------------- utilità


def srgb(hex_color):
    """Hex sRGB -> tupla lineare per i materiali di Blender."""
    h = hex_color.lstrip("#")
    vals = [int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)]
    return tuple(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in vals)


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


_MATS = {}


def mat(hex_color, rough=0.85, metallic=0.0, emission=None, strength=0.0, alpha=1.0):
    key = (hex_color, rough, metallic, emission, strength, alpha)
    if key in _MATS:
        return _MATS[key]
    m = bpy.data.materials.new("m_" + hex_color.lstrip("#"))
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    col = srgb(hex_color)
    bsdf.inputs["Base Color"].default_value = (*col, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metallic
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*srgb(emission), 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        try:
            m.blend_method = "BLEND"
        except Exception:
            pass
    _MATS[key] = m
    return m


PARTS = []


def _register(obj, material):
    obj.data.materials.append(material)
    PARTS.append(obj)
    return obj


def cube(size, loc, material, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.object
    o.scale = (size[0], size[1], size[2])
    return _register(o, material)


def cyl(r1, r2, depth, loc, material, rot=(0, 0, 0), verts=12):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth,
                                    location=loc, rotation=rot)
    return _register(bpy.context.object, material)


def cone(r, depth, loc, material, rot=(0, 0, 0), verts=10):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=0.02, depth=depth,
                                    location=loc, rotation=rot)
    return _register(bpy.context.object, material)


def ico(r, loc, material, subdiv=2, scale=(1, 1, 1), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdiv, radius=r, location=loc, rotation=rot)
    o = bpy.context.object
    o.scale = scale
    return _register(o, material)


def uv_sphere(r, loc, material, scale=(1, 1, 1), segs=16, rings=10):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=rings, radius=r, location=loc)
    o = bpy.context.object
    o.scale = scale
    return _register(o, material)


def torus(major, minor, loc, material, rot=(0, 0, 0), major_seg=20, minor_seg=8):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, location=loc,
                                     rotation=rot, major_segments=major_seg,
                                     minor_segments=minor_seg)
    return _register(bpy.context.object, material)


def finish(name, smooth=False):
    global PARTS
    bpy.ops.object.select_all(action="DESELECT")
    for o in PARTS:
        o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.ops.object.join()
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.shade_smooth() if smooth else bpy.ops.object.shade_flat()
    # pulizia: rimuove facce interne grossolane senza cambiare la sagoma
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_apply=True,
                              export_cameras=False, export_lights=False)
    PARTS = []
    print("ASSET", path)


# ---------------------------------------------------------------- alberi


def tree_oak(name="tree_oak", leaf="#4E9A4A", leaf2="#63B45C", bark="#7A5236", h=2.4):
    mat_bark = mat(bark, 0.9)
    mat_a = mat(leaf, 0.88)
    mat_b = mat(leaf2, 0.85)
    cyl(0.22, 0.32, h, (0, 0, h / 2), mat_bark, verts=8)
    # due rami inclinati
    cyl(0.09, 0.16, 0.9, (0.28, 0.0, h * 0.75), mat_bark, rot=(0, math.radians(38), 0), verts=6)
    cyl(0.08, 0.14, 0.8, (-0.26, 0.1, h * 0.8), mat_bark, rot=(math.radians(12), math.radians(-34), 0), verts=6)
    ico(1.05, (0.0, 0.0, h + 0.55), mat_a, subdiv=2, scale=(1.15, 1.05, 0.85))
    ico(0.78, (0.72, 0.18, h + 0.15), mat_b)
    ico(0.72, (-0.66, -0.2, h + 0.32), mat_b)
    ico(0.6, (0.1, 0.55, h + 1.05), mat_b)
    finish(name)


def tree_pine():
    mat_bark = mat("#6B4A32", 0.9)
    mat_a = mat("#2F6B4F", 0.86)
    mat_b = mat("#3E8058", 0.86)
    cyl(0.18, 0.26, 1.5, (0, 0, 0.75), mat_bark, verts=8)
    cone(1.35, 1.7, (0, 0, 1.85), mat_a, verts=9)
    cone(1.08, 1.5, (0, 0, 2.6), mat_b, verts=9)
    cone(0.75, 1.25, (0, 0, 3.3), mat_a, verts=9)
    finish("tree_pine")


def tree_autumn():
    tree_oak("tree_autumn", leaf="#D9822B", leaf2="#E8A33D", bark="#6E4A34", h=2.2)


def tree_birch():
    mat_bark = mat("#E8E2D4", 0.9)
    mat_leaf = mat("#8CC26A", 0.86)
    mat_leaf2 = mat("#A6D47C", 0.85)
    cyl(0.14, 0.2, 2.9, (0, 0, 1.45), mat_bark, verts=7)
    # macchie scure sul tronco
    for i in range(5):
        a = i * 1.9
        cube((0.12, 0.03, 0.06), (math.cos(a) * 0.17, math.sin(a) * 0.17, 0.5 + i * 0.45),
             mat("#4A4038"), rot=(0, 0, a))
    ico(0.85, (0, 0, 3.15), mat_leaf, subdiv=2, scale=(1.1, 1.1, 1.2))
    ico(0.6, (0.5, 0.2, 2.6), mat_leaf2)
    ico(0.55, (-0.5, -0.15, 2.75), mat_leaf2)
    finish("tree_birch")


def bush():
    a = mat("#4F8C4A", 0.9)
    b = mat("#63AA58", 0.9)
    berry = mat("#E0576A", 0.6)
    ico(0.55, (0, 0, 0.45), a, subdiv=2, scale=(1.2, 1.1, 0.9))
    ico(0.4, (0.45, 0.1, 0.35), b)
    ico(0.38, (-0.4, -0.2, 0.3), b)
    for i in range(5):
        ang = i * 1.4
        uv_sphere(0.06, (math.cos(ang) * 0.5, math.sin(ang) * 0.35, 0.62), berry, segs=8, rings=6)
    finish("bush")


def rock():
    a = mat("#9AA0A6", 0.92)
    b = mat("#B4BAC0", 0.9)
    ico(0.7, (0, 0, 0.28), a, subdiv=1, scale=(1.2, 0.95, 0.62))
    ico(0.35, (0.6, 0.25, 0.12), b, subdiv=1, scale=(1.0, 0.9, 0.55))
    ico(0.22, (-0.45, -0.3, 0.06), a, subdiv=1, scale=(1, 1, 0.6))
    finish("rock")


def mushroom():
    stem = mat("#F2E3C8", 0.9)
    cap = mat("#D9674A", 0.75)
    dot = mat("#FFF7E8", 0.8)
    cyl(0.09, 0.12, 0.4, (0, 0, 0.2), stem, verts=8)
    uv_sphere(0.3, (0, 0, 0.44), cap, scale=(1, 1, 0.62), segs=14, rings=8)
    for i in range(4):
        ang = i * 1.6
        uv_sphere(0.045, (math.cos(ang) * 0.16, math.sin(ang) * 0.16, 0.56), dot, segs=6, rings=4)
    finish("mushroom")


# ---------------------------------------------------------------- edifici


def cottage():
    wall = mat("#F3E6CC", 0.88)
    timber = mat("#7A5236", 0.85)
    roof = mat("#C4634B", 0.8)
    roof2 = mat("#A94F3C", 0.82)
    stone = mat("#B9B0A2", 0.9)
    glass = mat("#FFD98A", 0.35, emission="#FFC65C", strength=2.2)
    door = mat("#8A5A3B", 0.85)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 1.25))
    base = bpy.context.object
    base.scale = (4.2, 3.4, 2.5)
    _register(base, wall)

    # zoccolo in pietra
    cube((4.45, 3.65, 0.3), (0, 0, 0.15), stone)
    # travi a vista
    for x in (-2.05, 0.0, 2.05):
        cube((0.16, 3.44, 2.3), (x, 0, 1.3), timber)
    cube((4.24, 3.45, 0.16), (0, 0, 2.35), timber)
    cube((4.24, 3.45, 0.16), (0, 0, 0.95), timber)
    # tetto a due falde
    cube((4.9, 1.95, 0.22), (0, -1.05, 3.15), roof, rot=(math.radians(32), 0, 0))
    cube((4.9, 1.95, 0.22), (0, 1.05, 3.15), roof2, rot=(math.radians(-32), 0, 0))
    cube((4.95, 0.18, 0.18), (0, 0, 3.42), timber)
    # camino
    cube((0.6, 0.6, 1.5), (1.35, 0.85, 3.5), stone)
    cube((0.72, 0.72, 0.16), (1.35, 0.85, 4.28), stone)
    # porta verso +Y
    cube((1.0, 0.1, 1.7), (0, 1.72, 0.86), door)
    cube((1.2, 0.08, 0.14), (0, 1.76, 1.76), timber)
    uv_sphere(0.06, (0.32, 1.79, 0.85), mat("#F2C24B", 0.4, metallic=0.6), segs=8, rings=6)
    # finestre illuminate
    for x in (-1.35, 1.35):
        cube((0.78, 0.08, 0.78), (x, 1.73, 1.75), glass)
        cube((0.9, 0.1, 0.1), (x, 1.75, 1.75), timber)
        cube((0.1, 0.1, 0.9), (x, 1.75, 1.75), timber)
        # cassetta di fiori
        cube((0.86, 0.28, 0.18), (x, 1.86, 1.3), timber)
        for i in range(4):
            uv_sphere(0.07, (x - 0.3 + i * 0.2, 1.9, 1.44), mat(["#E9748A", "#F2C24B", "#FFF7E8"][i % 3], 0.7),
                      segs=8, rings=6)
    # abbaino
    cube((0.6, 0.5, 0.5), (0.6, 0.0, 3.55), wall)
    cube((0.5, 0.06, 0.34), (0.6, 0.27, 3.6), glass)
    finish("cottage")


def well():
    stone = mat("#B9B0A2", 0.9)
    stone2 = mat("#9E968A", 0.92)
    wood = mat("#7A5236", 0.88)
    roof = mat("#C4634B", 0.82)
    water = mat("#5FB6D6", 0.25, emission="#2E8DB0", strength=0.5)
    cyl(1.15, 1.25, 0.9, (0, 0, 0.45), stone, verts=14)
    cyl(0.85, 0.9, 0.2, (0, 0, 0.92), water, verts=14)
    for x in (-0.95, 0.95):
        cube((0.16, 0.16, 1.7), (x, 0, 1.7), wood)
    cube((2.2, 0.14, 0.14), (0, 0, 2.5), wood)
    cube((2.7, 1.5, 0.16), (0, -0.4, 2.75), roof, rot=(math.radians(30), 0, 0))
    cube((2.7, 1.5, 0.16), (0, 0.4, 2.75), roof, rot=(math.radians(-30), 0, 0))
    cyl(0.1, 0.1, 0.5, (0, 0, 2.28), wood, verts=8, rot=(0, math.radians(90), 0))
    cube((0.34, 0.34, 0.3), (0.0, 0.0, 2.0), wood)
    finish("well")


# ---------------------------------------------------------------- arredi


def lantern():
    iron = mat("#3F4A52", 0.6, metallic=0.4)
    glass = mat("#FFE6A8", 0.2, emission="#FFC65C", strength=4.0)
    stone = mat("#B9B0A2", 0.9)
    cyl(0.26, 0.34, 0.25, (0, 0, 0.12), stone, verts=10)
    cyl(0.09, 0.12, 2.6, (0, 0, 1.35), iron, verts=8)
    cube((0.06, 0.5, 0.06), (0, 0.2, 2.62), iron)
    cube((0.34, 0.34, 0.5), (0, 0.42, 2.35), glass)
    for x in (-0.2, 0.2):
        for y in (0.22, 0.62):
            cube((0.045, 0.045, 0.62), (x, y, 2.35), iron)
    cube((0.44, 0.44, 0.07), (0, 0.42, 2.66), iron)
    cone(0.32, 0.26, (0, 0.42, 2.82), iron, verts=8)
    uv_sphere(0.05, (0, 0.42, 2.98), iron, segs=8, rings=6)
    finish("lantern")


def fountain():
    stone = mat("#D6C6AC", 0.85)
    stone2 = mat("#BFB09A", 0.88)
    water = mat("#6FC7E0", 0.15, emission="#3FA8C8", strength=0.9)
    gold = mat("#F2C24B", 0.35, metallic=0.7, emission="#FFE066", strength=0.8)
    cyl(2.05, 2.3, 0.5, (0, 0, 0.25), stone2, verts=20)
    cyl(1.9, 1.95, 0.12, (0, 0, 0.48), water, verts=20)
    cyl(0.95, 1.15, 0.55, (0, 0, 0.7), stone, verts=16)
    cyl(0.82, 0.88, 0.1, (0, 0, 0.98), water, verts=16)
    cyl(0.26, 0.34, 1.35, (0, 0, 1.5), stone, verts=12)
    uv_sphere(0.34, (0, 0, 2.32), gold, segs=16, rings=10)
    for i in range(8):
        a = i * math.tau / 8.0
        uv_sphere(0.05, (math.cos(a) * 2.28, math.sin(a) * 2.28, 0.56), gold, segs=6, rings=4)
    finish("fountain")


def bench():
    wood = mat("#A97A48", 0.85)
    iron = mat("#4A5258", 0.6, metallic=0.35)
    for i in range(4):
        cube((1.9, 0.14, 0.08), (0, -0.22 + i * 0.15, 0.46), wood)
    for i in range(3):
        cube((1.9, 0.08, 0.14), (0, 0.28, 0.68 + i * 0.17), wood)
    for x in (-0.8, 0.8):
        cube((0.12, 0.6, 0.34), (x, 0, 0.24), iron)
        cube((0.1, 0.08, 0.5), (x, 0.3, 0.62), iron, rot=(math.radians(-12), 0, 0))
    finish("bench")


def crate():
    wood = mat("#A97A48", 0.88)
    wood2 = mat("#8A6242", 0.9)
    cube((0.9, 0.9, 0.8), (0, 0, 0.4), wood2)
    for x in (-0.46, 0.46):
        cube((0.06, 0.96, 0.86), (x, 0, 0.4), wood)
    for y in (-0.46, 0.46):
        cube((0.96, 0.06, 0.86), (0, y, 0.4), wood)
    cube((1.0, 1.0, 0.08), (0, 0, 0.82), wood)
    finish("crate")


def barrel():
    wood = mat("#9A6B44", 0.9)
    iron = mat("#4A5258", 0.6, metallic=0.3)
    cyl(0.42, 0.36, 1.0, (0, 0, 0.5), wood, verts=14)
    for z in (0.22, 0.78):
        torus(0.4, 0.035, (0, 0, z), iron, major_seg=16, minor_seg=6)
    finish("barrel")


def main():
    os.makedirs(OUT, exist_ok=True)
    builders = [
        tree_oak, tree_pine, tree_autumn, tree_birch, bush, rock, mushroom,
        cottage, well, lantern, fountain, bench, crate, barrel,
    ]
    for build in builders:
        reset()
        _MATS.clear()
        build()
    print("ASSETS OK")


if __name__ == "__main__":
    main()
