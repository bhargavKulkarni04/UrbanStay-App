import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_colors.dart';
import 'features/onboarding/presentation/screens/onboarding_walkthrough_screen.dart';
import 'features/owner_setup/presentation/screens/owner_setup_screen.dart';
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

class UrbanStayApp extends StatelessWidget {
  const UrbanStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanStay',
      debugShowCheckedModeBanner: false,
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
      // 🏢 Owner Setup Screen (with dynamic room sharing breakdown)
      home: const OwnerSetupScreen(),
    );
  }
}
