import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/storage/storage_service.dart';
import 'presentation/style/theme.dart';
import 'presentation/style/theme_controller.dart';
import 'presentation/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  Get.put(flutterLocalNotificationsPlugin, permanent: true);
  await _initServices();
  runApp(const MyApp());
}

Future<void> _initServices() async {
  await GetStorage.init('app_storage');
  Get.put(StorageService(), permanent: true);
  Get.put(ThemeController(), permanent: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final ThemeData currentTheme =
          themeController.themeMode.value == ThemeMode.dark
          ? AppTheme.darkTheme
          : themeController.themeMode.value == ThemeMode.light
          ? AppTheme.lightTheme
          : (MediaQuery.of(context).platformBrightness == Brightness.dark
                ? AppTheme.darkTheme
                : AppTheme.lightTheme);

      return AnimatedTheme(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        data: currentTheme,
        child: GetMaterialApp(
          title: 'GetX Flutter App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode.value,
          initialRoute:
              AppRoutes.batteryMonitor, // Changed from AppRoutes.splash
          getPages: AppRoutes.routes,
        ),
      );
    });
  }
}
