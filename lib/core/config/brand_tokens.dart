import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:ui' show Color;

/// Brand tokens loaded from brand_tokens.json (v1.1)
class BrandTokens {
  final BrandThemeColors dark;
  final BrandThemeColors light;

  const BrandTokens({
    required this.dark,
    required this.light,
  });

  /// Load brand tokens from assets
  static Future<BrandTokens> load() async {
    final String jsonString = await rootBundle.loadString('assets/brand_tokens.json');
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final Map<String, dynamic> modes = json['modes'];

    return BrandTokens(
      dark: BrandThemeColors.fromJson(modes['dark']),
      light: BrandThemeColors.fromJson(modes['light']),
    );
  }
}

/// Theme colors for a single theme mode
class BrandThemeColors {
  // Core colors
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color outline;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  // Neutral palette
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;

  // Elevation levels
  final ElevationColors elevation;

  // Component-specific colors
  final ComponentColors components;

  // Badge colors
  final BadgeColors badges;

  // Role-based colors
  final RoleColors roles;

  const BrandThemeColors({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.outline,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.elevation,
    required this.components,
    required this.badges,
    required this.roles,
  });

  factory BrandThemeColors.fromJson(Map<String, dynamic> json) {
    return BrandThemeColors(
      primary: _parseColor(json['primary']),
      onPrimary: _parseColor(json['onPrimary']),
      background: _parseColor(json['background']),
      surface: _parseColor(json['surface']),
      onSurface: _parseColor(json['onSurface']),
      surfaceVariant: _parseColor(json['surfaceVariant']),
      outline: _parseColor(json['outline']),
      success: _parseColor(json['success']),
      warning: _parseColor(json['warning']),
      error: _parseColor(json['error']),
      info: _parseColor(json['info']),
      neutral100: _parseColor(json['neutral100']),
      neutral200: _parseColor(json['neutral200']),
      neutral300: _parseColor(json['neutral300']),
      neutral400: _parseColor(json['neutral400']),
      neutral500: _parseColor(json['neutral500']),
      neutral600: _parseColor(json['neutral600']),
      neutral700: _parseColor(json['neutral700']),
      neutral800: _parseColor(json['neutral800']),
      neutral900: _parseColor(json['neutral900']),
      elevation: ElevationColors.fromJson(json['elevation']),
      components: ComponentColors.fromJson(json['components']),
      badges: BadgeColors.fromJson(json['badges']),
      roles: RoleColors.fromJson(json['roles']),
    );
  }

  static Color _parseColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    if (hexCode == 'transparent') {
      return const Color(0x00000000);
    }
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

/// Elevation level colors
class ElevationColors {
  final Color level0;
  final Color level1;
  final Color level2;
  final Color level3;
  final Color level4;

  const ElevationColors({
    required this.level0,
    required this.level1,
    required this.level2,
    required this.level3,
    required this.level4,
  });

  factory ElevationColors.fromJson(Map<String, dynamic> json) {
    return ElevationColors(
      level0: BrandThemeColors._parseColor(json['level0']),
      level1: BrandThemeColors._parseColor(json['level1']),
      level2: BrandThemeColors._parseColor(json['level2']),
      level3: BrandThemeColors._parseColor(json['level3']),
      level4: BrandThemeColors._parseColor(json['level4']),
    );
  }
}

/// Component-specific colors
class ComponentColors {
  final ComponentPair appBar;
  final ComponentTriple card;
  final ComponentPair chip;
  final ComponentQuad input;
  final ComponentTriple listTile;
  final ComponentTriple navBar;

  const ComponentColors({
    required this.appBar,
    required this.card,
    required this.chip,
    required this.input,
    required this.listTile,
    required this.navBar,
  });

  factory ComponentColors.fromJson(Map<String, dynamic> json) {
    return ComponentColors(
      appBar: ComponentPair.fromJson(json['appBar']),
      card: ComponentTriple.fromJson(json['card']),
      chip: ComponentPair.fromJson(json['chip']),
      input: ComponentQuad.fromJson(json['input']),
      listTile: ComponentTriple.fromJson(json['listTile']),
      navBar: ComponentTriple.fromJson(json['navBar']),
    );
  }
}

/// Component color pair (bg + fg)
class ComponentPair {
  final Color bg;
  final Color fg;

  const ComponentPair({required this.bg, required this.fg});

  factory ComponentPair.fromJson(Map<String, dynamic> json) {
    return ComponentPair(
      bg: BrandThemeColors._parseColor(json['bg']),
      fg: BrandThemeColors._parseColor(json['fg']),
    );
  }
}

/// Component color triple (bg + fg + border/subtitle/active)
class ComponentTriple {
  final Color bg;
  final Color fg;
  final Color extra; // border, subtitle, or active

  const ComponentTriple({
    required this.bg,
    required this.fg,
    required this.extra,
  });

  factory ComponentTriple.fromJson(Map<String, dynamic> json) {
    final extraKey = json.containsKey('border')
        ? 'border'
        : json.containsKey('subtitle')
            ? 'subtitle'
            : 'active';
    return ComponentTriple(
      bg: BrandThemeColors._parseColor(json['bg']),
      fg: BrandThemeColors._parseColor(json['fg']),
      extra: BrandThemeColors._parseColor(json[extraKey]),
    );
  }
}

/// Component color quad (bg + fg + border + hint)
class ComponentQuad {
  final Color bg;
  final Color fg;
  final Color border;
  final Color hint;

  const ComponentQuad({
    required this.bg,
    required this.fg,
    required this.border,
    required this.hint,
  });

  factory ComponentQuad.fromJson(Map<String, dynamic> json) {
    return ComponentQuad(
      bg: BrandThemeColors._parseColor(json['bg']),
      fg: BrandThemeColors._parseColor(json['fg']),
      border: BrandThemeColors._parseColor(json['border']),
      hint: BrandThemeColors._parseColor(json['hint']),
    );
  }
}

/// Badge colors for user levels
class BadgeColors {
  final Color newbie;
  final Color intermediate;
  final Color advanced;
  final Color explorer;
  final Color marshal;

  const BadgeColors({
    required this.newbie,
    required this.intermediate,
    required this.advanced,
    required this.explorer,
    required this.marshal,
  });

  factory BadgeColors.fromJson(Map<String, dynamic> json) {
    return BadgeColors(
      newbie: BrandThemeColors._parseColor(json['newbie']),
      intermediate: BrandThemeColors._parseColor(json['intermediate']),
      advanced: BrandThemeColors._parseColor(json['advanced']),
      explorer: BrandThemeColors._parseColor(json['explorer']),
      marshal: BrandThemeColors._parseColor(json['marshal']),
    );
  }
}

/// Role-based colors for buttons and alerts
class RoleColors {
  final ComponentPair ctaPrimary;
  final ComponentTriple ctaSecondary;
  final ComponentPair success;
  final ComponentPair warning;
  final ComponentPair error;
  final ComponentPair info;

  const RoleColors({
    required this.ctaPrimary,
    required this.ctaSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  factory RoleColors.fromJson(Map<String, dynamic> json) {
    return RoleColors(
      ctaPrimary: ComponentPair.fromJson(json['ctaPrimary']),
      ctaSecondary: ComponentTriple.fromJson(json['ctaSecondary']),
      success: ComponentPair.fromJson(json['success']),
      warning: ComponentPair.fromJson(json['warning']),
      error: ComponentPair.fromJson(json['error']),
      info: ComponentPair.fromJson(json['info']),
    );
  }
}
