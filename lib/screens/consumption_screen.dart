import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/water_tank.dart';
import '../services/storage_service.dart';
import '../services/bluetooth_service.dart';

class ConsumptionScreen extends StatefulWidget {
  @override
  _ConsumptionScreenState createState() => _ConsumptionScreenState();
}

class _ConsumptionScreenState extends State<ConsumptionScreen>
    with SingleTickerProviderStateMixin {
  // TabController
  late TabController _tabController;

  // Medições
  double _lastHeight = 0.0;
  WaterTank? _tank;
  final List<FlSpot> _realTimeHistory = [];
  final Map<int, double> _dailyConsumption = {};
  final Map<int, double> _weeklyConsumption = {};
  final Map<int, double> _monthlyConsumption = {};

  StreamSubscription<double>? _heightSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTank();

    // Escuta o stream do BLE
    _heightSub = BluetoothService.instance.heightStream.listen((height) {
      _addNewHeight(height);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heightSub?.cancel();
    super.dispose();
  }

  Future<void> _loadTank() async {
    final t = await StorageService.instance.getWaterTank();
    setState(() => _tank = t);
  }

  void _addNewHeight(double h) {
    final now = DateTime.now();
    setState(() {
      _lastHeight = h;
      double liters = currentLiters;

      // Tempo real
      _realTimeHistory.add(
        FlSpot(now.millisecondsSinceEpoch.toDouble(), liters),
      );
      if (_realTimeHistory.length > 50) _realTimeHistory.removeAt(0);

      // Diário
      _dailyConsumption[now.hour] = (_dailyConsumption[now.hour] ?? 0) + liters;

      // Semanal
      int weekday = now.weekday;
      _weeklyConsumption[weekday] = (_weeklyConsumption[weekday] ?? 0) + liters;

      // Mensal
      int day = now.day;
      _monthlyConsumption[day] = (_monthlyConsumption[day] ?? 0) + liters;
    });
  }

  double get currentLiters {
    if (_tank == null) return 0;
    double hCm = _lastHeight;
    double tankHeightCm = _tank!.tankHeight * 100;
    double percent = (hCm / tankHeightCm).clamp(0, 1);

    if (_tank!.type == 'cilindrica' || _tank!.type == 'balde') {
      return _tank!.capacityLiter * percent;
    } else if (_tank!.type == 'tronco') {
      double rTop = _tank!.topRadius * 100;
      double rBottom = _tank!.bottomRadius * 100;
      double volumeCm3 =
          (3.14159265359 * hCm / 3) *
          (rTop * rTop + rTop * rBottom + rBottom * rBottom);
      double totalVolumeCm3 =
          (3.14159265359 * tankHeightCm / 3) *
          (rTop * rTop + rTop * rBottom + rBottom * rBottom);
      return _tank!.capacityLiter * (volumeCm3 / totalVolumeCm3);
    }
    return 0;
  }

  Color _colorByLevel(double liters, double maxLiters) {
    double percent = liters / maxLiters;
    if (percent < 0.3) return Colors.blue;
    if (percent < 0.7) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Consumo de Água"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Tempo Real"),
            Tab(text: "Diário"),
            Tab(text: "Semanal/Mensal"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRealTimeTab(),
          _buildDailyTab(),
          _buildWeeklyMonthlyTab(),
        ],
      ),
    );
  }

  Widget _buildRealTimeTab() {
    double maxY = (_tank?.capacityLiter ?? 1000).toDouble();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Litros estimados: ${currentLiters.toStringAsFixed(1)} L",
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _realTimeHistory,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, _) => Text("${val.toInt()} L"),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTab() {
    double maxY = 200;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barGroups: _dailyConsumption.entries
              .map(
                (e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: _colorByLevel(e.value, maxY),
                      width: 12,
                    ),
                  ],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) => Text("${val.toInt()}h"),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (val, _) => Text("${val.toInt()} L"),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyMonthlyTab() {
    double maxWeekly = 1000;
    double maxMonthly = 5000;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("Consumo Semanal", style: TextStyle(fontSize: 18)),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxWeekly,
                barGroups: _weeklyConsumption.entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: _colorByLevel(e.value, maxWeekly),
                            width: 12,
                          ),
                        ],
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        const days = [
                          'Seg',
                          'Ter',
                          'Qua',
                          'Qui',
                          'Sex',
                          'Sáb',
                          'Dom',
                        ];
                        return Text(days[(value.toInt() - 1) % 7]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, _) => Text("${val.toInt()} L"),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Consumo Mensal", style: TextStyle(fontSize: 18)),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxMonthly,
                barGroups: _monthlyConsumption.entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: _colorByLevel(e.value, maxMonthly),
                            width: 12,
                          ),
                        ],
                      ),
                    )
                    .toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) => Text("${val.toInt()}"),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (val, _) => Text("${val.toInt()} L"),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
