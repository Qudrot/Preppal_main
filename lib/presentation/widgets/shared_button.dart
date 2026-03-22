import 'package:flutter/material.dart';
import 'package:prepal2/core/constants/app_colors.dart';

enum ButtonType { primary, secondary, tertiary }

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  final Color? backgroundColor;
  final Color? textColor;

  Color get _getBackgroundColor {
    if (backgroundColor != null) return backgroundColor!;
    if (onPressed == null && !isLoading) return AppColors.gray.withOpacity(0.5);
    switch (type) {
      case ButtonType.primary:
        return AppColors.secondary;
      case ButtonType.secondary:
        return AppColors.primary;
      case ButtonType.tertiary:
        return AppColors.white;
    }
  }

  Color get _getTextColor {
    if (textColor != null) return textColor!;
    switch (type) {
      case ButtonType.primary:
        return AppColors.white;
      case ButtonType.secondary:
        return AppColors.black;
      case ButtonType.tertiary:
        return AppColors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor,
          foregroundColor: _getTextColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: type == ButtonType.tertiary 
                ? const BorderSide(color: AppColors.gray) 
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: _getTextColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                     Icon(icon, size: 20),
                     const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
