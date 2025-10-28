import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/storage_service.dart';

class ThemeController extends GetxController {
  final StorageService storage = Get.find<StorageService>();
  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    String? savedThemeMode = storage.themeMode;
    if (savedThemeMode == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (savedThemeMode == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  void changeThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    if (mode == ThemeMode.light) {
      storage.themeMode = 'light';
    } else if (mode == ThemeMode.dark) {
      storage.themeMode = 'dark';
    } else {
      storage.themeMode = 'system';
    }
  }
}
