import math,wave,array,random
random.seed(23)
sr=22050;bpm=112;beat=60/bpm;duration=beat*64
buf=array.array('f',[0])*int(sr*duration)
def note(midi,start,length,amp,kind='bell'):
 f=440*2**((midi-69)/12);n=int(length*sr);offset=int(start*sr)
 for j in range(n):
  t=j/sr
  if kind=='bell':
   v=(math.sin(2*math.pi*f*t)*math.exp(-t*5)+0.32*math.sin(2*math.pi*f*2*t)*math.exp(-t*8)+0.12*math.sin(2*math.pi*f*3*t)*math.exp(-t*12))
  elif kind=='pluck':v=(math.sin(2*math.pi*f*t)+0.25*math.sin(2*math.pi*f*2*t))*math.exp(-t*8)
  elif kind=='bass':v=(math.sin(2*math.pi*f*t)+0.12*math.sin(2*math.pi*f*2*t))*min(1,t*80)*math.exp(-t*5)
  else:v=math.sin(2*math.pi*f*t)*min(1,t*45)*min(1,(length-t)*8)*0.7
  v*=amp*min(1,(length-t)*60)
  if offset+j<len(buf):buf[offset+j]+=v
# Original 16-bar melody; ukulele-like arpeggios, warm bass, and light woodblock.
chords=[[60,64,67,71],[57,60,64,67],[53,57,60,64],[55,59,62,67]]
melody=[[76,79,81,79,76,74],[72,76,79,76,74,72],[77,76,74,72,69,72],[74,79,77,74,71,72], [76,79,84,83,81,79],[81,79,76,74,72,76],[77,81,79,77,76,74],[74,71,67,71,72,79]]
for bar in range(16):
 t=bar*beat*4;c=chords[bar%4]
 for k in range(8):note(c[[0,2,1,2,0,2,3,2][k]],t+k*beat*0.5,0.45,0.09,'pluck')
 for k in range(4):note(c[0]-24+(7 if k%2 else 0),t+k*beat,0.43,0.16,'bass')
 for k,m in enumerate(melody[bar%8]):note(m,t+[0,0.5,1,2,2.5,3][k]*beat,0.65,0.115,'bell')
 for k in [1,3]:
  note(91,t+k*beat,0.035,0.035,'pluck')
mx=max(abs(v) for v in buf)
with wave.open('assets/boats/harbor-day.wav','wb') as out:
 out.setnchannels(1);out.setsampwidth(2);out.setframerate(sr)
 out.writeframes(array.array('h',[int(v/max(1,mx)*28000) for v in buf]).tobytes())
