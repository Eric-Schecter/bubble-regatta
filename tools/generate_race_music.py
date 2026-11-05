"""Original 32-bar cute regatta race loop, 140 BPM; no borrowed recordings."""
import math, wave, array, random
from pathlib import Path
rng=random.Random(72)
sr=22050
beat=60/140
frames=round(sr*beat*128)
left=array.array('f',[0])*frames
right=array.array('f',[0])*frames

def note(midi,start,length,amp,kind='marimba',pan=0):
    f=440*2**((midi-69)/12)
    offset=round(start*sr)
    for j in range(round(length*sr)):
        t=j/sr
        phase=2*math.pi*f*t
        if kind=='marimba':
            v=(math.sin(phase)+.3*math.sin(phase*2)*math.exp(-t*16)+.12*math.sin(phase*3))*math.exp(-t*9)
        elif kind=='pluck':
            v=(math.sin(phase)+.22*math.sin(phase*2)+.08*math.sin(phase*3))*math.exp(-t*13)
        elif kind=='bass':
            v=(math.sin(phase)+.18*math.sin(phase*2))*math.exp(-t*5)
        elif kind=='kick':
            v=math.sin(2*math.pi*(48*t+2.0*(1-math.exp(-t*32))))*math.exp(-t*24)
        elif kind=='clap':
            v=(rng.random()*2-1)*math.exp(-t*65)*.5+math.sin(phase)*math.exp(-t*40)*.3
        else:
            v=(rng.random()*2-1)*math.exp(-t*105)*.35
        v*=amp*min(1,t*700)*min(1,max(0,length-t)*100)
        idx=(offset+j)%frames
        left[idx]+=v*(1-pan*.65)
        right[idx]+=v*(1+pan*.65)
        if kind in ('marimba','pluck'):
            echo=(idx+round(beat*.75*sr))%frames
            left[echo]+=v*.12*(1+pan*.5)
            right[echo]+=v*.12*(1-pan*.5)

chords=[[60,64,67,72],[55,59,62,67],[57,60,64,69],[53,57,60,65],
        [60,64,67,72],[62,65,69,74],[53,57,60,65],[55,59,62,67]]
melodies=[
 [76,79,81,79,76,74,72], [74,79,83,81,79,74],
 [76,81,84,83,81,79,76], [77,81,79,77,76,72],
 [79,84,83,81,79,76,79], [81,77,74,77,81,84],
 [81,79,77,76,74,72,74], [79,77,74,71,74,79],
 [84,83,81,79,81,84,86], [83,81,79,74,79,83],
 [84,88,86,84,83,81,79], [81,84,81,79,77,76],
 [79,76,79,84,83,79,76], [77,81,86,84,81,77],
 [81,79,77,76,74,72,77], [79,74,71,74,79,83]]
for bar in range(32):
    t=bar*4*beat
    c=chords[bar%8]
    for k in range(8):
        note(c[[0,2,1,3,2,1,3,2][k]],t+k*.5*beat,.25,.095,'pluck',-.5)
    for k in range(4):
        note(c[0]-24+(7 if k%2 else 0),t+k*beat,.28,.22,'bass')
        note(36,t+k*beat,.16,.26,'kick')
        note(90,t+(k+.5)*beat,.055,.075,'hat',.45)
    for k in (1,3):note(76,t+k*beat,.09,.13,'clap',.12)
    melody=melodies[bar%16]
    positions=[0,.5,1,1.75,2.5,3,3.5] if len(melody)==7 else [0,.75,1.5,2,2.75,3.5]
    for k,m in enumerate(melody):
        note(m,t+positions[k]*beat,.30 if k<len(melody)-1 else .38,.16,'marimba',.22)
    # A small answer in the second half gives the loop a distinct B section.
    if bar>=16:
        for k in (1,3):note(c[2]+12,t+(k+.25)*beat,.19,.055,'pluck',.65)
peak=max(max(abs(v) for v in left),max(abs(v) for v in right))
out=array.array('h')
for a,b in zip(left,right):out.extend((round(a/peak*27000),round(b/peak*27000)))
path=Path(__file__).resolve().parents[1]/'assets/boats/bubble-sprint.wav'
with wave.open(str(path),'wb') as w:
    w.setparams((2,2,sr,0,'NONE','not compressed'))
    w.writeframes(out.tobytes())
print(f'{path}: 140 BPM, 32 bars, {frames/sr:.2f}s stereo loop')
