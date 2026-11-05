"""Soft hull knocks, wet impacts and cute reward/boost feedback, all original synthesis."""
import math, random, wave, array
from pathlib import Path
SR=22050
ROOT=Path(__file__).resolve().parents[1]/'assets/boats/sfx'
def save(name,b):
    peak=max(abs(v) for v in b) or 1
    data=array.array('h',(round(v/peak*23500) for v in b))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes(data.tobytes())
for variant in range(3):
    rng=random.Random(168+variant);b=[];low=body=0
    for i in range(round(.38*SR)):
        t=i/SR
        low+=.13*(rng.uniform(-1,1)-low)
        body+=.045*(rng.uniform(-1,1)-body)
        # Short rounded fender knock, followed by a soft irregular water spill.
        knock=(math.sin(math.tau*(155+variant*11)*t)*.62+math.sin(math.tau*(263+variant*9)*t)*.22)*math.exp(-t*45)*min(1,t*1200)
        wet=(low*.48+body*.8)*math.exp(-max(0,t-.025)*13)*min(1,t*65)
        b.append(knock*.6+wet)
    save('collision' if variant==0 else 'collision-'+str(variant+1),b)
for name,notes,duration in [
 ('shell',[(0,1046,.12,.3),(.055,1568,.14,.18)],.23),
 ('pad',[(0,440,.22,.25),(.07,659,.22,.24),(.15,880,.28,.22)],.47),
 ('ramp',[(0,520,.18,.22),(.08,780,.2,.22),(.17,1170,.25,.18)],.48)]:
    b=[0.0]*round(duration*SR)
    for start,f,length,amp in notes:
        for i in range(round(length*SR)):
            at=round(start*SR)+i
            if at>=len(b):break
            t=i/SR
            b[at]+=(math.sin(math.tau*f*t)+.12*math.sin(math.tau*f*2*t))*math.exp(-t*18)*min(1,t*300)*amp
    save(name,b)
rng=random.Random(39);b=[];low=0
for i in range(round(.4*SR)):
    t=i/SR;low+=.10*(rng.uniform(-1,1)-low)
    b.append(low*math.exp(-t*13)*min(1,t*100))
save('land',b)
print('Generated 3 soft wet collision variants, shell, pad, ramp and landing')
