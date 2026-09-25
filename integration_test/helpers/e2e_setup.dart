// Fixture E2E: pengganti "auth fixture" (app tanpa login, NG-2).
// Menyediakan setupDone + seeding/cleanup terisolasi via DbHelper.
// Dijalankan di CI emulator, bukan lokal.
import 'package:setoran_mobil/core/database/db_helper.dart';
import 'package:setoran_mobil/core/utils/week_helper.dart';
import 'package:setoran_mobil/models/pembayaran_log_model.dart';
import 'package:setoran_mobil/models/perbaikan_model.dart';
import 'package:setoran_mobil/models/setoran_model.dart';

class E2eSetup {
  E2eSetup._();

  static DbHelper get db => DbHelper();

  /// Reset total + seed konfigurasi dasar, akhiri sebagai "sudah login"
  /// (setup_done = 1) supaya test tidak mengulang flow onboarding.
  static Future<void> resetDanSeedDasar({
    String jenis = 'E2E Avanza',
    String plat = 'B 1234 E2E',
    int sisaLalu = 0,
    int jumlahMingguan = 700000,
    int jadwalHari = 0,
  }) async {
    final d = db;
    await d.resetSemuaData();
    await d.setJenisKendaraan(jenis);
    await d.setPlatNomor(plat);
    await d.setSisaTahunLalu(sisaLalu);
    await d.setJumlahMingguan(jumlahMingguan);
    await d.setJadwalHari(jadwalHari);
    await d.setSetupDone();
  }

  /// DB kosong tanpa setupDone → splash mengarah ke onboarding (J-1).
  static Future<void> resetKeOnboarding() async {
    await db.resetSemuaData();
  }

  static Future<void> cleanup() async {
    await db.resetSemuaData();
  }

  /// Seed 1 periode LUNAS: buat baris lalu bayar penuh 1 cicilan
  /// via append log (FR-13, bukan timpa).
  static Future<SetoranModel> seedSetoranLunas({
    required int mingguKe,
    required int bulan,
    required int tahun,
    int nominal = 700000,
  }) async {
    final d = db;
    final awal = SetoranModel.hitung(
      mingguKe: mingguKe,
      bulan: bulan,
      tahun: tahun,
      tanggal: WeekHelper.format(
        WeekHelper.tanggalJatuhTempo(mingguKe, 0, bulan, tahun),
      ),
      setoran: nominal,
      dibayarkan: 0,
    );
    await d.simpanSetoranLengkap(awal);
    final list = await d.getSetoranByBulan(bulan, tahun);
    final saved = list.firstWhere((s) => s.mingguKe == mingguKe);
    await d.simpanSetoranLengkap(
      saved,
      cicilan: PembayaranLogModel(
        setoranId: saved.id!,
        waktuIso: DateTime.now().toIso8601String(),
        nominal: saved.totalSetoran,
        catatan: 'e2e lunas',
      ),
    );
    final after = await d.getSetoranByBulan(bulan, tahun);
    return after.firstWhere((s) => s.mingguKe == mingguKe);
  }

  static Future<PerbaikanModel> seedPerbaikan({
    required int tahun,
    String jenis = 'Oli E2E',
    String bengkel = 'Bengkel E2E',
    int biaya = 150000,
  }) async {
    final d = db;
    final model = PerbaikanModel(
      tanggal: '15/06/$tahun',
      tahun: tahun,
      jenisPerbaikan: jenis,
      namaBengkel: bengkel,
      biaya: biaya,
    );
    final id = await d.insertPerbaikan(model);
    final list = await d.getPerbaikanByTahun(tahun);
    return list.firstWhere((p) => p.id == id);
  }
}
