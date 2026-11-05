"""Original synthesized boat feedback. No external samples or recordings."""
import array, math, random, wave
from pathlib import Path
SR=22050
ROOT=Path(__file__).resolve().parents[1]/'assets/boats/sfx'
ROOT.mkdir(parents=True,exist_ok=True)
rng=random.Random(930)

def save(name,buf,loop=False):
    if loop:
        # Equal-power overlap produces a continuous wrap without a click.
        n=int(.18*SR)
        for i in range(n):
            a=i/n
            buf[i]=buf[-n+i]*(1-a)+buf[i]*a
        buf=buf[:-n]
    peak=max(abs(v) for v in buf) or 1
    pcm=array.array('h',(round(max(-1,min(1,x/peak)) * 24000) for x in buf))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as w:
        w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes(pcm.tobytes())

def tone(buf,start,freq,length,amp=.3,end=None):
    phase=0
    for j in range(round(length*SR)):
        i=round(start*SR)+j
        if i>=len(buf):break
        t=j/SR;u=t/length
        f=freq if end is None else freq+(end-freq)*u
        phase+=2*math.pi*f/SR
        env=min(1,t*150)*(1-u)**2
        buf[i]+=amp*(math.sin(phase)+.15*math.sin(phase*2))*env

def splash(buf,start,length,amp):
    lo=0
    for j in range(round(length*SR)):
        i=round(start*SR)+j
        if i>=len(buf):break
        t=j/SR
        lo+=.17*(rng.uniform(-1,1)-lo)
        buf[i]+=lo*amp*min(1,t*160)*math.exp(-t*15)

# Low, rounded bow wash with small irregular liquid burbles; no high white hiss.
b=[0.0]*round(4.18*SR);lo=0;deep=0
for i in range(len(b)):
    t=i/SR;lo+=.10*(rng.uniform(-1,1)-lo);deep+=.012*(lo-deep)
    b[i]=(lo-deep*.6)*(.55+.12*math.sin(t*math.tau*1.7)+.08*math.sin(t*math.tau*3.3))
for k in range(27):
    start=rng.uniform(0,4);tone(b,start,rng.uniform(230,480),rng.uniform(.06,.16),.035,rng.uniform(110,240))
save('water',b,True)
b=[]
for i in range(round(2.18*SR)):
    t=i/SR;f=72
    b.append((math.sin(math.tau*f*t)+.20*math.sin(math.tau*f*2*t))*(.9+.08*math.sin(math.tau*12*t)))
save('motor',b,True)
b=[0.0]*round(2.18*SR)
for k in range(34):splash(b,k*.065,.14,.7)
save('boost-water',b,True)

for name,dur,notes in [
 ('navigate',.12,[(0,740,.09,.20)]),
 ('confirm',.28,[(0,660,.13,.22),(.09,990,.17,.22)]),
 ('back',.20,[(0,660,.11,.20),(.07,440,.12,.18)]),
 ('count',.22,[(0,660,.18,.25)]),
 ('go',.48,[(0,880,.24,.24),(.09,1108,.24,.18),(.19,1320,.27,.20)]),
 ('pickup',.46,[(0,784,.15,.20),(.09,988,.16,.20),(.18,1318,.24,.22)]),
 ('lap',.65,[(0,784,.17,.18),(.13,988,.17,.18),(.26,1175,.20,.18),(.39,1568,.24,.15)]),
 ('finish',1.5,[(0,784,.25,.23),(.18,988,.25,.23),(.36,1175,.25,.23),(.55,1568,.7,.23),(.55,988,.7,.13),(.55,1175,.7,.13)]),
 ('item',.45,[(0,320,.16,.22),(.08,640,.18,.20),(.19,960,.24,.20)]),
 ('charge',.22,[(0,660,.18,.16)]),
 ('boost',.55,[(0,330,.24,.20),(.10,660,.25,.22),(.22,990,.28,.17)])]:
    b=[0.0]*round(dur*SR)
    for start,f,length,amp in notes:tone(b,start,f,length,amp)
    if name in ('item','boost'):splash(b,0,.35,.6)
    save(name,b)
b=[0.0]*round(.42*SR)
tone(b,0,165,.18,.45,95)
splash(b,.015,.36,1)
tone(b,.08,380,.13,.07,180)
save('collision',b)
print('Generated 15 original boat SFX and loops in',ROOT)

# Sailing loops have a dedicated revision; regenerate those last.
import runpy
runpy.run_path(str(Path(__file__).with_name("generate_sailing_audio.py")))

runpy.run_path(str(Path(__file__).with_name("generate_course_audio.py")))
