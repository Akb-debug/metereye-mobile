import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class ErrorMessageWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onDismiss;

  const ErrorMessageWidget({
    super.key,
    this.errorMessage,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.alertRed,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF991B1B),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
