import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ElevatorLoadingGate extends StatefulWidget {
  final bool loading;
  final Widget child;

  const ElevatorLoadingGate({
    super.key,
    required this.loading,
    required this.child,
  });

  @override
  State<ElevatorLoadingGate> createState() => _ElevatorLoadingGateState();
}

class _ElevatorLoadingGateState extends State<ElevatorLoadingGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
      reverseDuration: const Duration(milliseconds: 880),
    );

    if (widget.loading) {
      _showOverlay = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ElevatorLoadingGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading == oldWidget.loading) return;

    if (widget.loading) {
      setState(() => _showOverlay = true);
      _controller.forward();
    } else {
      _controller.reverse().whenComplete(() {
        if (!mounted || widget.loading) return;
        setState(() => _showOverlay = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Positioned.fill(child: _ElevatorDoorOverlay(animation: _controller)),
      ],
    );
  }
}

class _ElevatorDoorOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ElevatorDoorOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    final doorCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final logoOpacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.22, 0.9, curve: Curves.easeOut),
      reverseCurve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );

    return Material(
      color: Colors.white,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth = constraints.maxWidth / 2;
              final value = doorCurve.value;

              return Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.white),
                  Transform.translate(
                    offset: Offset(-halfWidth * (1 - value), 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _DoorPanel(
                        width: halfWidth + 1,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(halfWidth * (1 - value), 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _DoorPanel(
                        width: halfWidth + 1,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  if (value > 0.08)
                    Center(
                      child: Opacity(
                        opacity: logoOpacity.value,
                        child: Transform.scale(
                          scale: 0.92 + (0.08 * value),
                          child: Container(
                            width: 116,
                            height: 116,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/app_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DoorPanel extends StatelessWidget {
  final double width;
  final Alignment alignment;

  const _DoorPanel({required this.width, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.vwBlue,
        border: Border(
          left: alignment == Alignment.centerLeft
              ? BorderSide(color: Colors.white.withValues(alpha: 0.16))
              : BorderSide.none,
          right: alignment == Alignment.centerRight
              ? BorderSide(color: Colors.white.withValues(alpha: 0.16))
              : BorderSide.none,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 22),
        ],
      ),
      child: Align(
        alignment: alignment,
        child: Container(width: 1, color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}
