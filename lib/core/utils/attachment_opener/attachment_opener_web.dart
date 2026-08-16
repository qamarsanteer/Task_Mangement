// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'dart:html' as html;

/// نتيجة محاولة تحميل/حفظ المرفق، حتى الشاشة تقدر تعرض رسالة مناسبة
/// لكل حالة (نجاح / المستخدم ألغى / فشل فعلي).
enum AttachmentDownloadResult { saved, cancelled, failed }

/// نسخة الويب: بدل ما نفتح الملف بتاب جديد (اللي كان بيخلي المتصفح
/// ينزّله مباشرة لأنواع كتير من الملفات زي docx/xlsx، أو يفتحه بره
/// التطبيق للصور/الـ PDF) — هلق منعمل تحميل صريح فقط عند ما المستخدم
/// يضغط زر "تحميل" تحديداً، عن طريق عنصر <a download> مخفي. هيك
/// المعاينة جوا التطبيق (AttachmentPreviewScreen) صارت منفصلة تماماً
/// عن فعل التحميل نفسه.
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