import wave,random,math,struct,pathlib
p=pathlib.Path(__file__).resolve().parent.parent/'game/assets/audio';p.mkdir(exist_ok=True,parents=True);random.seed(54);rate=22050
for name,duration,freq in [('cast',0.4,380),('nibble',0.14,650),('bite',0.5,880),('hook',0.26,560),('catch',1.3,660),('escape',0.5,240)]:
 s=[]
 for i in range(int(duration*rate)):
  t=i/rate;e=math.sin(math.pi*t/duration)**2*math.exp(-2*t)
  f=freq*(1+0.12*t) if name!='escape' else freq*(1-0.5*t)
  v=(math.sin(2*math.pi*f*t)+0.3*math.sin(2*math.pi*f*1.5*t))*e*0.19
  if name=='cast':v=(random.random()*2-1)*e*0.14
  s.append(int(v*32767))
 with wave.open(str(p/(name+'.wav')),'wb') as f:f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(struct.pack('<%dh'%len(s),*s))
s=[];filtered=0.0;n=rate*12
for i in range(n):
 t=i/rate;filtered=filtered*0.975+(random.random()*2-1)*0.025
 env=0.7+0.3*math.sin(2*math.pi*t/6)
 s.append(filtered*env*.7)
fade=rate
for i in range(fade):
 a=i/fade;s[i]=s[n-fade+i]*(1-a)+s[i]*a
with wave.open(str(p/'water.wav'),'wb') as f:f.setparams((1,2,rate,0,'NONE','not compressed'));f.writeframes(struct.pack('<%dh'%n,*[int(v*32767) for v in s]))
