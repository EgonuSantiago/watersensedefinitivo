import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothService {
  BluetoothService._internal();
  static final BluetoothService instance = BluetoothService._internal();

  // STREAM DE ALTURA
  final StreamController<double> _heightController =
      StreamController.broadcast();
  Stream<double> get heightStream => _heightController.stream;

  // STREAM DE STATUS
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  static const serviceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const txUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

  bool _reconnectCooldown = false;

  // ============================================================
  //  CONECTAR
  // ============================================================
  Future<void> connectToESP32() async {
    if (_isConnected || _reconnectCooldown) return;

    print("🔍 Escaneando por ESP32...");

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    BluetoothDevice? foundDevice;

    await for (final results in FlutterBluePlus.scanResults) {
      for (var r in results) {
        if (r.device.name == "WaterSenseESP32") {
          foundDevice = r.device;
          print("📌 ESP32 encontrado!");
          break;
        }
      }
      if (foundDevice != null) break;
    }

    FlutterBluePlus.stopScan();

    if (foundDevice == null) {
      print("❌ ESP32 não encontrado!");
      _connectionController.add(false);
      return;
    }

    _device = foundDevice;

    await _connectDevice();
  }

  // ============================================================
  //  CONECTAR DISPOSITIVO
  // ============================================================
  Future<void> _connectDevice() async {
    try {
      print("🔗 Conectando ao ESP32...");

      // IMPORTANTE → NÃO USAR license=null
      await _device!.connect(autoConnect: false);

      _isConnected = true;
      _connectionController.add(true);
      print("✅ ESP32 conectado!");

      await _discoverServices();

      _device!.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.disconnected) {
          if (_isConnected == false) return;

          print("⚠️ ESP32 desconectado.");
          _isConnected = false;
          _connectionController.add(false);

          _reconnectCooldown = true;

          Future.delayed(const Duration(seconds: 8), () {
            _reconnectCooldown = false;
            connectToESP32();
          });
        }
      });
    } catch (e) {
      print("❌ Erro ao conectar: $e");
      _connectionController.add(false);
    }
  }

  // ============================================================
  //  DISCOVER SERVICES + NOTIFY
  // ============================================================
  Future<void> _discoverServices() async {
    var services = await _device!.discoverServices();

    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == serviceUUID.toLowerCase()) {
        for (var c in s.characteristics) {
          var uuid = c.uuid.toString().toLowerCase();

          // TX do ESP32
          if (uuid == txUUID.toLowerCase()) {
            print("📥 TX encontrada");
            _txCharacteristic = c;

            // Ativar notify corretamente
            if (c.properties.notify) {
              await c.setNotifyValue(true);
            }

            c.lastValueStream.listen((data) {
              if (data.isEmpty) return;

              try {
                String msg = utf8.decode(data).trim();

                double? valor = double.tryParse(msg);

                if (valor != null) {
                  print("📡 Recebido: $valor");
                  _heightController.add(valor);
                  _saveOfflineData(valor);
                }
              } catch (e) {
                print("⚠️ Erro ao processar BLE: $e");
              }
            });
          }
        }
      }
    }
  }

  // ============================================================
  //  SALVAR OFFLINE
  // ============================================================
  Future<void> _saveOfflineData(double height) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('last_height', height);
  }

  Future<void> loadOfflineData() async {
    final p = await SharedPreferences.getInstance();
    double last = p.getDouble('last_height') ?? 0;
    _heightController.add(last);
  }

  // ============================================================
  //  DESCONECTAR
  // ============================================================
  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _txCharacteristic = null;

    _isConnected = false;
    _connectionController.add(false);
  }

  // ============================================================
  //  RECONNECT
  // ============================================================
  Future<void> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
    await connectToESP32();
  }
}
