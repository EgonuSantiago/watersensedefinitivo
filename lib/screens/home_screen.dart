import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';
import '../models/water_tank.dart';
import 'config_screen.dart';
import 'history_screen.dart';
import 'consumption_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _waterPercentage = 0;
  double _liters = 0;
  bool _connected = false;

  WaterTank? tank;
  StreamSubscription<double>? _heightSub;
  StreamSubscription<bool>? _connectionSub;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _loadTank();
    _listenBLE();
    try {
      await BluetoothService.instance.loadOfflineData();
    } catch (e) {
      print("Erro ao carregar dados offline: $e");
    }
    BluetoothService.instance.connectToESP32();
  }

  Future<void> _loadTank() async {
    tank = await StorageService.instance.getWaterTank();
    setState(() {});
  }

  void _listenBLE() {
    _heightSub?.cancel();
    _connectionSub?.cancel();

    _connectionSub = BluetoothService.instance.connectionStream.listen(
      (status) {
        setState(() => _connected = status);
      },
      onError: (e) => print("Erro connectionStream: $e"),
    );

    _heightSub = BluetoothService.instance.heightStream.listen(
      (distanciaCm) {
        if (tank == null) return;

        // 🔹 CONVERTE CM PARA METROS
        double distancia = distanciaCm / 100;

        double alturaTotal = tank!.tankHeight;
        distancia = distancia.clamp(0, alturaTotal);

        double alturaAgua = alturaTotal - distancia;
        alturaAgua = alturaAgua.clamp(0, alturaTotal);

        double litros = _calcularLitros(tank!, alturaAgua);
        double porcentagem = (alturaAgua / alturaTotal) * 100;

        setState(() {
          _waterPercentage = porcentagem;
          _liters = litros;
        });
      },
      onError: (e) => print("Erro heightStream: $e"),
    );
  }

  double _calcularLitros(WaterTank tank, double altura) {
    final keys = tank.calibrationTable.keys.toList()..sort();
    final values = tank.calibrationTable;

    if (keys.isEmpty) return 0.0;
    if (keys.length == 1) return values[keys.first]!;

    if (altura <= keys.first) return values[keys.first]!;
    if (altura >= keys.last) return values[keys.last]!;

    double h1 = keys.first, h2 = keys.last, l1 = 0, l2 = 0;
    for (int i = 0; i < keys.length - 1; i++) {
      if (altura >= keys[i] && altura <= keys[i + 1]) {
        h1 = keys[i];
        h2 = keys[i + 1];
        l1 = values[h1]!;
        l2 = values[h2]!;
        break;
      }
    }

    double t = (altura - h1) / (h2 - h1);
    return l1 + t * (l2 - l1);
  }

  @override
  void dispose() {
    _heightSub?.cancel();
    _connectionSub?.cancel();
    super.dispose();
  }

  Widget _buildHomeTab() {
    if (tank == null) return const Center(child: CircularProgressIndicator());
    final tankName = tank!.name;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 220,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (_waterPercentage.clamp(0, 100)) / 100,
                    strokeWidth: 18,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${_waterPercentage.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _connected ? "Conectado" : "Sem conexão",
                        style: TextStyle(
                          fontSize: 14,
                          color: _connected ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "Litros: ${_liters.toStringAsFixed(1)} / ${tank!.capacityLiter} L",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text("Modelo: $tankName", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => BluetoothService.instance.reconnect(),
                  child: const Text("Reconectar"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await BluetoothService.instance.loadOfflineData();
                  },
                  child: const Text("Load offline"),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      _buildHomeTab(),
      ConfigScreen(),
      HistoryScreen(),
      ConsumptionScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? "Home"
              : _currentIndex == 1
                  ? "Configurações"
                  : _currentIndex == 2
                      ? "Histórico"
                      : "Consumo",
        ),
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Config"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: "Histórico"),
          BottomNavigationBarItem(icon: Icon(Icons.water), label: "Consumo"),
        ],
      ),
    );
  }
}
