"""Original mahi mahi anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'mahi_mahi',
 'sections': [(-0.398, 0.01, 0.019, 0.012, 0),
              (-0.321, 0.018, 0.036, 0.028, 0.003),
              (-0.21, 0.028, 0.061, 0.04, 0.008),
              (-0.05, 0.038, 0.084, 0.06, 0.013),
              (0.12, 0.043, 0.111, 0.075, 0.018),
              (0.285, 0.044, 0.127, 0.074, 0.016),
              (0.375, 0.039, 0.141, 0.057, 0.012),
              (0.429, 0.031, 0.135, 0.04, 0.006),
              (0.466, 0.024, 0.07, 0.025, 0),
              (0.499, 0.013, 0.016, 0.014, -0.001),
              (0.51, 0.002, 0.003, 0.003, -0.001)],
 'skin': {'back': (0.035, 0.33, 0.35),
          'side': (0.58, 0.7, 0.22),
          'belly': (0.8, 0.82, 0.58),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.12, 0.32, 0.3),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.76,
 'anatomy': {'family': 'mahi', 'pigment': 'mahi_spots'},
 'morphology': ['Adult male high blunt forehead with laterally compressed elongated body',
                'Single tall continuous dorsal begins above eye and sweeps almost to caudal '
                'peduncle',
                'Long anal base and strongly forked tail',
                'Electric blue-green upper body, golden flanks and discrete blue speckles'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/dolphinfish/',
             'https://www.fisheries.noaa.gov/species/pacific-mahimahi']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.505, 0, -0.002)
