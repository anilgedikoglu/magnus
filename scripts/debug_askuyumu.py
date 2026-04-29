import sys, re, os, json
sys.stdout.reconfigure(encoding='utf-8')

def decode_escapes(s):
    result = []; i = 0
    while i < len(s):
        if s[i] == '\\' and i+1 < len(s):
            nxt = s[i+1]
            if nxt == 'u' and i+5 <= len(s):
                try: result.append(chr(int(s[i+2:i+6],16))); i+=6; continue
                except: pass
            elif nxt == 'x' and i+3 <= len(s):
                try: result.append(chr(int(s[i+2:i+4],16))); i+=4; continue
                except: pass
            elif nxt == 'n': result.append('\n'); i+=2; continue
            elif nxt == '"': result.append('"'); i+=2; continue
            elif nxt == '\\': result.append('\\'); i+=2; continue
        result.append(s[i]); i+=1
    return ''.join(result)

BASE = 'C:/Magnus/Assets/Resources/Editor/OnlineDOSYALAR/AnaMenu2/AskUyumu/BarAskUyumu/0-25'
f = sorted([x for x in os.listdir(BASE) if x.endswith('.asset')])[0]
with open(os.path.join(BASE, f), 'rb') as fh:
    raw = fh.read().decode('utf-8', errors='replace')

m = re.search(r'aciklama:(.*?)aciklamaEng:', raw, re.DOTALL)
blok = m.group(1)
print('BLOK LEN:', len(blok))
print('BLOK:', repr(blok))

items = re.findall(r'-\s+"((?:[^"\\\r\n]|\\[^\r\n]|[\r\n])*?)"', blok)
print('ITEMS COUNT:', len(items))
if items:
    t = decode_escapes(items[0])
    t = re.sub(r'\n[ \t]+', ' ', t).replace('\r','').strip().strip('"')
    t = re.sub(r'^\{\{barmenu\}\}', '', t).strip()
    print('TEXT:', t[:200])
    data = json.loads(t)
    print('EXPL:', data['bars'][0]['explanations'][0]['content'])
