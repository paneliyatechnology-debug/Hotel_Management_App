import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/pages/mobile_main_screen.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatelessWidget {
  final AuthRepository? authRepository;

  const LoginScreen({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    if (authRepository != null) {
      return BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(repository: authRepository!),
        child: const _LoginScreenView(),
      );
    }
    try {
      BlocProvider.of<AuthBloc>(context);
      return const _LoginScreenView();
    } catch (_) {
      return BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(repository: AuthRepository()),
        child: const _LoginScreenView(),
      );
    }
  }
}

class _LoginScreenView extends StatefulWidget {
  const _LoginScreenView();

  @override
  State<_LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<_LoginScreenView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberStation = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Dispatch LoginSubmitted event to AuthBloc
    context.read<AuthBloc>().add(
          LoginSubmitted(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberStation: _rememberStation,
          ),
        );
  }


  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Staff Password Reset',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Contact IT Admin or Duty Manager',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'For hotel security reasons, front desk terminal passwords can only be reset by the General Manager or IT Administrator.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IT Helpdesk Hotline',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '+91 98765 43210 • Ext 101',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Understood',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final hotelName = state.user?.hotel.name.isNotEmpty == true
              ? state.user!.hotel.name
              : 'Hotel';
          final staffName = state.user?.name.isNotEmpty == true
              ? state.user!.name
              : 'Staff Member';

          final role = state.user?.role ?? '';
          final effectiveRole = role.toUpperCase() == 'RECEPTIONIST' ? 'RECEPTIONIST' : 'HOTEL_ADMIN';

          // Navigate to MobileMainScreen with role
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MobileMainScreen(initialRole: effectiveRole),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F766E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF86EFAC), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome back, $staffName! $hotelName session active.',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state.status == AuthStatus.failure) {
          final errorMsg = state.errorMessage != null && state.errorMessage!.isNotEmpty
              ? state.errorMessage!
              : 'Login failed. Please check credentials.';

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMsg,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.isLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            children: [
              // Subtle background decorative ambient glow
              Positioned(
                top: -80,
                right: -60,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                top: 100,
                left: -70,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 1. Top Brand Logo & MYOWNPMS Platform Badge
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/myownpms_logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.holiday_village_rounded,
                                        size: 44,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'MYOWNPMS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.5,
                                      height: 5.5,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5.5),
                                    Text(
                                      'NEXT-GEN HOTEL PMS PLATFORM',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: const Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 2. Welcome Title & Station Tag
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to access reception desk, rooms & guest folios',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 3. Email Input Field
                        Text(
                          'Staff Email',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your staff email',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Staff email cannot be empty';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // 4. Password Input Field
                        Text(
                          'Password',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: Color(0xFF0F766E),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password cannot be empty';
                            }
                            if (value.length < 4) {
                              return 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // 5. Remember Me & Forgot Password Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        setState(() => _rememberStation = !_rememberStation);
                                      },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberStation,
                                        activeColor: const Color(0xFF0F766E),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        onChanged: isLoading
                                            ? null
                                            : (val) {
                                                setState(() => _rememberStation = val ?? true);
                                              },
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Remember station',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showForgotPasswordSheet(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 6. Sign In Button with Bloc Loading State
                        Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isLoading ? null : () => _handleSignIn(context),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Sign In to Front Desk',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 7. Footer Security Badge
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF0F766E)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '256-Bit SSL Encrypted Session • Hotel PMS v2026.4',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: const Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
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
