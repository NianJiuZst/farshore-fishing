"""Original, source-backed oceanic whitetip shark anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'oceanic_whitetip_shark',
 'sections': [(-0.39, 0.013, 0.019, 0.014, 0),
              (-0.31, 0.022, 0.031, 0.024, 0),
              (-0.21, 0.037, 0.05, 0.038, 0),
              (-0.08, 0.058, 0.074, 0.055, 0.002),
              (0.06, 0.078, 0.094, 0.067, 0.003),
              (0.2, 0.083, 0.096, 0.069, 0.002),
              (0.31, 0.072, 0.075, 0.051, 0),
              (0.4, 0.053, 0.048, 0.031, 0),
              (0.468, 0.031, 0.023, 0.017, 0),
              (0.506, 0.003, 0.005, 0.003, 0)],
 'skin': {'back': (0.3, 0.3, 0.26),
          'side': (0.51, 0.51, 0.44),
          'belly': (0.85, 0.84, 0.73),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.43, 0.43, 0.35),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.71,
 'morphology': ['Stocky open-ocean shark with broad long paddle-like pectorals and rounded first dorsal '
                'apex',
                'Mottled ivory terminal patches on first dorsal, pectorals and upper caudal; no white '
                'stripe along entire fins',
                'Blunt rounded snout, bronze-gray dorsal color and warm pale belly',
                'Low interdorsal ridge, small second dorsal and asymmetric upper-heavy tail',
                'Five gill slits each side and underside arched mouth distinguish shark face from '
                'teleost operculum'],
 'sources': ['https://www.fisheries.noaa.gov/species/oceanic-whitetip-shark',
             'https://www.fishbase.se/summary/carcharhinus-longimanus.html']}

PLAN = {'eye': (0.41, 1.4, 0.0095),
 'nostril': (0.462, 2.22),
 'mouth': (0.445, 0.364, 0.83),
 'gills': (0.304, 0.02, 0.75, 2.24),
 'interdorsal': (-0.019, -0.23),
 'white_dorsal': True,
 'white_pectoral': True,
 'white_tail': True,
 'dorsal': (0.19,
            -0.037,
            [(0.139, 0, 0.216),
             (0.11, 0, 0.238),
             (0.081, 0, 0.236),
             (0.029, 0, 0.152),
             (-0.061, 0, 0.083)]),
 'second': (-0.24, -0.294, [(-0.265, 0, 0.083), (-0.313, 0, 0.034)]),
 'anal': (-0.25, -0.31, [(-0.278, 0, -0.075), (-0.327, 0, -0.035)]),
 'pectoral': (0.202,
              0.127,
              1.7,
              2.01,
              [(0.133, 0.159, -0.029),
               (-0.006, 0.29, -0.067),
               (-0.066, 0.305, -0.076),
               (-0.096, 0.284, -0.084),
               (-0.054, 0.226, -0.084),
               (0.055, 0.108, -0.061)]),
 'pelvic': (-0.095,
            -0.167,
            2.1,
            2.44,
            [(-0.132, 0.093, -0.071), (-0.224, 0.103, -0.091), (-0.195, 0.047, -0.059)]),
 'tail': [(-0.402, 0, -0.021),
          (-0.492, 0, -0.114),
          (-0.514, 0, -0.118),
          (-0.454, 0, -0.029),
          (-0.425, 0, 0.003),
          (-0.507, 0, 0.095),
          (-0.601, 0, 0.208),
          (-0.576, 0, 0.161),
          (-0.482, 0, 0.062),
          (-0.406, 0, 0.026)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.445, 0, -0.0229743)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
