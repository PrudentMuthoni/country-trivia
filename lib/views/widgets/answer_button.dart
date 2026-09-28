import 'package:flutter/material.dart';

enum AnswerState { idle, correct, wrong, disabled }

class AnswerButton extends StatelessWidget {
  final String text;
  final AnswerState state;
  final VoidCallback onTap;

  const AnswerButton({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    IconData? icon;

    switch (state) {
      case AnswerState.correct:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        borderColor = Colors.green;
        icon = Icons.check_circle;
      case AnswerState.wrong:
        backgroundColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        borderColor = colorScheme.error;
        icon = Icons.cancel;
      case AnswerState.disabled:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey;
        borderColor = Colors.grey[300]!;
        icon = null;
      case AnswerState.idle:
        backgroundColor = colorScheme.surface;
        textColor = colorScheme.onSurface;
        borderColor = colorScheme.outline;
        icon = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: state == AnswerState.idle ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
          side: BorderSide(color: borderColor),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
