"""Rhinobagrus dumerili: original conical snout, short barbels and thick rayless adipose."""
import math
import numpy as np
from fish_profiles.channel_catfish import whisker, adipose_lobe
PROFILE={
 'id':'longsnout_catfish',
 'sections':[(-.371,.018,.029,.028,0),(-.29,.027,.046,.037,.001),(-.18,.044,.070,.053,.005),(-.04,.066,.094,.071,.007),(.11,.080,.106,.077,.007),(.22,.074,.084,.067,.004),(.32,.058,.063,.047,.001),(.411,.042,.042,.029,.001),(.478,.023,.023,.014,.005),(.532,.009,.008,.006,.010),(.542,.002,.002,.002,.011)],
 'skin':{'back':(.26,.29,.29),'side':(.62,.56,.51),'belly':(.84,.78,.68),'pattern':'smooth','variation':.035,'lateral_line':(.36,.36,.33),'lateral_curve':.07},
 'roughness':.46,'fin_color':(.31,.32,.32),'swim_amplitude':.84,
 'morphology':['Long projecting conical snout and small inferior thick-lipped crescent mouth','Eight short barbels, small eyes behind the mouth','Naked pink-gray skin with light belly','Strong dorsal and pectoral spines, thick rayless adipose and deeply forked tail'],
 'sources':['https://www.eco.gov.cn/news_info/8921.html','https://doi.org/10.5657/FAS.2012.0299','https://researcharchive.calacademy.org/research/ichthyology/catalog/fishcatget.asp?spid=5698']}

def anatomy(f):
 f.fin('Dorsal',[(.155,0,.103),(.09,0,.113),(.015,0,.108)],[(.155,0,.105),(.123,0,.227),(.042,0,.18),(.015,0,.108)],parent='spine_front',rays=8)
 f.tube('DorsalSpine',[(.154,0,.104),(.139,0,.17),(.123,0,.226)],[.0024,.0016,.00045],f.mats['ray'],'dorsal')
 adipose_lobe(f,'ThickAdipose',-.11,-.325,.047,.012,(.34,.34,.32))
 f.fin('Anal',[(-.151,0,-.052),(-.213,0,-.046),(-.286,0,-.033)],[(-.151,0,-.054),(-.186,0,-.106),(-.265,0,-.099),(-.30,0,-.046)],parent='spine_rear',rays=17)
 f.fin('Caudal',[(-.37,0,-.028),(-.373,0,0),(-.37,0,.028)],[(-.506,0,-.113),(-.50,0,-.084),(-.421,0,0),(-.495,0,.089),(-.511,0,.123)],bone='caudal',parent='tail',rays=26)
 lipmat=f.material('LongsnoutThickLip',(.57,.49,.43),.48)
 mouth=[f.surface(float(.425+.020*(1-t*t)),float(math.pi+t*.93),.0008) for t in np.linspace(-1,1,31)]
 f.tube('InferiorCrescentMouth',mouth,.0022,f.mats['dark'],'head',9)
 f.tube('ThickLowerLip',[(x,y,z-.0016) for x,y,z in mouth],.003,lipmat,'jaw',9)
 for s in (-1,1):
  tag='L' if s<0 else 'R'
  f.fin('Pectoral'+tag,[f.surface(float(x),s*1.95,-.0015) for x in np.linspace(0.272,0.205,14)],[(.272,s*.059,-.026),(.199,s*.143,-.058),(.078,s*.13,-.077),(.205,s*.06,-.039)],parent='spine_front',rays=14)
  f.tube('PectoralSpine'+tag,[(.272,s*.059,-.026),(.232,s*.102,-.046),(.199,s*.143,-.058)],[.0021,.0014,.0004],f.mats['ray'],'pectoral'+tag.lower())
  f.fin('Pelvic'+tag,[f.surface(float(x),s*2.45,-.0015) for x in np.linspace(0.005,-0.037,14)],[(.005,s*.047,-.06),(-.065,s*.099,-.105),(-.112,s*.067,-.095),(-.037,s*.043,-.061)],parent='spine_mid',rays=12)
  f.eye('SmallEye'+tag,f.surface(.354,s*1.15,.001),(0,s*.94,.34),.0067,iris=(.54,.47,.34))
  f.gill(tag,[f.surface(.25+.018*((t-1.0)/1.1)**2,s*t,.001) for t in np.linspace(.37,2.3,28)],.0011)
  whisker(f,'MaxillaryBarbel'+tag,[(.428,s*.034,-.022),(.405,s*.052,-.033),(.371,s*.073,-.046),(.348,s*.074,-.051)],[.0018,.0014,.0007,.00014],f.mats['edge'],'head')
  whisker(f,'NasalBarbel'+tag,[(.452,s*.027,.021),(.445,s*.036,.03),(.429,s*.044,.043),(.414,s*.045,.048)],[.0012,.001,.0005,.00012],f.mats['edge'],'head')
  whisker(f,'OuterChinBarbel'+tag,[(.424,s*.027,-.031),(.409,s*.041,-.045),(.382,s*.05,-.064),(.366,s*.048,-.070)],[.0016,.0012,.0006,.00013],lipmat,'jaw')
  whisker(f,'InnerChinBarbel'+tag,[(.443,s*.013,-.031),(.431,s*.02,-.045),(.410,s*.027,-.061),(.397,s*.026,-.068)],[.0014,.0011,.0006,.00013],lipmat,'jaw')
