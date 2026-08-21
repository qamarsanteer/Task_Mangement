import 'dart:typed_data';

class AttachmentBytesCache {
  AttachmentBytesCache._();
  static final AttachmentBytesCache instance = AttachmentBytesCache._();

  final Map<String, Uint8List> _bytesByKey = {};

  void put(String key, Uint8List bytes) => _bytesByKey[key] = bytes;

  Uint8List? get(String key) => _bytesByKey[key];

  bool has(String key) => _bytesByKey.containsKey(key);
}
