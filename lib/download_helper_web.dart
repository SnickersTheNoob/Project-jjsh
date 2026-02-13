import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> saveBytesAsFile(Uint8List bytes, String filename) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Try anchor download first
    try {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (_) {
      // If anchor click is blocked, fallback to opening in new tab
      try {
        html.window.open(url, '_blank');
        html.Url.revokeObjectUrl(url);
        return true;
      } catch (e) {
        html.Url.revokeObjectUrl(url);
        return false;
      }
    }
  } catch (_) {
    return false;
  }
}