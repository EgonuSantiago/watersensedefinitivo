import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/consumption.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Consumption> _list = [];

  // Tipo selecionado agora é do tipo enum
  ConsumptionType _selectedType = ConsumptionType.minutes30;

  // Labels amigáveis para exibição
  final Map<ConsumptionType, String> _typeLabels = {
    ConsumptionType.minutes30: '30 Minutos',
    ConsumptionType.daily: 'Diário',
    ConsumptionType.weekly: 'Semanal',
    ConsumptionType.monthly: 'Mensal',
  };

  @override
  void initState() {
    super.initState();
    _loadConsumptions();
  }

  Future<void> _loadConsumptions() async {
    List<Consumption> data;

    switch (_selectedType) {
      case ConsumptionType.daily:
        data = await StorageService.instance.getDailyConsumptions();
        break;
      case ConsumptionType.weekly:
        data = await StorageService.instance.getWeeklyConsumptions();
        break;
      case ConsumptionType.monthly:
        data = await StorageService.instance.getMonthlyConsumptions();
        break;
      case ConsumptionType.minutes30:
        data = await StorageService.instance.getHalfHourConsumptions();
        break;
    }

    // Exibe em ordem mais recente primeiro
    setState(() => _list = data.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: Column(
        children: [
          // Dropdown para escolher o tipo
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<ConsumptionType>(
              value: _selectedType,
              items: _typeLabels.entries.map((e) {
                return DropdownMenuItem<ConsumptionType>(
                  value: e.key,
                  child: Text(e.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                  _loadConsumptions();
                }
              },
            ),
          ),

          Expanded(
            child: _list.isEmpty
                ? const Center(child: Text('Sem dados'))
                : ListView.builder(
                    itemCount: _list.length,
                    itemBuilder: (context, idx) {
                      final c = _list[idx];
                      return ListTile(
                        title: Text('${c.volumeChange.toStringAsFixed(2)} L'),
                        subtitle: Text(fmt.format(c.timestamp)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
