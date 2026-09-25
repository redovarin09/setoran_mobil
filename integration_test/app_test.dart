// E2E J-1..J-8 — dijalankan HANYA di CI emulator (scripts/e2e_ci.sh).
// NEVER dijalankan lokal (aturan proyek: browser/E2E lewat Actions).
// Stack: integration_test (pengganti Playwright, disetujui owner):
// app Flutter offline tanpa login/backend (NG-2/NG-4), tanpa DOM web.
// Selector: ValueKey e2e_* (data-testid) + ikon + teks stabil.
// Auth fixture = E2eSetup.resetDanSeedDasar (setup_done=1, tanpa login).
// Seeding/cleanup: resetSemuaData di setUp/tearDown → terisolasi.
// NOTE pompa: pakai pump(Duration) manual, bukan pumpAndSettle,
// karena CircularProgressIndicator (splash/loading) tak pernah settle.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:setoran_mobil/core/database/db_helper.dart';
import 'package:setoran_mobil/core/error/app_error.dart';
import 'package:setoran_mobil/core/utils/backup.dart';
import 'package:setoran_mobil/core/utils/currency_formatter.dart';
import 'package:setoran_mobil/core/utils/week_helper.dart';
import 'package:setoran_mobil/main.dart';
import 'package:setoran_mobil/models/pembayaran_log_model.dart';
import 'package:setoran_mobil/models/perbaikan_model.dart';
import 'package:setoran_mobil/models/setoran_model.dart';
import 'package:setoran_mobil/widgets/bersama/bukti_bayar_widget.dart';

import 'helpers/e2e_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final db = DbHelper();
  final tahun = DateTime.now().year;
  final bulan = DateTime.now().month;

  // ── Helper pompa ──────────────────────────────────

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const SetoranMobilApp());
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> sheetSettle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<void> isiCurrency(
      WidgetTester tester, String key, String value) async {
    final field = find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextFormField),
    );
    expect(field, findsOneWidget, reason: 'field $key');
    await tester.enterText(field, value);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> bukaTab(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 500));
  }

  // ══ J-1 Onboarding/setup (US-1, US-13) ══════════════

  group('J-1 onboarding', () {
    setUp(() async => E2eSetup.resetKeOnboarding());
    tearDown(() async => E2eSetup.cleanup());

    testWidgets('happy: 3 langkah → MainNavigation', (tester) async {
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('onboardingNext')),
          findsOneWidget);

      // Halaman 1 → 2.
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 500));
      // Halaman 2: jenis + plat.
      await tester.enterText(
          find.byKey(const ValueKey('onboardingJenis')), 'E2E Avanza');
      await tester.enterText(
          find.byKey(const ValueKey('onboardingPlat')), 'B 1 E2E');
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 500));
      // Halaman 3: sisa + jumlah + jadwal default Minggu.
      await tester.enterText(
          find.byKey(const ValueKey('onboardingSisa')), '100000');
      await tester.enterText(
          find.byKey(const ValueKey('onboardingJumlah')), '700000');
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const ValueKey('navBar')), findsOneWidget);
      expect(await db.isSetupDone(), isTrue);
      expect(await db.getJenisKendaraan(), 'E2E Avanza');
      expect(await db.getSisaTahunLalu(), 100000);
      expect(await db.getJumlahMingguan(), 700000);
    });

    testWidgets('failure: jenis kosong → default Kendaraan Saya',
        (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 500));
      // Jenis dikosongkan, plat diisi.
      await tester.enterText(
          find.byKey(const ValueKey('onboardingJenis')), '');
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('onboardingNext')));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const ValueKey('navBar')), findsOneWidget);
      expect(await db.getJenisKendaraan(), 'Kendaraan Saya');
    });
  });

  // ══ J-2 Input setoran + preview (US-3, US-4, US-14) ══

  group('J-2 input setoran', () {
    setUp(() async => E2eSetup.resetDanSeedDasar());
    tearDown(() async => E2eSetup.cleanup());

    testWidgets('happy: cicilan penuh → Lunas', (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.receipt_long_outlined);
      await tester.tap(find.byKey(const ValueKey('setoranCard-1')));
      await sheetSettle(tester);
      expect(find.textContaining('Periode 1'), findsWidgets);

      // Nominal default 700000 (prefill jumlah mingguan); bayar penuh.
      await isiCurrency(tester, 'setoranCicilan', '700000');
      await tester.tap(find.byKey(const ValueKey('setoranSimpan')));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Lunas'), findsOneWidget);
      final rows = await db.getSetoranByBulan(bulan, tahun);
      final s = rows.firstWhere((e) => e.mingguKe == 1);
      expect(s.keterangan, 'Lunas');
      expect(s.sisa, 0);
      expect(s.dibayarkan, 700000);
    });

    testWidgets('failure: nominal 0 ditolak, sheet tetap terbuka',
        (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.receipt_long_outlined);
      await tester.tap(find.byKey(const ValueKey('setoranCard-2')));
      await sheetSettle(tester);

      await isiCurrency(tester, 'setoranNominal', '');
      await tester.tap(find.byKey(const ValueKey('setoranSimpan')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Nominal setoran tidak boleh 0'),
          findsOneWidget);
      // Sheet tidak tertutup.
      expect(find.textContaining('Periode 2'), findsWidgets);
    });
  });

  // ══ J-3 Cicilan log + reversal (US-5, NQ-3) ═════════

  group('J-3 log cicilan', () {
    setUp(() async => E2eSetup.resetDanSeedDasar());
    tearDown(() async => E2eSetup.cleanup());

    test('happy: 2 cicilan append → dibayarkan = Σlog', () async {
      final awal = SetoranModel.hitung(
        mingguKe: 1,
        bulan: bulan,
        tahun: tahun,
        tanggal: WeekHelper.format(
            WeekHelper.tanggalJatuhTempo(1, 0, bulan, tahun)),
        setoran: 700000,
        dibayarkan: 0,
      );
      await db.simpanSetoranLengkap(awal);
      var rows = await db.getSetoranByBulan(bulan, tahun);
      var s = rows.firstWhere((e) => e.mingguKe == 1);

      for (final nominal in [400000, 300000]) {
        await db.simpanSetoranLengkap(
          s,
          cicilan: PembayaranLogModel(
            setoranId: s.id!,
            waktuIso: DateTime.now().toIso8601String(),
            nominal: nominal,
          ),
        );
        rows = await db.getSetoranByBulan(bulan, tahun);
        s = rows.firstWhere((e) => e.mingguKe == 1);
      }

      final logs = await db.getLogBySetoran(s.id!);
      expect(logs.length, 2);
      expect(s.dibayarkan, 700000);
      expect(s.keterangan, 'Lunas');
    });

    test('happy: reversal negatif → Kurang lagi', () async {
      final lunas =
          await E2eSetup.seedSetoranLunas(mingguKe: 1, bulan: bulan, tahun: tahun);
      await db.simpanSetoranLengkap(
        lunas,
        cicilan: PembayaranLogModel(
          setoranId: lunas.id!,
          waktuIso: DateTime.now().toIso8601String(),
          nominal: -100000,
          catatan: 'koreksi e2e',
        ),
      );
      final rows = await db.getSetoranByBulan(bulan, tahun);
      final s = rows.firstWhere((e) => e.mingguKe == 1);
      final logs = await db.getLogBySetoran(s.id!);
      expect(logs.any((l) => l.isReversal), isTrue);
      expect(s.dibayarkan, 600000);
      expect(s.sisa, 100000);
      expect(s.keterangan, 'Kurang');
    });

    test('failure: log nominal 0 ditolak DB (CHECK)', () async {
      final lunas =
          await E2eSetup.seedSetoranLunas(mingguKe: 1, bulan: bulan, tahun: tahun);
      expect(
        () => db.insertLog(PembayaranLogModel(
          setoranId: lunas.id!,
          waktuIso: DateTime.now().toIso8601String(),
          nominal: 0,
        )),
        throwsA(anything),
      );
    });
  });

  // ══ J-4 Perbaikan CRUD + search (US-6, US-7, US-8) ══

  group('J-4 perbaikan', () {
    setUp(() async => E2eSetup.resetDanSeedDasar());
    tearDown(() async => E2eSetup.cleanup());

    testWidgets('happy: FAB tambah → kartu muncul', (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.build_outlined);
      await tester.tap(find.byKey(const ValueKey('perbaikanFab')));
      await sheetSettle(tester);
      expect(find.text('Tambah Perbaikan'), findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('perbaikanJenis')), 'Oli E2E');
      await isiCurrency(tester, 'perbaikanBiaya', '150000');
      await tester.tap(find.byKey(const ValueKey('perbaikanSimpan')));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Oli E2E'), findsWidgets);
      final rows = await db.getPerbaikanByTahun(tahun);
      expect(rows.any((p) => p.jenisPerbaikan == 'Oli E2E'), isTrue);
    });

    testWidgets('failure: jenis kosong & biaya 0 ditolak',
        (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.build_outlined);
      await tester.tap(find.byKey(const ValueKey('perbaikanFab')));
      await sheetSettle(tester);

      await tester.tap(find.byKey(const ValueKey('perbaikanSimpan')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Jenis perbaikan tidak boleh kosong'),
          findsOneWidget);

      await tester.enterText(
          find.byKey(const ValueKey('perbaikanJenis')), 'Ban E2E');
      await tester.tap(find.byKey(const ValueKey('perbaikanSimpan')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Biaya tidak boleh 0'), findsOneWidget);
      // Sheet tetap terbuka, data tidak tersimpan.
      expect(find.text('Tambah Perbaikan'), findsOneWidget);
      expect(await db.getPerbaikanByTahun(tahun), isEmpty);
    });

    testWidgets('happy: search filter + tahun ikut tanggal nota',
        (tester) async {
      await E2eSetup.seedPerbaikan(
          tahun: tahun, jenis: 'Oli E2E', biaya: 150000);
      await E2eSetup.seedPerbaikan(
          tahun: tahun, jenis: 'Ban E2E', biaya: 500000);
      // Nota beda tahun → tahun ikut tanggal, bukan filter (OQ-9).
      final lain = PerbaikanModel(
        tanggal: '20/01/2024',
        tahun: 2024,
        jenisPerbaikan: 'Aki E2E',
        namaBengkel: '',
        biaya: 800000,
      );
      await db.insertPerbaikan(lain);
      final rows2024 = await db.getPerbaikanByTahun(2024);
      expect(rows2024.any((p) => p.jenisPerbaikan == 'Aki E2E'), isTrue);

      await pumpApp(tester);
      await bukaTab(tester, Icons.build_outlined);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(
          find.byKey(const ValueKey('perbaikanSearch')), 'oli');
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Oli E2E'), findsWidgets);
      expect(find.text('Ban E2E'), findsNothing);
    });
  });

  // ══ J-5 Dashboard grand total (US-2) ════════════════

  group('J-5 dashboard', () {
    setUp(() async => E2eSetup.resetDanSeedDasar(sisaLalu: 500000));
    tearDown(() async => E2eSetup.cleanup());

    testWidgets('happy: grand positif + badge + angka cocok',
        (tester) async {
      await E2eSetup.seedSetoranLunas(
          mingguKe: 1, bulan: bulan, tahun: tahun);
      await E2eSetup.seedPerbaikan(tahun: tahun, biaya: 150000);
      // grand = 500000 + 0 − 150000 = 350000.
      await pumpApp(tester);
      expect(find.byKey(const ValueKey('dashboardGrandTotal')),
          findsOneWidget);
      expect(find.text('✓ Positif'), findsOneWidget);
      expect(find.text(CurrencyFormatter.format(350000)),
          findsWidgets);

      final sisa = await db.getSisaTahunLalu();
      final perBulan = await db.getAllSisaPerBulan(tahun);
      final total = perBulan.values.fold(0, (a, b) => a + b);
      final pbk = await db.getTotalPerbaikan(tahun);
      expect(hitungGrand(sisa, total, pbk), 350000);
    });

    testWidgets('empty: tanpa data → teks kosong', (tester) async {
      await pumpApp(tester);
      expect(find.text('Belum ada data setoran'), findsOneWidget);
      expect(find.text('Belum ada data'), findsOneWidget);
    });

    test('edge: overpay → Lunas + kembalian; potongan>nominal → minus',
        () {
      final overpay = SetoranModel.hitung(
        mingguKe: 1,
        bulan: bulan,
        tahun: tahun,
        tanggal: '01/01/2026',
        setoran: 700000,
        dibayarkan: 800000,
      );
      expect(overpay.sisa, -100000);
      expect(overpay.keterangan, 'Lunas');
      expect(hitungKembalian(overpay.sisa), 100000);

      final minus = SetoranModel.hitung(
        mingguKe: 2,
        bulan: bulan,
        tahun: tahun,
        tanggal: '08/01/2026',
        setoran: 100000,
        potongan: 150000,
        dibayarkan: 0,
      );
      expect(minus.totalSetoran, -50000);
      expect(minus.sisa, -50000);
      expect(minus.keterangan, 'Lunas');
    });
  });

  // ══ J-6 Foto bukti (US-9) ═══════════════════════════
  // Picker kamera/galeri butuh OS → hanya state widget yang reliable.

  group('J-6 foto bukti', () {
    testWidgets('reliable: counter 0/5 + tombol tambah ada',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuktiBayarWidget(
              initialFileNames: [],
              onChanged: _noop,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('0/5'), findsOneWidget);
      expect(find.bySemanticsLabel('Tambah foto bukti'),
          findsOneWidget);
    });

    test('SKIP-native: ambil foto kamera/galeri', skip: true, () {
      // Tidak reliable headless: butuh ImagePicker + dialog izin OS
      // + file galeri perangkat. Verifikasi manual di HP (M-4).
    });
  });

  // ══ J-7 Backup/restore + export (US-10, US-11) ══════

  group('J-7 backup restore', () {
    setUp(() async => E2eSetup.resetDanSeedDasar(sisaLalu: 50000));
    tearDown(() async => E2eSetup.cleanup());

    test('happy: export versi 2 + roundtrip sama', () async {
      await E2eSetup.seedSetoranLunas(
          mingguKe: 1, bulan: bulan, tahun: tahun);
      await E2eSetup.seedPerbaikan(tahun: tahun);
      final json = await db.exportToJson(tahun);
      expect(json['versi'], 2);
      expect(json['tahun'], tahun);
      expect((json['setoran'] as List).length, 1);
      expect((json['perbaikan'] as List).length, 1);
      expect(json['sisa_tahun_lalu'], 50000);

      await db.resetSemuaData();
      await E2eSetup.resetDanSeedDasar(sisaLalu: 0);
      await db.importFromJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect((await db.getSetoranByBulan(bulan, tahun)).length, 1);
      expect((await db.getPerbaikanByTahun(tahun)).length, 1);
      expect(await db.getSisaTahunLalu(), 50000);
    });

    test('failure: versi != 2 ditolak; teks bukan JSON ditolak',
        () async {
      expect(
        () => cekVersiBackup(
            {'versi': 1, 'tahun': tahun, 'sisa_tahun_lalu': 0}),
        throwsA(isA<AppError>().having(
            (e) => e.kode, 'kode', AppErrorCode.takDiproses)),
      );
      expect(() => jsonDecode('bukan json {{{'), throwsFormatException);
      expect(sanitasiNamaFile('Avanza/Putih?'), 'Avanza_Putih');
    });

    test('SKIP-native: share sheet Excel/JSON', skip: true, () {
      // Tidak reliable headless: SharePlus butuh handler OS
      // (E-17). Verifikasi manual: file .xlsx/.json ada + terbuka
      // di WPS/Excel Android (M-5, M-6).
    });
  });

  // ══ J-8 Pengaturan + carry-over + reset (US-12) ═════

  group('J-8 pengaturan', () {
    setUp(() async => E2eSetup.resetDanSeedDasar(sisaLalu: 100000));
    tearDown(() async => E2eSetup.cleanup());

    test('happy: carry-over bertanda asli (minus tetap minus)',
        () async {
      await E2eSetup.seedPerbaikan(tahun: tahun, biaya: 150000);
      // grand = 100000 + 0 − 150000 = −50000.
      await db.carryOverKeTahunDepan(tahun);
      expect(await db.getSisaTahunLalu(), -50000);
    });

    testWidgets('happy: reset double-confirm → onboarding',
        (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.settings_outlined);
      await tester.tap(find.text('Reset Semua Data'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('HAPUS SEMUA'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Ya, Hapus'));
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.byKey(const ValueKey('onboardingNext')),
          findsOneWidget);
      expect(await db.isSetupDone(), isFalse);
    });

    testWidgets('failure: batal di konfirmasi kedua → data utuh',
        (tester) async {
      await pumpApp(tester);
      await bukaTab(tester, Icons.settings_outlined);
      await tester.tap(find.text('Reset Semua Data'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('HAPUS SEMUA'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Tidak'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Zona Berbahaya'), findsOneWidget);
      expect(await db.isSetupDone(), isTrue);
      expect(await db.getJenisKendaraan(), 'E2E Avanza');
    });
  });
}

void _noop(List<String> _) {}
