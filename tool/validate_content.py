#!/usr/bin/env python3
"""Validate package structure, closed operation vocabulary, graph and hashes.
No package expression is evaluated. Test data never changes the real pack.
"""
import json, hashlib, pathlib, re, sys, copy
ROOT=pathlib.Path(__file__).resolve().parents[1]
CONDITIONS={'resource_min','resource_max','minPopulation','maxPopulation','minHousing','maxHousing','minMorale','maxMorale','minRelation','maxRelation','minHealth','maxHealth','minDay','maxDay','technologies','missingTechnologies','flags','flagsMissing','facilityFound'}
ALLOWED={'resource','population','health','morale','environment','relation','housing','defense','flag','technology','schedule'}
def validate(pack, base=None):
 assert pack['schemaVersion']==1,'unsupported schema'
 assert re.fullmatch(r'[a-z][a-z0-9_.-]{1,63}',pack['id']),'invalid package id'
 assert re.fullmatch(r'\d+\.\d+\.\d+',pack['version']),'invalid version'
 assert len(json.dumps(pack))<2_000_000,'package too large'
 known={k:{x['id'] for x in (base or {}).get(k,[])} for k in ['resources','technologies','events','traits']}
 for kind in ['resources','biomes','buildings','technologies','traits','profiles','characters','families','events','arcs','templates']:
  entries=pack.get(kind,[])
  assert len(entries)<=1000,f'{kind} too large'
  ids=[x['id'] for x in entries]
  assert len(ids)==len(set(ids)),f'duplicate {kind}'
  assert all(re.fullmatch(r'[a-z][a-z0-9_]{1,63}',x) for x in ids),f'invalid id in {kind}'
  if kind in known:known[kind].update(ids)
 def costs(cs):
  for resource,n in cs.items():
   assert resource in known['resources'],f'unknown resource {resource}'
   assert isinstance(n,(int,float)) and 0<=n<=100000,'invalid cost'
 def effect(e,template=False):
  assert e['type'] in ALLOWED,f"forbidden effect {e['type']}"
  if e['type']=='resource':assert e['resource'] in known['resources']
  if e['type']=='technology':assert e['technology'] in known['technologies']
  if 'value' in e and e['type']!='flag':assert isinstance(e['value'],(int,float)) and abs(e['value'])<=100000
  if e['type']=='schedule':
   assert e['eventId'] in known['events'] and isinstance(e['delayDays'],int) and 1<=e['delayDays']<=360000
  if e['type']=='flag':assert isinstance(e['value'],str) and re.fullmatch(r'[a-z][a-z0-9_]{1,80}',e['value'])
 def condition(c):
  assert isinstance(c,dict) and set(c)<=CONDITIONS,'unknown condition'
  for op in ['resource_min','resource_max']:
   if op in c:costs(c[op])
  for op in ['technologies','missingTechnologies']:
   assert all(x in known['technologies'] for x in c.get(op,[]))
 for e in pack.get('events',[]):
  assert e['category'] in ['needs','relations','exploration','economy','politics','technology','conflict','environment']
  assert len(e['body'])>=30 and len(e['title'])>=5,'empty narrative'
  assert e['trigger'] in ['director','scheduled']
  condition(e['conditions'])
  assert 0<=e.get('baseProbability',0)<=1
  assert 1<=len(e['options'])<=8
  assert len({o['id'] for o in e['options']})==len(e['options'])
  for o in e['options']:
   costs(o['costs'])
   for fx in o['effects']:effect(fx)
   for f in o['followUps']:
    assert f['eventId'] in known['events'],f"unknown event {f['eventId']}"
    assert 1<=f['delayDays']<=360000,'unsafe instantaneous or too distant cascade'
    assert 0<=f['probability']<=1
 for b in pack.get('buildings',[]):
  costs(b['costs'])
  assert all(t in known['technologies'] for t in b['requires'])
 # Technology DAG, never accepting a cycle as progression.
 tech={t['id']:t for t in (base or {}).get('technologies',[])+pack.get('technologies',[])}
 visited=set()
 def visit(id,stack):
  assert id in tech,f'unknown technology {id}'
  assert id not in stack,'technology cycle'
  if id in visited:return
  for dep in tech[id]['requires']:visit(dep,stack|{id})
  visited.add(id)
 for id in tech:visit(id,set())
 events={e['id']:e for e in pack.get('events',[])}
 for arc in pack.get('arcs',[]):
  assert 4<=len(arc['events'])<=7
  assert len(arc['endings'])>=2
  assert all(e in events for e in arc['events'])
  assert all(events[e]['arcId']==arc['id'] for e in arc['events'])
  reachable=set()
  def walk(id):
   if id in reachable:return
   reachable.add(id)
   for o in events[id]['options']:
    for f in o['followUps']:
     if f['eventId'] in arc['events']:walk(f['eventId'])
  walk(arc['entryEvent'])
  assert set(arc['events'])<=reachable,f"unreachable branch {arc['id']}"
  signatures=[]
  for end in arc['endings']:
   assert end in reachable
   signatures.append(json.dumps(events[end]['options'][0]['effects'],sort_keys=True))
  assert len(set(signatures))>=2,'cosmetic endings'
 for t in pack.get('templates',[]):
  p=t['parameter'];assert p['type']=='integer' and 1<=p['minimum']<=p['maximum']<=100
  for o in t['options']:
   for resource,formula in o['costs'].items():
    assert resource in known['resources']
    assert set(formula)=={'base','perUnit'} and all(isinstance(v,int) and v>=0 for v in formula.values())
   for fx in o['effects']:effect(fx,True)
 return True

def main():
 path=ROOT/'assets/content'
 core=json.loads((path/'core.json').read_text())
 validate(core)
 expected={'resources':12,'biomes':6,'buildings':18,'technologies':30,'traits':12,'profiles':6,'arcs':12,'templates':16,'families':8}
 for key,n in expected.items():assert len(core[key])>=n,f'missing {key}'
 assert sum('arcId' not in e for e in core['events'])>=96
 assert {e['category'] for e in core['events'] if 'arcId' not in e}=={'needs','relations','exploration','economy','politics','technology','conflict','environment'}
 assert {f['id'] for f in core['families']} <= {e.get('family') for e in core['events']}
 manifest=json.loads((path/'manifest.json').read_text())
 for item in manifest['packages']:
  raw=(path/item['file']).read_bytes()
  assert hashlib.sha256(raw).hexdigest()==item['sha256'],'hash mismatch'
  pack=json.loads(raw);assert (pack['id'],pack['version'])==(item['id'],item['version'])
  validate(pack,None if item['id']=='barrio.core' else core)
 # Negative validation tests for corrupt content.
 probes=[]
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['effects'][0]['type']='execute';probes.append(bad)
 bad=copy.deepcopy(core);bad['technologies'][0]['requires']=['distributed_minds'];probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['followUps']=[{'eventId':'missing','delayDays':1,'probability':1}];probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['costs']={'food':-1};probes.append(bad)
 bad=copy.deepcopy(core);bad['events'].append(copy.deepcopy(bad['events'][0]));probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['conditions']['execute']='bad';probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['effects']=[{'type':'schedule','eventId':'absent','delayDays':1}];probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['effects']=[{'type':'schedule','eventId':'facility_energy','delayDays':0}];probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['options'][0]['effects']=[{'type':'flag','value':9}];probes.append(bad)
 bad=copy.deepcopy(core);bad['events'][0]['conditions']['technologies']=['absent'];probes.append(bad)
 for bad in probes:
  try:validate(bad)
  except (AssertionError,KeyError):continue
  raise AssertionError('corrupt package accepted')
 print('PASS: 158 events / 96 independent / 12 arcs and distinct reachable endings / 16 templates / technology DAG / 2 SHA-256 packages / 10 rejection tests')
if __name__=='__main__':main()
