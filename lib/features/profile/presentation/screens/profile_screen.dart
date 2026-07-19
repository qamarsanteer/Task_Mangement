import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/custom_button.dart';
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
                        _buildInfoRow(context, Icons.person_outline, l10n.fullName, user?.fullName ?? '-'),
                        const Divider(height: 32),
                        _buildInfoRow(context, Icons.email_outlined, l10n.email, user?.email ?? '-'),
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

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.logOutTitle),
        content: Text(l10n.areYouSureLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
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
      ],
    );
  }
}