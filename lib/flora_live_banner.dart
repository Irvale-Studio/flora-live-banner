import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Flora Live "Video identification" home banner.
///
/// A self-contained, looping prototype of the PlantSnap Flora Live banner.
/// The right-hand tile plays a live phone-camera scene: the camera pans a room,
/// zooms out onto a plant, autofocus locks, a capture burst fires, and Flora
/// returns the name. Everything is drawn in Flutter, no video file.
///
/// Drop-in:
/// ```dart
/// FloraLiveBanner(onStart: () => openFloraLive())
/// ```
///
/// One asset is required: the Flora avatar PNG, declared in pubspec.yaml.
/// Default path: assets/flora_expert.png (override with [avatarAsset]).
class FloraLiveBanner extends StatefulWidget {
  const FloraLiveBanner({
    super.key,
    this.onStart,
    this.avatarAsset = 'assets/flora_expert.png',
    this.title = 'Video identification',
    this.ctaLabel = 'Start Flora Live',
    this.speciesName = 'Monstera',
    this.fontFamily = 'Montserrat',
  });

  /// Called when the user taps the CTA.
  final VoidCallback? onStart;

  /// Asset path of the circular Flora avatar image.
  final String avatarAsset;

  final String title;
  final String ctaLabel;
  final String speciesName;

  /// App font. Montserrat in PlantSnap; falls back to the platform font.
  final String fontFamily;

  @override
  State<FloraLiveBanner> createState() => _FloraLiveBannerState();
}

class _FloraLiveBannerState extends State<FloraLiveBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _recTimer;
  int _recSecs = 4;

  // Kit tokens.
  static const _flora = Color(0xFF7321D7);
  static const _floraStrong = Color(0xFF730EC3);
  static const _green = Color(0xFF1F8505);
  static const _ink = Color(0xFF0C3B2E);
  static const _mint = Color(0xFF7CFFB0);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recSecs = (_recSecs + 1) % 3600);
    });
  }

  @override
  void dispose() {
    _recTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  // Piecewise-linear keyframe interpolation over the 0..1 loop.
  double _seg(double p, List<double> st, List<double> vs) {
    if (p <= st.first) return vs.first;
    if (p >= st.last) return vs.last;
    for (var i = 0; i < st.length - 1; i++) {
      if (p >= st[i] && p <= st[i + 1]) {
        final t = (p - st[i]) / (st[i + 1] - st[i]);
        return vs[i] + (vs[i + 1] - vs[i]) * t;
      }
    }
    return vs.last;
  }

  ColorFilter _brightness(double b) => ColorFilter.matrix(<double>[
        b, 0, 0, 0, 0, //
        0, b, 0, 0, 0, //
        0, 0, b, 0, 0, //
        0, 0, 0, 1, 0, //
      ]);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 361,
      height: 186,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF221052), Color(0xFF45169E), Color(0xFF6A20C6)],
          stops: [0, .55, 1],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66451791), blurRadius: 40, offset: Offset(0, 16)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -30,
            child: Container(
              width: 186,
              height: 186,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x52E000FF), Color(0x00E000FF)],
                  stops: [0, .62],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _copy()),
              SizedBox(width: 130, child: Center(child: _tile())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _copy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 6, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIVE pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LiveDot(),
                const SizedBox(width: 6),
                Text('LIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                        fontFamily: widget.fontFamily)),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(widget.title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.2,
                  fontFamily: widget.fontFamily)),
          const SizedBox(height: 11),
          // CTA
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: widget.onStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        width: 17,
                        height: 17,
                        child: CustomPaint(painter: _VideoIcon(_floraStrong))),
                    const SizedBox(width: 8),
                    Text(widget.ctaLabel,
                        style: TextStyle(
                            color: _floraStrong,
                            fontSize: 13.5,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            fontFamily: widget.fontFamily)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile() {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = _c.value;

        // world filters
        final blur = _seg(p, [0, .08, .34, .46, .49, .88, 1],
            [3, 2.4, 1.3, 0, 0, 0, 3]);
        final bright = _seg(p, [0, .08, .34, .46, .49, .88, 1],
            [.5, 1, 1, 1.12, 1, 1, .5]);

        // handheld shake (2.6s cycle)
        final g = (p * 8 / 2.6) % 1;
        final shx = _seg(g, [0, .2, .45, .7, 1], [0, 1.4, -1.2, 1, 0]);
        final shy = _seg(g, [0, .2, .45, .7, 1], [0, -1, 1.2, 1.4, 0]);
        final shr = _seg(g, [0, .2, .45, .7, 1], [0, .5, -.4, .3, 0]);

        // camera layers
        final ntx =
            _seg(p, [0, .42, .46, .5, .86, 1], [18, -78, -78, -78, -80, 18]);
        final nty =
            _seg(p, [0, .42, .46, .5, .86, 1], [20, -13, -13, -13, -14, 20]);
        final ns = _seg(
            p, [0, .42, .46, .5, .86, 1], [.95, 1.12, 1.16, 1.12, 1.13, .95]);
        final ftx = _seg(p, [0, .42, .86, 1], [6, -50, -52, 6]);
        final fty = _seg(p, [0, .42, .86, 1], [10, -14, -15, 10]);
        final fs = _seg(p, [0, .42, .86, 1], [1.0, 1.14, 1.15, 1.0]);
        final otx = _seg(p, [0, .42, .86, 1], [-6, -150, -158, -6]);
        final oty = _seg(p, [0, .42, .86, 1], [64, 10, 8, 64]);
        final os = _seg(p, [0, .42, .86, 1], [1.3, 1.7, 1.72, 1.3]);

        // ui timeline
        final gridO = _seg(p, [0, .14, .22, .44, .52, 1], [0, 0, .5, .5, 0, 0]);
        final retiO = _seg(p, [0, .14, .22, .42, .46, 1], [0, 0, .9, .9, 0, 0]);
        final retiS =
            _seg(p, [0, .14, .22, .42, .46, 1], [1.4, 1.4, 1.1, 1, .92, .92]);
        final retigO = _seg(p, [0, .44, .46, .8, .92, 1], [0, 0, 1, 1, 0, 0]);
        final afO = _seg(
            p, [0, .30, .34, .44, .46, 1], [0, 0, .9, 1, 0, 0]);
        final afS = _seg(
            p, [0, .30, .34, .44, .46, 1], [1.6, 1.6, 1.18, 1, .86, .86]);
        final shutO = _seg(p, [0, .455, .465, .49, 1], [0, 0, .85, 0, 0]);
        final ringO = _seg(p, [0, .45, .47, .60, 1], [0, 0, .95, 0, 0]);
        final ringS = _seg(p, [0, .45, .47, .60, 1], [.4, .4, .7, 3.1, 3.1]);
        final sparkO = _seg(p, [0, .45, .47, .60, 1], [0, 0, 1, 0, 0]);
        final sparkF = _seg(p, [0, .45, .47, .60, 1], [0, 0, .3, 1, 1]);
        final scanO = _seg(p, [0, .50, .54, .66, .70, 1], [0, 0, 1, 1, 0, 0]);
        final scanY = _seg(p, [0, .50, .54, .66, .70, 1], [0, 0, 6, 120, 120, 0]);
        final resO = _seg(p, [0, .58, .64, .86, .94, 1], [0, 0, 1, 1, 0, 0]);
        final resY = _seg(p, [0, .58, .64, .86, .94, 1], [8, 8, 0, 0, 8, 8]);
        final wakeO = _seg(p, [0, .08, .90, 1], [.9, 0, 0, .9]);

        // OverflowBox lets the 210x150 world layers keep their real size
        // instead of being clamped to the 108x134 tile (which left the frame
        // half black after the camera transform).
        Widget layer(double tx, double ty, double s, Widget child) => Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.identity()
                ..translate(tx, ty)
                ..scale(s),
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: double.infinity,
                child: child,
              ),
            );

        return SizedBox(
          width: 108,
          height: 134,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 108,
                  height: 134,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D0B12),
                    border: Border.all(
                        color: Colors.white.withOpacity(.6), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ---- world (blur + brightness + shake) ----
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                              sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal),
                          child: ColorFiltered(
                            colorFilter: _brightness(bright),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..translate(shx, shy)
                                ..rotateZ(shr * math.pi / 180),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  layer(ftx, fty, fs, const _Room()),
                                  layer(
                                      ntx,
                                      nty,
                                      ns,
                                      SizedBox(
                                        width: 210,
                                        height: 150,
                                        child: SvgPicture.string(_plantSvg,
                                            width: 210,
                                            height: 150,
                                            fit: BoxFit.fill),
                                      )),
                                  layer(
                                      otx,
                                      oty,
                                      os,
                                      ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(
                                            sigmaX: 2.6, sigmaY: 2.6),
                                        child: const _ForeLeaf(),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ---- vignette ----
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                radius: .95,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(.5)
                                ],
                                stops: const [.6, 1],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ---- framing grid ----
                      Positioned.fill(
                        child: Opacity(
                          opacity: gridO,
                          child: CustomPaint(painter: _GridPainter()),
                        ),
                      ),
                      // ---- brackets (white hunting, green lock) ----
                      Positioned.fill(
                        child: Opacity(
                          opacity: retiO,
                          child: Transform.scale(
                            scale: retiS,
                            child: CustomPaint(
                                painter: _Brackets(Colors.white, false)),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: retigO,
                          child: CustomPaint(painter: _Brackets(_mint, true)),
                        ),
                      ),
                      // ---- autofocus square ----
                      Positioned(
                        left: 37,
                        top: 43,
                        child: Opacity(
                          opacity: afO,
                          child: Transform.scale(
                            scale: afS,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 1.6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ---- capture ring ----
                      Positioned(
                        left: 44,
                        top: 50,
                        child: Opacity(
                          opacity: ringO,
                          child: Transform.scale(
                            scale: ringS,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: _mint, width: 2.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ---- sparks ----
                      ..._sparks(sparkO, sparkF),
                      // ---- Flora scan sweep ----
                      Positioned(
                        left: 6,
                        right: 6,
                        top: 8,
                        child: Transform.translate(
                          offset: Offset(0, scanY),
                          child: Opacity(
                            opacity: scanO,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(colors: [
                                  Color(0x007CFFB0),
                                  _mint,
                                  Color(0xFFE000FF),
                                  Color(0x00E000FF),
                                ]),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0xB3E000FF), blurRadius: 12)
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ---- voice wave ----
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: Center(child: _VoiceWave(phase: p)),
                      ),
                      // ---- result chip ----
                      Positioned(
                        left: 6,
                        right: 6,
                        bottom: 6,
                        child: Opacity(
                          opacity: resO,
                          child: Transform.translate(
                            offset: Offset(0, resY),
                            child: _resultChip(),
                          ),
                        ),
                      ),
                      // ---- REC pill ----
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0x8C0A0610),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Opacity(
                                opacity: 0.55 +
                                    0.45 *
                                        (0.5 +
                                            0.5 *
                                                math.cos((p * 8 / 1.4) % 1 *
                                                    2 *
                                                    math.pi)),
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFFF2D55)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'REC ${_recSecs ~/ 60}:${(_recSecs % 60).toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontFamily: widget.fontFamily,
                                  fontFeatures: const [
                                    ui.FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // ---- shutter flash ----
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                              opacity: shutO,
                              child: const ColoredBox(color: Colors.white)),
                        ),
                      ),
                      // ---- wake / reset ----
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                              opacity: wakeO,
                              child: const ColoredBox(color: Color(0xFF0A0710))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ---- Flora avatar, overhanging the corner ----
              Positioned(
                left: -11,
                bottom: -13,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x80000000),
                          blurRadius: 14,
                          offset: Offset(0, 5)),
                    ],
                    image: DecorationImage(
                      image: AssetImage(widget.avatarAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _sparks(double o, double f) {
    const data = <List<double>>[
      [26, -20],
      [-24, -14],
      [22, 22],
      [-26, 18],
      [4, -30],
      [-6, 28],
    ];
    const colors = [_mint, Colors.white, Color(0xFFE0A9FF), _mint, Colors.white, Color(0xFFC02AFF)];
    return [
      for (var i = 0; i < data.length; i++)
        Positioned(
          left: 54 - 2.5,
          top: 60 - 2.5,
          child: Transform.translate(
            offset: Offset(data[i][0] * f, data[i][1] * f),
            child: Opacity(
              opacity: o,
              child: Container(
                width: 5,
                height: 5,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: colors[i]),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _resultChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.96),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FLORA',
              style: TextStyle(
                  color: _flora,
                  fontSize: 6.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .65,
                  fontFamily: widget.fontFamily)),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: _green),
                child: const Center(
                  child: SizedBox(
                      width: 9,
                      height: 9,
                      child: CustomPaint(painter: _CheckIcon(Colors.white))),
                ),
              ),
              const SizedBox(width: 6),
              Text(widget.speciesName,
                  style: TextStyle(
                      color: _ink,
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      fontFamily: widget.fontFamily)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFFFF2D55)),
      );
}

class _VoiceWave extends StatelessWidget {
  const _VoiceWave({required this.phase});
  final double phase;

  double _bar(double delay) {
    final ph = ((phase * 8 - delay) % 1 + 1) % 1;
    return .22 + .78 * (0.5 - 0.5 * math.cos(ph * 2 * math.pi));
  }

  @override
  Widget build(BuildContext context) {
    const delays = [0.0, .12, .26, .38, .2, .3, .16];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in delays)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 2.5,
              height: 15 * _bar(d),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100)),
            ),
          ),
      ],
    );
  }
}

/// Flat 2D room behind the plant (cream wall, window, light, floor).
class _Room extends StatelessWidget {
  const _Room();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 150,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEDE7D9), Color(0xFFE7DECB), Color(0xFFE1D6C0)],
                  stops: [0, .62, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 16,
            child: Container(
              width: 60,
              height: 66,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFFFBF6EC), Color(0xFFE9EFDD)],
                ),
              ),
              child: CustomPaint(painter: _WindowBars()),
            ),
          ),
          Positioned(
            right: 18,
            top: 22,
            child: Container(
              width: 26,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFD8CDB4),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFEDE7D9), width: 3),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD8CBAF), Color(0xFFCBBD9C)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowBars extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFDACFB6);
    canvas.drawRect(
        Rect.fromLTWH(size.width / 2 - 1, 6, 2, size.height - 12), p);
    canvas.drawRect(
        Rect.fromLTWH(6, size.height / 2 - 1, size.width - 12, 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ForeLeaf extends StatelessWidget {
  const _ForeLeaf();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Opacity(
        opacity: .9,
        child: ClipPath(
          clipper: _LeafClipper(),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.2),
                radius: .8,
                colors: [Color(0xFF3F8A34), Color(0xFF2C6A24)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeafClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    // rough monstera-leaf silhouette
    final pts = <Offset>[
      Offset(0, .40 * s.height),
      Offset(.42 * s.width, .10 * s.height),
      Offset(.70 * s.width, 0),
      Offset(.58 * s.width, .34 * s.height),
      Offset(s.width, .30 * s.height),
      Offset(.66 * s.width, .56 * s.height),
      Offset(.88 * s.width, .92 * s.height),
      Offset(.44 * s.width, .66 * s.height),
      Offset(.20 * s.width, s.height),
      Offset(.26 * s.width, .58 * s.height),
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(.6)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 3, 0),
        Offset(size.width / 3, size.height), p);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), p);
    canvas.drawLine(
        Offset(0, size.height / 3), Offset(size.width, size.height / 3), p);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Four L-shaped viewfinder corners inside the inset frame.
class _Brackets extends CustomPainter {
  _Brackets(this.color, this.glow);
  final Color color;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    const l = 12.0; // inset left
    const t = 12.0; // inset top
    const r = 12.0; // inset right
    const b = 18.0; // inset bottom
    const arm = 12.0;
    final rect = Rect.fromLTRB(l, t, size.width - r, size.height - b);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (glow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }
    // TL
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(arm, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, arm), paint);
    // TR
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-arm, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, arm), paint);
    // BL
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(arm, 0), paint);
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft + const Offset(0, -arm), paint);
    // BR
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(-arm, 0), paint);
    canvas.drawLine(
        rect.bottomRight, rect.bottomRight + const Offset(0, -arm), paint);
  }

  @override
  bool shouldRepaint(covariant _Brackets oldDelegate) =>
      oldDelegate.color != color;
}

/// Camcorder glyph for the CTA (no icon-font dependency).
class _VideoIcon extends CustomPainter {
  const _VideoIcon(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 24.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(2 * k, 6 * k, 13 * k, 12 * k), Radius.circular(3 * k)),
      p,
    );
    final tri = Path()
      ..moveTo(22 * k, 8.5 * k)
      ..lineTo(22 * k, 15.5 * k)
      ..lineTo(17 * k, 12 * k)
      ..close();
    c.drawPath(tri, p);
  }

  @override
  bool shouldRepaint(covariant _VideoIcon o) => o.color != color;
}

/// Checkmark glyph for the result chip (no icon-font dependency).
class _CheckIcon extends CustomPainter {
  const _CheckIcon(this.color);
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / 24.0;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(
      Path()
        ..moveTo(5 * k, 13 * k)
        ..lineTo(9 * k, 17 * k)
        ..lineTo(19 * k, 7 * k),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckIcon o) => o.color != color;
}

/// Flat monstera in a tapered black pot, matching the design kit.
const String _plantSvg = r'''<svg viewBox="0 0 210 150" preserveAspectRatio="none" width="210" height="150" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="118" cy="128" rx="40" ry="7" fill="#3C2D14" fill-opacity=".28"/>
<g stroke="#2F7D32" stroke-width="3" fill="none" stroke-linecap="round">
<path d="M118 118 C 116 96 112 84 100 70"/><path d="M118 118 C 120 96 126 84 138 70"/>
<path d="M118 118 C 118 98 118 86 118 66"/><path d="M118 118 C 114 100 104 92 92 86"/>
<path d="M118 118 C 122 100 132 92 144 86"/></g>
<g fill="#2E7D32">
<path d="M92 86 c -16 -3 -24 -16 -18 -32 c 4 -10 14 -13 20 -12 c 8 2 13 13 12 24 c -1 12 -8 20 -14 20 z"/>
<path d="M144 86 c 16 -3 24 -16 18 -32 c -4 -10 -14 -13 -20 -12 c -8 2 -13 13 -12 24 c 1 12 8 20 14 20 z"/></g>
<g fill="#4CA152">
<path d="M100 72 c -18 -2 -28 -18 -21 -37 c 5 -12 17 -15 24 -13 c 9 3 15 16 13 29 c -2 15 -10 23 -16 21 z"/>
<path d="M138 72 c 18 -2 28 -18 21 -37 c -5 -12 -17 -15 -24 -13 c -9 3 -15 16 -13 29 c 2 15 10 23 16 21 z"/>
<path d="M118 66 c -13 0 -22 -14 -22 -34 c 0 -14 11 -22 22 -22 c 11 0 22 8 22 22 c 0 20 -9 34 -22 34 z"/></g>
<g stroke="#DCF2CE" stroke-width="1.4" fill="none" opacity=".65" stroke-linecap="round">
<path d="M118 62 L118 16"/><path d="M101 68 C 96 50 90 40 82 34"/><path d="M137 68 C 142 50 148 40 156 34"/></g>
<g fill="#2E7D32" opacity=".9"><path d="M118 30 l6 8 l-6 4 z"/><path d="M118 44 l-6 6 l6 4 z"/>
<path d="M104 44 l5 6 l-6 2 z"/><path d="M132 44 l-5 6 l6 2 z"/></g>
<path d="M96 86 L140 86 L133 120 L103 120 Z" fill="#17130F"/>
<path d="M96 86 L140 86 L138 92 L98 92 Z" fill="#241C15"/>
<ellipse cx="118" cy="86" rx="22" ry="5.5" fill="#241C15"/>
<ellipse cx="118" cy="86" rx="18" ry="4" fill="#3A2A1C"/>
<path d="M103 120 L133 120 L131 124 L105 124 Z" fill="#0E0B08"/></svg>''';
