"""Original, source-backed tiger shark anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'tiger_shark',
 'sections': [(-0.39, 0.014, 0.02, 0.014, 0),
              (-0.31, 0.023, 0.033, 0.025, 0),
              (-0.2, 0.04, 0.056, 0.041, 0),
              (-0.05, 0.069, 0.086, 0.064, 0.002),
              (0.1, 0.092, 0.107, 0.078, 0.003),
              (0.23, 0.097, 0.104, 0.07, 0.001),
              (0.33, 0.088, 0.084, 0.056, 0),
              (0.414, 0.072, 0.057, 0.038, 0),
              (0.472, 0.049, 0.031, 0.024, 0),
              (0.505, 0.02, 0.017, 0.012, 0),
              (0.515, 0.004, 0.004, 0.004, 0)],
 'skin': {'back': (0.25, 0.28, 0.26),
          'side': (0.49, 0.5, 0.44),
          'belly': (0.84, 0.84, 0.75),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.37, 0.4, 0.35),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.73,
 'morphology': ['Broad bluntly rounded snout, heavy anterior body and relatively small lateral eyes',
                'Dark irregular vertical flank bars fade toward ventrum and rear; realistic gray-brown '
                'base',
                'Long upper tail lobe, low caudal keels and low interdorsal ridge',
                'Moderately tall first dorsal and broad robust pectorals distinct from oceanic white '
                'paddle fins',
                'Five curved gill slits, wide ventral mouth and small spiracles behind eyes'],
 'sources': ['https://australian.museum/learn/animals/fishes/tiger-shark-galeocerdo-cuvier-pron-lesueur-1822/',
             'https://www.fishbase.se/summary/886']}

PLAN = {'eye': (0.417, 1.37, 0.0088),
 'nostril': (0.479, 2.17),
 'mouth': (0.457, 0.359, 0.97),
 'gills': (0.3, 0.021, 0.74, 2.22),
 'interdorsal': (-0.027, -0.232),
 'dorsal': (0.178, -0.033, [(0.098, 0, 0.226), (0.049, 0, 0.197), (-0.059, 0, 0.092)]),
 'second': (-0.238, -0.299, [(-0.264, 0, 0.087), (-0.318, 0, 0.039)]),
 'anal': (-0.242, -0.307, [(-0.282, 0, -0.079), (-0.327, 0, -0.038)]),
 'pectoral': (0.201,
              0.135,
              1.75,
              2.01,
              [(0.118, 0.155, -0.035),
               (-0.013, 0.238, -0.083),
               (-0.042, 0.192, -0.096),
               (0.059, 0.095, -0.068)]),
 'pelvic': (-0.101,
            -0.172,
            2.07,
            2.44,
            [(-0.137, 0.093, -0.081), (-0.22, 0.119, -0.099), (-0.2, 0.05, -0.062)]),
 'tail': [(-0.401, 0, -0.021),
          (-0.483, 0, -0.104),
          (-0.513, 0, -0.111),
          (-0.456, 0, -0.028),
          (-0.428, 0, 0.004),
          (-0.521, 0, 0.12),
          (-0.634, 0, 0.253),
          (-0.6, 0, 0.185),
          (-0.493, 0, 0.068),
          (-0.404, 0, 0.027)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=True)

PROFILE["mouth_anchor"] = (0.457, 0, -0.0287323)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
    for s in (-1, 1):
        f.ellipsoid("SmallSpiracle"+str(s), f.surface(.393,s*1.20,.001),(.0035,.0018,.002),f.mats["dark"],"head")
