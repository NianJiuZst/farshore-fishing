"""Original, source-backed scalloped hammerhead anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'scalloped_hammerhead',
 'sections': [(-0.388, 0.01, 0.015, 0.012, 0),
              (-0.31, 0.018, 0.026, 0.021, 0),
              (-0.2, 0.029, 0.043, 0.034, 0),
              (-0.06, 0.043, 0.061, 0.046, 0.001),
              (0.1, 0.057, 0.073, 0.051, 0.002),
              (0.21, 0.059, 0.069, 0.048, 0.001),
              (0.29, 0.052, 0.052, 0.039, 0),
              (0.35, 0.037, 0.031, 0.026, 0),
              (0.397, 0.024, 0.02, 0.017, 0),
              (0.434, 0.003, 0.004, 0.004, 0)],
 'skin': {'back': (0.32, 0.34, 0.29),
          'side': (0.53, 0.54, 0.46),
          'belly': (0.85, 0.85, 0.76),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.42, 0.43, 0.36),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.76,
 'morphology': ['Broad flattened real cephalofoil, arched leading margin with central and lateral '
                'scalloped indentations',
                'Eyes at the distal head tips, compact central ventral mouth and five gill slits on '
                'each side',
                'Moderately tall curved first dorsal distinct from great hammerhead sail-like dorsal',
                'Pelvic fins with straighter rear margins, slender torso and upper-heavy heterocercal '
                'tail',
                'Bronze-gray upper skin and pale underside with muted fin pigmentation'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/scalloped-hammerhead/',
             'https://www.fishbase.se/summary/Sphyrna-lewini.html']}

PLAN = {'hammer': 'scalloped',
 'gills': (0.286, 0.015, 0.74, 2.23),
 'dorsal': (0.156, -0.014, [(0.085, 0, 0.22), (0.035, 0, 0.184), (-0.04, 0, 0.069)]),
 'second': (-0.232, -0.285, [(-0.262, 0, 0.065), (-0.301, 0, 0.034)]),
 'anal': (-0.246, -0.31, [(-0.275, 0, -0.07), (-0.323, 0, -0.041)]),
 'pectoral': (0.204,
              0.154,
              1.72,
              2.0,
              [(0.127, 0.124, -0.026),
               (-0.011, 0.203, -0.063),
               (-0.019, 0.167, -0.07),
               (0.067, 0.081, -0.052)]),
 'pelvic': (-0.115,
            -0.177,
            2.11,
            2.47,
            [(-0.144, 0.082, -0.065), (-0.217, 0.09, -0.074), (-0.196, 0.038, -0.059)]),
 'tail': [(-0.4, 0, -0.021),
          (-0.483, 0, -0.098),
          (-0.502, 0, -0.103),
          (-0.448, 0, -0.026),
          (-0.425, 0, 0.002),
          (-0.513, 0, 0.121),
          (-0.594, 0, 0.239),
          (-0.574, 0, 0.199),
          (-0.482, 0, 0.082),
          (-0.405, 0, 0.025)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.436, 0, -0.019)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)

PROFILE["sources"].append('https://www.nyt.sdnhm.org/oceanoasis/fieldguide/sphy-lew.html')
