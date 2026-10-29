import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'core/models/models.dart';
import 'features/owner_setup/presentation/screens/owner_setup_screen.dart';
import 'features/tenant_checkin/presentation/screens/tenant_checkin_screen.dart';
import 'features/tenant_dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/widgets/urban_loading.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseConfig.init();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization warning: $e');
  }

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
        fontFamily: GoogleFonts.outfit().fontFamily,
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

        Widget rootContent;
        // 100% natural fluid expansion on all real devices (>= 320px)
        // Auto-scale smoothly if dragged below 320px (e.g. 275px micro DevTools viewport)
        if (screenWidth < 320 && screenWidth > 0) {
          final double scale = screenWidth / 320;
          rootContent = MediaQuery(
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
        } else {
          rootContent = MediaQuery(
            data: adjustedMediaQuery,
            child: content,
          );
        }

        // Global app-wide centered loading overlay
        return ValueListenableBuilder<bool>(
          valueListenable: UrbanLoadingService.isLoading,
          builder: (context, loading, _) {
            return Stack(
              children: [
                rootContent,
                if (loading)
                  Positioned.fill(
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: ValueListenableBuilder<String?>(
                        valueListenable: UrbanLoadingService.message,
                        builder: (context, msg, _) =>
                            UrbanLoadingCard(message: msg),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
      // 🚀 Tenant Dashboard Web Release (ALL TOGGLES OFF FOR TESTING SPOTLIGHT)
      home: TenantDashboardScreen(
        propertyId: Uri.base.queryParameters['propertyId'] ??
            Uri.base.queryParameters['id'] ??
            'fff9b852-ea2c-44c2-82ca-09f7723cb303',
        tenantId: Uri.base.queryParameters['tenantId'] ??
            Uri.base.queryParameters['tenant_id'] ??
            Uri.base.queryParameters['tid'],
        roomNumber: Uri.base.queryParameters['room'] ?? '',
        bedId: Uri.base.queryParameters['bed'] ?? '',
        tenantName: Uri.base.queryParameters['name'] ?? '',
        tenantPhone: Uri.base.queryParameters['phone'] ??
            Uri.base.queryParameters['mobile'] ??
            '5851022581',
        initialTenantControls: const TenantControlsModel(
          propertyId: 'fff9b852-ea2c-44c2-82ca-09f7723cb303',
          payViaUpi: false,
          paidViaCash: false,
          raiseTicket: false,
          ticketStatus: false,
          bedsheetChange: false,
          rentAgreement: false,
        ),
      ),
    );
  }
}
