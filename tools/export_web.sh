#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/web
touch build/.gdignore
if [ ! -f .export_templates/web_nothreads_release.zip ]; then
  python3 tools/fetch_web_template.py
fi
# Godot validates both standard template slots even for a release-only build.
python3 - <<'TEMPLATE'
import os, platform, re, subprocess
from pathlib import Path
version = subprocess.check_output(['godot', '--version'], text=True).strip()
match = re.match(r'(\d+\.\d+(?:\.\d+)?)\.([^.]*)', version)
folder = match.group(1) + '.' + match.group(2)
base = Path.home() / 'Library/Application Support/Godot' if platform.system() == 'Darwin' else Path(os.environ.get('XDG_DATA_HOME', str(Path.home()/'.local/share'))) / 'godot'
target = base / 'export_templates' / folder
target.mkdir(parents=True, exist_ok=True)
import shutil
for kind in ['release', 'debug']:
    path = target / ('web_nothreads_' + kind + '.zip')
    if not path.exists(): shutil.copyfile('.export_templates/web_nothreads_release.zip', path)
TEMPLATE
godot --headless --editor --path . --import --quit
godot --headless --path . --export-release Web build/web/index.html
cp assets/boats/cover-web-v2.png build/web/cover.png
cp assets/boats/sfx/navigate.wav build/web/hover.wav
cp assets/boats/sfx/confirm.wav build/web/press.wav
cp assets/fonts/OFL.txt build/web/FONT-LICENSE.txt
cp assets/licenses/Godot.txt build/web/GODOT-LICENSE.txt
cp tools/WEB_README.txt build/web/README.txt
touch build/web/.nojekyll
python3 tools/pack_web.py
