"""Check local documentation links, README roster and the SVG banner."""
from pathlib import Path
import argparse
import json
import re
import urllib.parse
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--write-roster', action='store_true')
args = parser.parse_args()
catalog = json.loads((root/'payload/catalog.json').read_text(encoding='utf-8'))
names = sorted(item['name'] for item in catalog['scripts'])
rows = ['<details>', f'<summary><strong>View all {len(names)} operators</strong></summary>', '', '| Operator | Operator | Operator |', '| :--- | :--- | :--- |']
for i in range(0, len(names), 3):
    cells = names[i:i+3]
    rows.append('| ' + ' | '.join(cells + [''] * (3-len(cells))) + ' |')
rows += ['', '</details>']
generated = '\n'.join(rows)
readme = root/'README.md'
text = readme.read_text(encoding='utf-8')
assert not any(marker in text for marker in ['\u00c3', '\u00e2\u20ac', '\u00c2\u00b7', '\u00e2\u201d']), 'README contains mojibake; decode UTF-8 explicitly when editing'
pattern = r'(?<=<!-- operators:begin -->)\s*.*?\s*(?=<!-- operators:end -->)'
assert len(re.findall(pattern, text, flags=re.S)) == 1, 'Expected one roster block'
expected = re.sub(pattern, '\n' + generated + '\n', text, flags=re.S)
if args.write_roster:
    readme.write_bytes(expected.encode('utf-8'))
else:
    assert text == expected, 'README roster stale; run python check_docs.py --write-roster'

def anchors(path):
    headings = re.findall(r'^#{1,6}\s+(.+?)\s*#*$', path.read_text(encoding='utf-8'), flags=re.M)
    return {re.sub(r'[^\w\- ]', '', h.lower()).replace(' ', '-') for h in headings}

checked = 0
for doc in [root/'README.md', root/'CONTRIBUTING.md', root/'CHANGELOG.md', *list((root/'docs').glob('*.md'))]:
    for target in re.findall(r'!?\[[^\]]*\]\(([^\s)]+)\)', doc.read_text(encoding='utf-8')):
        if target.startswith(('https://', 'http://', 'mailto:')):
            continue
        path, _, fragment = target.partition('#')
        destination = (doc.parent/urllib.parse.unquote(path)).resolve() if path else doc
        assert destination.is_relative_to(root), f'Outside-repo link: {doc.name}: {target}'
        assert destination.exists(), f'Missing link: {doc.name}: {target}'
        if fragment and destination.suffix == '.md':
            assert fragment in anchors(destination), f'Missing heading: {doc.name}: {target}'
        checked += 1
svg = ET.parse(root/'assets/banner.svg').getroot()
assert svg.tag.endswith('svg')
assert not any(e.tag.endswith(('script', 'foreignObject')) for e in svg.iter())
print(f'PASS: {len(names)}-operator README roster, {checked} local links/anchors, valid static SVG banner.')
