import 'package:charge_checker/presentation/ui/base/splash_page/splash_binding.dart';
import 'package:charge_checker/presentation/ui/base/splash_page/splash_page.dart';
import 'package:flutter/animation.dart';
import 'package:get/get.dart';

class AppRoutes {
  static const String home = '/home';

  static List<GetPage> routes = [
    GetPage(
      name: home,
      page: () => SplashPage(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    ),
    // Item page removed
  ];
}
