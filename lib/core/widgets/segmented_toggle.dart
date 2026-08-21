import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SegmentedToggle extends StatelessWidget {
  final String? label;
  final String trueLabel;
  final String falseLabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  const SegmentedToggle({
    super.key,
    this.label,
    required this.trueLabel,
    required this.falseLabel,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? AppColors.primary;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(child: _segment(context, text: trueLabel, selected: value, color: color, onTap: () => onChanged(true), isStart: true, isDark: isDark)),
              Expanded(child: _segment(context, text: falseLabel, selected: !value, color: color, onTap: () => onChanged(false), isStart: false, isDark: isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(
    BuildContext context, {
    required String text,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    required bool isStart,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isStart ? const Radius.circular(9) : Radius.zero,
        right: !isStart ? const Radius.circular(9) : Radius.zero,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isStart ? const Radius.circular(9) : Radius.zero,
            right: !isStart ? const Radius.circular(9) : Radius.zero,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
