"""Original, source-backed great white shark anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'great_white_shark',
 'sections': [(-0.388, 0.015, 0.021, 0.017, 0),
              (-0.32, 0.023, 0.033, 0.026, 0),
              (-0.23, 0.042, 0.054, 0.043, 0),
              (-0.12, 0.066, 0.08, 0.066, 0.002),
              (0.02, 0.091, 0.108, 0.085, 0.003),
              (0.15, 0.103, 0.119, 0.087, 0.004),
              (0.26, 0.097, 0.104, 0.074, 0.003),
              (0.35, 0.076, 0.08, 0.053, 0.002),
              (0.42, 0.048, 0.045, 0.032, 0),
              (0.475, 0.019, 0.015, 0.013, 0),
              (0.504, 0.002, 0.003, 0.003, 0)],
 'skin': {'back': (0.055, 0.075, 0.09),
          'side': (0.18, 0.22, 0.24),
          'belly': (0.91, 0.92, 0.87),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.22, 0.26, 0.28),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.61,
 'morphology': ['Stocky adult Carcharodon with conical pointed snout, broad shoulders and pronounced '
                'caudal keels',
                'Broad triangular first dorsal, small second dorsal and anal, long but robust pectorals',
                'Near-lunate heterocercal tail with strongly developed lower lobe',
                'Five separate curved gill slits per side and ventral U-shaped mouth with broad '
                'triangular teeth',
                'Distinct gray upper surface and clean white ventral boundary; fine placoid texture '
                'rather than bony scales'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/white-shark/',
             'https://www.fisheries.noaa.gov/species/white-shark']}

PLAN = {'eye': (0.401, 1.37, 0.01),
 'nostril': (0.455, 2.2),
 'mouth': (0.434, 0.345, 0.82),
 'teeth': 'triangular',
 'gills': (0.305, 0.02, 0.74, 2.27),
 'keel': True,
 'dorsal': (0.178, -0.025, [(0.098, 0, 0.254), (0.043, 0, 0.23), (-0.049, 0, 0.104)]),
 'second': (-0.231, -0.291, [(-0.25, 0, 0.091), (-0.288, 0, 0.06), (-0.308, 0, 0.035)]),
 'anal': (-0.244, -0.303, [(-0.27, 0, -0.073), (-0.312, 0, -0.05)]),
 'pectoral': (0.218,
              0.155,
              1.69,
              1.98,
              [(0.118, 0.164, -0.03),
               (-0.03, 0.253, -0.076),
               (-0.045, 0.222, -0.088),
               (0.082, 0.124, -0.071)]),
 'pelvic': (-0.076,
            -0.145,
            2.21,
            2.49,
            [(-0.1, 0.101, -0.094), (-0.192, 0.121, -0.117), (-0.182, 0.067, -0.079)]),
 'tail': [(-0.402, 0, -0.023),
          (-0.515, 0, -0.166),
          (-0.55, 0, -0.177),
          (-0.484, 0, -0.064),
          (-0.448, 0, 0.001),
          (-0.492, 0, 0.084),
          (-0.576, 0, 0.204),
          (-0.539, 0, 0.195),
          (-0.411, 0, 0.035)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.434, 0, -0.0281856)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
