"""Original, source-backed great hammerhead anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'great_hammerhead',
 'sections': [(-0.388, 0.013, 0.019, 0.014, 0),
              (-0.31, 0.023, 0.033, 0.025, 0),
              (-0.2, 0.039, 0.052, 0.042, 0),
              (-0.06, 0.057, 0.078, 0.058, 0.002),
              (0.09, 0.073, 0.092, 0.066, 0.002),
              (0.2, 0.071, 0.084, 0.059, 0.002),
              (0.29, 0.059, 0.063, 0.043, 0),
              (0.35, 0.043, 0.037, 0.028, 0),
              (0.402, 0.023, 0.021, 0.017, 0),
              (0.434, 0.003, 0.004, 0.004, 0)],
 'skin': {'back': (0.27, 0.29, 0.28),
          'side': (0.49, 0.5, 0.46),
          'belly': (0.86, 0.86, 0.79),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.39, 0.41, 0.38),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.67,
 'morphology': ['Closed broad cephalofoil with almost straight adult leading edge and shallow central '
                'notch',
                'Very tall strongly falcate first dorsal, larger second dorsal and deeply concave '
                'pelvic rear margins',
                'Stockier body than scalloped hammerhead, separate eyes at distal hammer tips',
                'Five gill slits each side and central underside mouth, not a mouth stretched across '
                'hammer',
                'Upper-lobe-dominant heterocercal caudal and subdued gray-brown countershading'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-hammerhead/',
             'https://www.fishbase.se/summary/Sphyrna_mokarran.html',
             'https://researchonline.jcu.edu.au/45487/']}

PLAN = {'hammer': 'great',
 'gills': (0.283, 0.015, 0.7, 2.29),
 'dorsal': (0.178,
            -0.014,
            [(0.112, 0, 0.345),
             (0.078, 0, 0.328),
             (0.071, 0, 0.225),
             (0.031, 0, 0.142),
             (-0.041, 0, 0.081)]),
 'second': (-0.218,
            -0.286,
            [(-0.248, 0, 0.121), (-0.26, 0, 0.104), (-0.26, 0, 0.064), (-0.307, 0, 0.036)]),
 'anal': (-0.242, -0.312, [(-0.276, 0, -0.092), (-0.292, 0, -0.061), (-0.327, 0, -0.042)]),
 'pectoral': (0.202,
              0.143,
              1.72,
              2.02,
              [(0.132, 0.132, -0.029),
               (-0.014, 0.218, -0.069),
               (-0.02, 0.176, -0.079),
               (0.06, 0.089, -0.063)]),
 'pelvic': (-0.083,
            -0.165,
            2.05,
            2.4,
            [(-0.104, 0.109, -0.074),
             (-0.209, 0.146, -0.134),
             (-0.166, 0.079, -0.084),
             (-0.193, 0.04, -0.06)]),
 'tail': [(-0.4, 0, -0.023),
          (-0.486, 0, -0.11),
          (-0.514, 0, -0.116),
          (-0.457, 0, -0.031),
          (-0.424, 0, 0.005),
          (-0.509, 0, 0.12),
          (-0.605, 0, 0.249),
          (-0.572, 0, 0.192),
          (-0.483, 0, 0.079),
          (-0.406, 0, 0.029)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.436, 0, -0.019)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)

PROFILE["sources"].append('https://biogeodb.stri.si.edu/caribbean/en/thefishes/species/116')
