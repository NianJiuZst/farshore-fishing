"""Original cobia anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'cobia',
 'sections': [(-0.398, 0.013, 0.02, 0.017, 0),
              (-0.314, 0.025, 0.036, 0.028, 0),
              (-0.205, 0.039, 0.05, 0.039, 0),
              (-0.06, 0.052, 0.063, 0.048, 0),
              (0.103, 0.061, 0.073, 0.056, 0),
              (0.236, 0.065, 0.073, 0.054, -0.001),
              (0.326, 0.061, 0.058, 0.042, -0.003),
              (0.408, 0.049, 0.034, 0.025, -0.005),
              (0.476, 0.031, 0.015, 0.014, -0.006),
              (0.509, 0.005, 0.007, 0.006, -0.007)],
 'skin': {'back': (0.2, 0.22, 0.18),
          'side': (0.43, 0.44, 0.31),
          'belly': (0.77, 0.77, 0.61),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.31, 0.32, 0.22),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.72,
 'anatomy': {'family': 'cobia', 'pigment': 'cobia_stripe'},
 'morphology': ['Broad dorsoventrally flattened head with protruding lower jaw',
                'Seven isolated short dorsal spines preceding a long low soft dorsal',
                'Dark longitudinal side stripe bordered by paler flank regions',
                'Broad pectorals and crescent-shaped adult tail'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/cobia/']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.499, 0, -0.011)
