import 'dart:ui';
import 'package:flutter/material.dart';
import '../app/main_scaffold.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  late Animation<double> _textOpacity;
  late Animation<double> _textScale;
  late Animation<double> _letterSpacing;

  late Animation<double> _flipAnimation;
  late Animation<double> _fadeOut;
  late Animation<double> _containerScale;

  late Animation<double> _blur;
  late Animation<Color?> _backgroundColor;

  String _displayText = "SW";

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3300),
    );

    // SUPER SMOOTH CURVES
    final smoothOut = Curves.easeOutExpo;
    final smoothInOut = Curves.easeInOutCubic;

    _logoScale = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutExpo),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.35, 0.60, curve: smoothOut),
      ),
    );

    _textScale = Tween<double>(begin: 0.8, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.35, 0.90, curve: smoothInOut),
      ),
    );

    _letterSpacing = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.55, 0.90, curve: smoothOut),
      ),
    );

    _flipAnimation = Tween<double>(begin: 0, end: 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.65, 0.88, curve: smoothInOut),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.85, 1.0, curve: smoothInOut),
      ),
    );

    _containerScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.78, 1.0, curve: smoothInOut),
      ),
    );

    _blur = Tween<double>(begin: 0.0, end: 18.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.80, 1.0, curve: smoothOut),
      ),
    );

    _backgroundColor =
        ColorTween(
          begin: Colors.black,
          end: Colors.black.withOpacity(0.3),
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(0.80, 1.0, curve: smoothOut),
          ),
        );

    _controller.forward();

    // TEXT SWITCHING (now smoother)
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _displayText = "SW");
    });

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _displayText = "ShopWise");
    });

    // NAVIGATE TO HOME
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScaffold()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColor.value,
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.6,
                    colors: [
                      Colors.blue.shade900.withOpacity(0.85),
                      Colors.black.withOpacity(0.95),
                    ],
                  ),
                ),
              ),

              Center(
                child: AspectRatio(
                  aspectRatio: 9 / 19.5,
                  child: FadeTransition(
                    opacity: _fadeOut,
                    child: ScaleTransition(
                      scale: _containerScale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A7FDB), Color(0xFF0047B3)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: _blur.value,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _blur.value / 12,
                              sigmaY: _blur.value / 12,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(_flipAnimation.value),
                                  child: FadeTransition(
                                    opacity: _logoOpacity,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Image.asset(
                                        'assets/images/Logo.png',
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.65,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 35),

                                FadeTransition(
                                  opacity: _textOpacity,
                                  child: ScaleTransition(
                                    scale: _textScale,
                                    child: Text(
                                      _displayText,
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing:
                                            _displayText == "ShopWise"
                                            ? _letterSpacing.value
                                            : 0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            blurRadius: 15,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
}
