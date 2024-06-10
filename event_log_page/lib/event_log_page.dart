import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class EventLogPage extends StatefulWidget {
  @override
  _EventLogPageState createState() => _EventLogPageState();
}

class _EventLogPageState extends State<EventLogPage> {
  List<List<String>> _logData = [];
  TextEditingController _nameController = TextEditingController();
  TextEditingController _eventController = TextEditingController();
  String _userName = 'Anonymous'; // Default user name
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  void _logEvent(String eventDescription, String time) async {
    if (_userName == 'Anonymous') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final logEntry = [date, time, eventDescription];

    setState(() {
      _logData.add(logEntry);
      _logData.sort((a, b) => a[0].compareTo(b[0])); // Sort by date
      _logData.sort((a, b) => a[1].compareTo(b[1])); // Then by time
    });

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Event_Log_Data';
    final dir = Directory(path);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final filePath = '$path/${_fileName}.csv';
    final file = File(filePath);

    String csvData = ListToCsvConverter().convert(_logData);
    await file.writeAsString(csvData);

    // Print the log entry and file path to the console for debugging
    print('Log Entry: $logEntry');
    print('CSV file saved at: $filePath');
  }

  void _loadLog() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Event_Log_Data/$_fileName.csv';
    final file = File(path);

    if (await file.exists()) {
      final input = await file.readAsString();
      List<List<dynamic>> data = CsvToListConverter().convert(input);
      setState(() {
        _logData = data.map((row) => row.map((e) => e.toString()).toList()).toList();
      });

      // Print loaded data for debugging
      print('Loaded log data: $_logData');
    } else {
      setState(() {
        _logData = [];
      });
    }
  }

  Widget _buildLogList() {
    return ListView.builder(
      itemCount: _logData.length,
      itemBuilder: (context, index) {
        final entry = _logData[index];
        return ListTile(
          title: Text('${entry[2]}'), // Display event description
          subtitle: Text('${entry[0]} ${entry[1]}'), // Display date and time
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Log App'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _userName = value.trim();
                  _fileName = _userName;
                  _loadLog();
                });
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => _logEvent('Nausea', _getCurrentTime()),
                child: Text('Nausea'),
              ),
              ElevatedButton(
                onPressed: () => _logEvent('Anxiety', _getCurrentTime()),
                child: Text('Anxiety'),
              ),
              ElevatedButton(
                onPressed: () => _logEvent('Stress', _getCurrentTime()),
                child: Text('Stress'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildManualEventDialog(),
                  );
                },
                child: Text('Log Manual Event'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEventDialog() {
    TimeOfDay? selectedTime = TimeOfDay.now();

    return AlertDialog(
      title: Text('Log Manual Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _eventController,
            decoration: InputDecoration(
              labelText: 'Event Description',
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );

              if (pickedTime != null) {
                setState(() {
                  selectedTime = pickedTime;
                });

                _logEvent(
                  _eventController.text.trim(),
                  '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                );

                Navigator.pop(context);
              }
            },
            child: Text('Select Time'),
          ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}