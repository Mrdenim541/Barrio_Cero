import 'dart:ui' as ui;

import 'package:flutter/services.dart';

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
Future<ui.Image> loadArtPixels(AssetBundle bundle, String path, int width, int height) async {
  final data = await bundle.load(path);
  if (width <= 0 || height <= 0 || data.lengthInBytes != width * height * 4) {
    throw FormatException('Dimensiones del atlas no válidas: $path');
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(Uint8List.sublistView(data));
  final descriptor = ui.ImageDescriptor.raw(buffer, width: width, height: height,
    rowBytes: width * 4, pixelFormat: ui.PixelFormat.rgba8888);
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
