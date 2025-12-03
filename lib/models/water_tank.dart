import 'dart:convert';

class WaterTank {
  final String name;
  final String type; // 'cilindrica', 'tronco' ou 'manual'
  final int capacityLiter;
  final double tariffPerLiter;

  final double tankHeight; // altura total em METROS
  final double topRadius;
  final double bottomRadius;

  /// Tabela de calibração: {altura_em_metros : litros}
  final Map<double, double> calibrationTable;

  WaterTank({
    required this.name,
    required this.type,
    required this.capacityLiter,
    required this.tariffPerLiter,
    required this.tankHeight,
    required this.topRadius,
    required this.bottomRadius,
    required this.calibrationTable,
  });

  // ---------------------------------------------------------------
  // 🔵 CÁLCULO DO VOLUME (via tabela + interpolação)
  // ---------------------------------------------------------------
  double getVolumeFromHeight(double height) {
    if (calibrationTable.isEmpty) return 0;

    final keys = calibrationTable.keys.toList()..sort();

    if (height <= keys.first) return calibrationTable[keys.first]!;
    if (height >= keys.last) return calibrationTable[keys.last]!;

    for (int i = 0; i < keys.length - 1; i++) {
      final h1 = keys[i];
      final h2 = keys[i + 1];

      if (height >= h1 && height <= h2) {
        final v1 = calibrationTable[h1]!;
        final v2 = calibrationTable[h2]!;

        final percent = (height - h1) / (h2 - h1);
        return v1 + (v2 - v1) * percent;
      }
    }
    return 0;
  }

  // Porcentagem de água na caixa
  double getPercentage(double height) {
    final vol = getVolumeFromHeight(height);
    return (vol / capacityLiter).clamp(0, 1);
  }

  // ---------------------------------------------------------------
  // 🔵 heightToLiters() — usado pela HOME
  // ---------------------------------------------------------------
  double heightToLiters(double height) {
    if (calibrationTable.isEmpty) return 0;

    final keys = calibrationTable.keys.toList()..sort();

    // abaixo do mínimo
    if (height <= keys.first) return calibrationTable[keys.first]!;

    // acima do máximo
    if (height >= keys.last) return calibrationTable[keys.last]!;

    // interpolação
    for (int i = 0; i < keys.length - 1; i++) {
      final h1 = keys[i];
      final h2 = keys[i + 1];

      if (height >= h1 && height <= h2) {
        final v1 = calibrationTable[h1]!;
        final v2 = calibrationTable[h2]!;

        final frac = (height - h1) / (h2 - h1);
        return v1 + (v2 - v1) * frac;
      }
    }

    return 0;
  }

  // ---------------------------------------------------------------
  // 🔵 SERIALIZAÇÃO (JSON)
  // ---------------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'capacityLiter': capacityLiter,
      'tariffPerLiter': tariffPerLiter,
      'tankHeight': tankHeight,
      'topRadius': topRadius,
      'bottomRadius': bottomRadius,
      'calibrationTable': calibrationTable.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  static WaterTank fromJson(Map<String, dynamic> json) {
    return WaterTank(
      name: json['name'],
      type: json['type'],
      capacityLiter: json['capacityLiter'],
      tariffPerLiter: json['tariffPerLiter'],
      tankHeight: (json['tankHeight'] as num).toDouble(),
      topRadius: (json['topRadius'] as num).toDouble(),
      bottomRadius: (json['bottomRadius'] as num).toDouble(),
      calibrationTable: (json['calibrationTable'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(double.parse(k), (v as num).toDouble()),
      ),
    );
  }

  // ---------------------------------------------------------------
  // 🔵 MODELOS PRÉ-DEFINIDOS
  // ---------------------------------------------------------------
  static WaterTank l310() => WaterTank(
    name: 'Cilíndrica 310L',
    type: 'cilindrica',
    capacityLiter: 310,
    tariffPerLiter: 0.005,
    tankHeight: 1.0,
    topRadius: 0.35,
    bottomRadius: 0.35,
    calibrationTable: {0.0: 0, 0.25: 77, 0.50: 154, 0.75: 231, 1.0: 310},
  );

  static WaterTank l500() => WaterTank(
    name: 'Cilíndrica 500L',
    type: 'cilindrica',
    capacityLiter: 500,
    tariffPerLiter: 0.005,
    tankHeight: 1.2,
    topRadius: 0.40,
    bottomRadius: 0.40,
    calibrationTable: {0.0: 0, 0.30: 125, 0.60: 250, 0.90: 375, 1.20: 500},
  );

  static WaterTank l1000() => WaterTank(
    name: 'Cilíndrica 1000L',
    type: 'cilindrica',
    capacityLiter: 1000,
    tariffPerLiter: 0.005,
    tankHeight: 1.5,
    topRadius: 0.55,
    bottomRadius: 0.55,
    calibrationTable: {0.0: 0, 0.37: 250, 0.75: 500, 1.12: 750, 1.50: 1000},
  );

  // ---------------------------------------------------------------
  // 🔵 MODELO PADRÃO
  // ---------------------------------------------------------------
  static WaterTank defaultCylinder() => l500();
}
