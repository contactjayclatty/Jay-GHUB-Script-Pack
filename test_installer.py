from pathlib import Path
import subprocess, json, shutil, datetime

work = Path(__file__).resolve().parent
test_root = work / ('test-data-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
if test_root.exists():
    raise RuntimeError('Test directory already exists; use a fresh test location')
test_root.mkdir()
shell = r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
catalog = json.loads((work/'payload'/'catalog.json').read_text(encoding='utf-8'))
count = len(catalog['scripts'])
assert count == 78
for item in catalog['scripts']:
    text = (work/'payload'/item['file']).read_text(encoding='utf-8')
    assert 'RcCustomStrength = 0 ' in text and 'HorizontalStrength = 0 ' in text
    assert text.count('until not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3)') == 2
    assert text.count('Sleep(1)') == 2

def run(action, root, expected=0, operators=None):
    command=[shell, '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(work/'Installer.ps1'), '-Action', action, '-TargetRoot', str(root), '-TestMode']
    if operators is not None: command += ['-Operators',operators]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode != expected:
        raise AssertionError(result.stdout + result.stderr)
    return result.stdout

fresh = test_root/'fresh'
print(run('Install', fresh).splitlines()[0])
folders = list((fresh/'scripts').iterdir())
assert len(folders) == count
installed_names = {json.loads((p/'config.json').read_text(encoding='utf-8'))['name'] for p in folders}
assert installed_names == {item['name'] for item in catalog['scripts']}
original = {str(p.relative_to(fresh)): p.read_bytes() for p in (fresh/'scripts').rglob('*') if p.is_file()}
print(run('Install', fresh).splitlines()[0])
assert len(list((fresh/'scripts').iterdir())) == count
assert all((fresh/p).read_bytes() == data for p,data in original.items())
print(run('Uninstall', fresh).strip())
assert not list((fresh/'scripts').iterdir())

mixed = test_root/'mixed'
existing = mixed/'scripts'/'existing-user-script'
existing.mkdir(parents=True)
(existing/'config.json').write_text(json.dumps({'name':'Doc','fileName':'.\\script.lua'}))
(existing/'script.lua').write_text('-- user-owned Doc\n')
original_user = {p.name:p.read_bytes() for p in existing.iterdir()}
for alias in ['Jager','Valk']:
    alias_folder = mixed/'scripts'/('existing-'+alias)
    alias_folder.mkdir()
    (alias_folder/'config.json').write_text(json.dumps({'name':alias,'fileName':'.\\script.lua'}))
    (alias_folder/'script.lua').write_text('-- existing alias script')
print(run('Install', mixed).splitlines()[0])
assert len(list((mixed/'scripts').iterdir())) == count
manifest_path = mixed/'script-pack-installs'/'siege-operator-lua-pack-v1'/'installed.json'
manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
assert len(manifest['scripts']) == count - 3
assert not {'Doc','J\u00e4ger','Valkyrie'} & {i['name'] for i in manifest['scripts']}
edited = mixed/'scripts'/manifest['scripts'][0]['id']/'script.lua'
edited.write_bytes(edited.read_bytes()+b'\n-- user changed this script\n')
edited_bytes = edited.read_bytes()
print(run('Uninstall', mixed).strip())
assert len(list((mixed/'scripts').iterdir())) == 4
assert edited.read_bytes() == edited_bytes
assert all((existing/name).read_bytes() == data for name,data in original_user.items())
assert list((mixed/'script-pack-installs'/'siege-operator-lua-pack-v1'/'backups').iterdir())
print('PASS: fresh install, repeat install, duplicate preservation, edited-script preservation, uninstall and retained backups.')

# Corrupt payload must be rejected before touching the target.
bad_package = test_root/'bad-package'
bad_package.mkdir()
shutil.copy2(work/'Installer.ps1', bad_package/'Installer.ps1')
shutil.copytree(work/'payload', bad_package/'payload')
(bad_package/'payload'/catalog['scripts'][0]['file']).write_text('-- corrupt payload')
bad_target = test_root/'bad-target'
result = subprocess.run([shell,'-NoProfile','-ExecutionPolicy','Bypass','-File',str(bad_package/'Installer.ps1'),'-Action','Install','-TargetRoot',str(bad_target),'-TestMode'],capture_output=True,text=True)
assert result.returncode != 0
assert not bad_target.exists()
print('PASS: corrupt payload rejected without modifying target.')

# Selective installs must not add unrelated operators, and later installs merge ownership.
selective=test_root/'selective'
print(run('Install',selective,operators='Doc,Ash,Doc').splitlines()[0])
selected_configs=list((selective/'scripts').glob('*/config.json'))
assert {json.loads(p.read_text(encoding='utf-8'))['name'] for p in selected_configs}=={'Doc','Ash'}
print(run('Install',selective,operators='Jager,Valk').splitlines()[0])
manifest=json.loads((selective/'script-pack-installs'/'siege-operator-lua-pack-v1'/'installed.json').read_text(encoding='utf-8'))
assert len(manifest['scripts'])==4
assert {i['name'] for i in manifest['scripts']}=={'Doc','Ash','J\u00e4ger','Valkyrie'}
print(run('Uninstall',selective).strip())
assert not list((selective/'scripts').iterdir())
for selection in [',','NotAnOperator']:
    target=test_root/('invalid-'+str(len(selection)))
    result=run('Install',target,expected=1,operators=selection)
    assert not target.exists()
print('PASS: subset selection, deduplication, aliases, ownership merge, complete uninstall and invalid/empty selection rejection.')
