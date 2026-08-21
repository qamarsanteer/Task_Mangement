import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/image_source_picker.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import '../../../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          final isUpdatingPhoto = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: user == null ? null : () => _changePhoto(context, user.id),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(color: AppColors.primary, blurRadius: 20, offset: Offset(0, 10)),
                            ],
                            image: _resolvePhotoImage(user?.photoUrl),
                          ),
                          child: isUpdatingPhoto
                              ? const Center(child: CircularProgressIndicator(color: Colors.white))
                              : (user?.photoUrl == null
                                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                                  : null),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // الاسم — بس أيقونة القلم بتفتح التعديل
                        _buildInfoRow(
                          context: context,
                          l10n: l10n,
                          icon: Icons.person_outline,
                          label: l10n.fullName,
                          value: user?.fullName ?? '-',
                          onEdit: user != null
                              ? () => _showEditNameDialog(context, l10n, user.id, user.fullName, user.email)
                              : null,
                        ),
                        const Divider(height: 32),
                        // الإيميل — بس أيقونة القلم بتفتح التعديل
                        _buildInfoRow(
                          context: context,
                          l10n: l10n,
                          icon: Icons.email_outlined,
                          label: l10n.email,
                          value: user?.email ?? '-',
                          onEdit: user != null
                              ? () => _showEditEmailDialog(context, l10n, user.id, user.fullName, user.email)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: l10n.logout,
                    isOutlined: true,
                    backgroundColor: AppColors.error,
                    textColor: AppColors.error,
                    onPressed: () => _confirmLogout(context, l10n),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  DecorationImage? _resolvePhotoImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;

    final isLocalFile = !photoUrl.startsWith('http');
    return DecorationImage(
      image: isLocalFile ? FileImage(File(photoUrl)) as ImageProvider : NetworkImage(photoUrl),
      fit: BoxFit.cover,
    );
  }

  Future<void> _changePhoto(BuildContext context, String userId) async {
    final pickedFile = await showImageSourcePicker(context);
    if (pickedFile != null && context.mounted) {
      context.read<AuthBloc>().add(
        PhotoUploadRequested(userId: userId, photoPath: pickedFile.path),
      );
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    AppLocalizations l10n,
    String userId,
    String currentName,
    String currentEmail,
  ) {
    final nameController = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editName),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: nameController,
            label: l10n.fullName,
            hint: l10n.enterFullName,
            prefixIcon: const Icon(Icons.person_outline),
            autofocus: true,
            validator: (value) => value == null || value.trim().isEmpty ? l10n.requiredField : null,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(UpdateProfileRequested(
                  userId: userId,
                  fullName: nameController.text.trim(),
                  email: currentEmail,
                ));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.save),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showEditEmailDialog(
    BuildContext context,
    AppLocalizations l10n,
    String userId,
    String currentName,
    String currentEmail,
  ) {
    final emailController = TextEditingController(text: currentEmail);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editEmail),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: emailController,
            label: l10n.email,
            hint: l10n.enterEmail,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.requiredField;
              if (!value.contains('@')) return l10n.invalidEmail;
              return null;
            },
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthBloc>().add(UpdateProfileRequested(
                  userId: userId,
                  fullName: currentName,
                  email: emailController.text.trim(),
                ));
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text(l10n.save),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logOutTitle),
        content: Text(l10n.areYouSureLogout),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.logout),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required AppLocalizations l10n,
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: Icon(
              Icons.edit,
              size: 20,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: onEdit,
            tooltip: l10n.editProfile,
          ),
      ],
    );
  }
}