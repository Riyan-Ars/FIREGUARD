import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class EditorialCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;

  const EditorialCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor = AppColors.pureWhite,
    this.borderColor = AppColors.borderSubtle,
    this.borderWidth = 1.0,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              splashColor: AppColors.primaryForest.withValues(alpha: 0.06),
              highlightColor: AppColors.primaryForest.withValues(alpha: 0.03),
              child: Padding(
                padding: padding,
                child: child,
              ),
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );
  }
}
