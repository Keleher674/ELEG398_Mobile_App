import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

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
    String deviceId = _controller.text;
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

/// Screen 2: The chart screen that displays BLE data.
class ChartScreen extends StatefulWidget {
  final String deviceId;
  ChartScreen({required this.deviceId});

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<double> _dataPoints = [];
  double _currentValue = 0;

  // BLE-related objects.
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _startBleScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  /// Requests required Bluetooth and location permissions.
  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Starts scanning for BLE devices and filters by device name.
  void _startBleScan() async {
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      print("Permissions not granted");
      return;
    }
    
    _scanSubscription = _ble.scanForDevices(withServices: []).listen(
      (device) {
        // Compare device.name with the user-provided SHI Device ID (ignoring case).
        if (device.name.toLowerCase() == widget.deviceId.toLowerCase()) {
          print("Found target device: ${device.name} (${device.id})");
          _scanSubscription?.cancel();
          _connectToDevice(device);
        }
      },
      onError: (error) {
        print("Scan error: $error");
      },
    );
  }

  /// Connects to the discovered BLE device.
  void _connectToDevice(DiscoveredDevice device) {
    _connectionSubscription = _ble.connectToDevice(id: device.id).listen(
      (connectionState) {
        print("Connection state: ${connectionState.connectionState}");
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _subscribeToCharacteristic(device);
        }
      },
      onError: (error) {
        print("Connection error: $error");
      },
    );
  }

  /// Subscribes to the BLE characteristic to receive data.
  void _subscribeToCharacteristic(DiscoveredDevice device) {
    final serviceUuid = Uuid.parse("YOUR-SERVICE-UUID"); // Replace with your service UUID.
    final characteristicUuid = Uuid.parse("YOUR-CHARACTERISTIC-UUID"); // Replace with your characteristic UUID.

    final characteristic = QualifiedCharacteristic(
      serviceId: serviceUuid,
      characteristicId: characteristicUuid,
      deviceId: device.id,
    );

    _notificationSubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        // Assume the device sends a 4-byte float in little-endian format.
        if (data.length >= 4) {
          final value = ByteData.sublistView(Uint8List.fromList(data))
              .getFloat32(0, Endian.little);
          print("Received BLE data: $value");
          setState(() {
            _currentValue = value;
            _dataPoints.add(value);
            // Keep only the last 60 data points.
            if (_dataPoints.length > 60) {
              _dataPoints.removeAt(0);
            }
          });
        }
      },
      onError: (error) {
        print("Notification error: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert data points into chart spots.
    List<FlSpot> spots = [];
    for (int i = 0; i < _dataPoints.length; i++) {
      spots.add(FlSpot(i * 5.0, _dataPoints[i]));
    }

    // Define x-axis range.
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
            // Display the current BLE value.
            Text(
              "Current Value: ${_currentValue.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            SizedBox(height: 20),
            // The chart occupies the remaining space.
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
            // Display the current device ID.
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
