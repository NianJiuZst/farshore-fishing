"""Original opah anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'opah',
 'sections': [(-0.367, 0.013, 0.022, 0.019, 0),
              (-0.302, 0.026, 0.058, 0.049, 0.005),
              (-0.2, 0.044, 0.139, 0.127, 0.008),
              (-0.06, 0.061, 0.212, 0.209, 0.006),
              (0.08, 0.069, 0.249, 0.235, 0.004),
              (0.207, 0.068, 0.251, 0.218, 0),
              (0.312, 0.057, 0.201, 0.159, -0.003),
              (0.382, 0.042, 0.124, 0.092, -0.005),
              (0.43, 0.027, 0.054, 0.045, -0.006),
              (0.463, 0.011, 0.019, 0.017, -0.007),
              (0.478, 0.003, 0.005, 0.005, -0.007)],
 'skin': {'back': (0.21, 0.31, 0.37),
          'side': (0.63, 0.61, 0.55),
          'belly': (0.78, 0.69, 0.58),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.76, 0.25, 0.18),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.54,
 'anatomy': {'family': 'opah', 'pigment': 'opah_spots'},
 'morphology': ['Tall nearly circular strongly laterally compressed body',
                'Long angular red dorsal and anal fins and winglike red pectorals',
                'Large orange-rimmed eyes, small protruding terminal mouth',
                'Pale round flank spots on steel-silver bronze body and red forked tail'],
 'sources': ['https://www.fisheries.noaa.gov/feature-story/clues-fish-auction-reveal-several-new-species-opah',
             'https://www.fisheries.noaa.gov/species/opah']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.473, 0, -0.008)
