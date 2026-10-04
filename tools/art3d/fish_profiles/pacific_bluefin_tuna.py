"""Original pacific bluefin tuna anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'pacific_bluefin_tuna',
 'sections': [(-0.4, 0.009, 0.015, 0.012, 0),
              (-0.327, 0.018, 0.027, 0.022, 0),
              (-0.23, 0.036, 0.05, 0.043, 0.001),
              (-0.095, 0.059, 0.081, 0.07, 0.001),
              (0.056, 0.082, 0.113, 0.099, 0),
              (0.185, 0.089, 0.121, 0.105, 0),
              (0.284, 0.079, 0.108, 0.091, 0),
              (0.37, 0.058, 0.074, 0.054, 0.001),
              (0.442, 0.034, 0.039, 0.025, 0),
              (0.491, 0.011, 0.011, 0.009, 0),
              (0.507, 0.002, 0.003, 0.003, 0)],
 'skin': {'back': (0.035, 0.135, 0.17),
          'side': (0.45, 0.59, 0.58),
          'belly': (0.84, 0.87, 0.82),
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
             'pectoral_length': 0.165,
             'pectoral_span': 0.067,
             'dorsal_height': 0.181,
             'second_height': 0.138,
             'finlets': 8,
             'second_color': (0.47, 0.41, 0.23),
             'tail_height': 0.176,
             'eye_radius': 0.0109},
 'morphology': ['Compact muscular Pacific bluefin with green-blue iridescent flanks and short '
                'pectorals',
                'Slightly longer low caudal peduncle, eight finlets, broad lunate caudal',
                'Small eye and understated pale lower-flank transverse markings',
                'Individually authored Pacific bluefin head, belly, dorsal and pectoral '
                'dimensions'],
 'sources': ['https://www.fisheries.noaa.gov/species/pacific-bluefin-tuna',
             'https://repository.library.noaa.gov/view/noaa/23154/noaa_23154_DS1.pdf']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.502, 0, -0.001)
