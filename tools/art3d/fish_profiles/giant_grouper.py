"""Original giant grouper anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'giant_grouper',
 'sections': [(-0.397, 0.023, 0.037, 0.03, 0),
              (-0.31, 0.041, 0.06, 0.046, 0.002),
              (-0.2, 0.064, 0.087, 0.067, 0.004),
              (-0.065, 0.086, 0.115, 0.092, 0.007),
              (0.09, 0.11, 0.14, 0.117, 0.006),
              (0.228, 0.116, 0.15, 0.12, 0.003),
              (0.33, 0.103, 0.125, 0.094, -0.001),
              (0.411, 0.084, 0.075, 0.064, -0.008),
              (0.477, 0.061, 0.026, 0.026, -0.016),
              (0.516, 0.018, 0.016, 0.014, -0.016),
              (0.529, 0.003, 0.006, 0.005, -0.017)],
 'skin': {'back': (0.29, 0.3, 0.23),
          'side': (0.5, 0.48, 0.36),
          'belly': (0.72, 0.69, 0.53),
          'pattern': 'mottle',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.38, 0.37, 0.26),
 'normal_strength': 0.13,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.66,
 'anatomy': {'family': 'reef', 'pigment': 'grouper_mottle'},
 'morphology': ['Massive thick adult grouper body and enormous gape with thick maxillary lips',
                'Rounded caudal and broad rounded pectoral, soft dorsal and anal fins',
                'Coarse brown-grey mottling, avoiding yellow-black juvenile banding',
                'Low separated spinous peaks merge into rounded soft dorsal'],
 'sources': ['https://fishesofaustralia.net.au/home/species/4672'],
 'fin_pattern': 'spots'}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.519, 0, -0.022)
