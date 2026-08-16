import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// أداة لاستخراج نص/بيانات قابلة للقراءة من ملفات Office Open XML
/// (Word .docx، PowerPoint .pptx، Excel .xlsx). هاي الصيغ الثلاثة
/// أصلاً عبارة عن أرشيف ZIP فيه ملفات XML جوا، فمنقدر نستخرج منها
/// المحتوى بدون أي مكتبة متخصصة "تفتح" ملفات Office فعلياً —
/// يعني بدون تنسيقات/صور/جداول متقدمة، بس نص وبيانات خام قابلة
/// للقراءة والنسخ داخل التطبيق.
///
/// **مطلوب إضافة هاد الاعتمادين لـ pubspec.yaml إذا مش موجودين أصلاً:**
/// ```yaml
/// dependencies:
///   archive: ^3.6.1
///   xml: ^6.5.0
/// ```
class OfficeDocumentExtractor {
  OfficeDocumentExtractor._();

  /// بيرجع النص الكامل لملف Word (.docx)، فقرة بفقرة.
  static String extractDocx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentFile = _findFile(archive, 'word/document.xml');
    if (documentFile == null) {
      throw const FormatException('word/document.xml غير موجود — الملف مش .docx صالح.');
    }
    final document = XmlDocument.parse(utf8.decode(documentFile.content as List<int>));

    final buffer = StringBuffer();
    for (final paragraph in document.findAllElements('w:p')) {
      final line = paragraph.findAllElements('w:t').map((t) => t.innerText).join();
      buffer.writeln(line);
    }
    return buffer.toString().trim();
  }

  /// بيرجع نص كل سلايد بملف PowerPoint (.pptx)، مرتّبة حسب رقم السلايد.
  static String extractPptx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final slideFiles = archive.files
        .where((f) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name))
        .toList()
      ..sort((a, b) => _slideIndex(a.name).compareTo(_slideIndex(b.name)));

    if (slideFiles.isEmpty) {
      throw const FormatException('ما في سلايدات جوا الملف — مش .pptx صالح.');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < slideFiles.length; i++) {
      final document = XmlDocument.parse(utf8.decode(slideFiles[i].content as List<int>));
      final text = document.findAllElements('a:t').map((t) => t.innerText).join(' ');
      buffer.writeln('── سلايد ${i + 1} ──');
      buffer.writeln(text.trim().isEmpty ? '(بدون نص)' : text.trim());
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  /// بيرجع أول Sheet بملف Excel (.xlsx) كجدول صفوف/أعمدة نصّية — بدون
  /// صيغ (formulas) محسوبة أو تنسيقات، بس القيم الظاهرة/الخام.
  static List<List<String>> extractXlsxFirstSheet(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    // الإكسل بيخزّن النصوص المتكررة بجدول مشترك (sharedStrings.xml)
    // وبيرجّع بالخلية بس رقم index إلها جوا هداك الجدول.
    final sharedStrings = <String>[];
    final sharedStringsFile = _findFile(archive, 'xl/sharedStrings.xml');
    if (sharedStringsFile != null) {
      final doc = XmlDocument.parse(utf8.decode(sharedStringsFile.content as List<int>));
      for (final si in doc.findAllElements('si')) {
        sharedStrings.add(si.findAllElements('t').map((t) => t.innerText).join());
      }
    }

    final sheetFile = _findFile(archive, 'xl/worksheets/sheet1.xml');
    if (sheetFile == null) {
      throw const FormatException('xl/worksheets/sheet1.xml غير موجود — الملف مش .xlsx صالح.');
    }
    final sheetDoc = XmlDocument.parse(utf8.decode(sheetFile.content as List<int>));

    final rows = <List<String>>[];
    for (final row in sheetDoc.findAllElements('row')) {
      final cells = <String>[];
      for (final cell in row.findAllElements('c')) {
        final type = cell.getAttribute('t');
        final valueElements = cell.findElements('v');
        final rawValue = valueElements.isNotEmpty ? valueElements.first.innerText : '';
        if (type == 's' && rawValue.isNotEmpty) {
          final index = int.tryParse(rawValue);
          cells.add(index != null && index < sharedStrings.length ? sharedStrings[index] : '');
        } else {
          cells.add(rawValue);
        }
      }
      rows.add(cells);
    }
    return rows;
  }

  static ArchiveFile? _findFile(Archive archive, String name) {
    for (final f in archive.files) {
      if (f.name == name) return f;
    }
    return null;
  }

  static int _slideIndex(String name) {
    final match = RegExp(r'slide(\d+)\.xml$').firstMatch(name);
    return match != null ? int.parse(match.group(1)!) : 0;
  }
}