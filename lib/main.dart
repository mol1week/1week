import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'providers/my_team_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final myTeamProvider = MyTeamProvider();
  await myTeamProvider.loadMyTeam(); // SharedPreferences에서 초기값 불러오기

  runApp(
    ChangeNotifierProvider.value(
      value: myTeamProvider,
      child: const BaseballApp(),
    ),
  );
}

class BaseballApp extends StatelessWidget {
  const BaseballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Localization delegates for DatePickerDialog, etc.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ko', 'KR'),
      ],
      title: '야구 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'NotoSans',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}