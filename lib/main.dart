import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/onboarding/presentation/screens/onboarding_walkthrough_screen.dart';
import 'features/owner_setup/presentation/screens/owner_setup_screen.dart';
import 'features/owner_dashboard/presentation/screens/owner_dashboard_screen.dart';
import 'features/owner_rooms/presentation/screens/owner_rooms_screen.dart';
import 'features/owner_rent/presentation/screens/owner_rent_collection_screen.dart';
import 'features/owner_rent/presentation/screens/owner_day_collection_screen.dart';
import 'features/tenant_dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'features/tenant_payments/presentation/screens/rent_payment_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const UrbanStayApp());
}

class UniversalScrollBehavior extends MaterialScrollBehavior {
  const UniversalScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    );
  }
}

class UrbanStayApp extends StatelessWidget {
  const UrbanStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanStay',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const UniversalScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final Widget content = child ?? const SizedBox.shrink();

        // Safe text scale clamp to respect accessibility while preventing font overflows
        final safeTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.15,
        );

        final adjustedMediaQuery =
            mediaQuery.copyWith(textScaler: safeTextScaler);

        // 100% natural fluid expansion on all real devices (>= 320px)
        // Auto-scale smoothly if dragged below 320px (e.g. 275px micro DevTools viewport)
        if (screenWidth < 320 && screenWidth > 0) {
          final double scale = screenWidth / 320;
          return MediaQuery(
            data: adjustedMediaQuery.copyWith(
              size: Size(320, mediaQuery.size.height / scale),
            ),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 320,
                height: mediaQuery.size.height / scale,
                child: content,
              ),
            ),
          );
        }

        return MediaQuery(
          data: adjustedMediaQuery,
          child: content,
        );
      },
      // 🏢 Owner Command Center Dashboard (Navigation Hub)
      home: const OwnerDashboardScreen(),
    );
  }
}
