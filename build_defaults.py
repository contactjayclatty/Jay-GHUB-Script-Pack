from pathlib import Path
import json, re, hashlib, subprocess, zipfile

work = Path(__file__).resolve().parent
out = work / 'dist'
names = '''Noor|Solid Snake|Denari|Rauora|SkopÃ³s|Striker|Sentry|Deimos|TubarÃ£o|Ram|Fenrir|Brava|Solis|Grim|Sens|Azami|Thorn|Osa|Thunderbird|Flores|Aruni|Zero|Ace|Melusi|Oryx|Iana|Wamai|Kali|Amaru|Goyo|NÃ¸kk|Warden|Mozzie|Gridlock|Nomad|Kaid|Clash|Maverick|Maestro|Alibi|Lion|Finka|Vigil|Dokkaebi|Zofia|Ela|Ying|Lesion|Mira|Jackal|Hibana|Echo|Caveira|CapitÃ£o|Blackbeard|Valkyrie|Buck|Frost|Mute|Sledge|Smoke|Thatcher|Ash|Castle|Pulse|Thermite|Montagne|Twitch|Doc|Rook|JÃ¤ger|Bandit|Blitz|IQ|Fuze|Glaz|Tachanka|Kapkan'''.split('|')
assert len(names) == len(set(names)) == 78
aliases = {'JÃ¤ger':['Jager'], 'Valkyrie':['Valk'], 'SkopÃ³s':['Skopos'], 'TubarÃ£o':['Tubarao'], 'NÃ¸kk':['Nokk'], 'CapitÃ£o':['Capitao']}
source = (work/'template.lua').read_text(encoding='utf-8')
# Keep the tested control logic; replace personal tuning and all old header art.
body = source[source.index('local h_counter = 0'):]
assert body.count('until not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3)') == 2
assert body.count('Sleep(1)') == 2
assert len(re.findall(r'if IsMouseButtonPressed\(1\) then\s+v_counter = 0\s+h_counter = 0\s+repeat',body)) == 2
settings = '''-- NEUTRAL STARTING VALUES: these are not operator-specific recoil presets.
-- USER TUNING: adjust these two values after testing your weapon and sensitivity.
RcCustomStrength = 0       -- Downward movement per vertical step; 0 means none.
HorizontalStrength = 0     -- Negative = left, positive = right; 0 means none.

-- ADVANCED CONTROLS: leave these unchanged unless you understand their effect.
EnableRCS = true
RecoilControlMode = "Custom"
VerticalFrequency = 2
HorizontalFrequency = 4
RequireToggle = true
ToggleKey = "CapsLock"
DelayRate = 7

-- INTERNAL LOGIC: leave unchanged. Burst resets, idle waits and aim-release checks
-- are included. The firing loops remain separate.
if RecoilControlMode == "Low" then
  RecoilControlStrength = 2
elseif RecoilControlMode == "Medium" then
  RecoilControlStrength = 6
elseif RecoilControlMode == "High" then
  RecoilControlStrength = 8
elseif RecoilControlMode == "Ultra" then
  RecoilControlStrength = 12
elseif RecoilControlMode == "Insanity" then
  RecoilControlStrength = 31
elseif RecoilControlMode == "Custom" then
  RecoilControlStrength = RcCustomStrength
end

'''
payload = work/'payload'
# Archive the old packaged payload before replacing its files. Live files are read-only.
with zipfile.ZipFile(work/'previous-calibrated-payload.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in payload.iterdir():
        if p.is_file(): z.write(p,p.name)
for p in payload.iterdir():
    if not p.is_file(): raise RuntimeError('Unexpected subdirectory in payload')
    p.unlink()
catalog = []
for index,name in enumerate(names):
    filename = f'operator-{index+1:02d}.lua'
    data = (f'-- SPDX-License-Identifier: MIT\n-- Operator: {name}\n-- Script pack 1.2.0; roster checked 2026-10-22.\n\n'+settings+body).replace('\r\n','\n').encode('utf-8')
    p = payload/filename
    data = ('\n'.join(line.rstrip() for line in data.decode('utf-8').splitlines()).rstrip()+'\n').encode('utf-8')
    p.write_bytes(data)
    result = subprocess.run([r'C:\Program Files (x86)\Lua\5.1\luac.exe','-p',str(p)],capture_output=True,text=True)
    assert result.returncode == 0,result.stderr
    catalog.append({'name':name,'aliases':aliases.get(name,[]),'file':filename,'sha256':hashlib.sha256(data).hexdigest()})
(payload/'catalog.json').write_text(json.dumps({'version':'1.2.0','rosterVerified':'2026-10-22','rosterSource':'https://www.ubisoft.com/en-us/game/rainbow-six/siege/game-info/operators','defaults':{'RcCustomStrength':0,'HorizontalStrength':0,'VerticalFrequency':2,'HorizontalFrequency':4,'DelayRate':7},'scripts':catalog},indent=2,ensure_ascii=False),encoding='utf-8')
print('78 neutral templates generated; Lua syntax checked. Live G HUB scripts unchanged.')
