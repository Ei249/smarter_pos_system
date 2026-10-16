import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String _statusMessage = "Welcome back, Zhe Wei! Please clock in.";
  bool _isLoading = false;

  // 这是联通 Python API 的核心函数
  Future<void> _clockIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Syncing with database...";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/clock-in'),
        headers: {'Content-Type': 'application/json'},
        // 模拟 staff_id 为 1 (Zhe Wei)
        body: jsonEncode({'staff_id': 1}), 
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _statusMessage = "Success! Time: ${data['time']}";
        });
      } else {
        setState(() {
          _statusMessage = "Error: Database connection failed.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Network error. Is Python running?";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            const Icon(Icons.access_time_filled, size: 100, color: Colors.redAccent),
            const SizedBox(height: 30),
            Text(
              _statusMessage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 50),
            // 如果在 loading，就显示转圈圈；否则显示按钮
            _isLoading 
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
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