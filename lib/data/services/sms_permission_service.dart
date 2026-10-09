import 'package:permission_handler/permission_handler.dart';

class SmsPermissionService {
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  Future<bool> isPermanentlyDenied() async {
    return await Permission.sms.isPermanentlyDenied;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
