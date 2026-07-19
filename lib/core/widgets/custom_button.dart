import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final Widget? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: backgroundColor ?? theme.colorScheme.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                foregroundColor: textColor ?? theme.colorScheme.primary,
              ),
              child: _buildChild(theme),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? theme.colorScheme.primary,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _buildChild(theme),
            ),
    );
  }

  Widget _buildChild(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(isOutlined ? theme.colorScheme.primary : Colors.white),
        ),
      );
    }
    if (icon != null) {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon!,
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor ?? (isOutlined ? theme.colorScheme.primary : Colors.white))),
      ]);
    }
    return Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor ?? (isOutlined ? theme.colorScheme.primary : Colors.white)));
  }
}
