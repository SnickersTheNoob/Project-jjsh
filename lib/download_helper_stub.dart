import 'dart:typed_data';

Future<bool> saveBytesAsFile(Uint8List bytes, String filename) async {
  // No-op on non-web builds. Caller should fallback to platform-specific save.
  return false;
}