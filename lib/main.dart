import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHI BLE Data Viewer',
      debugShowCheckedModeBanner: false,
      home: DeviceIdInputScreen(),
    );
  }
}

/// Screen 1: Prompt for the SHI Device ID.
class DeviceIdInputScreen extends StatefulWidget {
  @override
  _DeviceIdInputScreenState createState() => _DeviceIdInputScreenState();
}

class _DeviceIdInputScreenState extends State<DeviceIdInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Retrieve the device ID from the text field.
    String deviceId = _controller.text;
    // Navigate to the chart screen and pass along the device ID.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChartScreen(deviceId: deviceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter SHI Device ID'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Enter your SHI Device ID:",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            // TextField that brings up the keyboard when tapped.
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Device ID',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}

/// Screen 2: The chart screen with the chart and the device ID display.
class ChartScreen extends StatefulWidget {
  final String deviceId;
  ChartScreen({required this.deviceId});

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<double> _dataPoints = [];
  double _currentValue = 0;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Add the first data point immediately.
    _addDataPoint();
    // Then add a new data point every 5 seconds.
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _addDataPoint();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _addDataPoint() {
    // Generate a random value between 60 and 75.
    double newValue = 60 + _random.nextDouble() * 15;
    setState(() {
      _currentValue = newValue;
      _dataPoints.add(newValue);
      // Keep only the last 5 minutes of data (max 60 points at 5-second intervals).
      if (_dataPoints.length > 60) {
        _dataPoints.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert the data points into chart spots.
    List<FlSpot> spots = [];
    for (int i = 0; i < _dataPoints.length; i++) {
      spots.add(FlSpot(i * 5.0, _dataPoints[i]));
    }

    // Determine x-axis range.
    double minX, maxX;
    if (spots.isEmpty) {
      minX = 0;
      maxX = 300;
    } else {
      double currentTime = (spots.length - 1) * 5.0;
      if (currentTime < 300) {
        minX = 0;
        maxX = currentTime;
      } else {
        minX = currentTime - 300;
        maxX = currentTime;
      }
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text('SHI Device Data'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the current random value.
            Text(
              "Current Value: ${_currentValue.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            // The chart takes up the remaining space.
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: 55,
                  maxY: 80,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 60,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.white.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 60,
                        getTitlesWidget: (value, meta) {
                          int minutes = (value / 60).floor();
                          return Text(
                            "${minutes}m",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Display the SHI Device ID below the chart.
            Text(
              "Current SHI Device ID: ${widget.deviceId}",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
