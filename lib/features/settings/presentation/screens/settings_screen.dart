import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/bloc/theme/theme_bloc.dart';
import '../../../../core/bloc/theme/theme_event.dart';
import '../../../../core/bloc/theme/theme_state.dart';
import '../../../bin/presentation/screens/bin_screen.dart';
import '../../../../core/bloc/locale/locale_bloc.dart';
import '../../../../core/bloc/locale/locale_event.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preferencesSectionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Theme Toggle
              BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, themeState) {
                  return _buildSettingTile(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    title: l10n.darkMode,
                    subtitle: l10n.darkModeSubtitle,
                    trailing: Switch.adaptive(
                      value: themeState.isDarkMode,
                      onChanged: (value) {
                        context.read<ThemeBloc>().add(const ThemeToggled());
                      },
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Language Selector
              _buildSettingTile(
                context: context,
                icon: Icons.language_outlined,
                title: l10n.language,
                subtitle: l10n.localeName == 'ar' ? l10n.arabic : l10n.english,
                onTap: () => _showLanguageDialog(context, l10n),
              ),

              const SizedBox(height: 12),

              // Bin
              _buildSettingTile(
                context: context,
                icon: Icons.delete_outline,
                title: l10n.bin,
                subtitle: l10n.deletedTasks,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BinScreen()),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                l10n.aboutSectionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              _buildSettingTile(
                context: context,
                icon: Icons.info_outline,
                title: l10n.about,
                subtitle: l10n.appVersionLabel,
                onTap: () => _showAboutDialog(context, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇬🇧'),
              title: Text(l10n.english),
              onTap: () {
                context.read<LocaleBloc>().add(const LocaleChanged(Locale('en')));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦'),
              title: Text(l10n.arabic),
              onTap: () {
                context.read<LocaleBloc>().add(const LocaleChanged(Locale('ar')));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(l10n.about),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.task_alt,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appTagline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.appVersionLabel,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}