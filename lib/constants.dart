import 'package:flutter/material.dart';

const String defaultListId = 'supermercado';
const String defaultUserId = 'local_user';
const String defaultUserName = 'Usuario';
const String defaultListIcon = '📝';
const String dbName = 'lista_familia.sqlite';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF388E3C);
  static const Color accent = Color(0xFF43A047);
  static const Color success = Color(0xFF66BB6A);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF424242);

  static const Color greenBg = Color(0xFFE8F5E9);
  static const Color greenText = Color(0xFF2E7D32);
  static const Color orangeBg = Color(0xFFFFF3E0);
  static const Color orangeText = Color(0xFFEF6C00);
  static const Color blueBg = Color(0xFFE3F2FD);
  static const Color blueText = Color(0xFF1976D2);
  static const Color yellowBg = Color(0xFFFFF8E1);
  static const Color yellowText = Color(0xFFF9A825);
  static const Color errorBg = Color(0xFFFDECEA);
  static const Color errorText = Color(0xFFD32F2F);
  static const Color starYellow = Color(0xFFFFC107);

  static const LinearGradient appGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 20;
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

class AppConstraints {
  AppConstraints._();
  static const int productSearchDebounceMs = 300;
  static const int syncIntervalSeconds = 30;
  static const double minTouchTarget = 48.0;
}

class AppDecorations {
  AppDecorations._();

  static InputDecoration searchInputDecoration({
    required String hintText,
    required BuildContext context,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 1,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: const BorderSide(color: AppColors.success, width: 1.5),
      ),
    );
  }

  static InputDecoration disabledInputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w500,
      ),
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 1,
      ),
      prefixIcon: Icon(
        Icons.visibility_outlined,
        color: Colors.grey.shade500,
        size: 20,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  static InputDecoration addProductInputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: InputBorder.none,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 1,
      ),
      prefixIcon: Icon(
        Icons.shopping_cart_outlined,
        color: Colors.grey.shade400,
        size: 20,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: const BorderSide(color: AppColors.success, width: 1.5),
      ),
    );
  }

  static BoxDecoration get cardShadow => BoxDecoration(
    color: Colors.white,
    borderRadius: AppRadius.mdAll,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get greenCircle => const BoxDecoration(
    color: AppColors.greenBg,
    shape: BoxShape.circle,
  );
}
