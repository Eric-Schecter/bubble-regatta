"""Replace only sailing loops with non-rhythmic wash and a rounded outboard motor."""
import math, random, array, wave
from pathlib import Path
SR=22050
ROOT=Path(__file__).resolve().parents[1]/'assets/boats/sfx'

def save(name,b,overlap=.8):
    n=round(overlap*SR)
    for i in range(n):
        u=i/n
        b[i]=b[-n+i]*math.cos(u*math.pi/2)+b[i]*math.sin(u*math.pi/2)
    b=b[:-n]
    peak=max(abs(x) for x in b)
    pcm=array.array('h',(round(x/peak*25000) for x in b))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes(pcm.tobytes())
    print(name,round(len(b)/SR,2),'seconds')

def wash(name,duration,seed,cutoff):
    rng=random.Random(seed);low=deep=texture=0.0;gain=.9;target=.9;until=0
    b=array.array('f')
    for i in range(round((duration+.8)*SR)):
        if i>=until:
            target=rng.uniform(.76,1.07)
            until=i+round(rng.uniform(.45,2.1)*SR)
        gain+=(target-gain)*.00012
        low+=cutoff*(rng.uniform(-1,1)-low)
        deep+=.004*(low-deep)
        texture+=.21*(rng.uniform(-1,1)-texture)
        # Diffuse continuous turbulence, without pitched bubbles or periodic swells.
        b.append(((low-deep*.7)*.9+texture*.035)*gain)
    save(name,b)
wash('water',29,812,.075)
wash('water-detail',37,417,.12)
wash('boost-water',17,609,.14)
rng=random.Random(63)
b=array.array('f');phase=0;air=0;rpm_wobble=0
for i in range(round(6.8*SR)):
    rpm_wobble+=(rng.uniform(-1,1)-rpm_wobble)*.001
    phase+=math.tau*(82+rpm_wobble*2.2)/SR
    air+=.08*(rng.uniform(-1,1)-air)
    # Rounded exhaust with audible middle harmonics; restrained propeller texture.
    exhaust=(math.sin(phase)+.47*math.sin(phase*2+.3)+.28*math.sin(phase*3+.7)+.10*math.sin(phase*5))
    b.append(math.tanh(exhaust*.85)*.8+air*.09)
save('motor',b)
