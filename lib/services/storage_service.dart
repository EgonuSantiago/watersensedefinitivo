import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_tank.dart';
import '../models/consumption.dart';

class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _getPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ================== USER EMAIL ==================
  Future<void> saveUserEmail(String email) async {
    final prefs = await _getPrefs;
    await prefs.setString('user_email', email);
  }

  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs;
    return prefs.getString('user_email');
  }

  // ================== WATER TANK ==================
  Future<void> saveWaterTank(WaterTank tank) async {
    final prefs = await _getPrefs;
    try {
      await prefs.setString('water_tank', jsonEncode(tank.toJson()));
    } catch (e) {
      print("❌ Erro ao salvar WaterTank: $e");
    }
  }

  Future<WaterTank> getWaterTank() async {
    final prefs = await _getPrefs;
    final raw = prefs.getString('water_tank');
    if (raw == null) return WaterTank.defaultCylinder();

    try {
      final data = jsonDecode(raw);
      return WaterTank.fromJson(data);
    } catch (e) {
      print("⚠️ Erro ao carregar WaterTank corrompido: $e");
      return WaterTank.defaultCylinder();
    }
  }

  // ================== LAST VOLUME ==================
  Future<void> saveLastVolume(double liters) async {
    final prefs = await _getPrefs;
    await prefs.setDouble('last_volume', liters);
  }

  Future<double?> getLastVolume() async {
    final prefs = await _getPrefs;
    return prefs.getDouble('last_volume');
  }

  // ================== CONSUMPTION ==================
  Future<void> saveConsumption(Consumption c) async {
    final prefs = await _getPrefs;
    List<String> list = prefs.getStringList('consumptions') ?? [];
    try {
      list.add(jsonEncode(c.toJson()));
      await prefs.setStringList('consumptions', list);
    } catch (e) {
      print("❌ Erro ao salvar Consumption: $e");
    }
  }

  Future<List<Consumption>> getAllConsumptions() async {
    final prefs = await _getPrefs;
    final list = prefs.getStringList('consumptions') ?? [];
    return list
        .map((s) {
          try {
            return Consumption.fromJson(jsonDecode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<Consumption>()
        .toList();
  }

  Future<List<Consumption>> getConsumptionsByType(ConsumptionType type) async {
    final all = await getAllConsumptions();
    return all.where((c) => c.type == type).toList();
  }

  Future<List<Consumption>> getHalfHourConsumptions() =>
      getConsumptionsByType(ConsumptionType.minutes30);

  Future<List<Consumption>> getDailyConsumptions() =>
      getConsumptionsByType(ConsumptionType.daily);

  Future<List<Consumption>> getWeeklyConsumptions() =>
      getConsumptionsByType(ConsumptionType.weekly);

  Future<List<Consumption>> getMonthlyConsumptions() =>
      getConsumptionsByType(ConsumptionType.monthly);

  // ================== CLEAR ALL ==================
  Future<void> clearAll() async {
    final prefs = await _getPrefs;
    await prefs.clear();
  }
}
