import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class AtlasLayout {
  final int tileWidth, tileHeight, columns, pixelWidth, pixelHeight;
  final String pixels;
  final List<String> ids, roles, actions;
  AtlasLayout._(
    this.tileWidth,
    this.tileHeight,
    this.columns,
    this.pixelWidth,
    this.pixelHeight,
    this.pixels,
    this.ids,
    this.roles,
    this.actions,
  );
  factory AtlasLayout.fromJson(Map<String, dynamic> raw) {
    final numbers = [
      'tileWidth',
      'tileHeight',
      'columns',
      'pixelWidth',
      'pixelHeight',
    ];
    if (numbers.any((k) => raw[k] is! int || raw[k] < 1 || raw[k] > 8192) ||
        raw['pixelDataFile'] is! String ||
        !RegExp(r'^[a-z][a-z0-9_]*\.rgba$').hasMatch(raw['pixelDataFile']) ||
        raw['pixelFormat'] != 'premultipliedRGBA8888' ||
        raw['pixelWidth'] != raw['columns'] * raw['tileWidth'] ||
        raw['pixelHeight'] % raw['tileHeight'] != 0 ||
        raw['pixelWidth'] * raw['pixelHeight'] > 8000000) {
      throw const FormatException('Manifiesto de atlas inválido');
    }
    List<String> names(String key) {
      final values = raw[key] ?? <dynamic>[];
      if (values is! List ||
          values.any((v) => v is! String || v.isEmpty) ||
          values.toSet().length != values.length) {
        throw const FormatException('Índices de atlas inválidos');
      }
      return List.unmodifiable(values.cast<String>());
    }

    final ids = names('ids'),
        roles = names('roles'),
        actions = names('actions');
    final rows = raw['pixelHeight'] ~/ raw['tileHeight'];
    if (ids.length > rows * raw['columns'] ||
        roles.length * actions.length > rows) {
      throw const FormatException('Sprites fuera de su atlas');
    }
    return AtlasLayout._(
      raw['tileWidth'],
      raw['tileHeight'],
      raw['columns'],
      raw['pixelWidth'],
      raw['pixelHeight'],
      raw['pixelDataFile'],
      ids,
      roles,
      actions,
    );
  }
  ui.Rect cell(int row, int column) {
    if (row < 0 ||
        column < 0 ||
        column >= columns ||
        (row + 1) * tileHeight > pixelHeight) {
      throw const FormatException('Fotograma fuera del atlas');
    }
    return ui.Rect.fromLTWH(
      column * tileWidth.toDouble(),
      row * tileHeight.toDouble(),
      tileWidth.toDouble(),
      tileHeight.toDouble(),
    );
  }

  ui.Rect? frame(String id) {
    final index = ids.indexOf(id);
    return index < 0 ? null : cell(index ~/ columns, index % columns);
  }
}

/// AssetBundle may return a view into a larger platform message buffer.
/// Decode only the asset's bytes, including its offset and length.
Future<ui.Image> loadArtImage(AssetBundle bundle, String path) async {
  final data = await bundle.load(path);
  final codec = await ui.instantiateImageCodec(Uint8List.sublistView(data));
  try {
    final image = (await codec.getNextFrame()).image;
    return image;
  } catch (error) {
    throw FormatException('No se pudo decodificar $path: $error');
  } finally {
    codec.dispose();
  }
}

/// Uploads the original atlas pixels without a platform compressed-image codec.
Future<ui.Image> loadArtPixels(
  AssetBundle bundle,
  String path,
  int width,
  int height,
) async {
  final data = await bundle.load(path);
  if (width <= 0 || height <= 0 || data.lengthInBytes != width * height * 4) {
    throw FormatException('Dimensiones del atlas no válidas: $path');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    Uint8List.sublistView(data),
  );
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: width,
    height: height,
    rowBytes: width * 4,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  try {
    final codec = await descriptor.instantiateCodec();
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  } finally {
    descriptor.dispose();
    buffer.dispose();
  }
}
