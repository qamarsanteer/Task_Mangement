import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// نتيجة محاولة تحميل/حفظ المرفق، حتى الشاشة تقدر تعرض رسالة مناسبة
/// لكل حالة (نجاح / المستخدم ألغى / فشل فعلي).
enum AttachmentDownloadResult { saved, cancelled, failed }

/// نسخة الموبايل/الديسكتوب: منستخدم مربع حوار "حفظ باسم" من file_picker
/// (FilePicker.platform.saveFile) يلي بياخد الـ bytes مباشرة ويكتبها
/// بالمكان يلي المستخدم بيختارو — هيك ما محتاجين مكتبة إضافية (متل
/// open_filex أو path_provider) وبيضل المستخدم هو يلي يقرر وين بدو
/// يحفظ الملف.
///
/// ملاحظة: باراميتر `bytes` بـ saveFile مدعوم بدءاً من file_picker
/// الإصدار 8.1.0 تقريباً (وهو مطلوب لتشتغل الميزة عالموبايل، لأنه ما
/// في مسار Path مباشر نقدر نكتب عليه هناك). تأكدي إنه pubspec.yaml
/// عندك عالإصدار المناسب أو أحدث.
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