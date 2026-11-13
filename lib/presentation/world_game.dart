import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

const earth = Color(0xffbda576);
const ink = Color(0xff1d282b);
const gold = Color(0xffe7bb70);
const moss = Color(0xff91a86c);

class WorldGame extends FlameGame {
  Map<String, dynamic> data = {};
  String? selected;
  String mode = 'Mundo';
  String filter = 'Territorios';
  Offset pan = Offset.zero;
  double zoom = 1;
  double phase = 0;
  bool reduceMotion = false;
  bool mini = true;
  ui.Image? people, buildings, terrain;
  final void Function(String) onSelect;
  WorldGame(this.onSelect);
  @override
  Color backgroundColor() => const Color(0xff283d40);
  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';
    try {
      people = await images.load('art/characters.png');
      buildings = await images.load('art/buildings.png');
      terrain = await images.load('art/terrain.png');
    } catch (_) { /* Geometric pixel fallback while assets are loading. */ }
  }
  @override
  void update(double dt) { super.update(dt); if (!reduceMotion) phase += dt; }
  List<Map<String, dynamic>> get societies => (data['societies'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  int number(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
  int get extent => number(data['size'], 96);
  Offset position(Map<String, dynamic> s) => Offset(number(s['x'], extent ~/ 2).toDouble(), number(s['y'], extent ~/ 2).toDouble());
  Offset get center => Offset(size.x / 2, size.y / 2);
  double get unit => math.min(size.x, size.y) / extent * zoom;
  void touch(Offset screen) {
    if (mode == 'Asentamiento') return;
    final p = (screen - center - pan) / unit + Offset(extent / 2, extent / 2);
    Map<String,dynamic>? best;
    double distance = double.infinity;
    for (final s in societies) {
      final d = (position(s)-p).distance;
      if(d < distance) { distance=d; best=s; }
    }
    if(best != null && distance < math.max(5, 18 / unit)) { selected=best['id'].toString(); onSelect(selected!); }
  }
  void locate(String id) {
    selected=id;
    if(mode=='Asentamiento'){pan=Offset.zero;return;}
    final s=societies.where((s)=>s['id']==id).firstOrNull;
    if(s != null) pan=-(position(s)-Offset(extent/2,extent/2))*unit;
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if(data.isEmpty) return;
    if(mode=='Asentamiento') { _settlement(canvas); return; }
    canvas.save();
    canvas.translate(center.dx+pan.dx,center.dy+pan.dy);
    canvas.scale(unit);
    canvas.translate(-extent/2,-extent/2);
    final tiles=data['tiles'] as List? ?? [];
    final colors=[const Color(0xff7e9460),const Color(0xff405b47),const Color(0xffb69c6c),const Color(0xff767875),const Color(0xff8c9b87),const Color(0xff426c75)];
    final paint=Paint()..isAntiAlias=false..filterQuality=FilterQuality.none;
    for(var y=0;y<extent;y++) {
      for(var x=0;x<extent;x++) {
        final sx=center.dx+pan.dx+(x-extent/2)*unit;
        final sy=center.dy+pan.dy+(y-extent/2)*unit;
        if(sx < -unit || sy < -unit || sx > size.x+unit || sy > size.y+unit)continue;
        final index=y*extent+x;
        final dynamic t=index<tiles.length?tiles[index]:null;
        final b=t is Map?t['biome']:t;
        int biome=b is num?b.toInt():['water','plains','forest','desert','mountain','wetland'].indexOf('$b');
        if(biome<0) biome=1;
        paint.color=colors[biome%colors.length];
        if(filter=='Recursos' && t is Map && number(t['richness'])>=4) paint.color=gold;
        if(filter=='Entorno' && t is Map && number(t['damage'])>0)paint.color=const Color(0xffb36d57);
        canvas.drawRect(Rect.fromLTWH(x.toDouble(),y.toDouble(),1.04,1.04),paint);
        if(zoom>2 && (x*17+y*13)%11==0) {
          paint.color=const Color(0x22000000);
          canvas.drawRect(Rect.fromLTWH(x+.2,y+.3,.3,.2),paint);
        }
      }
    }
    final routes=data['routes'] as List? ?? [];
    for(final dynamic route in routes){
      if(route is! Map)continue;
      final cells=route['path'] as List? ?? [];
      if(cells.isEmpty)continue;
      final path=Path();
      for(var i=0;i<cells.length;i++){
        final index=number(cells[i]);final p=Offset((index%extent)+.5,(index~/extent)+.5);
        if(i==0)path.moveTo(p.dx,p.dy);else path.lineTo(p.dx,p.dy);
      }
      canvas.drawPath(path,Paint()..color=route['blocked']==true?const Color(0xffbb715d):const Color(0xffc7b38b)..style=PaintingStyle.stroke..strokeWidth=.32..isAntiAlias=false);
      final cursor=number(route['progress'])%cells.length;final index=number(cells[cursor]);
      canvas.drawRect(Rect.fromLTWH(index%extent-.4,index~/extent-.4,1.4,1.4),Paint()..color=gold);
    }
    final colorsSoc=[const Color(0xffeac27b),const Color(0xff8cb3b0),const Color(0xffca886b),const Color(0xffa7bc87),const Color(0xffb3a0b8),const Color(0xffd7d0b5)];
    for(var i=0;i<societies.length;i++) {
      final s=societies[i]; final p=position(s);
      final color=colorsSoc[i%colorsSoc.length];
      if(filter=='Población'){canvas.drawCircle(p,math.max(1,math.sqrt(number(s['population'],40))/3),Paint()..color=color.withValues(alpha:.45));}
      if(filter=='Entorno'){canvas.drawCircle(p,2+number(s['environment'])/5,Paint()..color=const Color(0x88bc6b55));}
      if(filter=='Conflictos'){final relations=s['relations'] as Map? ?? {};for(final other in societies){if(number(relations[other['id']]) < -40)canvas.drawLine(p,position(other),Paint()..color=const Color(0xffda8469)..strokeWidth=.7);}}
      if(filter=='Territorios') {
        canvas.drawCircle(p,math.max(2,math.sqrt(number(s['population'],40))/2),Paint()..color=color.withValues(alpha:.2)..isAntiAlias=false);
      }
      canvas.drawRect(Rect.fromCenter(center:p,width:2.6,height:2.6),Paint()..color=ink);
      canvas.drawRect(Rect.fromCenter(center:p,width:1.8,height:1.8),Paint()..color=color);
      if(s['id']==selected) canvas.drawRect(Rect.fromCenter(center:p,width:4,height:4),Paint()..color=gold..style=PaintingStyle.stroke..strokeWidth=.4);
      if(mode=='Región' || s['id']==selected) {
        canvas.save(); canvas.translate(p.dx+2,p.dy-2); canvas.scale(1/unit);
        _text(canvas,'${s['name']}',Offset.zero,color:const Color(0xfff3e4c9),fontSize:11);
        canvas.restore();
      }
    }
    canvas.restore();
    if(mini) _mini(canvas);
    _text(canvas,'${mode.toUpperCase()}  •  $filter',const Offset(14,14),color:const Color(0xffe5ddc7),fontSize:10);
  }
  void _mini(Canvas c) {
    final r=Rect.fromLTWH(size.x-88,12,74,74);
    c.drawRect(r,Paint()..color=ink.withValues(alpha:.85));
    c.drawRect(r.deflate(4),Paint()..color=const Color(0xff566b53));
    for(final s in societies) {
      final p=position(s);
      c.drawRect(Rect.fromLTWH(r.left+5+p.dx/extent*62,r.top+5+p.dy/extent*62,3,3),Paint()..color=s['id']==selected?gold:const Color(0xffe8e2ca));
    }
  }
  void _settlement(Canvas c) {
    final s=societies.where((s)=>s['id']==selected).firstOrNull ?? societies.firstOrNull;
    if(s==null) return;
    final paint=Paint()..isAntiAlias=false..filterQuality=FilterQuality.none;
    const tile=32.0;
    c.save();
    c.translate(center.dx+pan.dx,center.dy+pan.dy);
    c.scale(math.min(size.x,size.y)/1024*zoom);
    c.translate(-512,-512);
    for(var y=0;y<32;y++) { for(var x=0;x<32;x++) {
      paint.color=(x+y)%2==0?const Color(0xff8f9668):const Color(0xff92996a);
      c.drawRect(Rect.fromLTWH(x*tile,y*tile,tile,tile),paint);
      paint.color=const Color(0xffa9a17a);
      if(x==4 || y==5) c.drawRect(Rect.fromLTWH(x*tile,y*tile,tile,tile),paint);
      if((x*3+y*7)%17==0) _tree(c,Offset(x*tile+9,y*tile+6));
    }}
    final sites=s['sites'] as List? ?? [];
    for(final dynamic site in sites) {
      final p=Offset(number(site['x'])*tile,number(site['y'])*tile);
      if(buildings!=null) {
        paint.colorFilter=s['extinct']==true?const ColorFilter.mode(Color(0xff80766b),BlendMode.saturation):null;
        const order=['farm','well','house','sawmill','quarry','workshop','clinic','school','market','wall','mine','laboratory','generator','loom','granary','recycler','observatory','habitat'];
        final index=order.indexOf(site['building'].toString());
        final artIndex=index<0?2:index;
        final col=artIndex%6; final row=artIndex~/6;
        c.drawImageRect(buildings!,Rect.fromLTWH(col*64.0,row*64.0,64,64),Rect.fromLTWH(p.dx,p.dy,64,64),paint);
      } else { _house(c,p); }
    }
    paint.colorFilter=null;
    final leaders=(s['people'] as List? ?? s['characters'] as List? ?? s['leaders'] as List? ?? []).where((dynamic p)=>p is Map && p['diedDay']==null).toList();
    final population=number(s['population'],40);
    final count=population<=0?0:math.min(12,math.max(leaders.length,population~/12));
    final projects=s['projects'] as List? ?? [];
    final route=(data['routes'] as List? ?? []).any((dynamic r)=>r['from']==s['id'] && r['blocked']!=true);
    for(var i=0;i<count;i++) {
      final person=i<leaders.length?leaders[i] as Map:null;
      final role=person==null?3:person['name']=='Ana'?0:person['name']=='Leo'?1:person['name']=='Tito'?2:person['role']=='técnica'?0:person['role']=='explorador'?1:3;
      final action=number(s['health'],100)<35?6:role==2&&route?3:projects.isNotEmpty&&(role==0||i>=leaders.length)?2:role==3?2:0;
      final stride=reduceMotion||action!=3?0:(phase*9+i*19)%40;
      final p=Offset(80+(i%6)*75+stride,180+(i~/6)*70);
      if(people!=null) {
        final frame=reduceMotion?0:(phase*4).floor()%4;
        c.drawImageRect(people!,Rect.fromLTWH(frame*32.0,(role*8+action)*48.0,32,48),Rect.fromLTWH(p.dx,p.dy,32,48),paint);
      } else { _person(c,p,i); }
    }
    c.restore();
    _text(c,'${s['name']}  •  ${number(s['population'])} habitantes',const Offset(14,14),color:const Color(0xfff8edd7),fontSize:12);
    _text(c,'32 × 32 · ${s['id']} · ${sites.length} edificios',Offset(14,size.y-24),color:const Color(0xffe4dfc5),fontSize:10);
  }
  void _tree(Canvas c,Offset p) {
    c.drawRect(Rect.fromLTWH(p.dx+6,p.dy+13,5,13),Paint()..color=const Color(0xff675645));
    c.drawRect(Rect.fromLTWH(p.dx,p.dy,20,17),Paint()..color=const Color(0xff435b43));
    c.drawRect(Rect.fromLTWH(p.dx+4,p.dy-4,12,10),Paint()..color=const Color(0xff567453));
  }
  void _house(Canvas c,Offset p) {
    c.drawRect(Rect.fromLTWH(p.dx,p.dy+14,48,34),Paint()..color=ink);
    c.drawRect(Rect.fromLTWH(p.dx+3,p.dy+17,42,27),Paint()..color=const Color(0xffc0a47a));
    c.drawRect(Rect.fromLTWH(p.dx-3,p.dy+7,54,14),Paint()..color=const Color(0xff64574b));
    c.drawRect(Rect.fromLTWH(p.dx+19,p.dy+30,12,18),Paint()..color=ink);
  }
  void _person(Canvas c,Offset p,int i) {
    c.drawRect(Rect.fromLTWH(p.dx+3,p.dy+1,14,13),Paint()..color=ink);
    c.drawRect(Rect.fromLTWH(p.dx+5,p.dy+4,10,8),Paint()..color=const Color(0xffce9b74));
    c.drawRect(Rect.fromLTWH(p.dx+4,p.dy+14,12,13),Paint()..color=i%2==0?const Color(0xff5b858c):const Color(0xffa47a4d));
    c.drawRect(Rect.fromLTWH(p.dx+4,p.dy+27,5,7),Paint()..color=ink);
    c.drawRect(Rect.fromLTWH(p.dx+12,p.dy+27,5,7),Paint()..color=ink);
  }
  void _text(Canvas c,String text,Offset p,{Color color=gold,double fontSize=12}) {
    final tp=TextPainter(text:TextSpan(text:text,style:TextStyle(color:color,fontSize:fontSize,fontWeight:FontWeight.w700,shadows:const [Shadow(color:ink,blurRadius:3)])),textDirection:TextDirection.ltr)..layout(maxWidth:400);
    tp.paint(c,p);
  }
}
