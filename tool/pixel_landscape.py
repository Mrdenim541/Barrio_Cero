"""Original, deterministic pixel art for the playable atlas. No external assets.

Architecture uses existing building IDs, not claims of new simulation features.
Native pixels, a limited palette, stepped outlines and directional shadows.
"""
from PIL import Image, ImageDraw
import random

P = dict(ink='#263b36', shadow='#3c5140', deep='#28483e', wood='#70533b',
         timber='#aa8050', edge='#d3aa69', wall='#d6c695', cream='#eee1b0',
         stone='#8c9a89', pale='#b8c1a7', roof='#a6583e', roofLight='#ce8250',
         straw='#c7a350', strawLight='#ebce7a', leaf='#477544', green='#71934c',
         light='#a1b65a', blue='#436d7c', water='#4e9ba4', gold='#edc361')


def building(kind):
    im = Image.new('RGBA', (64, 64))
    d = ImageDraw.Draw(im)
    rng = random.Random('barrio-art-2-' + kind)
    def rect(box, color, outline=None):
        d.rectangle(box, fill=P.get(color, color), outline=P.get(outline, outline))
    def poly(points, color, outline='ink'):
        d.polygon(points, fill=P.get(color, color), outline=P.get(outline, outline))
    def ln(points, color, width=1):
        d.line(points, fill=P.get(color, color), width=width)
    # A stepped contact shadow, shared ground and no opaque square behind art.
    poly([(4,49),(15,43),(51,43),(62,51),(55,58),(14,60),(3,55)], (26,46,31,75), None)

    def fence(x, y, width=48):
        ln([(x,y+3),(x+width,y+3)], 'timber', 2)
        for px in range(x, x+width+1, 8):
            rect((px,y,px+2,y+9),'wood');rect((px,y,px+1,y+5),'edge')

    def roof(straw=False, top=10, base=31):
        poly([(4,base),(27,top),(47,top+3),(61,base+2),(37,base+5)], 'straw' if straw else 'roof')
        poly([(27,top),(47,top+3),(61,base+2),(37,base+5)], '#a78643' if straw else '#824936')
        ln([(5,base),(27,top),(47,top+3)],'strawLight' if straw else 'roofLight',2)
        if straw:
            for x in range(10,58,4):
                ln([(x,base-2),(min(46,x+9),top+5)],'strawLight')
        else:
            for y in range(top+6,base,4):
                left=27-int((y-top)*1.12)
                ln([(left,y),(45+(y-top)//2,y+3)],'roofLight')
                for x in range(left+4,48,9): ln([(x,y),(x-2,y+3)],'#754631')
        ln([(4,base+1),(37,base+5),(61,base+2)],'wood',2)

    def house(straw=False, workshop=False):
        poly([(10,28),(38,31),(38,55),(10,52)], 'wall')
        poly([(38,31),(55,27),(55,51),(38,55)], '#9d9c76')
        for y in [38,48]: ln([(11,y),(37,y+2)],'#b7ad83')
        for x in [12,36,52]: rect((x,29,x+2,52),'wood')
        rect((23,38,33,54),'wood','ink');rect((25,39,31,52),'deep')
        rect((14,35,20,42),'wood','ink');rect((15,36,19,40),'blue')
        rect((43,34,49,41),'wood','ink');rect((44,35,48,39),'blue')
        rect((26,53,35,55),'pale');rect((25,55,37,57),'stone')
        if workshop: rect((44,5,51,25),'stone','ink');rect((43,4,52,8),'pale','ink')
        roof(straw)
        # An ivy patch and a real entrance, no extra house/road entity.
        for x,y in [(9,46),(8,49),(11,51),(53,47),(55,49)]: rect((x,y,x+2,y+2),'leaf')

    if kind == 'farm':
        poly([(4,24),(51,21),(61,51),(13,57)],'#8d6940')
        for row in range(4):
            y=29+row*7
            ln([(9,y+5),(55,y+1)],'#b08b50',2)
            for x in range(11,55,6):
                h=4+rng.randrange(4); yy=y-(x-11)//14
                ln([(x,yy+5),(x,yy-h)],'green')
                rect((x-1,yy-h,x+1,yy-h+3),'strawLight')
                rect((x+2,yy-h+1,x+3,yy-h+3),'gold')
        fence(6,48,48)
    elif kind == 'well':
        poly([(16,32),(37,29),(51,37),(49,51),(30,56),(13,47)],'stone')
        poly([(16,33),(35,29),(48,36),(30,43)],'deep')
        poly([(21,35),(35,32),(42,36),(30,40)],'water',None)
        for y in [41,47]: ln([(14,y),(30,y+7),(49,y+2)],'#64796d')
        rect((12,17,16,43),'wood','ink');rect((47,16,51,43),'wood','ink')
        ln([(15,24),(48,24)],'edge',2);ln([(32,24),(32,41)],'cream')
        rect((28,39,35,45),'timber','wood'); roof(top=4,base=19)
    elif kind in ['foraging_camp','shelter','water_collect','knapping_shed','oral_circle','surface_stone','fiber_weave']:
        if kind in ['foraging_camp','shelter']:
            poly([(5,52),(26,14),(39,13),(59,50),(35,57)],'straw')
            poly([(26,14),(39,13),(59,50),(35,57)],'#a88449')
            for x in range(9,53,4): ln([(x,49),(29+(x//15),19)],'strawLight')
            poly([(23,53),(32,27),(42,52)],'wood');poly([(27,52),(33,35),(37,52)],'deep')
            ln([(24,13),(40,59)],'wood',2);ln([(40,12),(24,58)],'wood',2)
            if kind=='foraging_camp':
                rect((3,45,12,54),'timber','wood');rect((51,47,61,55),'leaf','wood')
        elif kind=='water_collect':
            poly([(7,37),(48,30),(59,45),(16,55)],'stone')
            poly([(12,38),(46,34),(53,44),(18,50)],'water')
            for x in [7,50]:rect((x,18,x+3,40),'wood','ink')
            poly([(3,21),(23,10),(54,17),(50,29)],'straw');ln([(9,23),(48,27)],'cream')
            rect((51,47,59,56),'timber','wood')
        elif kind=='oral_circle':
            for x,y in [(10,24),(30,18),(49,25),(52,45),(30,52),(9,43)]:
                poly([(x-5,y),(x-3,y-4),(x+5,y-3),(x+6,y+3),(x-4,y+4)],'stone')
            ln([(23,42),(40,36)],'wood',3);ln([(23,36),(40,43)],'wood',3)
            poly([(26,39),(30,25),(34,34),(37,28),(40,40)],'roofLight')
            poly([(30,40),(33,30),(37,40)],'gold',None)
        elif kind=='surface_stone':
            for x,y in [(16,43),(38,32),(49,48),(29,51)]:
                poly([(x-10,y),(x-4,y-15),(x+7,y-12),(x+12,y),(x+2,y+4)],'stone')
                ln([(x-4,y-14),(x+1,y-7),(x+7,y-11)],'pale',2)
        elif kind=='fiber_weave':
            for x in [12,49]: rect((x,16,x+3,55),'wood','ink')
            rect((10,16,54,20),'timber','ink')
            for x in range(18,49,3): ln([(x,20),(x,48)],'cream')
            rect((17,35,48,47),'straw','wood')
            for y in [37,41,45]:ln([(18,y),(47,y)],'strawLight')
            rect((6,49,17,58),'leaf','wood')
        else:
            house(True);rect((3,42,26,46),'wood','ink');rect((6,46,9,55),'wood')
            for x in [8,17]:poly([(x,40),(x+3,34),(x+7,40)],'pale')
    elif kind in ['quarry','mine']:
        for x,y in [(15,42),(29,31),(46,41)]:
            poly([(x-12,y+10),(x-6,y-19),(x+3,y-24),(x+14,y+7)],'stone')
            poly([(x-6,y-19),(x+3,y-24),(x+8,y-9)],'pale',None)
            ln([(x+3,y-22),(x+2,y+7)],'#687b70',2)
        if kind=='mine':
            rect((20,31,43,55),'wood','ink');rect((25,35,38,55),'deep')
            for x in [24,37]:ln([(x,53),(x-3,63)],'stone',2)
            for y in [56,60]:ln([(20,y),(40,y)],'timber',2)
    elif kind=='wall':
        rect((5,25,58,52),'stone','ink')
        for x in range(5,59,8):rect((x,18,x+4,27),'pale','ink')
        for y in [32,40,48]:
            ln([(6,y),(57,y)],'#617766');
            for x in range(9+(y%3)*3,56,12):ln([(x,y-7),(x,y)],'#617766')
        poly([(25,53),(25,37),(30,32),(36,37),(36,53)],'deep')
    elif kind in ['loom','sawmill','market']:
        for x in [8,50]:rect((x,24,x+3,55),'wood','ink')
        roof(straw=kind=='loom',top=8,base=28)
        rect((6,42,56,46),'timber','wood');rect((8,47,55,55),'wood')
        if kind=='market':
            for x in range(7,57,7):rect((x,29,x+3,33),'cream')
            for x in range(13,52,7):rect((x,37,x+5,41),'gold' if x%2 else 'leaf','wood')
        elif kind=='sawmill':
            for y in [37,46,54]:
                rect((14,y,54,y+5),'wood','ink');d.ellipse((10,y,19,y+6),fill=P['edge'],outline=P['wood'])
        else:
            for x in range(18,48,3):ln([(x,31),(x,46)],'cream')
            rect((18,37,47,46),'blue','wood');ln([(20,41),(45,41)],'water')
    elif kind=='granary':
        rect((16,24,49,49),'straw','wood')
        for y in [30,39,47]:ln([(17,y),(48,y)],'wood',2)
        for x in [18,43]:rect((x,49,x+3,58),'wood','ink')
        roof(True,top=5,base=24);rect((28,34,37,48),'wood','ink')
    elif kind in ['generator','recycler','habitat','laboratory','observatory']:
        house(workshop=kind=='generator')
        if kind in ['habitat','laboratory','observatory']:
            poly([(6,28),(11,15),(24,7),(42,7),(53,17),(59,29)],'blue')
            ln([(10,25),(18,13),(31,9),(45,14),(55,26)],'water',2)
            ln([(32,9),(32,29)],'pale')
        if kind=='observatory':
            poly([(28,20),(46,6),(51,11),(33,25)],'pale');rect((25,22,28,29),'wood')
        if kind=='generator':
            rect((12,34,47,49),'blue','ink')
            for x in [16,21,26]:ln([(x,38),(x,46)],'deep',2)
            poly([(37,35),(32,42),(37,42),(34,48),(43,39),(38,39),(42,35)],'gold',None)
        if kind=='recycler':
            for x,c in [(5,'wood'),(25,'blue'),(45,'stone')]:rect((x,43,x+14,56),c,'ink')
    else:
        house(workshop=kind=='workshop')
        if kind=='clinic':
            rect((25,27,36,37),'cream','wood');rect((29,28,32,36),'roof');rect((26,31,35,33),'roof')
        if kind=='school':
            rect((2,39,20,49),'wood','ink');rect((4,40,18,47),'deep')
            for y in [42,45]:ln([(6,y),(15,y)],'cream')
        if kind=='workshop':
            rect((3,42,21,47),'wood','ink');rect((8,39,13,42),'stone')
    return im


def landscape():
    ids = [f'{name}_{v}' for v in range(4) for name in ['plains','forest','desert','mountain','wetland','water']]
    ids += ['oak','pine','boulder','peak','reeds','shrub','flowers','ruins']
    atlas = Image.new('RGBA',(8*64,4*64))
    bases=['#82964d','#627d43','#c1aa6c','#869477','#6b8b62','#286d85']
    for i,name in enumerate(ids):
        im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);rng=random.Random('landscape-'+name)
        if i<24:
            b=i%6;d.rectangle((0,0,63,63),fill=bases[b])
            accents=[['#a2ad61','#708647','#8e9b50'],['#718b4e','#526c3f','#829854'],['#d4bc7d','#af975e','#c5ac6e'],['#9caa8a','#75836d','#8d9b7d'],['#87a16a','#5b805e','#75966a'],['#357f96','#23657c','#408c9c']][b]
            for _ in range(120):
                x,y=rng.randrange(64),rng.randrange(64);w=rng.randrange(1,5)
                d.line((x,y,x+w,y),fill=rng.choice(accents),width=1)
        elif name in ['oak','pine']:
            d.ellipse((10,49,57,61),fill=(20,48,28,65))
            d.rectangle((29,30,35,57),fill='#69573b');d.rectangle((30,31,31,54),fill='#a2834f')
            if name=='pine':
                for y,w in [(44,24),(33,20),(22,15)]:
                    d.polygon([(32,y-20),(32-w,y+8),(32+w,y+8)],fill='#315b3b',outline='#2b4e36')
                    d.line([(32,y-18),(32-w+5,y+5)],fill='#74934d',width=2)
                    d.polygon([(32,y-18),(32,y+4),(32-w+4,y+4)],fill='#517e43')
            else:
                for x,y,r in [(23,31,17),(42,31,16),(32,17,17)]:
                    d.ellipse((x-r,y-r,x+r,y+r),fill='#38683e',outline='#2d5235')
                    d.ellipse((x-r+3,y-r+2,x+r-5,y+r-7),fill='#668d43')
                    d.ellipse((x-r+5,y-r+3,x+r-12,y+r-13),fill='#94ab50')
                for _ in range(55):
                    x,y=rng.randrange(11,52),rng.randrange(9,40)
                    if im.getpixel((x,y))[3]:d.rectangle((x,y,x+1,y+1),fill=rng.choice(['#7c9c49','#547b3c']))
        elif name in ['boulder','peak']:
            points=[(3,57),(15,24),(30,5),(42,20),(61,56)] if name=='peak' else [(5,52),(14,32),(35,26),(56,43),(53,56)]
            d.polygon(points,fill='#7f9388',outline='#405f56')
            d.polygon([(points[1]),points[2],(32,54),(8,54)],fill='#a8b8a1')
            if name=='peak':
                d.polygon([(21,19),(30,5),(42,20),(35,16),(31,23),(27,16)],fill='#e4e5ca')
                d.line([(31,24),(37,33),(35,44),(44,54)],fill='#576f67',width=2)
        elif name=='reeds':
            for x,y in [(13,53),(26,54),(41,49),(50,55)]:
                d.line((x,y,x-2,y-25),fill='#597440',width=2)
                d.rectangle((x-3,y-31,x,y-23),fill='#b9a063')
                d.line((x,y-5,x+7,y-16),fill='#8d9d4b',width=2)
        elif name in ['shrub','flowers']:
            for x,y in [(18,47),(31,43),(43,50)]:
                d.ellipse((x-9,y-10,x+9,y+5),fill='#527b40',outline='#3c6139')
                d.ellipse((x-7,y-8,x+4,y-1),fill='#91a650')
                if name=='flowers':d.rectangle((x-1,y-5,x+1,y-3),fill='#f0cd70')
        elif name=='ruins':
            for x,y,h in [(9,55,23),(27,55,35),(45,53,17)]:
                d.rectangle((x,y-h,x+9,y),fill='#8c9c83',outline='#4a6456')
                d.line((x+2,y-h+2,x+7,y-h+2),fill='#c3c8a3',width=2)
                for yy in range(y-h+7,y,7):d.line((x+1,yy,x+8,yy),fill='#667f68')
            d.rectangle((20,51,43,57),fill='#637d5a')
        atlas.alpha_composite(im,((i%8)*64,(i//8)*64))
    return atlas,ids
