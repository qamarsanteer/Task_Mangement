import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

enum AttachmentDownloadResult { saved, cancelled, failed }


Future<AttachmentDownloadResult> downloadAttachmentBytes({
  required String fileName,
  required Uint8List bytes,
}) async {
  try {
    final savedPath = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: bytes,
    );
    return savedPath == null ? AttachmentDownloadResult.cancelled : AttachmentDownloadResult.saved;
  } catch (_) {
    return AttachmentDownloadResult.failed;
  }
}