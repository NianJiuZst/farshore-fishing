"""Original, source-backed blue shark anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'blue_shark',
 'sections': [(-0.389, 0.008, 0.012, 0.01, 0),
              (-0.31, 0.013, 0.021, 0.017, 0),
              (-0.19, 0.022, 0.035, 0.027, 0),
              (-0.04, 0.031, 0.046, 0.035, 0),
              (0.12, 0.041, 0.055, 0.039, 0),
              (0.24, 0.041, 0.051, 0.035, 0),
              (0.33, 0.034, 0.039, 0.027, 0),
              (0.401, 0.026, 0.026, 0.018, 0),
              (0.464, 0.013, 0.013, 0.009, 0),
              (0.509, 0.002, 0.003, 0.002, 0)],
 'skin': {'back': (0.055, 0.15, 0.26),
          'side': (0.2, 0.45, 0.58),
          'belly': (0.84, 0.88, 0.85),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.12, 0.29, 0.39),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.86,
 'morphology': ['Very slender long-bodied shark with rounded elongate snout and relatively large '
                'lateral eyes',
                'Extremely long narrow pointed pectorals, first dorsal positioned well aft near pelvic '
                'region',
                'Non-lunate heterocercal tail with long upper lobe and no strong lamnid-style lateral '
                'keel',
                'Deep cobalt dorsal field, brighter blue lateral flanks and crisp pale belly',
                'Five curved gill slits per side; ventral arched mouth and small second dorsal'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/blue-shark/',
             'https://www.fisheries.noaa.gov/new-england-mid-atlantic/atlantic-highly-migratory-species/shark-identification-cooperative-shark']}

PLAN = {'eye': (0.389, 1.38, 0.0113),
 'nostril': (0.447, 2.23),
 'mouth': (0.443, 0.362, 0.75),
 'gills': (0.303, 0.017, 0.77, 2.25),
 'dorsal': (0.072, -0.067, [(0.01, 0, 0.164), (-0.02, 0, 0.144), (-0.088, 0, 0.049)]),
 'second': (-0.226, -0.278, [(-0.252, 0, 0.063), (-0.296, 0, 0.029)]),
 'anal': (-0.245, -0.297, [(-0.277, 0, -0.06), (-0.313, 0, -0.031)]),
 'pectoral': (0.207,
              0.163,
              1.77,
              2.04,
              [(0.133, 0.139, -0.028),
               (-0.122, 0.333, -0.079),
               (-0.087, 0.264, -0.079),
               (0.065, 0.075, -0.045)]),
 'pelvic': (-0.106,
            -0.163,
            2.07,
            2.44,
            [(-0.144, 0.069, -0.057), (-0.213, 0.082, -0.077), (-0.191, 0.039, -0.053)]),
 'tail': [(-0.401, 0, -0.017),
          (-0.477, 0, -0.083),
          (-0.496, 0, -0.088),
          (-0.446, 0, -0.024),
          (-0.427, 0, 0.003),
          (-0.504, 0, 0.098),
          (-0.601, 0, 0.214),
          (-0.566, 0, 0.154),
          (-0.476, 0, 0.062),
          (-0.403, 0, 0.018)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.443, 0, -0.0127892)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
