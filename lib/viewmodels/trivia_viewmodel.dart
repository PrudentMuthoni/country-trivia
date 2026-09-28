import 'package:flutter/foundation.dart';
import '../models/country.dart';
import '../services/country_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class TriviaViewModel extends ChangeNotifier {
  final CountryService _countryService;
  final StorageService _storageService;

  List<Country> _allCountries = [];
  Set<String> _solved = {};
  int _score = 0;
  int _attempts = 0;
  Country? _correctCountry;
  List<Country> _options = [];
  bool _roundOver = false;
  bool _isLoading = true;
  String? _lastError;
  Set<String> _wrongAnswers = {};

  TriviaViewModel({
    required CountryService countryService,
    required StorageService storageService,
  })  : _countryService = countryService,
        _storageService = storageService;

  int get score => _score;
  int get attempts => _attempts;
  Country? get correctCountry => _correctCountry;
  List<Country> get options => _options;
  bool get roundOver => _roundOver;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get solvedCount => _solved.length;
  int get totalCountries => _allCountries.length;
  Set<String> get wrongAnswers => _wrongAnswers;
  bool get allSolved => _allCountries.isNotEmpty && _solved.length >= _allCountries.length;

  Future<void> init() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _solved = await _storageService.loadSolved();
      _score = await _storageService.loadScore();
      _allCountries = await _countryService.fetchCountries();
      _generateQuestion();
    } catch (e) {
      _lastError = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _generateQuestion() {
    final available =
        _allCountries.where((c) => !_solved.contains(c.isoCode)).toList();
    if (available.isEmpty) {
      _correctCountry = null;
      _options = [];
      _roundOver = true;
      return;
    }

    available.shuffle();
    _correctCountry = available.first;

    final distractors = available
        .where((c) => c.isoCode != _correctCountry!.isoCode)
        .take(3)
        .toList();

    _options = [_correctCountry!, ...distractors]..shuffle();
    _attempts = 0;
    _wrongAnswers = {};
    _roundOver = false;
  }

  void answer(String isoCode) {
    if (_roundOver || _correctCountry == null) return;

    if (isoCode == _correctCountry!.isoCode) {
      _score += AppConstants.pointsPerTry[_attempts];
      _solved.add(_correctCountry!.isoCode);
      _storageService.saveScore(_score);
      _storageService.saveSolved(_solved);
      _roundOver = true;
    } else {
      if (!_wrongAnswers.contains(isoCode)) {
        _wrongAnswers.add(isoCode);
        _attempts++;
      }
      if (_attempts >= AppConstants.maxAttempts) {
        _solved.add(_correctCountry!.isoCode);
        _storageService.saveSolved(_solved);
        _roundOver = true;
      }
    }
    notifyListeners();
  }

  void nextQuestion() {
    _generateQuestion();
    notifyListeners();
  }

  Future<void> resetGame() async {
    _solved = {};
    _score = 0;
    _attempts = 0;
    _wrongAnswers = {};
    await _storageService.clearAll();
    _generateQuestion();
    notifyListeners();
  }
}
