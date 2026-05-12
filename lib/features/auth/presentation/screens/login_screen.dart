import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vstream/core/config/env.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();

  late final AnimationController _bgCtrl;   // slow background pulse
  late final AnimationController _inCtrl;   // entrance animation
  late final Animation<double>   _fadeIn;
  late final Animation<Offset>   _slideIn;

  bool _isSignUp    = false;
  bool _isLoading   = false;
  bool _obscure     = true;
  String? _error;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _inCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn  = CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _inCtrl, curve: Curves.easeOut));

    _inCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _inCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() { _error = null; _isLoading = true; });

    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (_isSignUp && name.isEmpty)) {
      setState(() { _error = 'Please fill in all fields.'; _isLoading = false; });
      return;
    }
    if (pass.length < 6) {
      setState(() { _error = 'Password must be at least 6 characters.'; _isLoading = false; });
      return;
    }

    final notifier = ref.read(sessionProvider.notifier);
    final result = _isSignUp
        ? await notifier.signUp(name, email, pass)
        : await notifier.signIn(email, pass);

    if (!mounted) return;
    if (result.success) {
      context.go('/');
    } else {
      setState(() { _error = result.error ?? 'Something went wrong.'; _isLoading = false; });
    }
  }

  Future<void> _guest() async {
    setState(() { _isLoading = true; });
    final router = GoRouter.of(context);
    await ref.read(sessionProvider.notifier).signInAsGuest();
    router.go('/');
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Animated background glows ────────────────────────────────────────
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _bgCtrl,
              builder: (_, __) {
                final t = _bgCtrl.value;
                return Stack(
                  children: [
                    // Top-right red glow
                    Positioned(
                      top: -size.height * 0.1 + (t * 40),
                      right: -size.width * 0.2 + (t * 30),
                      child: _Glow(
                        size: size.width * 1.2,
                        color: const Color(0xFFE50914).withAlpha((30 + t * 25).round()),
                      ),
                    ),
                    // Middle-left subtle glow
                    Positioned(
                      top: size.height * 0.3 - (t * 20),
                      left: -size.width * 0.3,
                      child: _Glow(
                        size: size.width * 0.9,
                        color: const Color(0xFF400000).withAlpha((40 + t * 20).round()),
                      ),
                    ),
                    // Bottom-right glow
                    Positioned(
                      bottom: -size.height * 0.1 + (t * 30),
                      right: -size.width * 0.1,
                      child: _Glow(
                        size: size.width * 0.8,
                        color: const Color(0xFF1A0000).withAlpha(180),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  AppColors.bgCard(context).withAlpha(150),
                                  AppColors.bgCard(context)
                                ],
                              ),
                            ),
                          ),
                          // Logo area
                          const Spacer(flex: 2),
                          _buildLogo(),
                          const Spacer(flex: 2),

                          // Auth card
                          _buildCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logo ─────────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge with animated border glow
        AnimatedBuilder(
          animation: _bgCtrl,
          builder: (_, __) {
            final glow = 0.4 + _bgCtrl.value * 0.5;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(120),
                border: Border.all(
                  color: AppColors.red.withAlpha((180 + _bgCtrl.value * 75).round()),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withAlpha((glow * 140).round()),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                'VSTREAM',
                style: GoogleFonts.outfit(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          'CINEMATIC STREAMING. REIMAGINED.',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 2.5,
          ),
        ),
        if (!Env.isConfigured) ...[
          const SizedBox(height: 16),
          _buildDemoBadge(),
        ],
      ],
    );
  }

  Widget _buildDemoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning(context).withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning(context).withAlpha(100)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: AppColors.warning(context)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'FREE PREMIUM ACCESS (DEMO MODE)',
              style: TextStyle(
                color: Color(0xFFFFB74D),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Auth card ────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard(context).withAlpha(220),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border(context).withAlpha(100)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab toggle
            _buildTabToggle(),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Name field (Sign Up only)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    child: _isSignUp
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _Field(
                              controller: _nameCtrl,
                              label: 'Full Name',
                              icon: Icons.person_rounded,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  // Email
                  _Field(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _Field(
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_rounded,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),

                  // Error message
                  _buildErrorDisplay(),

                  const SizedBox(height: 28),

                  // Submit button
                  _buildSubmitButton(),

                  const SizedBox(height: 20),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.border(context).withAlpha(100))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                    Expanded(child: Divider(color: AppColors.border(context).withAlpha(100))),
                  ]),

                  const SizedBox(height: 16),

                  // Guest button
                  _buildGuestButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _error != null
          ? Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error(context).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error(context).withAlpha(100)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: AppColors.error(context), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        color: AppColors.error(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          disabledBackgroundColor: AppColors.red.withAlpha(80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                _isSignUp ? 'Create Premium Account' : 'Sign In Now',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: 0.5),
              ),
      ),
    );
  }

  Widget _buildGuestButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _guest,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.border(context).withAlpha(150)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          'Continue as Guest',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary(context),
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
      ),
    );
  }

  // ── Tab toggle ────────────────────────────────────────────────────────────────
  Widget _buildTabToggle() {
    return Container(
      margin: const EdgeInsets.all(28),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context).withAlpha(80)),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'SIGN IN',
            selected: !_isSignUp,
            onTap: () => setState(() {
              _isSignUp = false;
              _error = null;
            }),
          ),
          _Tab(
            label: 'SIGN UP',
            selected: _isSignUp,
            onTap: () => setState(() {
              _isSignUp = true;
              _error = null;
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? AppColors.red : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.red.withAlpha(80),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary(context),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.red.withAlpha(180), size: 20),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context).withAlpha(100)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.border(context).withAlpha(80)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.red, width: 1.5),
          ),
          floatingLabelStyle: const TextStyle(color: AppColors.red),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.2, 1.0],
        ),
      ),
    );
  }
}

