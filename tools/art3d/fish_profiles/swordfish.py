"""Original swordfish anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'swordfish',
 'sections': [(-0.398, 0.009, 0.015, 0.012, 0),
              (-0.33, 0.015, 0.025, 0.019, 0),
              (-0.23, 0.0221, 0.036, 0.0288, 0.001),
              (-0.1, 0.03965, 0.058499999999999996, 0.0477, 0.002),
              (0.035, 0.05525, 0.0819, 0.0657, 0.004),
              (0.16, 0.065, 0.09, 0.07469999999999999, 0.004),
              (0.245, 0.059800000000000006, 0.0783, 0.062099999999999995, 0.003),
              (0.307, 0.0494, 0.0567, 0.0414, 0.002),
              (0.365, 0.0312, 0.026099999999999998, 0.019799999999999998, 0.001),
              (0.406, 0.008, 0.01, 0.007, 0)],
 'skin': {'back': (0.15, 0.18, 0.2),
          'side': (0.44, 0.48, 0.49),
          'belly': (0.73, 0.73, 0.67),
          'pattern': 'smooth',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.105, 0.19, 0.29),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.63,
 'anatomy': {'family': 'billfish', 'bill_tip': 0.875, 'eye_radius': 0.015},
 'morphology': ['Long broad flattened sword-shaped upper rostrum with no pelvic fins',
                'Large eye and heavy cylindrical trunk; smooth adult scaleless skin',
                'Tall curved isolated first dorsal, small separate rear dorsal and anal',
                'Single dominant caudal keel and sweeping crescent tail'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/swordfish/',
             'https://www.fishbase.se/summary/Xiphias-gladius.html'],
 'fin_pattern': ''}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.389, 0, -0.009)
