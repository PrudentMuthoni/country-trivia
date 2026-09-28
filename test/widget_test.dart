import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_trivia/models/country.dart';
import 'package:country_trivia/services/country_service.dart';
import 'package:country_trivia/services/storage_service.dart';
import 'package:country_trivia/viewmodels/trivia_viewmodel.dart';

class MockCountryService implements CountryService {
  @override
  Future<List<Country>> fetchCountries() async {
    return [
      const Country(name: 'United States', isoCode: 'US'),
      const Country(name: 'Canada', isoCode: 'CA'),
      const Country(name: 'Mexico', isoCode: 'MX'),
      const Country(name: 'Brazil', isoCode: 'BR'),
      const Country(name: 'Argentina', isoCode: 'AR'),
      const Country(name: 'France', isoCode: 'FR'),
      const Country(name: 'Germany', isoCode: 'DE'),
      const Country(name: 'Japan', isoCode: 'JP'),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TriviaViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    viewModel = TriviaViewModel(
      countryService: MockCountryService(),
      storageService: StorageService(),
    );
    await viewModel.init();
  });

  group('TriviaViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.score, 0);
      expect(viewModel.attempts, 0);
      expect(viewModel.roundOver, false);
      expect(viewModel.options.length, 4);
      expect(viewModel.correctCountry, isNotNull);
    });

    test('correct answer on first try awards 10 points', () {
      final correctIso = viewModel.correctCountry!.isoCode;
      viewModel.answer(correctIso);

      expect(viewModel.score, 10);
      expect(viewModel.roundOver, true);
      expect(viewModel.solvedCount, 1);
    });

    test('correct answer on second try awards 8 points', () {
      final correctIso = viewModel.correctCountry!.isoCode;
      final wrongIso = viewModel.options
          .firstWhere((o) => o.isoCode != correctIso)
          .isoCode;

      viewModel.answer(wrongIso);
      expect(viewModel.roundOver, false);
      expect(viewModel.attempts, 1);

      viewModel.answer(correctIso);
      expect(viewModel.score, 8);
      expect(viewModel.roundOver, true);
    });

    test('correct answer on third try awards 5 points', () {
      final correctIso = viewModel.correctCountry!.isoCode;
      final wrongIsos = viewModel.options
          .where((o) => o.isoCode != correctIso)
          .take(2)
          .map((o) => o.isoCode)
          .toList();

      viewModel.answer(wrongIsos[0]);
      viewModel.answer(wrongIsos[1]);
      expect(viewModel.roundOver, false);
      expect(viewModel.attempts, 2);

      viewModel.answer(correctIso);
      expect(viewModel.score, 5);
      expect(viewModel.roundOver, true);
    });

    test('three wrong answers awards 0 points and reveals answer', () {
      final correctIso = viewModel.correctCountry!.isoCode;
      final wrongIsos = viewModel.options
          .where((o) => o.isoCode != correctIso)
          .take(3)
          .map((o) => o.isoCode)
          .toList();

      viewModel.answer(wrongIsos[0]);
      viewModel.answer(wrongIsos[1]);
      viewModel.answer(wrongIsos[2]);

      expect(viewModel.score, 0);
      expect(viewModel.roundOver, true);
      expect(viewModel.solvedCount, 1);
    });

    test('tapping same wrong answer twice counts as one attempt', () {
      final correctIso = viewModel.correctCountry!.isoCode;
      final wrongIso = viewModel.options
          .firstWhere((o) => o.isoCode != correctIso)
          .isoCode;

      viewModel.answer(wrongIso);
      viewModel.answer(wrongIso);

      expect(viewModel.attempts, 1);
      expect(viewModel.roundOver, false);
    });

    test('solved countries are excluded from future questions', () {
      final firstCorrectIso = viewModel.correctCountry!.isoCode;
      viewModel.answer(firstCorrectIso);
      viewModel.nextQuestion();

      expect(viewModel.correctCountry?.isoCode, isNot(firstCorrectIso));
    });

    test('nextQuestion generates new options', () {
      final firstOptions = viewModel.options.map((o) => o.isoCode).toSet();
      viewModel.nextQuestion();
      final secondOptions = viewModel.options.map((o) => o.isoCode).toSet();

      expect(viewModel.options.length, 4);
      expect(viewModel.attempts, 0);
      expect(viewModel.roundOver, false);
      expect(secondOptions, isNot(same(firstOptions)));
    });

    test('resetGame clears score and solved flags', () async {
      final correctIso = viewModel.correctCountry!.isoCode;
      viewModel.answer(correctIso);
      expect(viewModel.score, 10);

      await viewModel.resetGame();
      expect(viewModel.score, 0);
      expect(viewModel.solvedCount, 0);
      expect(viewModel.roundOver, false);
    });

    test('persists score and solved flags', () async {
      final correctIso = viewModel.correctCountry!.isoCode;
      viewModel.answer(correctIso);

      final newViewModel = TriviaViewModel(
        countryService: MockCountryService(),
        storageService: StorageService(),
      );
      await newViewModel.init();

      expect(newViewModel.score, 10);
      expect(newViewModel.solvedCount, 1);
    });
  });
}
