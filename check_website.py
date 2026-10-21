"""Validate site navigation, preview provenance and versioned download bytes."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
import hashlib
import json

root = Path(__file__).resolve().parent
site = root / 'site'
pages = list(site.glob('*.html'))
assert {p.name for p in pages} == {'index.html', 'previews.html', 'download.html', 'guide.html', 'about.html'}

class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.links, self.names, self.current = set(), [], [], []
        self.h1 = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if 'id' in a:
            assert a['id'] not in self.ids, f'Duplicate ID: {a["id"]}'
            self.ids.add(a['id'])
        if tag == 'h1': self.h1 += 1
        if tag == 'li' and 'data-search' in a: self.names.append(a['data-search'])
        if a.get('aria-current') == 'page': self.current.append(a['href'])
        for key in ('href', 'src'):
            if key in a: self.links.append(a[key])

parsed = {}
for p in pages:
    page = Page()
    page.feed(p.read_text(encoding='utf-8'))
    assert page.h1 == 1, p.name
    assert page.current == [p.name], p.name
    parsed[p.name] = page
for name, page in parsed.items():
    for link in page.links:
        url = urlsplit(link)
        if url.scheme or url.netloc: continue
        target = site / unquote(url.path or name)
        assert target.is_file(), f'{name}: missing {link}'
        if url.fragment and target.suffix == '.html':
            assert url.fragment in parsed[target.name].ids, f'{name}: missing fragment {link}'

catalog = json.loads((root/'payload/catalog.json').read_text(encoding='utf-8'))
assert len(parsed['previews.html'].names) == len(catalog['scripts']) == 78
assert set(parsed['previews.html'].names) == {' '.join([s['name'], *s['aliases']]) for s in catalog['scripts']}
manifest = json.loads((site/'downloads/release.json').read_text(encoding='utf-8'))
assert set(manifest) == {'installer', 'bundle', 'source'}
for file in manifest.values():
    data = (site/file['url']).read_bytes()
    assert len(data) == file['size']
    assert hashlib.sha256(data).hexdigest() == file['sha256']
    assert file['github'].endswith('/v1.2.0/' + file['file'])
assert (site/'assets/example.lua').read_bytes() == (root/'payload/operator-69.lua').read_bytes()
assert '-- Operator: Doc' in (site/'assets/example.lua').read_text(encoding='utf-8')
print('PASS: five pages, navigation/anchors, 78 names and aliases, exact Doc preview and three download hashes.')
