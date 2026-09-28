import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';
import '../utils/constants.dart';

class CountryService {
  Future<List<Country>> fetchCountries() async {
    final response = await http.get(Uri.parse(AppConstants.countriesUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Country.fromJson(e)).toList();
    }
    throw Exception('Failed to load countries (${response.statusCode})');
  }
}
