import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Detecta sacudidas verticales (eje Y) del dispositivo mediante el acelerómetro.
class VerticalShakeDetectorService {
  VerticalShakeDetectorService({
    this.peakThreshold = 3.5,
    this.requiredPeaks = 3,
    this.detectionWindow = const Duration(milliseconds: 900),
    this.cooldown = const Duration(seconds: 2),
  });

  final double peakThreshold;
  final int requiredPeaks;
  final Duration detectionWindow;
  final Duration cooldown;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  bool _listening = false;

  double _lastY = 0;
  bool _initialized = false;
  bool? _lastDirectionUp;
  int _peaks = 0;
  DateTime? _windowStart;
  DateTime? _lastTrigger;

  bool get isListening => _listening;

  void start(void Function() onShake) {
    if (_listening || kIsWeb) return;

    _listening = true;
    _resetState();

    _subscription = userAccelerometerEventStream().listen(
      (event) {
        if (_processSample(event.y)) {
          onShake();
        }
      },
      onError: (_) => stop(),
      cancelOnError: false,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _listening = false;
    _resetState();
  }

  void _resetState() {
    _initialized = false;
    _lastDirectionUp = null;
    _peaks = 0;
    _windowStart = null;
  }

  bool _processSample(double y) {
    if (!_initialized) {
      _lastY = y;
      _initialized = true;
      return false;
    }

    final now = DateTime.now();
    if (_lastTrigger != null && now.difference(_lastTrigger!) < cooldown) {
      return false;
    }

    final delta = y - _lastY;
    _lastY = y;

    if (delta.abs() < peakThreshold) return false;

    final goingUp = delta > 0;
    if (_lastDirectionUp == goingUp) return false;

    _lastDirectionUp = goingUp;

    if (_windowStart == null || now.difference(_windowStart!) > detectionWindow) {
      _windowStart = now;
      _peaks = 1;
      return false;
    }

    _peaks++;
    if (_peaks < requiredPeaks) return false;

    _lastTrigger = now;
    _peaks = 0;
    _windowStart = null;
    _lastDirectionUp = null;
    return true;
  }
}
