import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';

/// يعرض bottom sheet لاختيار مصدر الصورة (كاميرا/معرض)
/// ويرجع الملف المختار، أو null لو المستخدم ألغى
Future<XFile?> showImageSourcePicker(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final picker = ImagePicker();

  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.choosePhoto, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null) return null;

  return picker.pickImage(source: source, imageQuality: 80, maxWidth: 1080);
}