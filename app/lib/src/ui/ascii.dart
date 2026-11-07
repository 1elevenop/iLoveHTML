import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_settings.dart';
import 'theme.dart';

/// The iLoveHTML logo in ASCII.
const asciiLogo = r'''
 _ _                    _   _ _____ __  __ _
(_) |    _____   _____ | | | |_   _|  \/  | |
| | |   / _ \ \ / / _ \| |_| | | | | |\/| | |
| | |__| (_) \ V /  __/|  _  | | | | |  | | |___
|_|_____\___/ \_/ \___||_| |_| |_| |_|  |_|_____|''';

const asciiTagline = '<html> -> app  <3';

const _emptyArt = r'''
 +------------------+
 | <html>           |
 |   <body>         |
 |     <h1><3</h1>  |
 |   </body>        |
 | </html>          |
 +------------------+''';

TextStyle _asciiStyle(BuildContext context, {double size = 12, Color? color}) => TextStyle(
      fontFamily: Eleven.font,
      fontFamilyFallback: Eleven.fallback,
      fontSize: size,
      height: 1.15,
      color: color ?? context.eleven.fg,
    );

/// Types the ASCII logo out at launch, then fades into [child].
/// Skipped when animations are off; a tap skips it too.
class AsciiSplash extends StatefulWidget {
  const AsciiSplash({super.key, required this.settings, required this.child});

  final AppSettings settings;
  final Widget child;

  @override
  State<AsciiSplash> createState() => _AsciiSplashState();
}

class _AsciiSplashState extends State<AsciiSplash> with SingleTickerProviderStateMixin {
  static const _typing = 0.75;

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        });
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (animationsOn(context, widget.settings)) {
      _anim.forward();
    } else {
      _done = true;
    }
  }

  void _finish() {
    if (!_done && mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _done ? widget.child : _splash(context),
    );
  }

  Widget _splash(BuildContext context) {
    final e = context.eleven;
    return GestureDetector(
      key: const ValueKey('splash'),
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final t = math.min(1.0, _anim.value / _typing);
                  final shown = (asciiLogo.length * t).floor();
                  final cursorOn = (_anim.value * 12).floor().isEven;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: asciiLogo.substring(0, shown)),
                            TextSpan(text: cursorOn ? '█' : ' ', style: TextStyle(color: e.acc)),
                          ]),
                          style: _asciiStyle(context, size: 13),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: t >= 1 ? 1 : 0,
                          child: Text(asciiTagline, style: _asciiStyle(context, size: 13, color: e.acc)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ASCII drawing for the empty project list, with a blinking cursor.
class AsciiEmptyArt extends StatefulWidget {
  const AsciiEmptyArt({super.key, required this.animate});

  final bool animate;

  @override
  State<AsciiEmptyArt> createState() => _AsciiEmptyArtState();
}

class _AsciiEmptyArtState extends State<AsciiEmptyArt> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _blink.repeat();
  }

  @override
  void didUpdateWidget(AsciiEmptyArt old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_blink.isAnimating) {
      _blink.repeat();
    } else if (!widget.animate) {
      _blink.stop();
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedBuilder(
          animation: _blink,
          builder: (context, _) {
            final on = !widget.animate || _blink.value < 0.5;
            // The heart is the one accent in the drawing.
            final parts = _emptyArt.split('<3');
            return Text.rich(
              TextSpan(children: [
                TextSpan(text: parts[0]),
                TextSpan(text: '<3', style: TextStyle(color: e.acc)),
                TextSpan(text: parts[1]),
                TextSpan(text: on ? '\n  > _' : '\n  >  ', style: TextStyle(color: e.acc)),
              ]),
              style: _asciiStyle(context, size: 13, color: e.mute),
            );
          },
        ),
      ),
    );
  }
}

/// A terminal-style busy indicator for builds: a spinner and a block that
/// bounces along a bar. Builds report no percentage, so it is indeterminate.
class AsciiBuildProgress extends StatefulWidget {
  const AsciiBuildProgress({super.key, required this.label, required this.animate});

  /// Shown after the bar, e.g. "Building… 42 log lines".
  final String label;
  final bool animate;

  @override
  State<AsciiBuildProgress> createState() => _AsciiBuildProgressState();
}

class _AsciiBuildProgressState extends State<AsciiBuildProgress> with SingleTickerProviderStateMixin {
  static const _spinner = ['|', '/', '-', r'\'];
  static const _width = 22, _block = 5;

  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _anim.repeat();
  }

  @override
  void didUpdateWidget(AsciiBuildProgress old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!widget.animate) {
      _anim.stop();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = context.eleven;
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            final String bar, spin;
            if (widget.animate) {
              // Ping-pong position of the block.
              final travel = _width - _block;
              final phase = _anim.value * 2;
              final pos = ((phase <= 1 ? phase : 2 - phase) * travel).round();
              bar = '${' ' * pos}${'#' * _block}${' ' * (travel - pos)}';
              spin = _spinner[(_anim.value * 16).floor() % _spinner.length];
            } else {
              bar = '${'#' * (_width ~/ 2)}${' ' * (_width - _width ~/ 2)}';
              spin = '*';
            }
            return Text.rich(
              TextSpan(children: [
                TextSpan(text: '$spin ', style: TextStyle(color: e.acc)),
                const TextSpan(text: '['),
                TextSpan(text: bar, style: TextStyle(color: e.acc)),
                TextSpan(text: '] ${widget.label}'),
              ]),
              style: _asciiStyle(context, size: 12.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ),
    );
  }
}
