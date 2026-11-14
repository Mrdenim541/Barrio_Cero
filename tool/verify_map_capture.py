#!/usr/bin/env python3
"""Reject premature API29/320x640 captures using the saved tile's ground color.

This checks terrain presence, not game behavior or artistic quality. A manual
review must still identify the date, settlement, buildings and camera framing.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--checkpoint', type=Path, required=True)
parser.add_argument('--positive', type=Path, nargs='+', required=True)
parser.add_argument('--negative', type=Path, nargs='+', required=True)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
world = json.loads(args.checkpoint.read_text())['payload']['world']
town = next(s for s in world['societies'] if s['id'] == world['controlledId'])
biome = world['tiles'][town['y'] * world['size'] + town['x']]['biome']
ground = [(130, 147, 101), (101, 126, 88), (182, 156, 108),
          (133, 136, 123), (116, 140, 119), (108, 133, 128)][biome]
crop = (8, 95, 260, 230)
records, positives = [], []
for expected, paths in [(True, args.positive), (False, args.negative)]:
    for path in paths:
        with Image.open(path) as source:
            if source.size != (320, 640):
                raise ValueError('This fixture crop requires an actual 320x640 capture')
            image = source.convert('RGB').crop(crop)
        histogram = image.getcolors(100000)
        terrain_pixels = sum(count for count, color in histogram
                             if max(abs(color[i] - ground[i]) for i in range(3)) <= 14)
        present = len(histogram) > 100 and terrain_pixels > 3000
        records.append({'path': str(path), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                        'terrainPixels': terrain_pixels, 'uniqueColors': len(histogram),
                        'terrainPresent': present, 'expectedTerrain': expected,
                        'passed': present == expected})
        if expected:
            positives.append(image)
camera_difference = None
if len(positives) == 2:
    histogram = ImageChops.difference(*positives).getcolors(100000)
    camera_difference = sum(count for count, color in histogram if max(color) > 5)
report = {'scope': 'Terrain presence on declared API29 capture crop; not complete visual/game acceptance',
          'checkpointSha256': hashlib.sha256(args.checkpoint.read_bytes()).hexdigest(),
          'biome': biome, 'groundColor': ground, 'crop': crop,
          'captures': records, 'changedPixelsBetweenApprovedFrames': camera_difference,
          'passed': all(r['passed'] for r in records) and
                    (camera_difference is None or camera_difference > 2000)}
args.output.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
raise SystemExit(0 if report['passed'] else 1)
