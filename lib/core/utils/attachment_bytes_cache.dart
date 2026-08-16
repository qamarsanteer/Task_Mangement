import 'dart:typed_data';

/// كاش بالذاكرة فقط (Session-only) لمحتوى الملفات يلي المستخدم اختارها
/// كمرفقات. بما إنه التطبيق حالياً شغال بـ Mock Data (بدون سيرفر حقيقي)،
/// ما في مكان نخزن فيه المحتوى الفعلي للملف غير الذاكرة — بالـ Cache
/// المحلي (SharedPreferences) منخزن بس *اسم* الملف كنص، مش محتواه.
///
/// يعني: طول ما التطبيق مفتوح بنفس التبويب، فتح/معاينة المرفق رح يشتغل
/// عادي. لو صار Refresh للصفحة أو قفلتي التطبيق وفتحتيه من جديد، المحتوى
/// الفعلي بيضيع (بيضل بس اسم الملف محفوظ)، وهاد طبيعي بمرحلة الـ Mock —
/// بالسيرفر الحقيقي المستقبلي رح يترجع رابط دائم قابل للفتح بأي وقت.
class AttachmentBytesCache {
  AttachmentBytesCache._();
  static final AttachmentBytesCache instance = AttachmentBytesCache._();

  final Map<String, Uint8List> _bytesByKey = {};

  void put(String key, Uint8List bytes) => _bytesByKey[key] = bytes;

  Uint8List? get(String key) => _bytesByKey[key];

  bool has(String key) => _bytesByKey.containsKey(key);
}
