import 'package:flutter/material.dart';

void main() {
  runApp(const HRApp());
}

class HRApp extends StatelessWidget {
  const HRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haidilao HR',
      theme: ThemeData(
        // 海底捞的招牌红色主题
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red), 
        useMaterial3: true,
      ),
      home: const PunchCardScreen(),
    );
  }
}

class PunchCardScreen extends StatefulWidget {
  const PunchCardScreen({super.key});

  @override
  State<PunchCardScreen> createState() => _PunchCardScreenState();
}

class _PunchCardScreenState extends State<PunchCardScreen> {
  // 星期三的进度只是设计 UI，所以我们先做个假的打卡效果
  String _statusMessage = "Welcome back, Zhe Wei! Please clock in.";

  void _clockIn() {
    setState(() {
      _statusMessage = "Clocked in successfully!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Punch Card (Haidilao)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.access_time_filled,
              size: 100,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 30),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              onPressed: _clockIn,
              child: const Text('CLOCK IN'),
            ),
          ],
        ),
      ),
    );
  }
}