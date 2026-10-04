#!/usr/bin/env python3
"""Original, deterministic Red Sea environment, authored in metres.

No downloaded mesh, Blender installation, or old-region substitution is used.
The desert headlands, pale reef platform and branching/table corals are separate
volumetric objects. Runtime water, sky, waves and lighting remain the user's.
"""
import json
import math
import random
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = {'asset': {'version': '2.0', 'generator': 'Farshore original Red Sea environment 1.4'},
       'scene': 0, 'scenes': [{'nodes': [0]}], 'nodes': [{'name': 'RedSeaDesertReef', 'children': []}],
       'meshes': [], 'materials': [], 'bufferViews': [], 'accessors': []}
BIN = bytearray()


def accessor(values, kind, dimensions, component=5126):
    while len(BIN) % 4:
        BIN.append(0)
    offset = len(BIN)
    fmt = 'f' if component == 5126 else 'I'
    flat = [x for row in values for x in row] if dimensions > 1 else values
    BIN.extend(struct.pack('<' + fmt * len(flat), *flat))
    view = len(DOC['bufferViews'])
    DOC['bufferViews'].append({'buffer': 0, 'byteOffset': offset, 'byteLength': len(BIN) - offset})
    result = {'bufferView': view, 'componentType': component, 'count': len(values), 'type': kind}
    if kind == 'VEC3':
        result['min'] = [min(v[k] for v in values) for k in range(3)]
        result['max'] = [max(v[k] for v in values) for k in range(3)]
    index = len(DOC['accessors'])
    DOC['accessors'].append(result)
    return index


def material(name, color, roughness=.82):
    index = len(DOC['materials'])
    DOC['materials'].append({'name': name, 'doubleSided': True,
                            'pbrMetallicRoughness': {'baseColorFactor': list(color) + [1],
                                                    'metallicFactor': 0, 'roughnessFactor': roughness}})
    return index


def mesh(name, vertices, faces, material_index):
    positions, normals = [], []
    for face in faces:
        for j in range(1, len(face) - 1):
            tri = [vertices[face[k]] for k in [0, j, j + 1]]
            a = [tri[1][k] - tri[0][k] for k in range(3)]
            b = [tri[2][k] - tri[0][k] for k in range(3)]
            n = [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]]
            length = max(.000001, math.sqrt(sum(x*x for x in n)))
            for p in tri:
                positions.append(p)
                normals.append([x/length for x in n])
    index = len(DOC['meshes'])
    DOC['meshes'].append({'name': name, 'primitives': [{'attributes': {
        'POSITION': accessor(positions, 'VEC3', 3), 'NORMAL': accessor(normals, 'VEC3', 3)},
        'indices': accessor(list(range(len(positions))), 'SCALAR', 1, 5125), 'material': material_index}]})
    DOC['nodes'][0]['children'].append(len(DOC['nodes']))
    DOC['nodes'].append({'name': name, 'mesh': index})


def ellipsoid(center, scale, segments=18, rings=9):
    vertices, faces = [], []
    for r in range(rings + 1):
        theta = math.pi*r/rings
        for j in range(segments):
            phi = math.tau*j/segments
            vertices.append([center[0] + scale[0]*math.sin(theta)*math.cos(phi),
                             center[1] + scale[1]*math.cos(theta),
                             center[2] + scale[2]*math.sin(theta)*math.sin(phi)])
    for r in range(rings):
        for j in range(segments):
            a = r*segments + j
            b = r*segments + (j+1)%segments
            faces.append([a, b, b+segments, a+segments])
    return vertices, faces


def branch(start, end, radius, sides=8):
    axis = [end[k]-start[k] for k in range(3)]
    length = math.sqrt(sum(x*x for x in axis))
    axis = [x/length for x in axis]
    u = [axis[2], 0, -axis[0]]
    ul = math.sqrt(sum(x*x for x in u))
    if ul < .001:
        u = [1, 0, 0]
    else:
        u = [x/ul for x in u]
    v = [axis[1]*u[2]-axis[2]*u[1], axis[2]*u[0]-axis[0]*u[2], axis[0]*u[1]-axis[1]*u[0]]
    vertices, faces = [], []
    for ring in range(2):
        center = start if ring == 0 else end
        rad = radius if ring == 0 else radius*.52
        for j in range(sides):
            vertices.append([center[k] + rad*(u[k]*math.cos(j*math.tau/sides)+v[k]*math.sin(j*math.tau/sides)) for k in range(3)])
    for j in range(sides):
        faces.append([j, (j+1)%sides, (j+1)%sides+sides, j+sides])
    faces.extend([list(reversed(range(sides))), list(range(sides, sides*2))])
    return vertices, faces


def main():
    random.seed(140036)
    rock = material('RedSeaOchreLimestone', [.65, .38, .20])
    sand = material('RedSeaPaleCarbonateSand', [.82, .75, .54], .91)
    coral_materials = [material('RedSeaCoral'+str(i), color, .66) for i, color in enumerate([
        [.58, .35, .28], [.69, .61, .39], [.43, .58, .49], [.52, .31, .40]])]
    # Layered coastline: a broad curving sandy sill with geological terraces.
    for band in range(3):
        vertices, faces = [], []
        for row in range(7):
            for j in range(81):
                z = 70-j*12
                edge = -27 - math.sin(j*.16)*8 - max(0, j-30)*.62
                x = edge - row*13 - band*28
                y = -.8 + row*(1.1+band*.8) + band*3.8
                y += math.sin(j*.29+row*.83)*(.35+row*.9)
                vertices.append([x, y, z])
        for row in range(6):
            for j in range(80):
                a = row*81+j
                faces.append([a, a+81, a+82, a+1])
        mesh('DesertShoreTerrace_'+str(band), vertices, faces, sand if band == 0 else rock)
    # Distant arid headlands, completely distinct from the old green islands.
    for n in range(20):
        pos = [-160-random.uniform(0,150), 13+random.uniform(0,14), -80-n*45]
        scale = [random.uniform(35,70), random.uniform(26,61), random.uniform(35,75)]
        verts, faces = ellipsoid(pos, scale, 14, 7)
        mesh('DesertHeadland_'+str(n), verts, faces, rock)
    # Foreground reef platform, below water; keep the open camera channel clear.
    for n in range(28):
        pos = [-21+random.uniform(-8,4), -2.8, -12-random.uniform(0,54)]
        verts, faces = ellipsoid(pos, [random.uniform(.8,2.5), .6, random.uniform(.7,2.1)])
        mesh('ReefLimestone_'+str(n), verts, faces, sand)
    for n in range(38):
        base = [-17+random.uniform(-10,5), -2.9, -16-random.uniform(0,62)]
        vertices, faces = [], []
        for b in range(7):
            top = [base[0]+math.sin(b*2.1)*.47, base[1]+random.uniform(.38,1.24), base[2]+math.cos(b*2.1)*.47]
            pts, fs = branch(base, top, .055)
            offset = len(vertices)
            vertices.extend(pts); faces.extend([[i+offset for i in f] for f in fs])
            for k in range(2):
                twig = [top[0]+.24*math.sin(b+k), top[1]+.24, top[2]+.25*math.cos(b+k)]
                pts, fs = branch(top, twig, .035)
                offset = len(vertices)
                vertices.extend(pts); faces.extend([[i+offset for i in f] for f in fs])
        mesh('BranchingCoral_'+str(n), vertices, faces, coral_materials[n%4])
    for n in range(12):
        base = [-25+random.uniform(-6,7), -2.1, -17-random.uniform(0,56)]
        verts, faces = ellipsoid(base, [1.2, .10, .95], 24, 5)
        mesh('TableCoral_'+str(n), verts, faces, coral_materials[(n+1)%4])
    DOC['buffers'] = [{'byteLength': len(BIN)}]
    data = json.dumps(DOC, separators=(',', ':')).encode()
    data += b' ' * (-len(data)%4)
    BIN.extend(b'\0' * (-len(BIN)%4))
    out = ROOT / 'game/assets/3d/environment/region_red_sea.glb'
    payload = (struct.pack('<4sII', b'glTF', 2, 28+len(data)+len(BIN))
               + struct.pack('<II', len(data), 0x4E4F534A) + data
               + struct.pack('<II', len(BIN), 0x004E4942) + BIN)
    out.write_bytes(payload)
    print(json.dumps({'path': str(out.relative_to(ROOT)), 'bytes': len(payload),
                      'objects': len(DOC['meshes']), 'source': __file__}))


if __name__ == '__main__':
    main()
