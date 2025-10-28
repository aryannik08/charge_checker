import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:charge_checker/presentation/ui/battery_monitor/battery_monitor_controller.dart';

class BatteryMonitorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FlutterLocalNotificationsPlugin>(
      () => FlutterLocalNotificationsPlugin(),
      fenix: true,
    );
    Get.lazyPut<BatteryMonitorController>(
      () => BatteryMonitorController(notifications: Get.find()),
    );
  }
}
