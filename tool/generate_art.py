"""Original Barrio Cero pixel assets; Python 3 + Pillow, no external artwork.

Run from repository root: python3 tool/generate_art.py
All drawing coordinates are native resolution, without antialiasing.
"""
from pathlib import Path
import json
import random
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'art'
OUT.mkdir(parents=True, exist_ok=True)
P = dict(ink='#25282b', shadow='#414445', stone='#777c78', pale='#b5b6a2',
         earth='#897256', soil='#665441', sand='#c0aa77', grass='#758269',
         leaf='#4f685b', deep='#344a48', water='#527983', blue='#536f88',
         sky='#829c9d', skin='#b98361', light='#d2a577', hair='#554139',
         rust='#925847', red='#aa614e', gold='#d0ab57', cream='#d8cfad',
         white='#e4dfcd', teal='#428780', darkBlue='#3c5269')
ROLES = ['ana', 'leo', 'tito', 'farmer', 'guard', 'medic', 'ancestral_artisan', 'ancestral_scout', 'ancestral_elder']
ACTIONS = ['idle', 'walk', 'work', 'carry', 'rest', 'celebrate', 'danger', 'loss']
BUILDINGS = ['farm','well','house','sawmill','quarry','workshop','clinic','school','market',
             'wall','mine','laboratory','generator','loom','granary','recycler','observatory','habitat','foraging_camp','water_collect','shelter','surface_stone','knapping_shed','oral_circle','fiber_weave']

def box(d, xy, color, outline=None):
    d.rectangle(xy, fill=P.get(color,color), outline=P.get(outline,outline))

def line(d, xy, color, width=1):
    d.line(xy, fill=P.get(color,color), width=width)

def person(role, action, frame):
    im=Image.new('RGBA',(32,48)); d=ImageDraw.Draw(im)
    # Deliberately large head, compact torso and visible task equipment.
    bob = 1 if frame in (1,3) and action in ('walk','work','carry') else 0
    ox = 1 if action=='danger' and frame%2 else 0
    oy = 4 if action=='rest' else bob
    d.ellipse((7,42,26,46),fill=(25,28,30,70))
    def b(xy,c,o=None): box(d, tuple(v+(ox if i%2==0 else oy) for i,v in enumerate(xy)),c,o)
    def l(xy,c,w=1): line(d,[(x+ox,y+oy) for x,y in xy],c,w)
    shirt=['blue','earth','teal','leaf','darkBlue','cream','earth','leaf','sand'][role]
    step=2 if action=='walk' and frame%2 else 0
    b((10-step,34,14-step,42),'shadow','ink'); b((18+step,34,22+step,42),'shadow','ink')
    b((9-step,41,15-step,44),'ink'); b((18+step,41,24+step,44),'ink')
    b((9,23,23,35),shirt,'ink'); b((10,33,22,35),'hair')
    b((14,24,16,33),'pale'); b((16,32,19,34),'gold')
    # Head: stepped outline rather than smooth vectors.
    b((8,9,24,20),'ink'); b((10,7,22,23),'ink'); b((9,10,23,19),'skin')
    b((11,9,22,21),'light'); b((8,9,24,12),'hair'); b((10,7,22,10),'hair')
    b((9,11,11,17),'hair'); b((19,14,20,15),'ink'); b((15,14,16,15),'ink')
    b((17,19,20,19),'hair'); b((12,22,20,24),'skin')
    if role>=6:
        b((10,24,23,35),'earth' if role==6 else 'leaf' if role==7 else 'sand','ink')
        b((12,25,20,28),'cream');b((8,9,11,24),'hair');b((21,9,24,24),'hair')
        l([(12,30),(21,32)],'hair',2)
    elif role==0: # Ana: goggles, cable pouch, wrench
        b((8,9,24,11),'blue'); b((12,10,16,13),'ink'); b((18,10,22,13),'ink')
        b((13,11,15,12),'sky'); b((19,11,21,12),'sky'); b((9,29,12,33),'gold','ink')
    elif role==1: # Leo: hood, backpack, scouting pole
        b((7,8,11,20),'hair'); b((9,6,23,9),'earth','ink'); b((7,24,10,33),'earth','ink')
        b((23,27,26,35),'hair','ink')
    elif role==2: # Tito: wool cap, apron and large supply satchel
        b((8,7,24,10),'teal','ink'); b((10,5,21,8),'teal'); b((12,26,20,34),'earth','ink')
        b((19,29,24,34),'sand','ink')
    elif role==3:
        b((7,9,25,11),'sand','ink'); b((11,6,22,9),'sand','ink'); b((12,28,19,34),'earth')
    elif role==4:
        b((8,7,24,11),'stone','ink'); b((10,5,22,8),'stone','ink'); b((11,25,21,31),'stone','ink')
    else:
        b((10,7,23,10),'cream','ink'); b((13,26,20,32),'white'); b((16,27,17,31),'red'); b((14,28,19,29),'red')
    raised= action in ('celebrate','danger')
    work=action=='work' and frame%2==0
    b((6,24 if not raised else 17,9,32 if not raised else 25),shirt,'ink')
    b((24,24 if not raised else 17,27,31 if not raised else 25),shirt,'ink')
    b((6,31 if not raised else 15,9,34 if not raised else 19),'skin','ink')
    b((24,30 if not raised else 15,27,33 if not raised else 19),'skin','ink')
    if action=='carry':
        b((8,28,27,37),'earth','ink'); b((9,30,26,31),'sand'); l([(10,29),(24,36)],'hair')
        b((7,29,10,32),'skin'); b((25,29,28,32),'skin')
    elif action not in ('rest','celebrate','loss'):
        if role>=6:
            l([(27,29),(28,42)],'hair',2);b((26,26,30,30),'stone','ink')
        elif role==0:
            l([(26,31),(29,22 if work else 28)],'pale',2); b((27,20 if work else 26,30,23 if work else 29),'stone','ink')
        elif role==1:
            l([(27,24),(27,43)],'earth',2); b((26,21,29,25),'pale','ink')
        elif role==2:
            b((24,31,30,39),'earth','ink'); b((25,29,29,31),'ink')
        elif role==3:
            l([(27,23),(27,43)],'hair',2); l([(23,23),(30,23)],'stone',2)
        elif role==4:
            b((24,28,30,38),'blue','ink'); b((26,29,27,36),'pale')
        else:
            b((23,31,30,38),'cream','ink'); b((26,32,27,37),'red'); b((24,34,29,35),'red')
    if action=='loss':
        b((12,17,21,21),'skin'); l([(14,17),(15,16)],'ink'); l([(19,16),(20,17)],'ink')
        b((18,21,19,22),'sky')
    if action=='rest':
        b((7,39,27,42),'earth','ink'); b((8,42,10,47),'hair'); b((24,42,26,47),'hair')
    return im

characters=Image.new('RGBA',(128,48*len(ROLES)*len(ACTIONS)))
for role in range(len(ROLES)):
    for action, name in enumerate(ACTIONS):
        for frame in range(4): characters.paste(person(role,name,frame),(frame*32,(role*8+action)*48))
characters.save(OUT/'characters.png')

def building(kind):
    im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im)
    d.ellipse((3,48,61,61),fill=(25,28,30,65))
    def b(xy,c,o=None):box(d,xy,c,o)
    def l(xy,c,w=1):line(d,xy,c,w)
    if kind=='shelter':
        d.polygon([(5,53),(19,17),(35,8),(59,53)],fill=P['earth'],outline=P['ink'])
        d.polygon([(19,17),(35,8),(38,51),(8,51)],fill=P['sand'],outline=P['ink'])
        d.polygon([(28,52),(36,29),(44,52)],fill=P['ink'])
        for x,y in [(17,28),(13,40),(41,23),(48,39)]:l([(x,y),(x+4,y+3)],'hair',2)
        l([(34,8),(31,57)],'hair',2);l([(20,14),(58,56)],'hair',2)
    elif kind=='foraging_camp':
        for x,y in [(8,29),(24,23),(41,32)]:
            d.ellipse((x,y,x+16,y+18),fill=P['leaf'],outline=P['ink'])
            for dx,dy in [(3,5),(10,4),(7,12)]:b((x+dx,y+dy,x+dx+2,y+dy+2),'red')
        b((13,48,32,57),'earth','ink');l([(15,51),(30,51)],'sand',2)
        b((39,47,52,57),'sand','ink')
    elif kind=='water_collect':
        d.ellipse((4,33,59,57),fill=P['water'],outline=P['ink'])
        for x,y in [(7,32),(20,29),(38,31),(49,41),(18,53)]:b((x,y,x+10,y+6),'stone','ink')
        for x in [22,34,45]:l([(x,38),(x+6,38)],'sky')
        b((42,44,52,56),'earth','ink');l([(43,43),(50,43)],'sand',2)
    elif kind=='surface_stone':
        for x,y in [(9,35),(25,28),(42,37),(20,47)]:
            d.polygon([(x,y+12),(x+3,y),(x+13,y-3),(x+17,y+10)],fill=P['stone'],outline=P['ink'])
            l([(x+5,y+2),(x+12,y)],'pale',2)
        b((44,49,57,56),'earth','ink')
    elif kind=='knapping_shed':
        b((9,30,15,54),'hair','ink');b((47,30,53,54),'hair','ink')
        d.polygon([(6,30),(20,13),(48,16),(58,31)],fill=P['sand'],outline=P['ink'])
        b((16,42,48,49),'earth','ink');b((22,36,34,42),'stone','ink')
        d.polygon([(38,38),(45,32),(42,43)],fill=P['pale'],outline=P['ink'])
        l([(26,34),(33,27)],'hair',3)
    elif kind=='oral_circle':
        for x,y in [(8,39),(18,51),(39,51),(48,36),(28,27)]:
            b((x,y,x+10,y+5),'stone','ink')
        l([(24,46),(39,36)],'hair',3);l([(25,37),(39,46)],'hair',3)
        d.polygon([(27,42),(28,25),(33,30),(36,18),(41,38),(36,45)],fill=P['rust'],outline=P['ink'])
        d.polygon([(31,40),(34,29),(38,40)],fill=P['gold'])
    elif kind=='fiber_weave':
        b((11,21,16,55),'hair','ink');b((46,21,51,55),'hair','ink');b((11,20,51,25),'earth','ink')
        for x in range(19,45,4):l([(x,25),(x+2,47)],'sand',2)
        b((20,37,45,49),'earth','ink')
        for y in [39,43,47]:l([(21,y),(44,y)],'cream')
        d.ellipse((4,47,17,58),fill=P['leaf'],outline=P['ink'])
    elif kind=='quarry':
        d.polygon([(5,49),(15,24),(45,21),(59,48),(48,56),(14,56)],fill=P['stone'],outline=P['ink'])
        for y in (31,39,47):l([(13,y),(49,y)],'shadow',2)
        for x,y in ((10,47),(41,41),(28,30)):b((x,y,x+10,y+6),'pale','ink')
        l([(31,17),(22,38)],'hair',3);l([(22,19),(39,26)],'stone',3)
    elif kind=='mine':
        d.polygon([(3,54),(13,26),(31,11),(50,23),(61,54)],fill=P['shadow'],outline=P['ink'])
        b((20,30,45,54),'hair','ink');b((25,34,40,54),'ink')
        l([(27,54),(22,62)],'stone',2);l([(37,54),(42,62)],'stone',2)
        for y in (56,59):l([(23,y),(40,y)],'earth',2)
        b((18,35,21,54),'earth');b((43,35,46,54),'earth')
    elif kind=='sawmill':
        b((8,23,13,50),'hair','ink');b((50,23,55,50),'hair','ink')
        d.polygon([(4,25),(18,13),(48,13),(60,25)],fill=P['rust'],outline=P['ink'])
        for y in (35,43,51):
            b((9,y,52,y+6),'hair','ink');l([(15,y+2),(50,y+2)],'earth')
            d.ellipse((8,y,16,y+6),fill=P['sand'],outline=P['ink'])
        l([(48,28),(40,47)],'stone',2);b((44,26,53,30),'stone','ink')
    elif kind=='loom':
        # Open timber frame, visible warp threads and a dyed hanging cloth.
        b((8,15,13,56),'hair','ink');b((49,15,54,56),'hair','ink')
        b((7,14,55,19),'earth','ink');b((9,48,53,53),'earth','ink')
        for x in range(16,48,4):l([(x,20),(x,47)],'cream')
        b((15,31,48,45),'blue','ink')
        for y in (33,38,43):l([(17,y),(46,y)],'sky')
        b((4,37,12,41),'gold','ink');b((27,49,37,58),'rust','ink')
    elif kind=='granary':
        # Round raised silo, visibly different from a dwelling or store room.
        b((15,19,49,50),'sand','ink');d.ellipse((15,11,49,27),fill=P['earth'],outline=P['ink'])
        d.polygon([(12,17),(32,4),(52,17)],fill=P['rust'],outline=P['ink'])
        for y in (29,39,48):l([(16,y),(48,y)],'hair',2)
        b((18,50,22,58),'hair','ink');b((43,50,47,58),'hair','ink')
        b((30,33,39,47),'earth','ink');b((33,36,36,44),'ink')
        for x in (5,53):
            d.ellipse((x,43,x+8,56),fill=P['sand'],outline=P['ink']);l([(x+2,46),(x+6,46)],'hair')
    elif kind=='recycler':
        # Sorting gantry, hopper and output bins, with three material colors.
        b((8,21,15,54),'stone','ink');b((45,21,52,54),'stone','ink')
        b((7,19,53,24),'shadow','ink')
        d.polygon([(19,25),(43,25),(37,41),(25,41)],fill=P['teal'],outline=P['ink'])
        b((26,41,36,48),'shadow','ink')
        b((3,47,23,57),'earth','ink');b((26,49,44,58),'blue','ink');b((47,47,60,57),'stone','ink')
        for x,y,c in [(6,43,'rust'),(12,45,'pale'),(51,44,'stone'),(32,46,'gold')]:b((x,y,x+5,y+5),c,'ink')
    elif kind=='habitat':
        # Sealed stepped community habitat, green biosphere roof and airlocks.
        b((5,29,59,55),'pale','ink');b((11,20,53,32),'stone','ink');b((18,12,46,22),'leaf','ink')
        for x in (9,20,40,51):b((x,35,x+6,44),'darkBlue','ink');b((x+1,36,x+4,39),'sky')
        b((27,39,36,55),'teal','ink');b((29,42,34,50),'sky','ink')
        for x in (23,30,37):l([(x,14),(x,19)],'grass',2)
        b((3,52,61,57),'stone','ink');b((51,13,56,28),'blue','ink')
    elif kind=='generator':
        b((8,31,55,53),'blue','ink');b((12,27,49,31),'stone','ink')
        b((44,8,51,30),'shadow','ink');b((42,7,53,10),'stone','ink')
        for x in (14,19,24):l([(x,36),(x,47)],'ink',2)
        b((33,35,48,46),'shadow','ink');d.polygon([(40,35),(37,41),(41,41),(38,47),(45,40),(41,40),(44,35)],fill=P['gold'])
    elif kind in ('farm','greenhouse'):
        b((5,29,58,55),'soil','ink')
        for y in (33,40,47):
            l([(8,y+3),(55,y+3)],'earth',2)
            for x in range(10,56,8):
                b((x,y,x+2,y+4),'leaf');b((x-2,y,x+4,y+1),'grass')
        if kind=='greenhouse':
            d.polygon([(6,28),(18,14),(48,14),(58,28)], fill=P['sky'],outline=P['ink'])
            b((6,28,58,43),'water','ink')
            for x in (8,20,32,44,56):l([(x,28),(x,43)],'pale',2)
            l([(18,14),(20,28)],'pale',2);l([(32,14),(32,28)],'pale',2)
    elif kind in ('well','reservoir'):
        b((10,34,53,54),'stone','ink');b((15,36,48,48),'deep','ink');b((19,39,44,46),'water')
        if kind=='well':
            b((14,16,17,41),'hair','ink');b((47,16,50,41),'hair','ink')
            d.polygon([(8,18),(32,7),(57,18)],fill=P['rust'],outline=P['ink'])
            l([(32,18),(32,41)],'sand');b((27,40,37,47),'earth','ink')
        else:
            b((6,23,13,52),'stone','ink');b((50,23,57,52),'stone','ink');l([(15,25),(48,25)],'pale',3)
    elif kind=='solar':
        for y in (17,34):
            b((7,y,57,y+14),'darkBlue','ink')
            for x in range(9,57,9):l([(x,y+1),(x,y+12)],'sky')
            l([(8,y+7),(56,y+7)],'blue')
        b((10,49,13,57),'stone');b((51,49,54,57),'stone')
    elif kind=='wall':
        b((5,20,59,53),'stone','ink')
        for x in range(5,60,12):b((x,15,x+6,22),'stone','ink')
        for y in (28,39,49):l([(6,y),(58,y)],'shadow')
        for x in (17,39):l([(x,21),(x,28),(x+8,28),(x+8,39),(x,39),(x,49)],'shadow')
    else:
        tall=kind in ('watchtower','observatory')
        top=15 if tall else 27
        b((11,top,53,54),'stone','ink'); b((15,top+3,50,51),'earth' if kind in ('house','storehouse','market') else 'pale')
        d.polygon([(7,top+1),(30,top-14),(57,top+1)],fill=P['rust'] if kind not in ('laboratory','observatory','clinic') else P['blue'],outline=P['ink'])
        l([(11,top-1),(31,top-11),(51,top-1)],'sand')
        b((27,39,37,54),'hair','ink');b((29,41,35,53),'deep');b((34,46,35,47),'gold')
        for x in (17,43):
            b((x,top+6,x+7,top+13),'ink');b((x+1,top+7,x+5,top+10),'sky')
        l([(12,52),(52,52)],'shadow',2)
        if kind=='workshop':
            b((42,6,50,22),'stone','ink');b((7,41,20,49),'hair','ink');b((10,37,14,42),'stone')
        elif kind=='storehouse':
            for x,y in ((5,47),(44,45),(50,51)):
                b((x,y,x+9,y+9),'earth','ink');l([(x+1,y+1),(x+8,y+8)],'sand')
        elif kind=='clinic':b((26,25,37,36),'cream','ink');b((30,26,33,35),'red');b((27,29,36,32),'red')
        elif kind=='school':
            b((7,32,25,43),'deep','hair');l([(10,35),(20,35)],'cream');l([(10,39),(22,39)],'cream')
        elif kind=='watchtower':
            b((7,15,57,22),'hair','ink');b((16,24,20,54),'hair','ink');b((44,24,48,54),'hair','ink')
            l([(19,27),(45,52)],'earth',2);l([(19,52),(45,27)],'earth',2)
        elif kind=='laboratory':
            b((6,37,20,50),'blue','ink');b((8,34,18,37),'stone','ink');b((44,31,56,46),'teal','ink')
            l([(47,31),(47,23),(52,23)],'pale',2)
        elif kind=='market':
            b((5,29,59,35),'cream','ink')
            for x in range(6,59,12):b((x,30,x+5,35),'red')
            b((7,40,56,45),'earth','ink');b((8,46,10,55),'hair');b((53,46,55,55),'hair')
            for x in range(12,54,8):b((x,37,x+4,40),'gold' if x%3 else 'leaf')
        elif kind=='foundry':
            b((43,3,52,27),'shadow','ink');b((20,33,42,49),'ink');b((24,36,38,48),'red');b((27,40,35,48),'gold')
        elif kind in ('library','archive'):
            b((15,30,24,47),'hair','ink');b((43,30,52,47),'hair','ink')
            for x in (16,19,22,44,47,50):b((x,32,x+1,38),'blue' if x%2 else 'red');b((x,41,x+1,46),'sand')
        elif kind=='observatory':
            d.ellipse((13,1,51,27),fill=P['blue'],outline=P['ink']);b((12,20,52,27),'stone','ink')
            d.polygon([(30,17),(45,5),(51,9),(36,22)],fill=P['pale'],outline=P['ink'])
    return im

buildings=Image.new('RGBA',(6*64,((len(BUILDINGS)+5)//6)*64))
for i,name in enumerate(BUILDINGS): buildings.paste(building(name),((i%6)*64,(i//6)*64))
buildings.save(OUT/'buildings.png')

BIOMES=['plains','forest','desert','mountain','wetland','water']
terrain=Image.new('RGBA',(192,32));rnd=random.Random(841)
for i,name in enumerate(BIOMES):
    tile=Image.new('RGBA',(32,32),P[['grass','leaf','sand','stone','deep','water'][i]]);d=ImageDraw.Draw(tile)
    for n in range(26):
        x,y=rnd.randrange(30),rnd.randrange(30)
        color=['earth','grass','earth','pale','leaf','sky'][i]
        line(d,[(x,y),(x+2,y)],color)
    if i==1:
        for x,y in ((8,8),(21,16),(7,26)):
            box(d,(x,y,x+2,y+5),'hair');d.polygon([(x-5,y+1),(x+1,y-10),(x+7,y+1)],fill=P['deep'],outline=P['ink'])
    if i==3:d.polygon([(3,27),(14,5),(29,27)],fill=P['shadow'],outline=P['ink']);d.polygon([(11,11),(14,5),(18,12)],fill=P['pale'])
    if i==4:
        for x,y in ((5,8),(16,18),(25,27)):line(d,[(x,y+4),(x,y-3)],'grass');line(d,[(x+2,y+4),(x+2,y-1)],'grass')
    terrain.paste(tile,(i*32,0))
terrain.save(OUT/'terrain.png')

ICONS=['food','wood','stone','metal','water','medicine','tools','energy','knowledge','cloth','electronics','fuel',
       'population','housing','health','diplomacy','science','danger','ruins','trade','calendar','policy','save','world']
icons=Image.new('RGBA',(16*len(ICONS),16))
for i,name in enumerate(ICONS):
    im=Image.new('RGBA',(16,16));d=ImageDraw.Draw(im)
    if name=='food':
        box(d,(4,5,12,12),'red','ink');box(d,(7,2,8,5),'hair');box(d,(9,2,12,3),'leaf')
    elif name in ('wood','fuel'):
        box(d,(2,5,13,11),'earth','ink');line(d,[(3,7),(12,7)],'sand');d.ellipse((1,5,6,11),fill=P['sand'],outline=P['ink'])
    elif name in ('stone','metal'):
        d.polygon([(2,11),(4,4),(10,3),(14,8),(12,13)],fill=P['stone'] if name=='stone' else P['blue'],outline=P['ink']);line(d,[(5,5),(10,5)],'pale')
    elif name in ('water','medicine','energy'):
        d.polygon([(8,1),(13,10),(11,14),(5,14),(2,10)],fill=P['water'] if name=='water' else P['teal'] if name=='medicine' else P['gold'],outline=P['ink']);box(d,(7,7,9,11),'pale')
    elif name in ('knowledge','science','policy'):
        box(d,(2,3,13,13),'cream','ink');line(d,[(8,4),(8,12)],'hair');line(d,[(4,6),(6,6)],'blue');line(d,[(10,8),(12,8)],'blue')
    elif name=='tools':
        line(d,[(3,13),(11,5)],'stone',3);box(d,(9,2,13,6),'stone','ink')
    elif name=='cloth':
        d.polygon([(2,4),(6,2),(10,2),(14,4),(12,8),(11,7),(11,14),(5,14),(5,7),(4,8)],fill=P['blue'],outline=P['ink'])
    elif name=='electronics':
        box(d,(3,3,12,12),'leaf','ink');box(d,(6,6,10,10),'ink')
        for p in (4,8,11):line(d,[(p,1),(p,3)],'gold');line(d,[(p,12),(p,14)],'gold')
    elif name in ('population','health','diplomacy'):
        box(d,(5,2,10,7),'skin','ink');box(d,(4,8,12,14),'blue','ink')
        if name=='health':box(d,(7,9,9,13),'red');box(d,(6,10,10,11),'red')
    elif name in ('housing','ruins'):
        box(d,(3,7,13,14),'stone','ink');d.polygon([(1,7),(8,2),(15,7)],fill=P['rust'],outline=P['ink']);box(d,(7,10,9,14),'ink')
        if name=='ruins':box(d,(10,4,15,9),(0,0,0,0))
    elif name=='danger':
        d.polygon([(8,1),(15,14),(1,14)],fill=P['gold'],outline=P['ink']);box(d,(7,5,8,9),'ink');box(d,(7,11,8,12),'ink')
    elif name=='trade':
        box(d,(3,4,13,10),'earth','ink');d.ellipse((2,10,6,14),fill=P['ink']);d.ellipse((10,10,14,14),fill=P['ink'])
    elif name=='calendar':
        box(d,(2,3,14,14),'cream','ink');box(d,(3,4,13,6),'red');box(d,(5,1,6,4),'ink');box(d,(10,1,11,4),'ink')
    elif name=='save':
        box(d,(2,2,14,14),'blue','ink');box(d,(4,2,11,6),'pale');box(d,(5,9,12,13),'cream')
    elif name=='world':
        d.ellipse((1,1,14,14),fill=P['water'],outline=P['ink']);d.polygon([(3,4),(8,2),(9,6),(6,9),(7,13),(3,10)],fill=P['grass'])
    icons.paste(im,(i*16,0))
icons.save(OUT/'icons.png')

# Runtime companions preserve exactly the artwork, with premultiplied RGBA.
# This bypasses platform PNG decompression and makes the upload deterministic.
for image_name in ('characters', 'buildings', 'terrain'):
    source = Image.open(OUT / f'{image_name}.png').convert('RGBA')
    pixels = bytearray(source.tobytes())
    for offset in range(0, len(pixels), 4):
        alpha = pixels[offset + 3]
        for channel in range(3):
            pixels[offset + channel] = (pixels[offset + channel] * alpha + 127) // 255
    (OUT / f'{image_name}.rgba').write_bytes(pixels)

manifest={'version':1,'license':'Original project artwork; see ART_GUIDE.md','palette':P,
 'characters':{'file':'characters.png','tileWidth':32,'tileHeight':48,'columns':4,'roles':ROLES,'actions':ACTIONS,'rowFormula':'roleIndex * 8 + actionIndex','frameSeconds':0.18},
 'buildings':{'file':'buildings.png','tileWidth':64,'tileHeight':64,'columns':6,'ids':BUILDINGS},
 'terrain':{'file':'terrain.png','tileWidth':32,'tileHeight':32,'columns':6,'ids':BIOMES},
 'icons':{'file':'icons.png','tileWidth':16,'tileHeight':16,'columns':len(ICONS),'ids':ICONS}}
for image_name in ('characters', 'buildings', 'terrain'):
    size = Image.open(OUT / f'{image_name}.png').size
    manifest[image_name].update(pixelDataFile=f'{image_name}.rgba', pixelFormat='premultipliedRGBA8888', pixelWidth=size[0], pixelHeight=size[1])
(OUT/'atlas.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
# Inspectable nearest-neighbor production contact sheet, not an application capture.
preview=Image.new('RGBA',(576,160+buildings.height*3//2+96),P['soil'])
for role in range(len(ROLES)):
    preview.paste(person(role,'idle',0).resize((64,96),Image.Resampling.NEAREST),(role*64,12),person(role,'idle',0).resize((64,96),Image.Resampling.NEAREST))
preview.paste(buildings.resize((576,buildings.height*3//2),Image.Resampling.NEAREST),(0,120),buildings.resize((576,buildings.height*3//2),Image.Resampling.NEAREST))
preview.paste(terrain.resize((576,96),Image.Resampling.NEAREST),(0,140+buildings.height*3//2))
preview.convert('RGB').save(OUT/'contact_sheet.png')
# App icon is original art too; integer enlargement, then a native-size frame.
launcher=Image.new('RGBA',(48,48),P['deep']);ld=ImageDraw.Draw(launcher)
box(ld,(2,2,45,45),'earth','ink');box(ld,(4,4,43,43),'sand')
house=building('house').resize((42,42),Image.Resampling.NEAREST)
launcher.alpha_composite(house,(3,-2))
box(ld,(4,35,43,44),'ink');box(ld,(6,37,41,42),'teal')
for x in (9,15,21,27,33,39):box(ld,(x,38,x+2,40),'cream')
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    directory=OUT.parents[1]/'android'/'app'/'src'/'main'/'res'/('mipmap-'+density)
    directory.mkdir(parents=True,exist_ok=True)
    launcher.resize((size,size),Image.Resampling.NEAREST).convert('RGB').save(directory/'ic_launcher.png')
print('Generated characters, buildings, terrain, icons, atlas and production contact sheet.')
