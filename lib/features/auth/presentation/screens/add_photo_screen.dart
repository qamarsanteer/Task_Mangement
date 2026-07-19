import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/image_source_picker.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../../l10n/app_localizations.dart';

class AddPhotoScreen extends StatefulWidget {
  final UserEntity user;
  const AddPhotoScreen({super.key, required this.user});

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  l10n.addPhotoTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.addPhotoSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: _selectedImagePath != null
                        ? ClipOval(
                            child: Image.file(
                              File(_selectedImagePath!),
                              fit: BoxFit.cover,
                              width: 180,
                              height: 180,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.addPhoto,
                                style: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const Spacer(),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: _selectedImagePath != null ? l10n.continueText : l10n.addPhoto,
                      isLoading: state is AuthLoading,
                      onPressed: _selectedImagePath != null ? _uploadAndContinue : _pickImage,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  child: Text(
                    l10n.skip,
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await showImageSourcePicker(context);
    if (pickedFile != null) {
      setState(() => _selectedImagePath = pickedFile.path);
    }
  }

  void _uploadAndContinue() {
    if (_selectedImagePath != null) {
      context.read<AuthBloc>().add(
            PhotoUploadRequested(userId: widget.user.id, photoPath: _selectedImagePath!),
          );
    }
  }
}