import 'package:flutter/material.dart';
import 'screens/home_screen.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BaseballApp()); // 이걸 지우면 앱이 실행되지 않음
}

class BaseballApp extends StatelessWidget {
  const BaseballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
