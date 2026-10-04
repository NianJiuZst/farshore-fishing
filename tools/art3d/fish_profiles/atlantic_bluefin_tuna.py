"""Original atlantic bluefin tuna anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'atlantic_bluefin_tuna',
 'sections': [(-0.398, 0.01, 0.015, 0.012, 0),
              (-0.33, 0.019, 0.028, 0.022, 0),
              (-0.24, 0.038, 0.053, 0.041, 0.002),
              (-0.1, 0.063, 0.087, 0.069, 0.003),
              (0.04, 0.087, 0.119, 0.096, 0.003),
              (0.17, 0.096, 0.127, 0.109, 0.001),
              (0.28, 0.084, 0.111, 0.099, 0),
              (0.37, 0.061, 0.085, 0.061, 0.002),
              (0.438, 0.037, 0.045, 0.032, 0),
              (0.493, 0.012, 0.012, 0.009, 0),
              (0.512, 0.002, 0.003, 0.003, 0)],
 'skin': {'back': (0.055, 0.115, 0.19),
          'side': (0.48, 0.59, 0.65),
          'belly': (0.87, 0.88, 0.84),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.24, 0.3, 0.34),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.72,
 'anatomy': {'family': 'tuna',
             'pectoral_length': 0.178,
             'pectoral_span': 0.071,
             'dorsal_height': 0.19,
             'second_height': 0.146,
             'finlets': 9,
             'second_color': (0.46, 0.36, 0.26),
             'tail_height': 0.18},
 'morphology': ['Very deep muscular Atlantic bluefin spindle with robust belly and thick shoulders',
                'Short pectorals end well before second dorsal; short reddish-brown second dorsal '
                'and anal',
                'Nine separate yellow finlets per margin; strong central caudal keels and two '
                'minor keels',
                'Smooth dark indigo back, metallic silver sides, small eyes and broad crescent '
                'tail'],
 'sources': ['https://www.fisheries.noaa.gov/species/atlantic-bluefin-tuna',
             'https://www.fisheries.noaa.gov/resource/outreach-materials/atlantic-tunas-identification-guide']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.507, 0, -0.001)
