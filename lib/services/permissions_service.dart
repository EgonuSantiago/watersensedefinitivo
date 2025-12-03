import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  /// Solicita todas as permissões necessárias para BLE funcionar
  static Future<bool> requestBlePermissions() async {
    // Lista de permissões
    List<Permission> permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.location,
    ];

    // Solicita todas
    Map<Permission, PermissionStatus> statuses = await permissions.request();

    // Verifica se todas foram concedidas
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print("⚠️ Algumas permissões BLE não foram concedidas!");
    }

    return allGranted;
  }
}
