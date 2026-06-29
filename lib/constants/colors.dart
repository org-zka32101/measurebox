import 'package:flutter/material.dart';

// Primary colors
const Color primaryColor = Color(0xFF4A6FFF);   // 落ち着いた青
const Color primaryDark = Color(0xFF3A56CC);
const Color primaryLight = Color(0xFF7B95FF);

// Status colors
const Color safeColor = Color(0xFF22C55E);      // Green - 安全
const Color warningColor = Color(0xFFF59E0B);  // Amber - 注意
const Color dangerColor = Color(0xFFEF4444);   // Red - 危険

// Neutral colors
const Color backgroundColor = Color(0xFFF5F7FB);
const Color surfaceColor = Color(0xFFFFFFFF);
const Color errorColor = Color(0xFFE53935);
const Color greyLight = Color(0xFFEEEEEE);
const Color greyMedium = Color(0xFF9E9E9E);
const Color greyDark = Color(0xFF424242);
const Color textPrimary = Color(0xFF212121);
const Color textSecondary = Color(0xFF757575);
const Color textHint = Color(0xFFBDBDBD);

// Gradient colors
const LinearGradient safeGradient = LinearGradient(
  colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient warningGradient = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient dangerGradient = LinearGradient(
  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient primaryGradient = LinearGradient(
  colors: [Color(0xFF4A6FFF), Color(0xFF6B8AFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
