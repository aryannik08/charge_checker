import 'package:charge_checker/presentation/ui/base/splash_page/splash_binding.dart';
import 'package:charge_checker/presentation/ui/base/splash_page/splash_page.dart';
import 'package:charge_checker/presentation/ui/battery_monitor/battery_monitor_page.dart';
import 'package:charge_checker/presentation/ui/battery_monitor/battery_monitor_binding.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String splash = '/home';
  static const String batteryMonitor = '/batteryMonitor';

  static List<GetPage> routes = [
    GetPage(
      name: splash,
      page: () => SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: batteryMonitor,
      page: () => BatteryMonitorPage(notifications: Get.find()),
      binding: BatteryMonitorBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ),
    // Item page removed
  ];
}
