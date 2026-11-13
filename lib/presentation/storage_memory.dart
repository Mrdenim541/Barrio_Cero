// Browser preview is volatile; Android uses atomic local files.
class SaveStore {
  static final Map<String, String> _values = {};
  Future<void> write(String slot, String value) async {
    if (_values.containsKey(slot)) _values['$slot.backup'] = _values[slot]!;
    _values[slot] = value;
  }
  Future<String?> read(String slot, {bool backup = false}) async => _values[backup ? '$slot.backup' : slot];
}
