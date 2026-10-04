"""Original great barracuda anatomy; source references retained below."""
from fish_profiles._ocean_bony import anatomy, paint

PROFILE = {'id': 'great_barracuda',
 'sections': [(-0.398, 0.013, 0.019, 0.016, 0),
              (-0.31, 0.022, 0.031, 0.027, 0),
              (-0.2, 0.028, 0.04, 0.034, 0.001),
              (-0.06, 0.035, 0.05, 0.039, 0.001),
              (0.1, 0.037, 0.057, 0.041, 0.002),
              (0.22, 0.039, 0.059, 0.045, 0.001),
              (0.31, 0.034, 0.048, 0.032, 0),
              (0.395, 0.027, 0.029, 0.021, -0.003),
              (0.475, 0.017, 0.013, 0.014, -0.005),
              (0.536, 0.006, 0.005, 0.008, -0.008),
              (0.554, 0.002, 0.002, 0.004, -0.009)],
 'skin': {'back': (0.21, 0.3, 0.29),
          'side': (0.63, 0.69, 0.64),
          'belly': (0.83, 0.85, 0.77),
          'pattern': 'fine_scales',
          'scale_columns': 120,
          'scale_rows': 58,
          'variation': 0.014},
 'fin_color': (0.31, 0.37, 0.31),
 'normal_strength': 0.055,
 'roughness': 0.36,
 'specular': 0.4,
 'coat': 0.08,
 'swim_amplitude': 0.72,
 'anatomy': {'family': 'barracuda', 'pigment': 'barracuda'},
 'morphology': ['Long nearly cylindrical body and long pointed jaws with underslung lower-jaw tip',
                'Two widely separated dorsals and opposed posterior anal',
                'Conspicuous interlocking conical fangs, dark irregular upper bars and lower flank '
                'blotches',
                'Deep-forked dusky caudal on robust peduncle'],
 'sources': ['https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/great-barracuda/']}
PROFILE["custom_skin"] = paint(PROFILE)
PROFILE["compress_master"] = True
PROFILE["mouth_anchor"] = (0.549, 0, -0.009999999999999998)
