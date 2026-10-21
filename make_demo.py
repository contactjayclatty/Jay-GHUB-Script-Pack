"""Render a UI walkthrough backed by real install/uninstall results in a test folder.

Optional development dependency: Pillow. No live G HUB folders are touched.
"""
from pathlib import Path
import datetime
import json
import subprocess
from PIL import Image

root=Path(__file__).resolve().parent
test=root/('test-data-demo-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S'))
test.mkdir()
shell=r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
base=[shell,'-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',str(root/'Installer.ps1')]

def render(name,status,filter_text=None):
    p=test/(name+'.png')
    command=base+['-Operators','Doc,Ash','-RenderPreview',str(p),'-PreviewStatus',status]
    if filter_text:command+=['-PreviewFilter',filter_text]
    subprocess.run(command,check=True,capture_output=True)
    return Image.open(p).convert('RGB')

frames=[render('01-select','DEMO / Isolated test folder. Choose operators before installation.')]
frames.append(render('02-filter','DEMO / Search narrows the list without clearing hidden selections.','Doc'))
result=subprocess.run(base+['-Action','Install','-TargetRoot',str(test/'LGHUB'),'-TestMode','-Operators','Doc,Ash'],check=True,capture_output=True,text=True)
names={json.loads(p.read_text(encoding='utf-8'))['name'] for p in (test/'LGHUB/scripts').glob('*/config.json')}
assert names=={'Doc','Ash'}
frames.append(render('03-installed','DEMO / Isolated test folder: '+result.stdout.splitlines()[0]))
removed=subprocess.run(base+['-Action','Uninstall','-TargetRoot',str(test/'LGHUB'),'-TestMode'],check=True,capture_output=True,text=True)
assert not list((test/'LGHUB/scripts').iterdir())
frames.append(render('04-uninstalled','DEMO / Isolated test folder: '+removed.stdout.strip()))
frames[0].save(root/'assets/installer-demo.gif',save_all=True,append_images=frames[1:],duration=[2600,2600,3200,3200],loop=0,optimize=True)
frames[0].save(root/'assets/installer-preview.png')
print('Demo rendered from the real form; actual isolated install/uninstall verified. No live scripts modified.')
