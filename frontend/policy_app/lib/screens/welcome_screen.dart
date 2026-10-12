import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _gradientStart = Color(0xFF3B82F6);
  static const _gradientEnd = Color(0xFF8B5CF6);

  // ---- Visual-only tokens (redesign) ----
  // Same background image as the login and register screens.
  static const _backgroundAsset = 'assets/images/register_bg.png';
  static const _oxblood = Color(0xFF5E0E14);

  Widget _buildBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _oxblood),
        Image.asset(
          _backgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.bottomRight,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.15),
                Colors.black.withOpacity(0.25),
                Colors.black.withOpacity(0.60),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _oxblood,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Bounded height lets the Spacer push the buttons to the
                  // bottom; on very short screens the page scrolls instead.
                  final height =
                      constraints.maxHeight < 640 ? 640.0 : constraints.maxHeight;

                  return SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 640 : double.infinity,
                        ),
                        child: SizedBox(
                          height: height,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: isWide ? 40 : 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // LOGO ICON
                                _GlassIconCircle(),
                                const SizedBox(height: 22),

                                // BRAND NAME (with tiny blipping red light)
                                const _BrandName(),
                                const SizedBox(height: 26),

                                Text(
                                  'Protect your identity from insurance fraud',
                                  textAlign: TextAlign.left,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: isWide ? 40 : 34,
                                    height: 1.12,
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: -0.6,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Verify insurance policies linked to your South African ID number, detect fraudulent activity in real-time, and stay in control of your identity.',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Colors.white.withOpacity(0.82),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                const Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    _FeatureChip(
                                      icon: Icons.bolt_outlined,
                                      label: 'Real-time fraud detection',
                                    ),
                                    _FeatureChip(
                                      icon: Icons.verified_outlined,
                                      label: 'Instant verification',
                                    ),
                                    _FeatureChip(
                                      icon: Icons.lock_outline,
                                      label: 'Secure & private',
                                    ),
                                  ],
                                ),

                                const Spacer(),

                                // LOG IN — blue liquid glass
                                _GlassActionButton(
                                  label: 'Log In',
                                  blue: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/login',
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // CREATE ACCOUNT — crystal clear glass
                                _GlassActionButton(
                                  label: 'Create Account',
                                  blue: false,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/register',
                                  ),
                                ),
                                const SizedBox(height: 22),

                                Text(
                                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: Colors.white.withOpacity(0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// GLASS LOGO CIRCLE
// ------------------------------------------------------------

class _GlassIconCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.32),
            Colors.white.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.55),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.shield, color: Colors.white, size: 40),
    );
  }
}

// ------------------------------------------------------------
// BRAND NAME with a tiny red light that blips every 3 seconds
// ------------------------------------------------------------

class _BrandName extends StatefulWidget {
  const _BrandName();

  @override
  State<_BrandName> createState() => _BrandNameState();
}

class _BrandNameState extends State<_BrandName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 0..1 blip: quick rise, short fade, then rest until next cycle.
  double _blip(double v) {
    if (v < 0.06) return v / 0.06;
    if (v < 0.22) return 1 - ((v - 0.06) / 0.16);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 13, 20, 13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withOpacity(0.40),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PolicyCheck SA',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final b = _blip(_controller.value);

                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          const Color(0xFF5A0A0A),
                          const Color(0xFFFF2D2D),
                          b,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D2D)
                                .withOpacity(0.85 * b),
                            blurRadius: 4 + (8 * b),
                            spreadRadius: 1.5 * b,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// FEATURE CHIP (glass)
// ------------------------------------------------------------

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF7CF5A4),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// LIQUID GLASS ACTION BUTTON
//   blue: true  -> glowing blue liquid glass
//   blue: false -> crystal-clear glowing glass
//
// Interactions:
//  - ambient glow that breathes, plus a slow light sheen
//  - jelly squish on press (springs back with a small bounce)
//  - a light follows your finger inside the glass
//  - a ripple bursts from the touch point on tap
// ------------------------------------------------------------

class _GlassActionButton extends StatefulWidget {
  final String label;
  final bool blue;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.label,
    required this.blue,
    required this.onTap,
  });

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _sheen;
  late final AnimationController _burst;
  late final AnimationController _press; // unbounded so it can overshoot

  // Touch point as a fraction of the button (0..1).
  Offset _touch = const Offset(0.5, 0.5);
  bool _navigating = false;

  static const _pressSpring = SpringDescription(
    mass: 1,
    stiffness: 600,
    damping: 32,
  );

  static const _releaseSpring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 11, // under-damped -> jelly bounce
  );

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat();

    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _press = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sheen.dispose();
    _burst.dispose();
    _press.dispose();
    super.dispose();
  }

  void _updateTouch(Offset local) {
    final box = context.size;
    if (box == null || box.isEmpty) return;
    _touch = Offset(
      (local.dx / box.width).clamp(0.0, 1.0).toDouble(),
      (local.dy / box.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  void _down(TapDownDetails d) {
    _updateTouch(d.localPosition);
    _press.animateWith(SpringSimulation(_pressSpring, _press.value, 1, 0));
  }

  void _release() {
    _press.animateWith(
      SpringSimulation(_releaseSpring, _press.value, 0, 0),
    );
  }

  void _tap() {
    if (_navigating) return;
    _navigating = true;

    _burst.forward(from: 0);

    // Short pause so the ripple is seen before the next page opens.
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _navigating = false;
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final blue = widget.blue;

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _down,
        onPanUpdate: (d) => _updateTouch(d.localPosition),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        onTap: _tap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulse, _sheen, _burst, _press]),
          builder: (context, _) {
            final pulse = Curves.easeInOut.transform(_pulse.value);
            final p = _press.value; // ~0..1 (can overshoot slightly)
            final pc = p.clamp(0.0, 1.0).toDouble();

            // Jelly squish: narrower and shorter when pressed.
            final sx = 1 - 0.035 * p;
            final sy = 1 - 0.075 * p;

            final glowColor = blue
                ? const Color(0xFF3B82F6)
                : const Color(0xFFBFE3FF);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    // Wide breathing glow
                    BoxShadow(
                      color: glowColor.withOpacity(
                        (blue ? 0.38 : 0.20) + pulse * 0.16 + pc * 0.28,
                      ),
                      blurRadius: 26 + pulse * 14 + pc * 16,
                      spreadRadius: 1 + pulse * 2 + pc * 3,
                      offset: Offset(0, 10 - pc * 5),
                    ),
                    // Tight rim glow
                    BoxShadow(
                      color: glowColor.withOpacity(
                        (blue ? 0.55 : 0.30) + pc * 0.25,
                      ),
                      blurRadius: 10 + pc * 8,
                      spreadRadius: -1,
                    ),
                    // Grounding shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: blue
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF8CC4FF).withOpacity(0.96),
                                const Color(0xFF2F6BFF).withOpacity(0.96),
                                const Color(0xFF1B45C9).withOpacity(0.96),
                              ],
                              stops: const [0.0, 0.55, 1.0],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.36),
                                Colors.white.withOpacity(0.10),
                              ],
                            ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55 + pc * 0.35),
                        width: 1.3,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Liquid depth: glow rising from the bottom edge
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.center,
                                colors: [
                                  (blue
                                          ? const Color(0xFF9FE0FF)
                                          : Colors.white)
                                      .withOpacity(0.30 + pulse * 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Slow sheen sweeping across the glass
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment(
                              -1.8 + _sheen.value * 3.6,
                              0,
                            ),
                            child: Transform.rotate(
                              angle: 0.5,
                              child: Container(
                                width: 54,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.26),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Light that follows the finger
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(
                                  _touch.dx * 2 - 1,
                                  _touch.dy * 2 - 1,
                                ),
                                radius: 0.85,
                                colors: [
                                  Colors.white.withOpacity(0.55 * pc),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Ripple burst from the touch point
                        if (_burst.isAnimating || _burst.value > 0)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _RipplePainter(
                                progress: _burst.value,
                                origin: _touch,
                              ),
                            ),
                          ),

                        // Top specular highlight
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 30,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.55),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Label
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 19),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.5,
                                  letterSpacing: 0.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white
                                          .withOpacity(0.35 + pc * 0.45),
                                      blurRadius: 8 + pc * 10,
                                    ),
                                    Shadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress; // 0..1
  final Offset origin; // fraction of size

  _RipplePainter({required this.progress, required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(origin.dx * size.width, origin.dy * size.height);
    final maxRadius = size.width * 0.9;
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = 1 - progress;

    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.30 * fade),
        ],
        stops: const [0.6, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: maxRadius * eased),
      );

    canvas.drawCircle(center, maxRadius * eased, fill);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.55 * fade);

    canvas.drawCircle(center, maxRadius * eased, ring);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.origin != origin;
}