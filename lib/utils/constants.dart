class AppConstants {
  static const String countriesUrl =
      'https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json';

  static String flagUrl(String isoCode) =>
      'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';

  static const String solvedKey = 'solved_iso_codes';
  static const String scoreKey = 'total_score';

  static const List<int> pointsPerTry = [10, 8, 5];
  static const int maxAttempts = 3;
}
