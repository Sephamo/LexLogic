import 'package:flutter/material.dart';

import 'screens/identity_verification_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/registration_otp_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/password_screen.dart';

import 'utils/page_transitions.dart';

void main() {
  runApp(const PolicyApp());
}

class PolicyApp extends StatelessWidget {
  const PolicyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const babyBlue = Color(0xFF89CFF0);
    const deepBlue = Color(0xFF4A90D9);

    return MaterialApp(
      title: 'PolicyChecker SA',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: babyBlue,
          primary: deepBlue,
          secondary: babyBlue,
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF5FAFF),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: babyBlue.withOpacity(0.4),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: babyBlue.withOpacity(0.4),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: deepBlue,
              width: 1.8,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.redAccent,
            ),
          ),

          labelStyle: const TextStyle(
            color: Colors.black54,
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: deepBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        textButtonTheme:
            TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: deepBlue,
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      ),

      initialRoute: '/welcome',

      onGenerateRoute: (settings) {
        switch (settings.name) {

          // --------------------------------------------------
          // WELCOME
          // --------------------------------------------------

          case '/welcome':
            return slideFadeRoute(
              const WelcomeScreen(),
            );

          // --------------------------------------------------
          // LOGIN
          // --------------------------------------------------

          case '/login':
            return slideFadeRoute(
              const LoginScreen(),
            );

          // --------------------------------------------------
          // REGISTER
          // --------------------------------------------------

          case '/register':
            return slideFadeRoute(
              const RegisterScreen(),
            );

          // --------------------------------------------------
          // LOGIN OTP
          // --------------------------------------------------

          case '/otp':
            final arguments = settings.arguments;

            if (arguments is Map<String, dynamic>) {
              return slideFadeRoute(
                OtpScreen(
                  userId: arguments['userId'] as int?,
                  phoneNumber:
                      arguments['phoneNumber'] as String?,
                  type: arguments['type'] as String?,
                ),
              );
            }

            return slideFadeRoute(
              const LoginScreen(),
            );

          // --------------------------------------------------
          // REGISTRATION OTP
          // --------------------------------------------------

          case '/registration-otp':
            final arguments = settings.arguments;

            if (arguments is Map<String, dynamic>) {
              final userId =
                  arguments['userId'] as int?;

              final phoneNumber =
                  arguments['phoneNumber'] as String?;

              if (userId != null &&
                  phoneNumber != null) {
                return slideFadeRoute(
                  RegistrationOtpScreen(
                    userId: userId,
                    phoneNumber: phoneNumber,
                  ),
                );
              }
            }

            // If required registration OTP data
            // wasn't provided, return to register.
            return slideFadeRoute(
              const RegisterScreen(),
            );

          // --------------------------------------------------
          // PASSWORD
          // --------------------------------------------------

          case '/password':
            final arguments = settings.arguments;

            if (arguments is Map<String, dynamic>) {
              return slideFadeRoute(
                PasswordScreen(
                  userId:
                      arguments['userId'] as int?,
                  phoneNumber:
                      arguments['phoneNumber'] as String?,
                ),
              );
            }

            return slideFadeRoute(
              const PasswordScreen(),
            );

          // --------------------------------------------------
          // DASHBOARD
          // --------------------------------------------------

          case '/dashboard':
            return slideFadeRoute(
              const MainNavigation(),
            );

          // --------------------------------------------------
          // IDENTITY VERIFICATION
          // --------------------------------------------------

          case '/verify':
            return slideFadeRoute(
              const IdentityVerificationScreen(),
            );

          // --------------------------------------------------
          // DEFAULT
          // --------------------------------------------------

          default:
            return slideFadeRoute(
              const LoginScreen(),
            );
        }
      },
    );
  }
}