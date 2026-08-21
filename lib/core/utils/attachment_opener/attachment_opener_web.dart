// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'dart:html' as html;

enum AttachmentDownloadResult { saved, cancelled, failed }

Future<AttachmentDownloadResult> downloadAttachmentBytes({
  required String fileName,
  required Uint8List bytes,
}) async {
  try {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return AttachmentDownloadResult.saved;
  } catch (_) {
    return AttachmentDownloadResult.failed;
  }
}