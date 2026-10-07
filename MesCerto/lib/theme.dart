import 'package:flutter/material.dart';

/// Equivalente a constants/colors.ts
class AppPalette {
  final Color foreground, mutedForeground, background, surface, surfaceAlt;
  final Color primary, primaryDark, primarySoft, border;
  final Color danger, dangerSoft, warning, warningSoft;
  final Color blue, purple, orange, pink;

  const AppPalette({
    required this.foreground,
    required this.mutedForeground,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.primary,
    required this.primaryDark,
    required this.primarySoft,
    required this.border,
    required this.danger,
    required this.dangerSoft,
    required this.warning,
    required this.warningSoft,
    required this.blue,
    required this.purple,
    required this.orange,
    required this.pink,
  });

  static const light = AppPalette(
    foreground: Color(0xFF17251F),
    mutedForeground: Color(0xFF74837C),
    background: Color(0xFFF5F8F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF6F2),
    primary: Color(0xFF058A61),
    primaryDark: Color(0xFF006347),
    primarySoft: Color(0xFFDFF6EA),
    border: Color(0xFFDCE8E2),
    danger: Color(0xFFD95757),
    dangerSoft: Color(0xFFFFEDED),
    warning: Color(0xFFC98820),
    warningSoft: Color(0xFFFFF4D8),
    blue: Color(0xFF4387DC),
    purple: Color(0xFF8156D8),
    orange: Color(0xFFEF9E21),
    pink: Color(0xFFE66875),
  );

  static const dark = AppPalette(
    foreground: Color(0xFFF1FAF5),
    mutedForeground: Color(0xFF9BB1A5),
    background: Color(0xFF0D1915),
    surface: Color(0xFF14231D),
    surfaceAlt: Color(0xFF1A3429),
    primary: Color(0xFF36D998),
    primaryDark: Color(0xFF18B579),
    primarySoft: Color(0xFF173F31),
    border: Color(0xFF29473A),
    danger: Color(0xFFFF8585),
    dangerSoft: Color(0xFF482529),
    warning: Color(0xFFF6BD5C),
    warningSoft: Color(0xFF493A20),
    blue: Color(0xFF7DAEFF),
    purple: Color(0xFFB093FF),
    orange: Color(0xFFFFC15A),
    pink: Color(0xFFFF9AA2),
  );
}

/// Ionicons -> Material Icons
const Map<String, IconData> appIcons = {
  'restaurant': Icons.restaurant_outlined,
  'car': Icons.directions_car_outlined,
  'game': Icons.sports_esports_outlined,
  'home': Icons.home_outlined,
  'heart': Icons.favorite_border,
  'school': Icons.school_outlined,
  'repeat': Icons.repeat,
  'flight': Icons.flight_outlined,
  'phone': Icons.smartphone_outlined,
  'shield': Icons.verified_user_outlined,
  'flag': Icons.flag_outlined,
  'play': Icons.play_circle_outline,
  'music': Icons.music_note_outlined,
  'cloud': Icons.cloud_outlined,
  'gym': Icons.fitness_center,
  'wallet': Icons.account_balance_wallet_outlined,
  'plus': Icons.add_circle_outline,
};

/// Equivalente a constants/theme.ts (ordem das categorias preservada)
const List<String> categoryNames = [
  'Alimentação',
  'Transporte',
  'Lazer',
  'Moradia',
  'Saúde',
  'Educação',
  'Assinaturas',
];

const Map<String, String> _categoryIcon = {
  'Alimentação': 'restaurant',
  'Transporte': 'car',
  'Lazer': 'game',
  'Moradia': 'home',
  'Saúde': 'heart',
  'Educação': 'school',
  'Assinaturas': 'repeat',
  'Salário': 'wallet',
  'Outras entradas': 'plus',
};

class CatMeta {
  final Color color;
  final IconData icon;
  const CatMeta(this.color, this.icon);
}

CatMeta getCategoryMeta(String category, AppPalette c) {
  final colors = <String, Color>{
    'Alimentação': c.blue,
    'Transporte': c.purple,
    'Lazer': c.orange,
    'Moradia': c.pink,
    'Saúde': const Color(0xFF69E29B),
    'Educação': const Color(0xFFBF9CFF),
    'Assinaturas': const Color(0xFFFF91BF),
    'Salário': const Color(0xFF36B86D),
    'Outras entradas': c.blue,
  };
  final key = _categoryIcon.containsKey(category) ? category : 'Alimentação';
  return CatMeta(colors[key]!, appIcons[_categoryIcon[key]]!);
}
