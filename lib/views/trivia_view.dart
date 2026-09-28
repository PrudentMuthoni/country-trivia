import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/trivia_viewmodel.dart';
import '../views/widgets/answer_button.dart';
import '../views/widgets/flag_display.dart';
import '../views/widgets/result_overlay.dart';
import '../views/widgets/score_header.dart';

class TriviaView extends StatelessWidget {
  const TriviaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Country Trivia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Game',
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Consumer<TriviaViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.lastError != null) {
            return _ErrorView(
              error: vm.lastError!,
              onRetry: () => vm.init(),
            );
          }

          if (vm.allSolved) {
            return _AllSolvedView(
              score: vm.score,
              total: vm.totalCountries,
              onReset: () => vm.resetGame(),
            );
          }

          return Column(
            children: [
              ScoreHeader(
                score: vm.score,
                solvedCount: vm.solvedCount,
                totalCountries: vm.totalCountries,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (vm.correctCountry != null)
                        FlagDisplay(isoCode: vm.correctCountry!.isoCode),
                      const SizedBox(height: 24),
                      Text(
                        'Which country does this flag belong to?',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ...vm.options.map((country) {
                        final isCorrect = vm.roundOver &&
                            country.isoCode == vm.correctCountry?.isoCode;
                        final isWrong = vm.wrongAnswers.contains(country.isoCode);
                        final isDisabled = vm.roundOver || isWrong;

                        AnswerState state;
                        if (isCorrect) {
                          state = AnswerState.correct;
                        } else if (isWrong) {
                          state = AnswerState.wrong;
                        } else if (isDisabled) {
                          state = AnswerState.disabled;
                        } else {
                          state = AnswerState.idle;
                        }

                        return AnswerButton(
                          text: country.name,
                          state: state,
                          onTap: () => vm.answer(country.isoCode),
                        );
                      }),
                      if (vm.roundOver) ...[
                        const SizedBox(height: 16),
                        ResultOverlay(
                          wasCorrect: vm.wrongAnswers.length < 3 &&
                              vm.attempts < 3 &&
                              vm.options.any(
                                  (o) => o.isoCode == vm.correctCountry?.isoCode),
                          countryName: vm.correctCountry?.name ?? '',
                          pointsEarned: vm.attempts < 3
                              ? [10, 8, 5][vm.attempts]
                              : 0,
                          onNext: () => vm.nextQuestion(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Game?'),
        content: const Text(
          'This will clear your score and all solved flags. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<TriviaViewModel>().resetGame();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllSolvedView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onReset;

  const _AllSolvedView({
    required this.score,
    required this.total,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'You have solved all $total flags!',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Final Score: $score points',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
