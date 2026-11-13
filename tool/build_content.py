#!/usr/bin/env python3
"""Source-authoring tool for the original, offline Spanish catalog. No downloaded assets."""
import json, hashlib, pathlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
def effect(kind, value, resource=None):
 d={'type':kind,'value':value}
 if resource:d['resource']=resource
 return d
resources=[('food','Alimentos','raciones','Consumo diario y reservas de expedición'),('wood','Madera','tablones','Vivienda, combustible y caminos'),('stone','Piedra','bloques','Cimientos y defensas'),('metal','Metal','piezas','Herramientas, industria y defensa'),('water','Agua','cántaros','Salud, cultivos y refrigeración'),('medicine','Medicinas','dosis','Clínicas y epidemias'),('tools','Herramientas','juegos','Productividad y mantenimiento'),('energy','Energía','celdas','Industria, señales y automatización'),('knowledge','Conocimiento','notas','Investigación y archivos'),('fiber','Fibras','rollos','Ropa, comercio y refugios'),('fuel','Combustible','bidones','Transporte y generadores'),('relics','Reliquias','núcleos','Tecnología antigua e intercambio')]
biomes=[('plain','Llanura',1,1.2,['food','fiber']),('forest','Bosque',2,1.05,['wood','medicine']),('desert','Desierto',3,.55,['stone','energy']),('wetland','Humedal',3,.8,['water','food']),('mountain','Sierra',4,.65,['metal','stone']),('ruins','Ruinas',2,.7,['relics','knowledge'])]
buildings=[('farm','Huerto',{'wood':18,'stone':6},12,'food',5,[]),('house','Vivienda',{'wood':24,'stone':12},18,'housing',12,[]),('well','Pozo',{'stone':25,'tools':3},15,'water',6,[]),('lumberyard','Aserradero',{'wood':20,'tools':5},18,'wood',4,['forestry']),('quarry','Cantera',{'wood':18,'tools':5},20,'stone',4,['masonry']),('mine','Mina',{'wood':28,'stone':20,'tools':8},30,'metal',3,['metallurgy']),('workshop','Taller',{'wood':24,'metal':12},24,'tools',2,['craft']),('clinic','Clínica',{'wood':25,'medicine':15},25,'health',8,['medicine']),('school','Escuela',{'wood':30,'knowledge':15},30,'knowledge',3,['writing']),('archive','Archivo',{'stone':30,'knowledge':20},35,'preservation',1,['archives']),('market','Mercado',{'wood':30,'fiber':12},20,'trade',1,['barter']),('wall','Muralla',{'stone':70,'metal':8},40,'defense',20,['fortification']),('solar','Campo solar',{'metal':35,'relics':3},40,'energy',5,['solar']),('generator','Generador',{'metal':25,'tools':12},30,'energy',8,['engines']),('laboratory','Laboratorio',{'metal':40,'knowledge':30},45,'research',4,['scientific_method']),('reservoir','Embalse',{'stone':60,'tools':10},50,'water_storage',200,['irrigation']),('greenhouse','Invernadero',{'metal':30,'energy':20},35,'food',9,['hydroponics']),('observatory','Observatorio',{'stone':45,'relics':6},60,'signal',1,['astronomy'])]
techs=[('craft','Oficios',[],30),('agriculture','Agricultura',[],30),('masonry','Albañilería',[],35),('writing','Escritura',[],35),('barter','Trueque',[],25),('forestry','Silvicultura',['craft'],50),('irrigation','Riego',['agriculture','masonry'],65),('metallurgy','Metalurgia',['craft'],60),('medicine','Medicina',['writing'],55),('fortification','Fortificación',['masonry'],70),('archives','Archivos',['writing'],60),('roads','Caminos',['masonry','barter'],65),('engines','Motores',['metallurgy'],100),('scientific_method','Método científico',['archives','medicine'],110),('electricity','Electricidad',['metallurgy','archives'],100),('solar','Energía solar',['electricity'],120),('logistics','Logística',['roads','writing'],90),('sanitation','Saneamiento',['medicine','irrigation'],100),('hydroponics','Hidroponía',['sanitation','electricity'],140),('automation','Automatización',['engines','electricity'],160),('radio','Radio',['electricity','scientific_method'],140),('astronomy','Astronomía',['scientific_method'],130),('biotech','Biotecnología',['medicine','scientific_method'],180),('cybernetics','Cibernética',['automation','medicine'],200),('ecology','Ecología',['forestry','scientific_method'],120),('fusion','Fusión',['solar','scientific_method'],250),('translation','Traducción de señales',['radio','astronomy'],190),('orbital','Infraestructura orbital',['fusion','astronomy'],300),('symbiosis','Simbiosis diseñada',['biotech','ecology'],250),('distributed_minds','Mentes distribuidas',['cybernetics','translation'],300)]
traits=[('prudent','Prudente','risk',-.25),('bold','Audaz','risk',.3),('generous','Generoso','trade',.25),('guarded','Reservado','diplomacy',-.2),('inventive','Inventivo','research',.3),('traditional','Tradicional','research',-.15),('patient','Paciente','reserves',.3),('restless','Inquieto','expansion',.3),('conciliatory','Conciliador','diplomacy',.35),('severe','Severo','defense',.3),('green','Custodio','environment',.35),('pragmatic','Pragmático','production',.25)]
profiles=[('growers','Sembradores',{'reserves':90,'research':'agriculture','expansion':.3,'trade':.6,'risk':.2},['Vega','Semilla','Huerta']),('keepers','Custodios',{'reserves':120,'research':'ecology','expansion':.1,'trade':.3,'risk':.1},['Sauce','Umbral','Raíz']),('traders','Caminantes',{'reserves':45,'research':'logistics','expansion':.5,'trade':.9,'risk':.5},['Paso','Cruce','Caravana']),('scholars','Archivistas',{'reserves':60,'research':'scientific_method','expansion':.2,'trade':.5,'risk':.4},['Faro','Índice','Memoria']),('wardens','Bastiones',{'reserves':90,'research':'fortification','expansion':.7,'trade':.2,'risk':.6},['Bastión','Muro','Guardia']),('tinkerers','Recuperadores',{'reserves':40,'research':'automation','expansion':.4,'trade':.7,'risk':.8},['Chispa','Taller','Núcleo'])]
# Twelve authored situations in each of eight categories. Every row has context,
# a concrete cost, two different outcomes, and its own eligibility tension.
rows={
'needs':[
('granary_mold','Moho en el granero','Tito encuentra costales húmedos. Separarlos salva el resto, pero reduce la reserva.', 'food',12,'health',6,'food',-24,'foodBelow',160),
('dry_well','El pozo calla','El agua baja antes de la cosecha; el fondo permite profundizar con herramientas.', 'tools',4,'resource',30,'health',-7,'waterBelow',100),
('cold_roofs','Techos en invierno','El viento entra en las viviendas. Las familias piden tablones para cerrar los huecos.', 'wood',16,'health',5,'mood',-9,'populationAbove',20),
('shared_pot','La olla común','Dos cocinas proponen reunir sus reservas y alimentar primero a quienes trabajan lejos.', 'food',15,'mood',9,'health',-3,'foodAbove',30),
('tainted_cups','Vasos turbios','Varias familias enferman tras beber del canal. Hervir el agua consume combustible.', 'fuel',5,'health',10,'health',-12,'healthBelow',90),
('orphan_apprentices','Aprendices sin hogar','Tres jóvenes ofrecen aprender un oficio a cambio de espacio y herramientas.', 'tools',3,'knowledge',12,'mood',-4,'housingAbove',0),
('harvest_injury','Una mano herida','Una cosechadora necesita atención. Los turnos pueden cubrir su ausencia.', 'medicine',4,'health',7,'population',-1,'populationAbove',15),
('fiber_blankets','Mantas deshilachadas','El taller puede tejer mantas antes de que llegue el frío.', 'fiber',10,'health',5,'mood',-6,'fiberAbove',12),
('ration_dispute','La última ración','La guardia exige prioridad en el reparto; el consejo puede repartir por necesidad.', 'food',10,'mood',8,'mood',-12,'foodBelow',70),
('clinic_shift','Turno de madrugada','La clínica pide luz para atender sin suspender tratamientos.', 'energy',8,'health',9,'health',-5,'healthBelow',85),
('crowded_homes','Paredes compartidas','La población supera las camas. Un refugio provisional puede ganar tiempo.', 'wood',20,'housing',8,'health',-6,'populationAbove',35),
('funeral_garden','Jardín de nombres','Las familias quieren un lugar donde recordar a sus muertos y reunirse.', 'stone',14,'mood',12,'mood',-5,'dayAbove',360)],
'relations':[
('bridge_meeting','La mesa del puente','Una comunidad vecina propone hablar sin armas en el paso del río.', 'food',8,'relation',12,'relation',-5,'populationAbove',10),
('borrowed_tools','Herramientas prestadas','La caravana pide herramientas y promete devolver metal al terminar el viaje.', 'tools',5,'relation',10,'relation',-4,'toolsAbove',6),
('insulted_banner','Un estandarte roto','Un símbolo vecino aparece rasgado en el mercado. Una reparación pública evitaría rumores.', 'fiber',6,'relation',8,'relation',-12,'moodBelow',80),
('wedding_delegation','La delegación de boda','Dos familias de distintas ciudades celebran una unión e invitan a las autoridades.', 'food',12,'relation',14,'mood',-3,'foodAbove',40),
('border_spring','El manantial limítrofe','Dos comunidades reclaman la misma fuente. Mantenerla juntos cuesta materiales.', 'stone',15,'relation',16,'relation',-16,'waterBelow',120),
('returned_child','El camino de regreso','Exploradores devuelven a una niña perdida y piden ayuda para señalizar el sendero.', 'wood',8,'relation',9,'mood',-4,'woodAbove',10),
('guest_healer','La sanadora visitante','Una curandera ofrece sus notas si puede atender también a los extranjeros.', 'medicine',3,'knowledge',18,'relation',-6,'medicineAbove',4),
('broken_promise','La promesa vencida','Una entrega pendiente sigue sin llegar. El consejo puede compensar parte del retraso.', 'metal',6,'relation',10,'relation',-15,'metalAbove',8),
('river_festival','La fiesta del río','Los pueblos ribereños quieren una jornada común y un mercado sin peajes.', 'food',18,'relation',18,'mood',-3,'foodAbove',60),
('refugee_letter','Carta de refugio','Un grupo desplazado pregunta si habrá sitio para sus mayores y sus semillas.', 'food',20,'population',5,'relation',-8,'housingAbove',3),
('envoy_detained','Un enviado retenido','La guardia ha detenido a un mensajero. Soltarlo con provisiones sería una señal clara.', 'food',6,'relation',11,'relation',-18,'moodBelow',90),
('joint_maps','Mapas sobre la mesa','Los viajeros ofrecen corregir nuestros mapas a cambio de copias del archivo.', 'knowledge',8,'relation',14,'knowledge',-3,'knowledgeAbove',10)],
'exploration':[
('buried_cart','Carro bajo la arena','Leo encuentra un carro hundido. Sacarlo exige madera para una palanca.', 'wood',8,'metal',18,'knowledge',3,'dayAbove',10),
('glowing_moss','Musgo luminoso','Un túnel brilla con una vida desconocida; tomar muestras requiere recipientes limpios.', 'medicine',3,'knowledge',20,'health',-5,'dayAbove',30),
('sealed_library','Biblioteca sellada','Una sala conserva libros tras una pared agrietada.', 'tools',4,'knowledge',35,'stone',8,'toolsAbove',5),
('old_battery','Batería dormida','Ana reconoce una celda antigua y pide aislarla antes de abrirla.', 'tools',3,'energy',25,'health',-6,'dayAbove',40),
('herd_tracks','Huellas entre juncos','Un rebaño cruza cerca; seguirlo puede revelar pastos y rutas.', 'food',6,'food',25,'knowledge',5,'foodAbove',20),
('ravine_rope','Al otro lado de la grieta','Una antena asoma en una cornisa. Llegar requiere cuerdas nuevas.', 'fiber',8,'relics',2,'knowledge',4,'fiberAbove',9),
('salt_cave','La cueva salada','Los depósitos pueden conservar alimentos, pero la entrada necesita refuerzo.', 'wood',12,'food',30,'stone',6,'woodAbove',15),
('sunken_station','Estación inundada','Un plano industrial espera bajo el agua; bombear consume combustible.', 'fuel',8,'knowledge',28,'metal',4,'fuelAbove',9),
('watchtower_echo','Eco en la torre','Una señal repite tres pulsos. Anotarla requiere mantener una lámpara encendida.', 'energy',4,'knowledge',15,'mood',-2,'dayAbove',60),
('orchard_ruins','Huerto de las ruinas','Frutales sobreviven entre edificios. Limpiar el terreno evita una tala apresurada.', 'tools',3,'food',35,'wood',10,'toolsAbove',4),
('marked_stones','Piedras numeradas','Las marcas describen una ruta de refugios. Leo quiere verificar una por una.', 'food',10,'knowledge',22,'stone',5,'dayAbove',20),
('buried_machines','Máquinas enterradas','Un taller sepultado guarda piezas; excavar con cuidado impide que se hunda.', 'wood',14,'tools',12,'metal',8,'woodAbove',16)],
'economy':[
('wagon_axle','El eje partido','Una caravana queda inmóvil junto al mercado. Repararla conserva la ruta.', 'metal',5,'relation',8,'food',-8,'metalAbove',6),
('grain_offer','Oferta de grano','Una cosecha vecina permite comprar alimentos con fibras.', 'fiber',12,'food',45,'relation',-2,'foodBelow',150),
('tool_standard','Medidas comunes','El taller propone piezas intercambiables y necesita un lote inicial de metal.', 'metal',12,'tools',16,'knowledge',3,'metalAbove',14),
('fuel_spill','Combustible derramado','Un depósito pierde líquido cerca del canal. Absorberlo requiere fibras.', 'fiber',8,'health',7,'environment',-10,'fuelAbove',5),
('storage_labels','Etiquetas del almacén','Tito pide tablillas para contar las reservas antes de repartirlas.', 'wood',6,'food',12,'mood',-3,'populationAbove',20),
('counterfeit_relic','Una reliquia falsa','Un mercader ofrece un núcleo dudoso. Probarlo consume energía pero revela su origen.', 'energy',4,'knowledge',10,'metal',-5,'energyAbove',5),
('flooded_quarry','Cantera anegada','Las lluvias frenan la extracción. Un drenaje permitiría volver al trabajo.', 'tools',5,'stone',25,'stone',-8,'stoneBelow',100),
('loom_cooperative','Telar compartido','Varias familias quieren operar un telar con un fondo común.', 'wood',14,'fiber',28,'mood',-4,'woodAbove',16),
('caravan_guarantee','La carga asegurada','Los comerciantes piden una reserva de alimentos antes de salir por una ruta difícil.', 'food',16,'metal',14,'relation',-5,'foodAbove',50),
('scrap_sorting','Montaña de chatarra','Separar piezas útiles requiere herramientas y evita fundir materiales valiosos.', 'tools',3,'metal',22,'environment',-3,'toolsAbove',4),
('empty_stalls','Puestos vacíos','El mercado pierde vendedores. Una comida común puede atraerlos de nuevo.', 'food',14,'relation',9,'mood',-7,'moodBelow',75),
('water_contract','Contrato de agua','Un vecindario ofrece metal por el excedente de nuestros pozos.', 'water',30,'metal',16,'relation',-3,'waterAbove',80)],
'politics':[
('open_council','Consejo abierto','Trabajadores piden una sesión pública para revisar las reservas.', 'knowledge',4,'mood',12,'mood',-9,'populationAbove',25),
('guard_petition','Petición de la guardia','La guardia quiere mejores equipos y un registro de sus atribuciones.', 'metal',10,'defense',12,'mood',-6,'dayAbove',60),
('succession_notes','Las notas del relevo','Una dirigente quiere formar a su reemplazo antes de dejar el cargo.', 'knowledge',12,'mood',8,'knowledge',-6,'dayAbove',720),
('ration_records','El libro del reparto','Faltan firmas en el reparto. Una auditoría exige tiempo de los escribas.', 'knowledge',8,'mood',10,'mood',-12,'foodBelow',120),
('quiet_dissent','Voces en el taller','Los operarios critican los turnos. Reparar el espacio común permite negociar.', 'wood',12,'mood',13,'tools',-5,'moodBelow',75),
('archive_access','Puertas del archivo','El consejo discute quién puede consultar los mapas antiguos.', 'knowledge',5,'relation',7,'mood',-8,'knowledgeAbove',20),
('land_registry','Parcelas sin nombre','Los nuevos cultivos se solapan. Marcar límites evita futuros agravios.', 'stone',10,'mood',11,'relation',-8,'populationAbove',35),
('night_patrol','Patrullas nocturnas','Las familias piden seguridad sin dar poderes ilimitados a la guardia.', 'food',10,'defense',8,'mood',-10,'moodBelow',85),
('public_work','La plaza común','Dos barrios compiten por una obra. Una plaza compartida reparte los beneficios.', 'stone',18,'mood',15,'relation',-5,'stoneAbove',22),
('old_debt','Deuda de los fundadores','Una familia conserva un pacto incumplido. El consejo puede reconocer su aportación.', 'metal',5,'mood',9,'mood',-11,'dayAbove',360),
('school_vote','La escuela decide','Los docentes solicitan materiales para enseñar también historia crítica.', 'knowledge',10,'knowledge',22,'mood',-5,'knowledgeAbove',15),
('emergency_powers','Poderes de emergencia','Tras una crisis, la guardia pide conservar sus prerrogativas. Una asamblea puede limitarlas.', 'food',12,'mood',14,'defense',8,'healthBelow',70)],
'technology':[
('coil_test','La prueba de la bobina','Ana prepara un circuito; una descarga controlada puede enseñar más que un desmontaje.', 'metal',8,'knowledge',24,'energy',5,'metalAbove',10),
('sterile_room','Sala limpia','La clínica puede separar instrumental contaminado si recibe energía estable.', 'energy',10,'health',12,'medicine',-4,'healthBelow',90),
('seed_selection','Semillas elegidas','Una agricultora propone reservar parte de la cosecha para comparar variedades.', 'food',18,'knowledge',18,'food',8,'foodAbove',60),
('radio_noise','Ruido de radio','Un aparato capta voces discontinuas. Repetir la escucha requiere celdas.', 'energy',8,'relation',8,'knowledge',5,'energyAbove',10),
('metal_fatigue','Metal fatigado','Una pieza rota revela un fallo repetido. Ensayar un reemplazo cuesta herramientas.', 'tools',4,'knowledge',20,'metal',-8,'toolsAbove',5),
('river_turbine','Turbina del canal','El taller puede probar una rueda de agua sin cerrar el paso de peces.', 'wood',20,'energy',25,'environment',-6,'woodAbove',24),
('lens_polish','Pulir la lente','Un vidrio antiguo necesita abrasivos y paciencia para recuperar imágenes del cielo.', 'stone',10,'knowledge',26,'relics',1,'stoneAbove',15),
('culture_vat','Cultivo experimental','Un cultivo diseñado podría fabricar medicinas, con contención y consumo eléctrico.', 'energy',12,'medicine',16,'health',-4,'knowledgeAbove',80),
('servitor_trial','La primera máquina','Un autómata recuperado puede transportar cargas si se reemplazan sus articulaciones.', 'metal',16,'tools',20,'energy',8,'metalAbove',20),
('heat_recovery','El calor sobrante','Un horno puede calentar viviendas mediante un circuito cerrado.', 'metal',12,'health',8,'fuel',-5,'fuelAbove',8),
('memory_crystal','Cristal de memoria','Las notas de una técnica fallecida están en un soporte dañado.', 'energy',10,'knowledge',35,'relics',1,'knowledgeAbove',40),
('quiet_reactor','El reactor silencioso','Un núcleo admite una prueba breve si se preservan los anillos de seguridad.', 'tools',10,'energy',45,'health',-10,'toolsAbove',12)],
'conflict':[
('stolen_crates','Cajas robadas','Las huellas llevan a un campamento hambriento. Compartir puede evitar una represalia.', 'food',18,'relation',10,'defense',-6,'foodAbove',35),
('border_patrol','Patrulla en la frontera','Una columna vecina se acerca al lindero. Preparar suministros permite negociar con firmeza.', 'food',12,'defense',10,'relation',-10,'populationAbove',25),
('deserter_gate','Desertores en la puerta','Un pequeño grupo pide refugio y entrega sus mapas militares.', 'food',20,'population',4,'relation',-12,'housingAbove',3),
('supply_siege','Cerco de suministros','Una ruta está amenazada. Almacenar agua y grano reduce la vulnerabilidad.', 'water',20,'defense',12,'food',-15,'waterAbove',40),
('watch_fire','Fuego en la atalaya','Una señal de humo avisa de una incursión. Reparar el puesto permite responder.', 'wood',16,'defense',14,'metal',-8,'woodAbove',20),
('armistice_cost','El precio de la tregua','Una mediación exige alimentos para ambas delegaciones.', 'food',22,'relation',18,'population',-2,'relationBelow',0),
('damaged_wall','Brecha en el muro','Una defensa agrietada puede repararse antes de la próxima tormenta.', 'stone',22,'defense',18,'defense',-10,'stoneAbove',24),
('missing_scout','La exploradora ausente','Una patrulla no regresa. Enviar provisiones a buscarla impide una retirada precipitada.', 'food',10,'mood',8,'population',-1,'populationAbove',15),
('captured_wagon','Caravana capturada','Un grupo armado exige metal para soltar a los transportistas.', 'metal',12,'relation',9,'population',-2,'metalAbove',15),
('militia_drill','Ejercicio de milicia','Un entrenamiento requiere alimentos y reduce el tiempo de cosecha.', 'food',16,'defense',15,'mood',-5,'foodAbove',50),
('burial_truce','Tregua para enterrar','Ambos bandos quieren recuperar a sus muertos. Preparar el encuentro exige telas.', 'fiber',10,'relation',20,'mood',-9,'relationBelow',10),
('weapon_cache','Depósito de armas','Un arsenal ficticio antiguo puede vigilarse o fundirse para recuperar metal.', 'food',8,'defense',22,'metal',18,'dayAbove',120)],
'environment':[
('river_silt','Limo en el canal','El río arrastra sedimentos fértiles y amenaza con taponar la toma.', 'tools',4,'food',24,'water',-15,'waterBelow',150),
('young_forest','Bosque joven','Los brotes crecen sobre antiguas parcelas; protegerlos frena la tala inmediata.', 'food',8,'environment',12,'wood',20,'dayAbove',90),
('locust_cloud','Nube de insectos','Una plaga se acerca a las hortalizas. Redes nuevas pueden salvar una parte.', 'fiber',10,'food',18,'food',-30,'foodAbove',40),
('landslide_signs','La ladera cruje','Grietas nuevas aconsejan reforzar la pendiente antes de que llueva.', 'stone',20,'environment',10,'housing',-6,'stoneAbove',22),
('ash_sky','Cielo de ceniza','Polvo lejano oscurece las mañanas. Cubrir depósitos mantiene el agua potable.', 'wood',12,'health',8,'health',-10,'dayAbove',180),
('wildfire_break','Línea contra el fuego','El verano seca el matorral. Abrir un cortafuegos consume herramientas.', 'tools',5,'environment',9,'wood',-30,'woodAbove',35),
('fish_return','Regresan los peces','Un tramo del río vuelve a llenarse de vida. Respetar la cría protege el futuro.', 'food',10,'environment',15,'food',28,'foodAbove',35),
('toxic_pool','Charca de colores','Un residuo antiguo aflora cerca de viviendas. Contenerlo exige piedra y conocimiento.', 'stone',18,'health',10,'environment',-18,'stoneAbove',20),
('dust_masks','Polvo en los pulmones','El viento del desierto obliga a fabricar mascarillas para quienes salen a trabajar.', 'fiber',12,'health',12,'health',-14,'healthBelow',90),
('seed_bank','Banco de semillas','Una bóveda seca puede conservar variedades ante una mala temporada.', 'food',20,'environment',10,'knowledge',8,'foodAbove',70),
('winter_water','Agua bajo hielo','Los depósitos se congelan. Aislar tuberías requiere telas y una reserva de trabajo.', 'fiber',8,'water',25,'water',-20,'waterBelow',100),
('earth_tremor','La tierra tiembla','Un temblor daña viviendas. Apuntalar tiene prioridad sobre recuperar objetos.', 'wood',20,'housing',10,'health',-12,'populationAbove',20)]}

def normalized(kind,value,resource=None):
 if kind in dict((r[0],1) for r in resources):return effect('resource',value,kind)
 return effect('morale' if kind=='mood' else kind,value,resource)
def cond(key,value):
 for suffix,operator in [('Below','resource_max'),('Above','resource_min')]:
  if key.endswith(suffix):
   name=key[:-len(suffix)]
   special={'population':('maxPopulation','minPopulation'),'housing':('maxHousing','minHousing'),'health':('maxHealth','minHealth'),'mood':('maxMorale','minMorale'),'relation':('maxRelation','minRelation'),'day':('maxDay','minDay')}
   if name in special:return {special[name][suffix=='Above']:value}
   return {operator:{name:value}}
 raise ValueError(key)
events=[]
for cat,items in rows.items():
 for i,(id,title,body,cost,n,kind,gain,other,loss,condition,threshold) in enumerate(items):
  gain_effect=normalized(kind,gain,'water' if id=='dry_well' else None)
  events.append({'id':id,'category':cat,'title':title,'body':body,'trigger':'director','location':'settlement','participants':['living_society'],'conditions':cond(condition,threshold),'baseProbability':.08+i*.003,'conditionalProbability':[{'conditions':{'maxHealth':60},'multiplier':1.25}],'cooldownDays':720+i*30,'repeatable':True,'exclusionGroup':id,'deadlineDays':30,'options':[{'id':'accept','label':'Organizar la respuesta','description':f'Invertir {n} unidades de {next(r[1].lower() for r in resources if r[0]==cost)}; {kind} {gain:+}.','costs':{cost:n},'effects':[gain_effect],'followUps':[]},{'id':'decline','label':'Aceptar el riesgo y conservar las reservas','description':f'Consecuencia conocida: {other} {loss:+}.','costs':{},'effects':[normalized(other,loss)],'followUps':[]}]})
# Arc tuples: scenario, commitment, counterproposal, positive end, divergent end.
arc_rows=[
('canal','El canal de las dos orillas','disaster','Dos aldeas comparten un canal dañado. Una obra conjunta puede alimentar ambas o convertir el agua en un arma.','Reparar en común','Cerrar nuestra toma','Las compuertas compartidas','Agua tras la frontera','stone',25,'food',65,'relation',-20),
('fever','La fiebre de vidrio','epidemic','Una epidemia ficticia deja manchas brillantes. El archivo atribuye su origen a un cultivo antiguo, no a un grupo de personas.','Abrir un cordón sanitario con víveres','Aislar sin intercambio','La clínica de los dos turnos','Una ciudad tras el cordón','medicine',12,'health',25,'population',-7),
('machine','La voz de la fábrica','autonomous','Una fábrica autónoma acepta órdenes incompletas y ofrece producir sin descanso. Sus sensores confunden viviendas con almacenes.','Instalar límites verificables','Delegar toda la producción','La máquina aprende límites','Producción sin habitantes','tools',15,'metal',90,'housing',-12),
('seed','El jardín diseñado','transformation','Un banco de ingeniería biológica ofrece semillas adaptadas al suelo. La transformación es diseñada, con costes y riesgos, no evolución espontánea.','Ensayar en parcelas aisladas','Liberar el cultivo de inmediato','La semilla que arraigó','El campo de una sola especie','knowledge',25,'food',100,'environment',-30),
('comet','La segunda sombra','planetary','Una observación confirma fragmentos orbitales en trayectoria incierta. Preparar refugios compite con las cosechas.','Reforzar refugios','Mantener las cosechas','El cielo sobre los refugios','Las luces del impacto','stone',40,'housing',20,'population',-12),
('council','Las llaves del consejo','political','Una coalición exige que las llaves del almacén dejen de pertenecer a una familia. La guardia reclama poder para sostener el orden.','Compartir el control con auditorías','Entregar las llaves a la guardia','Instituciones que permanecen','El almacén de los uniformes','knowledge',20,'morale',25,'relation',-25),
('aquifer','El último acuífero','scarcity','El acuífero cae y el mercado no puede abastecer a todos. Racionar y recuperar agua tardará meses.','Financiar reutilización','Comprar acceso exclusivo','El circuito del agua','Pozos detrás de los muros','tools',20,'water',150,'relation',-30),
('visitors','Los visitantes del eco','contact','Una señal antigua recibe respuesta. Los visitantes distinguen entre una invitación, un contrato y una rendición.','Traducir antes de prometer','Aceptar tutela a cambio de energía','El intercambio entre iguales','La ciudad bajo tutela','energy',25,'knowledge',100,'morale',-25),
('caravan','La ruta del cobre',None,'Una ruta atraviesa una sierra aislada. Los pueblos quieren comercio pero recuerdan antiguas exacciones.','Pactar mantenimiento compartido','Imponer peaje armado','Las caravanas del acuerdo','La ruta de los puestos cerrados','wood',30,'metal',70,'relation',-24),
('heirs','Los herederos del archivo',None,'El archivo conserva decisiones antiguas cuyo autor ha muerto. Sus herederos reclaman decidir qué se publica.','Preservar acceso público','Reservar los documentos al consejo','La memoria de todos','El archivo de las sombras','knowledge',18,'knowledge',80,'morale',-18),
('island','Los que partieron',None,'Una colonia lejana solicita herramientas y autonomía. Negarle la segunda puede conservar tributos y perder lealtad.','Reconocer su autonomía','Exigir tributo y guarnición','Dos ciudades de una memoria','La colonia que rompió el sello','tools',18,'relation',35,'population',-8),
]
arcs=[]
def arc_event(id,arc,title,body,conditions,options,root=False,family=None):
 d={'id':id,'arcId':arc,'category':'exploration' if arc=='facility' else 'technology','title':title,'body':body,'trigger':'director' if root else 'scheduled','location':'settlement','participants':['living_society'],'conditions':conditions,'baseProbability':.04,'conditionalProbability':[],'deadlineDays':90,'cooldownDays':36000,'repeatable':False,'exclusionGroup':arc,'options':options}
 if family:d['family']=family
 events.append(d)
 return id
def option(id,label,costs=None,effects=None,next=None,days=90,prob=1):
 return {'id':id,'label':label,'description':'Los costes se reservan al decidir; las consecuencias se revalidan en su fecha.','costs':costs or {},'effects':effects or [],'followUps':[{'eventId':next,'delayDays':days,'probability':prob}] if next else []}
for id,title,family,premise,yes,no,good,bad,cost,n,gain,amount,loss,lossn in arc_rows:
 ids=[id+'_'+s for s in ['opening','cooperation','pressure','legacy','fracture']]
 arc_event(ids[0],id,title,premise,{'minDay':90},[option('cooperate',yes,{cost:n},[effect('flag',id+'_cooperation')],ids[1],30),option('control',no,{},[effect('flag',id+'_control')],ids[2],45)],True,family)
 arc_event(ids[1],id,'El trabajo pendiente',f'La decisión «{yes.lower()}» ya moviliza personas. La comunidad debe sostener el proyecto o abandonar lo prometido.',{'flags':[id+'_cooperation']},[option('finish','Sostener el compromiso',{cost:max(1,n//2)},[normalized('morale',3)],ids[3],180),option('abandon','Retirar apoyo',{},[normalized('relation',-8)],ids[4],30)],family=family)
 arc_event(ids[2],id,'La presión del presente',f'La política «{no.lower()}» divide a quienes reciben sus ventajas y a quienes cargan con sus costes.',{'flags':[id+'_control']},[option('reform','Renegociar con garantías',{cost:n},[normalized('relation',6)],ids[3],360),option('enforce','Mantener la orden',{},[normalized('defense',5)],ids[4],90)],family=family)
 arc_event(ids[3],id,good,'Los registros y las reservas muestran el resultado del esfuerzo sostenido. Este cambio procede de decisiones registradas, no de una recompensa por esperar.',{},[option('record','Incorporar el legado',{},[normalized(gain,amount),effect('flag',id+'_legacy')])],family=family)
 arc_event(ids[4],id,bad,'El coste acumulado se hace visible. Los habitantes recuerdan el compromiso original y quién decidió mantenerlo o romperlo.',{},[option('face','Reconocer las consecuencias',{},[normalized(loss,lossn),effect('flag',id+'_fracture')])],family=family)
 arcs.append({'id':id,'title':title,'entryEvent':ids[0],'events':ids,'endings':[ids[3],ids[4]],'family':family,'mechanicalOutcomes':[f'{gain} +{amount}',f'{loss} {lossn}']})
# Required installation arc: four meaningful branches and three enduring legacies.
fids=['facility_found','facility_sealed','facility_salvage','facility_shared','facility_study','facility_energy','facility_contact']
arc_event(fids[0],'facility','La puerta bajo el polvo','Leo localiza una instalación intacta. Ana reconoce sus anillos de contención; Tito calcula cuánto costaría abrirla.',{'minDay':3,'facilityFound':True,'flagsMissing':['facility_committed']},[option('seal','Sellar la instalación',{'stone':15},[effect('flag','facility_closed')],fids[1],20),option('dismantle','Desmontar con cuidado',{'tools':8},[effect('flag','facility_dismantled')],fids[2],30),option('share','Ofrecer acceso a otra comunidad',{'food':15},[effect('flag','facility_shared')],fids[3],40),option('study','Estudiar el núcleo',{'knowledge':15,'energy':5},[effect('flag','facility_studied')],fids[4],60)],True)
arc_event(fids[1],'facility','El sello y la memoria','La entrada permanece cerrada y señalizada. El riesgo inmediato cede; el conocimiento del lugar no desaparece.',{'flags':['facility_closed']},[option('record','Conservar el protocolo',{},[normalized('environment',8),normalized('morale',6),effect('flag','facility_safe')])])
arc_event(fids[2],'facility','Las piezas de la bóveda','El desmontaje termina. El núcleo deja de emitir, pero sus piezas sostendrán talleres y reparaciones.',{'flags':['facility_dismantled']},[option('reuse','Distribuir los materiales',{},[normalized('metal',60),normalized('tools',15),effect('flag','facility_scrapped')])])
arc_event(fids[3],'facility','El laboratorio de dos pueblos','Una comisión vecina acepta custodiar la sala y compartir los informes. Ninguna ciudad controla ya todo el descubrimiento.',{'flags':['facility_shared']},[option('pact','Firmar el protocolo común',{},[normalized('relation',30),normalized('knowledge',45),effect('flag','facility_pact')])])
arc_event(fids[4],'facility','La corriente y el pulso','El núcleo entrega energía, pero su control conserva dos circuitos: uno local y otro orientado hacia el cielo.',{'flags':['facility_studied']},[option('local','Aislar el circuito exterior',{'tools':5},[normalized('health',-3)],fids[5],90),option('signal','Escuchar el circuito exterior',{'energy':10},[normalized('knowledge',15)],fids[6],360)])
arc_event(fids[5],'facility','La ciudad encendida','El suministro atrae proyectos y trabajadores. La producción mejora, mientras las nuevas viviendas y la alimentación siguen siendo responsabilidad del gobierno.',{},[option('integrate','Integrar la energía',{},[normalized('energy',100),normalized('population',6),effect('flag','facility_power')])])
arc_event(fids[6],'facility','La respuesta del cielo','La señal recibe un eco estructurado. Su procedencia sigue siendo una hipótesis; traducirla abre relaciones, no una invasión inevitable.',{},[option('listen','Traducir con cautela',{'knowledge':20},[normalized('knowledge',60),effect('flag','contact_signal')],'visitors_opening',180),option('disconnect','Desconectar el enlace',{'tools':4},[normalized('energy',35),effect('flag','contact_refused')])],family='contact')
arcs.append({'id':'facility','title':'La instalación antigua','entryEvent':fids[0],'events':fids,'endings':[fids[1],fids[2],fids[3],fids[5],fids[6]],'family':None,'mechanicalOutcomes':['sello: entorno y moral','desmontaje: metal y herramientas','acceso: relaciones y conocimiento','estudio: energía y población','señal: contacto condicionado']})
# Sixteen parameterized templates are not counted as authored independent events.
templates=[]
for id,title,cat,parameter,cost,reward,base in [
('lost_pack','Carga extraviada','exploration','distance','food','tools',3),('ore_vein','Veta superficial','economy','depth','tools','metal',4),('crop_blight','Mancha en la cosecha','needs','severity','medicine','food',6),('water_exchange','Intercambio de cantimploras','relations','households','water','metal',8),('road_repair','Tramo hundido','economy','distance','stone','food',5),('guest_lesson','Lección de paso','technology','skill','food','knowledge',4),('roof_storm','Tejados tras la tormenta','environment','severity','wood','tools',5),('market_fair','Mercado estacional','relations','visitors','fiber','food',7),('ruin_survey','Plano de una ruina','exploration','depth','energy','knowledge',5),('border_mediation','Mediación entre rutas','politics','distance','food','metal',6),('clinic_supply','Pedido de la clínica','needs','households','fiber','medicine',5),('salvage_contract','Contrato de recuperación','economy','depth','tools','relics',2),('defense_drill','Maniobras compartidas','conflict','visitors','food','tools',4),('seed_exchange','Semillas viajeras','environment','households','water','food',6),('battery_repair','Celda averiada','technology','skill','metal','energy',5),('refuge_outpost','Refugio de caminantes','needs','distance','wood','food',5)]:
 templates.append({'id':id,'title':title,'category':cat,'parameter':{'name':parameter,'type':'integer','minimum':1,'maximum':8},'conditions':{'minPopulation':10},'options':[{'id':'fund','label':'Preparar la expedición','costs':{cost:{'base':base,'perUnit':2}},'effects':[{'type':'resource','resource':reward,'base':base*3,'perUnit':4}]},{'id':'pass','label':'Conservar las reservas','costs':{},'effects':[effect('morale',-2)]}],'cooldownDays':180})
pack={'schemaVersion':1,'id':'barrio.core','version':'2.0.0','language':'es','title':'BARRIO CERO: ERAS — Crónicas de reconstrucción','resources':[{'id':id,'name':name,'unit':unit,'use':use} for id,name,unit,use in resources],'biomes':[{'id':id,'name':name,'movementCost':movement,'fertility':fertility,'resources':res} for id,name,movement,fertility,res in biomes],'buildings':[{'id':id,'name':name,'costs':cost,'days':days,'workers':2,'effect':{'type':kind,'value':value},'requires':req} for id,name,cost,days,kind,value,req in buildings],'technologies':[{'id':id,'name':name,'requires':req,'knowledgeCost':cost,'effects':[{'type':'flag','value':'technology_'+id}]} for id,name,req,cost in techs],'traits':[{'id':id,'name':name,'modifier':{'policy':policy,'value':value}} for id,name,policy,value in traits],'profiles':[{'id':id,'name':name,'priorities':policy,'nameRoots':names} for id,name,policy,names in profiles],'characters':[{'id':'ana','name':'Ana','age':28,'occupation':'técnica','trait':'inventive','goal':'Recuperar energía sin repetir los errores antiguos.'},{'id':'leo','name':'Leo','age':24,'occupation':'explorador','trait':'bold','goal':'Conectar las comunidades sin borrar sus diferencias.'},{'id':'tito','name':'Tito','age':42,'occupation':'suministros','trait':'patient','goal':'Que ningún salto histórico olvide las reservas.'}],'families':[{'id':id,'name':name,'origin':origin,'scope':scope,'enabledByDefault':False} for id,name,origin,scope in [('contact','Contacto e invasiones','Señales y expediciones extraterrestres',['local','planetary']),('disaster','Desastres ambientales','Clima, terremotos y cauces',['local','regional']),('epidemic','Epidemias ficticias','Cultivos y agentes ficticios',['local','regional']),('scarcity','Crisis de recursos','Agotamiento y redes de suministro',['local','regional']),('political','Crisis políticas','Instituciones, agravios y disputas',['local','regional']),('autonomous','Sistemas autónomos','Software y máquinas antiguas',['local','planetary']),('transformation','Transformación diseñada','Biotecnología y cibernética explícitas',['local','regional']),('planetary','Amenazas planetarias','Restos orbitales y fenómenos astronómicos',['planetary'])]],'events':events,'arcs':arcs,'templates':templates}
def canonicalize(value):
 if isinstance(value,dict):return {({'fiber':'textiles','relics':'crystal'}.get(k,k)):canonicalize(v) for k,v in value.items()}
 if isinstance(value,list):return [canonicalize(v) for v in value]
 return {'fiber':'textiles','relics':'crystal'}.get(value,value) if isinstance(value,str) else value
# Declarative authoring source: runtime constants are generated from these same tables.
catalog=json.loads((ROOT/'content/catalog.json').read_text())
pack['technologies']=catalog['technologies']
pack['buildings']=catalog['buildings']
pack['biomes']=[{'id':id,'name':name,'movementCost':movement,'fertility':fertility,'resources':res} for id,name,movement,fertility,res in [('plain','Pradera',1,1.15,['food','fiber']),('forest','Bosque',2,1.0,['wood','medicine']),('desert','Desierto',3,.65,['stone','energy']),('mountain','Montaña',0,.6,['metal','stone']),('wetland','Humedal',3,1.1,['water','food']),('coast','Costa',0,.8,['water','relics'])]]
tech_alias={'craft':'engineering','forestry':'ecology','barter':'trade','archives':'education','roads':'logistics','engines':'industry','scientific_method':'science','solar':'electricity','hydroponics':'adaptation','astronomy':'orbital','translation':'xenology','symbiosis':'synthesis','distributed_minds':'computing','fortification':'masonry'}
for profile in pack['profiles']:
 profile['priorities']['research']=tech_alias.get(profile['priorities']['research'],profile['priorities']['research'])
# Environment is damage in the engine: protective measures reduce it.
for event in pack['events']:
 for o in event['options']:
  for fx in o['effects']:
   if fx['type']=='environment':fx['value']=-fx['value']

pack=canonicalize(pack)
def save(path,obj):
 path.parent.mkdir(parents=True,exist_ok=True)
 path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
save(ROOT/'assets/content/core.json',pack)
example={'schemaVersion':1,'id':'barrio.senderos','version':'2.0.0','language':'es','requires':{'barrio.core':'2.0.0'},'events':[{'id':'senderos_waystone','category':'exploration','title':'La piedra de los viajeros','body':'Un camino olvidado conserva señales. Restaurarlas puede reducir el aislamiento sin reclamar el territorio.','trigger':'director','location':'settlement','participants':['living_society'],'conditions':{'minDay':60,'resource_min':{'stone':10}},'baseProbability':.08,'repeatable':False,'cooldownDays':36000,'exclusionGroup':'senderos_waystone','deadlineDays':30,'options':[option('restore','Restaurar las marcas',{'stone':10},[normalized('relation',8),normalized('knowledge',6)]),option('ignore','Anotar y seguir',{},[normalized('knowledge',2)])]}]}
save(ROOT/'assets/content/example_pack.json',example)
manifest={'schemaVersion':1,'packages':[{'id':p['id'],'version':p['version'],'file':file,'sha256':hashlib.sha256((ROOT/'assets/content'/file).read_bytes()).hexdigest()} for p,file in [(pack,'core.json'),(example,'example_pack.json')]]}
save(ROOT/'assets/content/manifest.json',manifest)
lines=['# Inventario verificable','','Generado por `python3 tool/build_content.py`; el validador comprueba referencias y desenlaces.','','| Identificador | Categoría | Dependencias | Desenlaces / efectos |','|---|---|---|---|']
for e in pack['events']:
 ends='; '.join(o['id']+': '+', '.join(str(x) for x in o['effects'])+(' → '+','.join(f['eventId'] for f in o['followUps']) if o['followUps'] else '') for o in e['options'])
 lines.append('| '+e['id']+' | '+e['category']+' | '+json.dumps(e['conditions'],ensure_ascii=False)+' | '+ends+' |')
(ROOT/'CONTENT_INVENTORY.md').write_text('\n'.join(lines)+'\n')
print(f"Wrote {len(pack['events'])} events ({sum('arcId' not in e for e in pack['events'])} independent), {len(arcs)} arcs, {len(templates)} templates")
