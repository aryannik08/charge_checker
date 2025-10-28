import 'dart:async';
import 'package:get/get.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart'; // Import for Brightness

class BatteryMonitorController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final Battery _battery = Battery();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _pollTimer;

  final RxInt level = 0.obs;
  final Rx<BatteryState> state = BatteryState.unknown.obs;
  final RxBool monitoring = true.obs;
  final RxInt threshold = 80.obs;
  final RxBool hasPlayed = false.obs;
  final Rx<DateTime?> lastPlayed = Rx<DateTime?>(null);

  late final AnimationController pulseController;
  late final AnimationController bgController;

  final FlutterLocalNotificationsPlugin notifications;

  BatteryMonitorController({required this.notifications});

  @override
  void onInit() {
    super.onInit();
    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initBattery();
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _initBattery() async {
    level.value = await _battery.batteryLevel;
    state.value = await _battery.batteryState;

    _stateSub = _battery.onBatteryStateChanged.listen((s) async {
      state.value = s;
      level.value = await _battery.batteryLevel;
      _checkAndNotify();
      _animateBackgroundForState();
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (monitoring.value) {
        level.value = await _battery.batteryLevel;
        _checkAndNotify();
      }
    });

    _animateBackgroundForState();
  }

  void _animateBackgroundForState() {
    if (state.value == BatteryState.charging) {
      bgController.forward();
    } else {
      bgController.reverse();
    }
  }

  Future<void> _checkAndNotify() async {
    if (state.value == BatteryState.charging &&
        level.value >= threshold.value &&
        !hasPlayed.value) {
      hasPlayed.value = true;
      pulseController.repeat(reverse: true);
      await _player.play(AssetSource('audio/charge_full.mp3'));
      lastPlayed.value = DateTime.now();
      await _showNotification();
      Future.delayed(const Duration(seconds: 4), () {
        if (pulseController.isAnimating) {
          pulseController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 400),
          );
        }
      });
    } else if (level.value < threshold.value ||
        state.value != BatteryState.charging) {
      if (hasPlayed.value) {
        hasPlayed.value = false;
        pulseController.stop();
        pulseController.value = 0.0;
      }
    }
  }

  Future<void> _showNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'battery_channel',
      'Battery Notifications',
      channelDescription: 'Notifies when battery reaches threshold',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      '🔋 شارژ کامل یا نزدیک به کامل',
      'باتری در سطح ${level.value}% قرار دارد.',
      notificationDetails,
    );
  }

  void updateThreshold(double value) {
    threshold.value = value.round();
    _checkAndNotify();
  }

  Future<void> refreshBatteryStatus() async {
    level.value = await _battery.batteryLevel;
    state.value = await _battery.batteryState;
    _checkAndNotify();
  }

  Future<void> testNotification() async {
    await _player.play(AssetSource('audio/charge_full.mp3'));
    lastPlayed.value = DateTime.now();
    await _showNotification();
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    pulseController.dispose();
    bgController.dispose();
    super.onClose();
  }
}
