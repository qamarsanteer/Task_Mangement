import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/masar_logo.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _tileScale;
  late final Animation<double> _tileOpacity;

  late final Animation<double> _routeProgress;
  late final Animation<double> _markerProgress;

  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _dividerWidth;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _tileScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOutBack),
      ),
    );

    _tileOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeIn),
      ),
    );

    _routeProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOutCubic),
    );

    _markerProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.80, curve: Curves.easeOutBack),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.90, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.90, curve: Curves.easeIn),
      ),
    );

    _dividerWidth = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 1.0, curve: Curves.easeOutCubic),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authBloc = context.read<AuthBloc>();

    final authStateFuture = authBloc.stream.firstWhere(
      (state) => state is AuthAuthenticated || state is AuthUnauthenticated,
    );

    authBloc.add(const AuthStatusChecked());

    await _controller.forward();
    final authState = await authStateFuture;

    if (!mounted) return;

    if (authState is AuthAuthenticated) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _tileOpacity.value,
                  child: Transform.scale(
                    scale: _tileScale.value,
                    child: MasarLogo(
                      size: 140,
                      progress: _routeProgress.value,
                      markerProgress: _markerProgress.value,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  opacity: _textOpacity.value,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          'Masar',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Task Management',
                          style: TextStyle(
                            fontSize: 14,
                            letterSpacing: 0.4,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // A small route-line accent under the wordmark, tying
                        // the tagline back to the logo's path motif.
                        ClipRect(
                          child: Align(
                            alignment: Alignment.center,
                            widthFactor: _dividerWidth.value,
                            child: Container(
                              width: 48,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Opacity(
                  opacity: _textOpacity.value,
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}