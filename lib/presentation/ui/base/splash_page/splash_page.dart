import 'package:charge_checker/presentation/ui/base/splash_page/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {


    return GetBuilder(
      init: SplashController(),
      builder: (controller) => Scaffold(
        body: SafeArea(
          bottom: true,
          child: Center(
            child: FlutterLogo(),
          ),
        ),
      ),
    );
  }
}
