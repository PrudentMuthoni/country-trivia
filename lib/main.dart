import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/country_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/trivia_viewmodel.dart';
import 'views/trivia_view.dart';

void main() {
  runApp(const TriviaApp());
}

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => CountryService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProxyProvider2<CountryService, StorageService,
            TriviaViewModel>(
          create: (ctx) => TriviaViewModel(
            countryService: ctx.read<CountryService>(),
            storageService: ctx.read<StorageService>(),
          )..init(),
          update: (_, countryService, storageService, previous) =>
              previous ??
              TriviaViewModel(
                countryService: countryService,
                storageService: storageService,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'Country Trivia',
        theme: AppTheme.light,
        home: const TriviaView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
