import 'package:flutter/material.dart';
import '../models/water_tank.dart';
import '../services/storage_service.dart';

class ConfigScreen extends StatefulWidget {
  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  String? _selectedType;
  double _capacity = 500;
  double _height = 1.3;
  double _topRadius = 0.4;
  double _bottomRadius = 0.4;

  // 🔥 TABELAS DE CALIBRAÇÃO SÃO TODAS EM METROS
  final Map<String, WaterTank> predefinedTanks = {
    // CILÍNDRICAS
    'Cilíndrica 310L': WaterTank.l310(),
    'Cilíndrica 500L': WaterTank.l500(),
    'Cilíndrica 1000L': WaterTank.l1000(),

    'Cilíndrica 1500L': WaterTank(
      name: '1500L',
      type: 'cilindrica',
      capacityLiter: 1500,
      tariffPerLiter: 0.005,
      tankHeight: 1.8,
      topRadius: 0.65,
      bottomRadius: 0.65,
      calibrationTable: {0.0: 0, 0.45: 375, 0.9: 750, 1.35: 1125, 1.8: 1500},
    ),

    'Cilíndrica 2000L': WaterTank(
      name: '2000L',
      type: 'cilindrica',
      capacityLiter: 2000,
      tariffPerLiter: 0.005,
      tankHeight: 2.0,
      topRadius: 0.7,
      bottomRadius: 0.7,
      calibrationTable: {0.0: 0, 0.5: 500, 1.0: 1000, 1.5: 1500, 2.0: 2000},
    ),

    // TRONCO-CÔNICAS
    'Tronco 500L': WaterTank(
      name: 'Tronco 500L',
      type: 'tronco',
      capacityLiter: 500,
      tariffPerLiter: 0.005,
      tankHeight: 1.2,
      topRadius: 0.4,
      bottomRadius: 0.35,
      calibrationTable: {0.0: 0, 0.3: 125, 0.6: 250, 0.9: 375, 1.2: 500},
    ),

    'Tronco 1000L': WaterTank(
      name: 'Tronco 1000L',
      type: 'tronco',
      capacityLiter: 1000,
      tariffPerLiter: 0.005,
      tankHeight: 1.8,
      topRadius: 0.55,
      bottomRadius: 0.45,
      calibrationTable: {0.0: 0, 0.45: 250, 0.9: 500, 1.35: 750, 1.8: 1000},
    ),

    'Tronco 1500L': WaterTank(
      name: 'Tronco 1500L',
      type: 'tronco',
      capacityLiter: 1500,
      tariffPerLiter: 0.005,
      tankHeight: 2.0,
      topRadius: 0.65,
      bottomRadius: 0.55,
      calibrationTable: {0.0: 0, 0.5: 375, 1.0: 750, 1.5: 1125, 2.0: 1500},
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadSavedTank();
  }

  Future<void> _loadSavedTank() async {
    final tank =
        await StorageService.instance.getWaterTank() ??
        WaterTank.defaultCylinder();

    setState(() {
      // Seleciona o item corretamente pelo nome
      _selectedType = predefinedTanks.entries
          .firstWhere(
            (entry) => entry.value.name == tank.name,
            orElse: () => MapEntry('Manual', WaterTank.defaultCylinder()),
          )
          .key;

      _capacity = tank.capacityLiter.toDouble();
      _height = tank.tankHeight;
      _topRadius = tank.topRadius;
      _bottomRadius = tank.bottomRadius;
    });
  }

  void _onSave() async {
    WaterTank tank;

    if (_selectedType == 'Manual') {
      tank = WaterTank(
        name: 'Manual',
        type: 'manual',
        capacityLiter: _capacity.toInt(),
        tariffPerLiter: 0.005,
        tankHeight: _height,
        topRadius: _topRadius,
        bottomRadius: _bottomRadius,

        // calibração mínima obrigatória (altura final → capacidade total)
        calibrationTable: {0.0: 0, _height: _capacity},
      );
    } else {
      tank = predefinedTanks[_selectedType!]!;
    }

    await StorageService.instance.saveWaterTank(tank);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configurações salvas!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Caixa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Selecione o tipo da caixa',
              ),
              items: [
                ...predefinedTanks.keys.map(
                  (k) => DropdownMenuItem(value: k, child: Text(k)),
                ),
                const DropdownMenuItem(
                  value: 'Manual',
                  child: Text('Manual (Configurar manualmente)'),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedType = val;

                  if (val != 'Manual' && predefinedTanks.containsKey(val)) {
                    final t = predefinedTanks[val]!;
                    _capacity = t.capacityLiter.toDouble();
                    _height = t.tankHeight;
                    _topRadius = t.topRadius;
                    _bottomRadius = t.bottomRadius;
                  }
                });
              },
            ),

            const SizedBox(height: 20),

            // CAMPOS MANUAIS
            if (_selectedType == 'Manual') ...[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Capacidade (L)'),
                initialValue: _capacity.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) => _capacity = double.tryParse(v) ?? 0,
              ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Altura (m)'),
                initialValue: _height.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) => _height = double.tryParse(v) ?? 0,
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Raio do Topo (m)',
                ),
                initialValue: _topRadius.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) => _topRadius = double.tryParse(v) ?? 0,
              ),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Raio da Base (m)',
                ),
                initialValue: _bottomRadius.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) => _bottomRadius = double.tryParse(v) ?? 0,
              ),
            ],

            const SizedBox(height: 30),

            ElevatedButton(onPressed: _onSave, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
