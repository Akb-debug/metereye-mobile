import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[700],
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: Colors.red[700],
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}