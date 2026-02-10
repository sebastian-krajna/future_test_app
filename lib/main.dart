// ignore_for_file: avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Future Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Future Resolution Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.future_test');

  String _result = 'Press a button to test';
  final List<String> _testLog = [];
  int _testCounter = 0;

  void _logTest(String testName, String status, String details) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final logEntry = '[$timestamp] TEST #${_testCounter++}\n'
        'Name: $testName\n'
        'Status: $status\n'
        'Details: $details\n'
        '${'-' * 50}';

    setState(() {
      _testLog.add(logEntry);
    });

    print('═' * 60);
    print('FLUTTER TEST LOG #${_testCounter - 1}');
    print('Time: $timestamp');
    print('Test: $testName');
    print('Status: $status');
    print('Details: $details');
    print('═' * 60);
  }

  void _copyLogsToClipboard() {
    final allLogs = '# Future Resolution Test Results\n'
        '# Date: ${DateTime.now()}\n'
        '# Total Tests: $_testCounter\n\n'
        '${_testLog.join('\n\n')}';

    Clipboard.setData(ClipboardData(text: allLogs));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_testCounter test logs copied to clipboard!')),
    );
  }

  void _clearLogs() {
    setState(() {
      _testLog.clear();
      _testCounter = 0;
      _result = 'Logs cleared. Press a button to test';
    });
  }

  // TEST 1: neverResolves (no try/catch)
  Future<void> _testNeverResolved() async {
    const testName = 'TEST 1: neverResolves';
    setState(() => _result = 'Running: $testName');

    _logTest(testName, 'STARTED', 'Calling method that never calls result()');

    final result = await platform.invokeMethod('neverResolves').timeout(
      const Duration(seconds: 5),
      onTimeout: () => 'TIMEOUT_MARKER',
    );

    if (result == 'TIMEOUT_MARKER') {
      _logTest(testName, 'TIMEOUT', 'Future never resolved');
      setState(() => _result = 'TEST 1: TIMEOUT\nFuture was never resolved.');
    } else {
      _logTest(testName, 'SUCCESS', 'Unexpected: $result');
      setState(() => _result = 'TEST 1 UNEXPECTED: $result');
    }
  }

  // TEST 2: throwsError (no try/catch - error will propagate / red screen)
  Future<void> _testThrowsError() async {
    const testName = 'TEST 2: throwsError';
    setState(() => _result = 'Running: $testName');

    _logTest(testName, 'STARTED', 'Calling method that throws PlatformException (NO try/catch)');

    final result = await platform.invokeMethod('throwsError');

    _logTest(testName, 'SUCCESS', 'Got result: $result');
    setState(() => _result = 'TEST 2: Got result $result');
  }

  // TEST 3: returnsNull (no try/catch)
  Future<void> _testReturnsNull() async {
    const testName = 'TEST 3: returnsNull';
    setState(() => _result = 'Running: $testName');

    _logTest(testName, 'STARTED', 'Calling method that returns null');

    final result = await platform.invokeMethod('returnsNull');

    _logTest(testName, 'SUCCESS', 'Received: $result (type: ${result.runtimeType})');
    setState(() => _result = 'TEST 3: NULL RECEIVED\nValue: $result\nType: ${result.runtimeType}');
  }

  // TEST 4: nativeThrow - real throw on native side (no try/catch - error will propagate)
  Future<void> _testNativeThrow() async {
    const testName = 'TEST 4: nativeThrow';
    setState(() => _result = 'Running: $testName');

    _logTest(testName, 'STARTED', 'Native code will throw (RuntimeException/NSException), NO try/catch');

    await platform.invokeMethod('nativeThrow');

    _logTest(testName, 'SUCCESS', 'No exception');
    setState(() => _result = 'TEST 4: No exception thrown');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs',
            onPressed: _testLog.isEmpty ? null : _copyLogsToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear logs',
            onPressed: _testLog.isEmpty ? null : _clearLogs,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Text('Tests Run: $_testCounter'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(_result),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testNeverResolved,
                child: const Text('TEST 1: neverResolves'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testThrowsError,
                child: const Text('TEST 2: throwsError'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testReturnsNull,
                child: const Text('TEST 3: returnsNull'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _testNativeThrow,
                child: const Text('TEST 4: nativeThrow'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
