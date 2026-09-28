import 'package:flutter/material.dart';

class ResultOverlay extends StatelessWidget {
  final bool wasCorrect;
  final String countryName;
  final int pointsEarned;
  final VoidCallback onNext;

  const ResultOverlay({
    super.key,
    required this.wasCorrect,
    required this.countryName,
    required this.pointsEarned,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            wasCorrect ? Icons.check_circle : Icons.cancel,
            size: 64,
            color: wasCorrect ? Colors.green : colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            wasCorrect ? 'Correct!' : 'Out of tries!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: wasCorrect ? Colors.green : colorScheme.error,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            countryName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (wasCorrect)
            Text(
              '+$pointsEarned points',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
            )
          else
            Text(
              'No points awarded',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                  ),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Next Flag'),
          ),
        ],
      ),
    );
  }
}
