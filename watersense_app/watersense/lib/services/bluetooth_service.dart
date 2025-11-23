import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show Uint8List;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService instance = BluetoothService._internal();

  final StreamController<double> _heightController =
      StreamController.broadcast();
  Stream<double> get heightStream => _heightController.stream;

  BluetoothConnection? _connection;
  bool _isConnected = false;

  Timer? _mockTimer;
  double _current = 1.0;
  bool _mock = false; // comece com simulação desativada

  /// Alterna o modo de simulação (para testar sem ESP)
  void toggleMockStream() {
    _mock = !_mock;
    if (_mock) {
      _mockTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        final choices = [-0.02, -0.01, 0.0, 0.01, 0.02];
        choices.shuffle();
        _current += choices.first;
        if (_current < 0) _current = 0;
        _heightController.add(_current);
      });
    } else {
      _mockTimer?.cancel();
    }
  }

  /// Conecta ao ESP32 via Bluetooth
  Future<void> connectToESP32() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial
          .instance
          .getBondedDevices();

      final device = bondedDevices.firstWhere(
        (d) => d.name?.contains("ESP32") ?? false,
        orElse: () => bondedDevices.first,
      );

      _connection = await BluetoothConnection.toAddress(device.address);
      _isConnected = true;
      print('✅ Conectado a ${device.name}');

      _connection!.input!
          .listen((Uint8List data) {
            final message = utf8.decode(data);
            final height = double.tryParse(message.trim());
            if (height != null) {
              _heightController.add(height);
              _saveOfflineData(height);
            }
          })
          .onDone(() {
            _isConnected = false;
            print('⚠️ Conexão encerrada.');
          });
    } catch (e) {
      print('❌ Erro ao conectar: $e');
      _isConnected = false;
      await _loadOfflineData();
    }
  }

  /// Salva o último valor localmente (para modo offline)
  Future<void> _saveOfflineData(double height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('last_height', height);
  }

  /// Carrega o último valor salvo caso o Bluetooth esteja desconectado
  Future<void> _loadOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getDouble('last_height') ?? 0.0;
    _heightController.add(last);
  }

  void dispose() {
    _mockTimer?.cancel();
    _connection?.dispose();
    _heightController.close();
  }
}
