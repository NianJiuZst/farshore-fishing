"""Original, source-backed whitetip reef shark anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'whitetip_reef_shark',
 'sections': [(-0.39, 0.01, 0.014, 0.011, 0),
              (-0.31, 0.016, 0.023, 0.018, 0),
              (-0.2, 0.025, 0.036, 0.027, 0),
              (-0.05, 0.037, 0.049, 0.035, 0),
              (0.11, 0.046, 0.058, 0.038, 0),
              (0.24, 0.047, 0.055, 0.033, 0),
              (0.34, 0.045, 0.043, 0.026, 0),
              (0.414, 0.038, 0.028, 0.018, 0),
              (0.474, 0.026, 0.017, 0.012, 0),
              (0.511, 0.003, 0.004, 0.003, 0)],
 'skin': {'back': (0.34, 0.37, 0.32),
          'side': (0.57, 0.59, 0.52),
          'belly': (0.86, 0.86, 0.77),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.45, 0.48, 0.41),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.88,
 'morphology': ['Small slender reef shark with wide flattened blunt head and relatively horizontally '
                'oval eyes',
                'First dorsal origin distinctly behind pectoral free rear tips; second dorsal '
                'relatively substantial',
                'Bright white tip on first dorsal and upper tail lobe; pectorals lack broad '
                'oceanic-white patches',
                'No interdorsal ridge, rounded narrow pectorals and elongate heterocercal tail',
                'Five curved gill slits and central underside mouth, a bottom-resting reef morphology'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/whitetip-reef-shark/',
             'https://sharks.linnaeus.naturalis.nl/linnaeus_ng/app/views/species/taxon.php?epi=74&id=62734']}

PLAN = {'eye_shape': (1.18, .78), 'eye': (0.417, 1.36, 0.0084),
 'nostril': (0.474, 2.23),
 'mouth': (0.455, 0.375, 0.82),
 'gills': (0.312, 0.017, 0.76, 2.23),
 'white_dorsal': True,
 'white_tail': True,
 'dorsal': (0.065,
            -0.08,
            [(0.002, 0, 0.156), (-0.025, 0, 0.158), (-0.059, 0, 0.093), (-0.104, 0, 0.047)]),
 'second': (-0.227, -0.302, [(-0.258, 0, 0.105), (-0.282, 0, 0.086), (-0.323, 0, 0.03)]),
 'anal': (-0.25, -0.316, [(-0.278, 0, -0.077), (-0.301, 0, -0.065), (-0.335, 0, -0.027)]),
 'pectoral': (0.216,
              0.155,
              1.77,
              2.05,
              [(0.149, 0.103, -0.024),
               (0.048, 0.166, -0.055),
               (0.006, 0.156, -0.065),
               (0.069, 0.093, -0.054)]),
 'pelvic': (-0.123,
            -0.188,
            2.13,
            2.44,
            [(-0.158, 0.069, -0.052), (-0.226, 0.081, -0.068), (-0.212, 0.035, -0.045)]),
 'tail': [(-0.4, 0, -0.017),
          (-0.466, 0, -0.063),
          (-0.487, 0, -0.069),
          (-0.443, 0, -0.018),
          (-0.421, 0, 0.001),
          (-0.505, 0, 0.08),
          (-0.615, 0, 0.184),
          (-0.585, 0, 0.132),
          (-0.478, 0, 0.048),
          (-0.401, 0, 0.021)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.455, 0, -0.0150663)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
