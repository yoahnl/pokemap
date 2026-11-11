import json,os,re,sys
root='/Users/karim/Project/pokemonProject'
os.chdir(root)
d=json.load(open('documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/proofs/t01-execution/owner-qualification-20261111/g0-static-diagnostic-after-character-retirement.json'))
legacy=set(v['path'] for v in d['violations'] if v['kind']=='physical')
inv=json.load(open('documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/ui-retirement-inventory.json'))
symbols=set()
for e in inv['entries']:
  symbols.update(e.get('widgetClasses') or [])
exc=json.load(open('documentation/reports/avelune_studio/plans/2026-11-09-constructeur-cartes/t01-technical-exceptions.json'))
for e in exc['exceptions']:
  symbols.difference_update(e['symbols'])
excpaths={e['path'] for e in exc['exceptions']}
def bad(p): return p not in excpaths and (p in legacy or p.startswith('packages/avelune_design_system/lib/') or p.startswith('packages/map_editor/lib/src/ui/') or p.startswith('apps/avelune_studio/lib/presentation/'))
pkgs={}
for base in ['apps','packages','examples']:
  for n in os.listdir(base):
    if os.path.exists(f'{base}/{n}/pubspec.yaml'): pkgs[n]=f'{base}/{n}'
imp=re.compile(r"^\s*(?:import|export|part)\s+'([^']+)'",re.M)
def deps(path):
  try: src=open(path).read()
  except: return []
  out=[]
  for u in imp.findall(src):
    if u.startswith('dart:'): continue
    if u.startswith('package:'):
      n,rest=u[8:].split('/',1)
      if n in pkgs: out.append(os.path.normpath(f'{pkgs[n]}/lib/{rest}'))
    else: out.append(os.path.normpath(os.path.join(os.path.dirname(path),u)))
  return out
def chain(p,seen):
  if bad(p): return [p]
  if p in seen: return None
  seen.add(p)
  for x in deps(p):
    c=chain(x,seen)
    if c: return [p]+c
  return None
tok=re.compile(r'[A-Za-z_$][A-Za-z0-9_$]*')
ok=True
for f in sys.argv[1:]:
  f=os.path.relpath(os.path.abspath(f),root)
  c=chain(f,set())
  src=re.sub(r"'(?:\\.|[^'])*'|\"(?:\\.|[^\"])*\"",'',open(f).read())
  hs=sorted(symbols & set(tok.findall(src)))
  if c or hs:
    ok=False; print('DIRTY',f,'chain=',' -> '.join(c) if c else '-', 'symbols=',hs)
  else: print('CLEAN',f)
sys.exit(0 if ok else 1)
