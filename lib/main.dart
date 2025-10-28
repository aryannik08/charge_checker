import 'dart:async';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: android);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(MyApp(notifications: flutterLocalNotificationsPlugin));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin notifications;

  const MyApp({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Monitor (Animated)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: BatteryMonitorPage(notifications: notifications),
    );
  }
}

class BatteryMonitorPage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifications;

  const BatteryMonitorPage({super.key, required this.notifications});

  @override
  State<BatteryMonitorPage> createState() => _BatteryMonitorPageState();
}

class _BatteryMonitorPageState extends State<BatteryMonitorPage>
    with TickerProviderStateMixin {
  final Battery _battery = Battery();
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _pollTimer;

  int _level = 0;
  BatteryState _state = BatteryState.unknown;
  bool _monitoring = true;
  int _threshold = 80;
  bool _hasPlayed = false;
  DateTime? _lastPlayed;

  // animation controllers
  late final AnimationController
  _pulseController; // for pulsing battery when threshold reached
  late final AnimationController _bgController; // for background gradient tween

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initBattery();
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _initBattery() async {
    _level = await _battery.batteryLevel;
    _state = await _battery.batteryState;
    setState(() {});

    _stateSub = _battery.onBatteryStateChanged.listen((s) async {
      _state = s;
      _level = await _battery.batteryLevel;
      _checkAndNotify();
      _animateBackgroundForState();
      setState(() {});
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (_monitoring) {
        _level = await _battery.batteryLevel;
        _checkAndNotify();
        setState(() {});
      }
    });

    // initial background animation based on state
    _animateBackgroundForState();
  }

  void _animateBackgroundForState() {
    if (_state == BatteryState.charging) {
      _bgController.forward();
    } else {
      _bgController.reverse();
    }
  }

  Future<void> _checkAndNotify() async {
    if (_state == BatteryState.charging &&
        _level >= _threshold &&
        !_hasPlayed) {
      _hasPlayed = true;
      _pulseController.repeat(reverse: true);
      await _player.play(AssetSource('audio/charge_full.mp3'));
      _lastPlayed = DateTime.now();
      await _showNotification();
      // stop pulsing after a short while but leave a gentle pulse
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted)
          _pulseController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 400),
          );
      });
      if (mounted) setState(() {});
    } else if (_level < _threshold || _state != BatteryState.charging) {
      if (_hasPlayed) {
        _hasPlayed = false;
        _pulseController.stop();
        _pulseController.value = 0.0;
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

    await widget.notifications.show(
      0,
      '🔋 شارژ کامل یا نزدیک به کامل',
      'باتری در سطح $_level% قرار دارد.',
      notificationDetails,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    _pulseController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  // helper to draw battery fill width smoothly
  Widget _buildAnimatedBattery(double width) {
    final fillPercent = (_level.clamp(0, 100)).toDouble() / 100.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: fillPercent),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // outline
            CustomPaint(
              size: Size(width, 36),
              painter: _BatteryPainter(level: (_level)),
            ),
            // fill bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: (width - 8) * value,
                height: 28,
                decoration: BoxDecoration(
                  color: _level >= _threshold
                      ? Colors.greenAccent.shade700
                      : Colors.indigo,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // animated background colors depending on bgController value
    final theme = Theme.of(context);
    final Color topColor = Color.lerp(
      Colors.indigo.shade900,
      Colors.green.shade700,
      _bgController.value,
    )!;
    final Color bottomColor = Color.lerp(
      Colors.indigo.shade400,
      Colors.green.shade300,
      _bgController.value,
    )!;

    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [topColor, bottomColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  spacing: 70,
                  children: [
                    // header
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Icon(
                            _state == BatteryState.charging
                                ? Icons.battery_charging_full
                                : Icons.battery_std,
                            key: ValueKey(_state),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              _state == BatteryState.charging
                                  ? 'در حال شارژ...'
                                  : 'استفاده از باتری',
                              key: ValueKey(_state.toString()),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          '${_level}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // big battery + pulse effect when threshold reached
                    Center(
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                              CurvedAnimation(
                                parent: _pulseController,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _buildAnimatedBattery(220),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _hasPlayed
                                  ? 'هشدار ارسال شد'
                                  : (_state == BatteryState.charging
                                        ? 'در حال شارژ'
                                        : 'خالی شدن'),
                              key: ValueKey(
                                _hasPlayed.toString() + _state.toString(),
                              ),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_lastPlayed != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'آخرین هشدار: ${_lastPlayed!.toLocal()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // threshold slider with animated label
                    Card(
                      color: Colors.white.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 12,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.track_changes_outlined,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'حد آستانه',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(
                                    '$_threshold%',
                                    key: ValueKey(_threshold),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _threshold.toDouble(),
                              min: 50,
                              max: 100,
                              divisions: 10,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: (v) {
                                setState(() {
                                  _threshold = v.round();
                                });
                                _checkAndNotify();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.12),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final lvl = await _battery.batteryLevel;
                            final st = await _battery.batteryState;
                            setState(() {
                              _level = lvl;
                              _state = st;
                            });
                            _checkAndNotify();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('بروزرسانی'),
                        ),
                        GestureDetector(
                          onTapDown: (_) => _pulseController.forward(),
                          onTapUp: (_) => _pulseController.reverse(),
                          onTapCancel: () => _pulseController.reverse(),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.shade400,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              // manual test: play & notify
                              await _player.play(
                                AssetSource('audio/charge_full.mp3'),
                              );
                              _lastPlayed = DateTime.now();
                              await _showNotification();
                              setState(() {});
                            },
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('تست هشدار'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom battery painter (outline)
class _BatteryPainter extends CustomPainter {
  final int level;

  _BatteryPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * 0.88, size.height),
      Radius.circular(8),
    );
    canvas.drawRRect(body, stroke);

    final term = Rect.fromLTWH(
      size.width * 0.88 + 2,
      size.height * 0.22,
      size.width * 0.12 - 4,
      size.height * 0.56,
    );
    canvas.drawRect(term, stroke);

    // background fill (subtle)
    final bgFill = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width * 0.84, size.height - 8),
        Radius.circular(6),
      ),
      bgFill,
    );
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter oldDelegate) =>
      oldDelegate.level != level;
}
