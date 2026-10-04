"""Original red snapper anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'red_snapper',
 'sections': [(-0.398, 0.016, 0.028, 0.024, 0),
              (-0.306, 0.028, 0.048, 0.037, 0.002),
              (-0.196, 0.043, 0.078, 0.057, 0.004),
              (-0.064, 0.061, 0.107, 0.079, 0.004),
              (0.09, 0.074, 0.13, 0.098, 0.005),
              (0.211, 0.075, 0.139, 0.1, 0.004),
              (0.303, 0.062, 0.113, 0.074, 0.003),
              (0.386, 0.048, 0.071, 0.046, 0.001),
              (0.454, 0.029, 0.031, 0.023, -0.003),
              (0.494, 0.01, 0.01, 0.008, -0.006),
              (0.509, 0.002, 0.003, 0.003, -0.006)],
 'skin': {'back': (0.52, 0.13, 0.14),
          'side': (0.8, 0.32, 0.32),
          'belly': (0.91, 0.63, 0.57),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.71, 0.25, 0.26),
 'normal_strength': 0.15,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.72,
 'anatomy': {'family': 'reef'},
 'morphology': ['High oval snapper body with triangular sloping forehead',
                'Continuous spiny plus soft dorsal silhouette and pointed pectorals',
                'Red iris, rosy-red scales and small upper-jaw canine teeth',
                'Moderately forked red caudal and strong anal spines'],
 'sources': ['https://www.fisheries.noaa.gov/species/red-snapper']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.504, 0, -0.007)
