import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-Time Chart Demo',
      debugShowCheckedModeBanner: false,
      home: ChartPage(),
    );
  }
}

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  // List to store random values
  final List<double> _dataPoints = [];
  double _currentValue = 0;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Add the first data point immediately
    _addDataPoint();
    // Then add a new data point every 5 seconds
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
    // Generate a random value between 60 and 75
    double newValue = 60 + _random.nextDouble() * 15;
    setState(() {
      _currentValue = newValue;
      _dataPoints.add(newValue);
      // Keep only the last 5 minutes of data (max 60 points at 5-second intervals)
      if (_dataPoints.length > 60) {
        _dataPoints.removeAt(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert data points to chart spots
    // Each point is 5 seconds apart, so x = index * 5
    List<FlSpot> spots = [];
    for (int i = 0; i < _dataPoints.length; i++) {
      spots.add(FlSpot(i * 5.0, _dataPoints[i]));
    }
    
    // Determine x-axis range:
    // Before 5 minutes, x ranges from 0 to the current time
    // After 5 minutes, it displays a sliding window of 300 seconds
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
        title: Text("Real-Time Chart"),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display the current random value
            Text(
              "Current Value: ${_currentValue.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            // The chart expands to fill the remaining space
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
                        interval: 60, // Label every minute
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
          ],
        ),
      ),
    );
  }
}
