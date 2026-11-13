import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android document picker. Cancellation is null; failures never masquerade as a
/// successful export. Returned imported text still needs save/content validation.
class DocumentExchange {
  DocumentExchange({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.barriocero.eras/documents');

  static const maxBytes = 25000000;
  final MethodChannel _channel;
  bool _busy = false;

  bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String?> exportDocument({
    required String text,
    String suggestedName = 'barrio-cero.json',
  }) async {
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('El documento supera 25 MB.');
    }
    return _invoke('exportDocument', {'text': text, 'suggestedName': suggestedName});
  }

  Future<String?> importDocument() => _invoke('importDocument');

  Future<String?> _invoke(String method, [Map<String, Object?>? arguments]) async {
    if (!supported) {
      throw UnsupportedError('El selector de documentos está disponible en Android.');
    }
    if (_busy) {
      throw PlatformException(code: 'document_busy', message: 'Ya hay un intercambio en curso.');
    }
    _busy = true;
    try {
      return await _channel.invokeMethod<String>(method, arguments);
    } finally {
      _busy = false;
    }
  }
}
