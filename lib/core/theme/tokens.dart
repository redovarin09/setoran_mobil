// Token semantik — SATU-SATUNYA yang boleh dipakai widget.
// Sumber: docs/design-brief.md §3. Larangan: widget dilarang merujuk primitive langsung.
// Seed brand #1565C0 dipertahankan (ganti = churn tanpa nilai UAT).
// Kontras: primary di atas putih 5.9:1, secondary 5.0:1 (WCAG AA, brief §10).

import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  // ── Teks ──
  static const Color textDefault = Color(0xFF1A1C1E);
  static const Color textSubtle = Color(0xFF5A626B);

  // ── Background ──
  static const Color backgroundApp = Color(0xFFF5F7FA);
  static const Color backgroundPrimary = Color(0xFF1565C0);
  static const Color backgroundDanger = Color(0xFFC62828);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFD5DCE3);

  // ── Status (selalu + label teks, tak mengandalkan warna saja) ──
  static const Color statusLunas = Color(0xFF2E7D32);
  static const Color statusLunasBg = Color(0xFFE8F5E9);
  static const Color statusKurang = Color(0xFFC62828);
  static const Color statusKurangBg = Color(0xFFFFEBEE);
  static const Color statusKembalian = Color(0xFFF9A825);
  static const Color chartTouched = Color(0xFFFF8F00);

  // ── Radius ──
  static const double radiusCard = 12;
  static const double radiusInput = 8;
  static const double radiusSheetTop = 16;
  static const double radiusChip = 20;

  // ── Spacing (basis 4) ──
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
}
