import 'package:flutter/material.dart';
import 'schedule_screen.dart';
import 'prediction_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ScheduleScreen(),
    const PredictionScreen(),
    const PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정 보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '예측 보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '선수 보기',
          ),
        ],
      ),
    );
  }
}

