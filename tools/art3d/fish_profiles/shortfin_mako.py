"""Original, source-backed shortfin mako anatomical profile."""
from fish_profiles._ocean_sharks import anatomy as build_anatomy, shark_skin

PROFILE = {'id': 'shortfin_mako',
 'sections': [(-0.388, 0.012, 0.018, 0.014, 0),
              (-0.31, 0.02, 0.028, 0.022, 0),
              (-0.2, 0.036, 0.047, 0.038, 0),
              (-0.06, 0.058, 0.074, 0.058, 0.002),
              (0.08, 0.071, 0.089, 0.067, 0.002),
              (0.2, 0.075, 0.09, 0.065, 0.002),
              (0.29, 0.067, 0.073, 0.052, 0.001),
              (0.37, 0.051, 0.052, 0.035, 0),
              (0.433, 0.032, 0.03, 0.02, 0),
              (0.48, 0.011, 0.011, 0.008, 0),
              (0.516, 0.0015, 0.002, 0.002, 0)],
 'skin': {'back': (0.05, 0.14, 0.23),
          'side': (0.29, 0.43, 0.49),
          'belly': (0.89, 0.9, 0.85),
          'pattern': 'smooth',
          'variation': 0.012},
 'fin_color': (0.23, 0.34, 0.4),
 'normal_strength': 0.035,
 'roughness': 0.47,
 'specular': 0.31,
 'coat': 0.035,
 'swim_amplitude': 0.61,
 'morphology': ['Hydrodynamic spindle body slimmer than white shark with strongly pointed conical snout',
                'Short pointed pectorals, tiny second dorsal and anal and prominent single lateral tail '
                'keel',
                'Near-lunate tail with large lower lobe, but upper lobe subtly longer',
                'Fine hooked smooth-edged teeth rather than white-shark triangular saw teeth',
                'Metallic navy back and white belly including underside of snout and mouth'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/shortfin-mako/',
             'https://fishbase.se/summary/752']}

PLAN = {'eye': (0.398, 1.37, 0.011),
 'nostril': (0.455, 2.23),
 'mouth': (0.439, 0.355, 0.81),
 'teeth': 'needle',
 'gills': (0.305, 0.021, 0.68, 2.28),
 'keel': True,
 'dorsal': (0.15, -0.019, [(0.073, 0, 0.221), (0.028, 0, 0.185), (-0.043, 0, 0.076)]),
 'second': (-0.251, -0.287, [(-0.269, 0, 0.058), (-0.307, 0, 0.031)]),
 'anal': (-0.273, -0.306, [(-0.291, 0, -0.049), (-0.321, 0, -0.03)]),
 'pectoral': (0.205,
              0.151,
              1.76,
              2.02,
              [(0.129, 0.107, -0.025),
               (0.002, 0.171, -0.063),
               (0.016, 0.131, -0.071),
               (0.082, 0.076, -0.055)]),
 'pelvic': (-0.07,
            -0.124,
            2.16,
            2.49,
            [(-0.108, 0.069, -0.073), (-0.162, 0.084, -0.096), (-0.157, 0.043, -0.061)]),
 'tail': [(-0.401, 0, -0.021),
          (-0.512, 0, -0.151),
          (-0.54, 0, -0.163),
          (-0.481, 0, -0.058),
          (-0.445, 0, 0.001),
          (-0.487, 0, 0.072),
          (-0.566, 0, 0.183),
          (-0.539, 0, 0.171),
          (-0.409, 0, 0.03)]}

PROFILE["custom_skin"] = shark_skin(PROFILE["skin"]["back"], PROFILE["skin"]["side"], PROFILE["skin"]["belly"], tiger=False)

PROFILE["mouth_anchor"] = (0.439, 0, -0.0191874)
PROFILE["compress_master"] = True

def anatomy(f):
    build_anatomy(f, PLAN)
