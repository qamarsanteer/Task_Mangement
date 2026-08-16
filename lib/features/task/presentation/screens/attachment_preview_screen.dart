import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/attachment_opener/attachment_opener.dart';
import '../../../../core/utils/office_document_extractor.dart';
import '../../../../l10n/app_localizations.dart';

/// شاشة معاينة مرفق واحد جوا التطبيق (بدل ما نفتحه بره التطبيق أو
/// ننزّله مباشرة بمجرد ما يضغط المستخدم عليه). المعاينة والتحميل هلق
/// فعلين منفصلين تماماً:
/// - الضغط على المرفق بالقائمة → بيفتح هاي الشاشة ويعرض المحتوى، لأكبر
///   عدد ممكن من أنواع الملفات (صور، نصوص، Word، PowerPoint، Excel،
///   PDF).
/// - زر "تحميل" الصريح بأعلى/أسفل الشاشة → هو الوحيد يلي بيحفظ/ينزّل
///   الملف فعلياً عالجهاز، وبيختار المستخدم مكان الحفظ بنفسه.
///
/// **ملاحظة مهمة عن الاعتماديات (packages):** معاينة Word/PowerPoint/
/// Excel هون مبنية على استخراج النص/الخلايا مباشرة من ملفات XML جوا
/// الأرشيف (بدون تنسيقات أو صور أو جداول متقدمة) عن طريق
/// `OfficeDocumentExtractor` (يحتاج: `archive` و `xml`). أما معاينة
/// PDF فبتحتاج مكتبة عرض حقيقية، فاستخدمت
/// `syncfusion_flutter_pdfviewer` (فيها رخصة مجانية Community License
/// لحد حجم شركة/إيرادات معيّن — تأكدي من شروطها إلها علاقة فيكي أو لا).
/// لازم تضيفي هاد الاعتماديات لـ pubspec.yaml:
/// ```yaml
/// dependencies:
///   archive: ^3.6.1
///   xml: ^6.5.0
///   syncfusion_flutter_pdfviewer: ^26.2.14
/// ```
/// (الأرقام تقريبية حسب معرفتي وقت كتابة هاد الكود — ما قدرت أتحقق من
/// pub.dev مباشرة، فتأكدي من آخر إصدار متوافق مع Flutter عندك بعد
/// `flutter pub get`، وصلّحي رقم الإصدار هون إذا لزم.)
class AttachmentPreviewScreen extends StatefulWidget {
  final String fileName;
  final Uint8List bytes;

  const AttachmentPreviewScreen({
    super.key,
    required this.fileName,
    required this.bytes,
  });

  @override
  State<AttachmentPreviewScreen> createState() => _AttachmentPreviewScreenState();
}

enum _PreviewKind { image, text, docx, pptx, xlsx, pdf, unsupported }

class _AttachmentPreviewScreenState extends State<AttachmentPreviewScreen> {
  bool _isDownloading = false;

  static const _imageExtensions = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'};
  static const _textExtensions = {'txt', 'md', 'json', 'csv', 'log', 'yaml', 'yml', 'xml'};

  String get _extension {
    final parts = widget.fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  _PreviewKind get _kind {
    final ext = _extension;
    if (_imageExtensions.contains(ext)) return _PreviewKind.image;
    if (_textExtensions.contains(ext)) return _PreviewKind.text;
    if (ext == 'docx') return _PreviewKind.docx;
    if (ext == 'pptx') return _PreviewKind.pptx;
    if (ext == 'xlsx') return _PreviewKind.xlsx;
    if (ext == 'pdf') return _PreviewKind.pdf;
    return _PreviewKind.unsupported;
  }

  Future<void> _download(AppLocalizations l10n) async {
    setState(() => _isDownloading = true);
    final result = await downloadAttachmentBytes(fileName: widget.fileName, bytes: widget.bytes);
    if (!mounted) return;
    setState(() => _isDownloading = false);

    final String message;
    final Color color;
    switch (result) {
      case AttachmentDownloadResult.saved:
        message = l10n.attachmentDownloadSuccess;
        color = AppColors.primary;
        break;
      case AttachmentDownloadResult.cancelled:
        message = l10n.attachmentDownloadCancelled;
        color = AppColors.textSecondaryLight;
        break;
      case AttachmentDownloadResult.failed:
        message = l10n.attachmentDownloadFailed;
        color = AppColors.error;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final kind = _kind;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: l10n.attachmentDownload,
            onPressed: _isDownloading ? null : () => _download(l10n),
          ),
        ],
      ),
      body: _buildBody(context, l10n, isDark, kind),
      // معاينة الـ PDF عندها شريط أدوات وتنقّل خاص فيها (SfPdfViewer)،
      // فمنخبي زر التحميل السفلي بحالتها حتى ما يتزاحم الاثنين، وبيضل
      // زر التحميل بالـ AppBar متوفر دايماً.
      bottomNavigationBar: kind == _PreviewKind.pdf
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : () => _download(l10n),
                icon: const Icon(Icons.download_outlined),
                label: Text(l10n.attachmentDownload),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, bool isDark, _PreviewKind kind) {
    switch (kind) {
      case _PreviewKind.image:
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Center(child: Image.memory(widget.bytes)),
        );

      case _PreviewKind.text:
        return _tryOrFallback(
          l10n,
          isDark,
          () => _buildSelectableText(utf8.decode(widget.bytes)),
        );

      case _PreviewKind.docx:
        return _tryOrFallback(
          l10n,
          isDark,
          () => _buildSelectableText(OfficeDocumentExtractor.extractDocx(widget.bytes)),
        );

      case _PreviewKind.pptx:
        return _tryOrFallback(
          l10n,
          isDark,
          () => _buildSelectableText(OfficeDocumentExtractor.extractPptx(widget.bytes)),
        );

      case _PreviewKind.xlsx:
        return _tryOrFallback(
          l10n,
          isDark,
          () => _buildSheetTable(OfficeDocumentExtractor.extractXlsxFirstSheet(widget.bytes), isDark),
        );

      case _PreviewKind.pdf:
        // SfPdfViewer.memory بيعرض الـ PDF فعلياً (كل الصفحات، مع تكبير
        // وتصفّح) — بدون ما نحتاج نستخرج نص يدوياً متل باقي الأنواع.
        return SfPdfViewer.memory(widget.bytes);

      case _PreviewKind.unsupported:
        return _buildUnsupportedFallback(context, l10n, isDark);
    }
  }

  /// بيحاول يبني ويجت المعاينة، ولو صار أي خطأ بالاستخراج (ملف تالف،
  /// صيغة غير متوقعة...) بيرجع لبطاقة "ما في معاينة" العامة بدل ما
  /// يوقّع التطبيق (crash) بشاشة بيضا.
  Widget _tryOrFallback(AppLocalizations l10n, bool isDark, Widget Function() builder) {
    try {
      return builder();
    } catch (_) {
      return _buildUnsupportedFallback(context, l10n, isDark);
    }
  }

  Widget _buildSelectableText(String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content.isEmpty ? '(الملف فاضي)' : content,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }

  Widget _buildSheetTable(List<List<String>> rows, bool isDark) {
    if (rows.isEmpty) {
      return Center(
        child: Text('(الشيت فاضي)', style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
      );
    }
    final columnCount = rows.map((r) => r.length).fold<int>(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: DataTable(
          // ignore: deprecated_member_use
          headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(0.1)),
          columns: List.generate(columnCount, (i) => DataColumn(label: Text('عمود ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)))),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: List.generate(
                    columnCount,
                    (i) => DataCell(Text(i < row.length ? row[i] : '')),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildUnsupportedFallback(BuildContext context, AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 72,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              widget.fileName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatSize(widget.bytes.length),
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.attachmentNoPreviewAvailable,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}