#!/usr/bin/env python3
"""Package an already validated Android artifact; never builds or publishes it."""
import argparse
import hashlib
import json
import shutil
import zipfile
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--apk', type=Path, required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--out', type=Path, required=True)
args = parser.parse_args()
assert all(c in '0123456789.' for c in args.version), 'Numeric version required'
args.out.mkdir(parents=True, exist_ok=False)
name = f'Barrio-Cero-Eras-{args.version}'
apk = args.out / (name + '.apk')
shutil.copyfile(args.apk, apk)
apk_hash = hashlib.sha256(apk.read_bytes()).hexdigest()
readme = f'''BARRIO CERO: ERAS {args.version} — versión de pruebas

1. Termina de descargar el ZIP y elige Extraer en el gestor de archivos.
2. Abre {apk.name}, que está dentro del ZIP, y pulsa Instalar.
3. Si Android lo pide, permite instalar aplicaciones desde ese gestor de archivos.

Requiere Android 7 o posterior. APK universal: ARM32, ARM64 y x86_64.
Puedes actualizar la versión anterior sin desinstalarla; conserva tus partidas.
Por precaución, exporta una copia de tu historia antes de actualizar.

Novedades: recorridos guardados de habitantes, equipos de trabajo animados,
Construir y Explorar visibles, y saltos con mapa actualizado durante el cálculo.
Pulsa Jugar para iniciar la vida del mundo. Tus intervenciones no detienen
la autonomía de las sociedades. Los saltos conservan reglas diarias; todavía
no se garantiza un siglo en cinco segundos en el teléfono.
Para ver continentes de la receta nueva, crea otra partida; los mundos antiguos
conservan su terreno. Para consultar actividad, toca el nombre de la comunidad
y después Ver actividad. Avanza un día para obtener la primera jornada.

El juego continúa en desarrollo: esta entrega no completa todos los hitos.
No incluye publicidad, cuentas ni conexión obligatoria para jugar.
SHA-256 del APK: {apk_hash}
'''
(args.out / 'LEE-PRIMERO.txt').write_text(readme, encoding='utf-8')
(args.out / 'SHA256SUMS.txt').write_text(f'{apk_hash}  {apk.name}\n')
archive = args.out / (name + '.zip')
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for path in [apk, args.out / 'LEE-PRIMERO.txt', args.out / 'SHA256SUMS.txt']:
        z.write(path, path.name)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert hashlib.sha256(z.read(apk.name)).hexdigest() == apk_hash
record = {'version': args.version, 'apk': apk.name, 'apkBytes': apk.stat().st_size,
          'apkSha256': apk_hash, 'zip': archive.name, 'zipBytes': archive.stat().st_size,
          'zipSha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
          'zipCrcPassed': True, 'innerApkMatches': True}
(args.out / 'package.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record, indent=2))
