"""Original wahoo anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'wahoo',
 'sections': [(-0.399, 0.008, 0.011, 0.009, 0),
              (-0.323, 0.014, 0.022, 0.017, 0),
              (-0.21, 0.023, 0.036, 0.029, 0),
              (-0.07, 0.031, 0.046, 0.039, 0),
              (0.08, 0.038, 0.054, 0.047, 0),
              (0.23, 0.04, 0.056, 0.043, 0),
              (0.326, 0.032, 0.043, 0.033, 0),
              (0.415, 0.022, 0.022, 0.016, 0),
              (0.488, 0.012, 0.012, 0.007, 0),
              (0.55, 0.002, 0.003, 0.003, 0)],
 'skin': {'back': (0.06, 0.22, 0.31),
          'side': (0.61, 0.72, 0.74),
          'belly': (0.88, 0.89, 0.85),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.27, 0.38, 0.45),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.72,
 'anatomy': {'family': 'wahoo', 'pigment': 'wahoo_bars'},
 'morphology': ['Extremely elongated narrow cylindrical body with long pointed snout',
                'Long low first dorsal, distinct small second dorsal/anal and seven rear finlets',
                'Twenty-four irregular cobalt vertical bars across silver flanks',
                'Narrow keel-bearing tail stalk and deep crescent caudal'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/wahoo/',
             'https://www.fisheries.noaa.gov/species/wahoo']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.545, 0, -0.001)
