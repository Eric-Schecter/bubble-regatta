"""Prepare compressed transport assets and a deployable static bundle."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import gzip, json
root=Path('build/web')
manifest={}
for name in ['index.wasm','index.pck']:
    data=(root/name).read_bytes()
    compressed=gzip.compress(data,compresslevel=9,mtime=0)
    target=name+'.gzip'
    (root/target).write_bytes(compressed)
    manifest[name]={'url':target,'size':len(compressed),'rawSize':len(data),'type':'application/wasm' if name.endswith('.wasm') else 'application/octet-stream'}
html=root/'index.html'
html.write_text(html.read_text().replace('$REGATTA_ASSETS',json.dumps(manifest,separators=(',',':'))))
for file in root.glob('*.import'):file.unlink()
with ZipFile('build/bubble-regatta-web.zip','w',ZIP_DEFLATED) as archive:
    for file in sorted(root.iterdir()):
        if file.is_file():archive.write(file,file.name)
print('Transport: %.1f MB -> %.1f MB' % (sum(v['rawSize'] for v in manifest.values())/1e6,sum(v['size'] for v in manifest.values())/1e6))
