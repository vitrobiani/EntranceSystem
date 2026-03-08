import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entrance System Logs',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Entrance System Logs'),
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
  String logs = "";
  List<Map<String, dynamic>> logList = [];
  late SSEReceiver _sseReceiver;

  @override
  void initState() {
    super.initState();
    _sseReceiver = SSEReceiver("http://localhost:3000/sse");

    // Listen to SSE. When a ping arrives, trigger the fetch.
    _sseReceiver.subscribe((newData) {
      // Don't use setState here. Just call the async function.
      _fetchLatestData();
    });

    // Optional: Fetch data immediately when the app starts
    _fetchLatestData();
  }

  @override
  void dispose() {
    _sseReceiver.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchLatestData() async {
    var url = Uri.http('localhost:3000');
    try {
      var response = await http.get(url);

      // Call setState ONLY after the data has successfully arrived.
      // This tells Flutter to rebuild the UI with the new 'logs' string.
      setState(() {
        logs = response.body;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> _incrementCounter() async {
    var url = Uri.http('localhost:3000');
    var response = await http.get(url);
    print(response.body);
    setState(() {
      logs = response.body;
    });
    _handle_logs();
  }

  List<DataRow> _handle_logs() {
    List<DataRow> rows = [];
    if (logs.isEmpty) return rows;
    final List<dynamic> decoded_logs = jsonDecode(logs);
    for (var i = 0; i < decoded_logs.length; i++) {
      // final Map<String, dynamic> decoded_log = jsonDecode(decoded_logs[i]);
      DataRow dr = DataRow(cells: <DataCell> [
        DataCell(Text(decoded_logs[i]["id"]!.toString())),
        DataCell(Text(decoded_logs[i]["uid"]!)),
        DataCell(Text(decoded_logs[i]["status"]!)),
        DataCell(Text(decoded_logs[i]["timestamp"]!)),
      ]);
      rows.add(dr);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            SingleChildScrollView(
              child:
              DataTable( columns: [
                DataColumn(label: Text("log id")),
                DataColumn(label: Text("chip id")),
                DataColumn(label: Text("status")),
                DataColumn(label: Text("timestamp")),
              ], rows: _handle_logs()
              ),
            ),
          ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class SSEReceiver {
  final String url;
  http.Client? _client; // Keep a reference to the client

  SSEReceiver(this.url);

  // 1. Changed expected type to String
  void subscribe(Function(String) onDataReceived) async {
    _client = http.Client(); // Initialize the client
    final request = http.Request("GET", Uri.parse(url));

    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Accept'] = 'text/event-stream';

    try {
      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        print("SSE Connected!");

        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          if (line.isEmpty) return;

          if (line.startsWith("data: ")) {
            // 2. Just grab the raw string, no need to parse JSON for a ping
            final dataString = line.substring(6);
            onDataReceived(dataString);
          }
        }, onError: (error) {
          print("Stream error: $error");
        });
      }
    } catch (e) {
      print("SSE Connection Error: $e");
    }
  }

  // 3. Add an unsubscribe method to close the connection
  void unsubscribe() {
    _client?.close();
    print("SSE Connection Closed");
  }
}