from pathlib import Path
from html.parser import HTMLParser

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / 'index.html'

class LocalAssetParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.paths = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for key in ('src', 'href'):
            value = attrs.get(key, '')
            if value and not value.startswith(('http://', 'https://', 'data:', '#', 'mailto:')):
                self.paths.append(value.split('?', 1)[0])

parser = LocalAssetParser()
parser.feed(HTML.read_text(encoding='utf-8'))
missing = [p for p in parser.paths if not (ROOT / p).exists()]
assert not missing, f'Missing local HTML assets: {missing}'
for required in ['src/app.js', 'src/multiplayer.js', 'src/styles.css', 'backend/config.js', 'manifest.webmanifest', 'service-worker.js', 'public/icon.svg']:
    assert (ROOT / required).is_file(), f'Missing required project file: {required}'
tracks = sorted((ROOT / 'assets/audio/music').glob('*.mp3'))
assert len(tracks) >= 4, f'Expected at least four soundtrack tracks, found {len(tracks)}'
assert (ROOT / 'GITHUB_SETUP.md').is_file()
assert (ROOT / '.gitignore').is_file()
assert (ROOT / 'backend/fix_room_code_generation.sql').is_file()
for sql_path in [ROOT / 'backend/schema.sql', ROOT / 'backend/upgrade_v3.sql']:
    sql_text = sql_path.read_text(encoding='utf-8')
    assert 'gen_random_bytes' not in sql_text, f'Legacy pgcrypto dependency remains in {sql_path.name}'
    assert 'replace(gen_random_uuid()::text' in sql_text, f'UUID room-code generator missing in {sql_path.name}'
hotfix = (ROOT / 'backend/fix_room_code_generation.sql').read_text(encoding='utf-8')
assert 'nexora_create_room_v2' in hotfix and 'gen_random_bytes' not in hotfix
index = HTML.read_text(encoding='utf-8')
assert 'id="copyRoomCode"' in index
assert 'Mysterious Big Boss' in index
css = (ROOT / 'src/styles.css').read_text(encoding='utf-8')
assert '.multi-actions{display:grid;grid-template-columns:repeat(2,minmax(0,1fr))' in css
assert '.multi-action-card .primary-btn,.multi-action-card .secondary-btn{display:block' in css
print(f'PASS GitHub package: {len(parser.paths)} local HTML references resolve, {len(tracks)} music tracks, project folders retained, room controls centred.')
