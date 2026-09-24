import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/setoran_model.dart';
import '../../models/pembayaran_log_model.dart';
import '../../models/perbaikan_model.dart';
import '../error/app_error.dart';
import '../utils/backup.dart';
import '../utils/image_helper.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'setoran_mobil.db');
    return openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE setoran (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        minggu_ke     INTEGER NOT NULL,
        bulan         INTEGER NOT NULL,
        tahun         INTEGER NOT NULL,
        tanggal       TEXT    NOT NULL,
        setoran       INTEGER NOT NULL DEFAULT 0,
        potongan      INTEGER NOT NULL DEFAULT 0,
        total_setoran INTEGER NOT NULL DEFAULT 0,
        dibayarkan    INTEGER NOT NULL DEFAULT 0,
        sisa          INTEGER NOT NULL DEFAULT 0,
        keterangan    TEXT    NOT NULL DEFAULT '',
        catatan       TEXT    NOT NULL DEFAULT '',
        bukti_bayar   TEXT    NOT NULL DEFAULT '',
        UNIQUE(minggu_ke, bulan, tahun)
      )
    ''');
    await db.execute('''
      CREATE TABLE perbaikan (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        tanggal          TEXT    NOT NULL,
        tahun            INTEGER NOT NULL,
        jenis_perbaikan  TEXT    NOT NULL,
        nama_bengkel     TEXT    NOT NULL,
        biaya            INTEGER NOT NULL DEFAULT 0,
        km               TEXT    NOT NULL DEFAULT '',
        keterangan       TEXT    NOT NULL DEFAULT '',
        bukti_bayar      TEXT    NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE konfigurasi (
        kunci TEXT PRIMARY KEY,
        nilai TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE pembayaran_log (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        setoran_id  INTEGER NOT NULL
                    REFERENCES setoran(id) ON DELETE CASCADE,
        waktu       TEXT    NOT NULL,
        nominal     INTEGER NOT NULL CHECK(nominal != 0),
        bukti_bayar TEXT    NOT NULL DEFAULT '',
        catatan     TEXT    NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pembayaran_log_setoran '
      'ON pembayaran_log(setoran_id)',
    );
    await db.insert('konfigurasi', {
      'kunci': 'sisa_tahun_lalu',
      'nilai': '0',
    });
  }

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // E-18: gagal migrasi wajib dilaporkan, bukan try/catch kosong.
      for (final sql in [
        'ALTER TABLE setoran ADD COLUMN '
        'bukti_bayar TEXT NOT NULL DEFAULT ""',
        'ALTER TABLE perbaikan ADD COLUMN '
        'bukti_bayar TEXT NOT NULL DEFAULT ""',
      ]) {
        try {
          await db.execute(sql);
        } on DatabaseException catch (e) {
          if (!e.toString().contains('duplicate column name')) {
            rethrow;
          }
        }
      }
    }
    if (oldVersion < 3) {
      // DELTA OQ-6: tabel log append-only (Q1 tech-design).
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pembayaran_log (
          id          INTEGER PRIMARY KEY AUTOINCREMENT,
          setoran_id  INTEGER NOT NULL
                      REFERENCES setoran(id) ON DELETE CASCADE,
          waktu       TEXT    NOT NULL,
          nominal     INTEGER NOT NULL CHECK(nominal != 0),
          bukti_bayar TEXT    NOT NULL DEFAULT '',
          catatan     TEXT    NOT NULL DEFAULT ''
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_pembayaran_log_setoran '
        'ON pembayaran_log(setoran_id)',
      );
      // E-1: dibayarkan existing → 1 log pembuka per setoran.
      final rows = await db.query(
          'setoran', columns: ['id', 'dibayarkan']);
      final batch = db.batch();
      for (final r in rows) {
        final id = r['id'] as int;
        final dibayarkan = (r['dibayarkan'] as int?) ?? 0;
        if (dibayarkan == 0) continue;
        final ada = await db.query('pembayaran_log',
            columns: ['id'],
            where: 'setoran_id = ?',
            whereArgs: [id],
            limit: 1);
        if (ada.isNotEmpty) continue;
        batch.insert('pembayaran_log', {
          'setoran_id':  id,
          'waktu':       DateTime.now().toIso8601String(),
          'nominal':     dibayarkan,
          'bukti_bayar': '',
          'catatan':     'migrasi v2→v3',
        });
      }
      await batch.commit(noResult: true);
    }
  }

  // ─── SETORAN CRUD ──────────────────────────────────

  /// Insert polos: UNIQUE(minggu_ke,bulan,tahun) dilanggar → error,
  /// dilarang replace diam-diam (OQ-6).
  Future<int> insertSetoran(SetoranModel s) async {
    final d = await db;
    return d.insert(
      'setoran',
      s.toMap()..remove('id'),
    );
  }

  Future<int> updateSetoran(SetoranModel s) async {
    final d = await db;
    return d.update('setoran', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteSetoran(int id) async {
    final d = await db;
    await d.delete('pembayaran_log',
        where: 'setoran_id = ?', whereArgs: [id]);
    return d.delete('setoran',
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── PEMBAYARAN LOG (append-only, FR-13) ─────────────
  // Larang UPDATE/DELETE log dari UI; koreksi = reversal negatif.

  Future<int> insertLog(PembayaranLogModel l) async {
    final d = await db;
    return d.insert(
        'pembayaran_log', l.toMap()..remove('id'));
  }

  Future<List<PembayaranLogModel>> getLogBySetoran(
      int setoranId) async {
    final d    = await db;
    final rows = await d.query('pembayaran_log',
        where: 'setoran_id = ?',
        whereArgs: [setoranId],
        orderBy: 'id ASC');
    return rows.map(PembayaranLogModel.fromMap).toList();
  }

  /// Simpan periode + 1 cicilan (opsional) dalam 1 transaksi,
  /// lalu hitung ulang dibayarkan (= Σ log), sisa bertanda,
  /// keterangan dari baris setoran.
  Future<void> simpanSetoranLengkap(
    SetoranModel s, {
    PembayaranLogModel? cicilan,
  }) async {
    final d = await db;
    await d.transaction((txn) async {
      int setoranId;
      if (s.id == null) {
        setoranId = await txn.insert(
            'setoran', s.toMap()..remove('id'));
      } else {
        setoranId = s.id!;
        await txn.update('setoran', s.toMap()..remove('id'),
            where: 'id = ?', whereArgs: [setoranId]);
      }
      if (cicilan != null && cicilan.nominal != 0) {
        await txn.insert('pembayaran_log',
            cicilan.toMap()
              ..remove('id')
              ..['setoran_id'] = setoranId);
      }
      final sum = await txn.rawQuery(
        'SELECT SUM(nominal) as t FROM pembayaran_log '
        'WHERE setoran_id = ?',
        [setoranId],
      );
      final dibayarkan = (sum.first['t'] as int?) ?? 0;
      final total = s.setoran - s.potongan;
      final sisa  = total - dibayarkan;
      await txn.update(
        'setoran',
        {
          'dibayarkan':  dibayarkan,
          'total_setoran': total,
          'sisa':        sisa,
          'keterangan':  sisa <= 0 ? 'Lunas' : 'Kurang',
        },
        where: 'id = ?',
        whereArgs: [setoranId],
      );
    });
  }

  Future<List<SetoranModel>> getSetoranByBulan(
      int bulan, int tahun) async {
    final d    = await db;
    final rows = await d.query('setoran',
        where: 'bulan = ? AND tahun = ?',
        whereArgs: [bulan, tahun],
        orderBy: 'minggu_ke ASC');
    return rows.map(SetoranModel.fromMap).toList();
  }

  Future<int> getTotalSisaByBulan(int bulan, int tahun) async {
    final d      = await db;
    final result = await d.rawQuery(
      'SELECT SUM(sisa) as total FROM setoran '
      'WHERE bulan = ? AND tahun = ?',
      [bulan, tahun],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<Map<int, int>> getAllSisaPerBulan(int tahun) async {
    final d      = await db;
    final result = await d.rawQuery(
      'SELECT bulan, SUM(sisa) as total FROM setoran '
      'WHERE tahun = ? GROUP BY bulan',
      [tahun],
    );
    final map = <int, int>{};
    for (final row in result) {
      map[row['bulan'] as int] =
          (row['total'] as int?) ?? 0;
    }
    return map;
  }

  Future<List<SetoranModel>> getSetoranByBulanAll(
      int tahun) async {
    final d    = await db;
    final rows = await d.query('setoran',
        where: 'tahun = ?',
        whereArgs: [tahun],
        orderBy: 'bulan ASC, minggu_ke ASC');
    return rows.map(SetoranModel.fromMap).toList();
  }

  // ─── PERBAIKAN CRUD ────────────────────────────────

  Future<int> insertPerbaikan(PerbaikanModel p) async {
    final d = await db;
    return d.insert('perbaikan', p.toMap()..remove('id'));
  }

  Future<int> updatePerbaikan(PerbaikanModel p) async {
    final d = await db;
    return d.update('perbaikan', p.toMap(),
        where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> deletePerbaikan(int id) async {
    final d = await db;
    return d.delete('perbaikan',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PerbaikanModel>> getPerbaikanByTahun(
      int tahun) async {
    final d    = await db;
    final rows = await d.query('perbaikan',
        where: 'tahun = ?',
        whereArgs: [tahun],
        orderBy: 'tanggal ASC');
    return rows.map(PerbaikanModel.fromMap).toList();
  }

  Future<int> getTotalPerbaikan(int tahun) async {
    final d      = await db;
    final result = await d.rawQuery(
      'SELECT SUM(biaya) as total FROM perbaikan '
      'WHERE tahun = ?',
      [tahun],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ─── KONFIGURASI ───────────────────────────────────

  Future<int> getSisaTahunLalu() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['sisa_tahun_lalu']);
    if (rows.isEmpty) return 0;
    return int.tryParse(
            rows.first['nilai'] as String) ?? 0;
  }

  Future<void> setSisaTahunLalu(int nilai) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'sisa_tahun_lalu',
       'nilai': nilai.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> isSetupDone() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?', whereArgs: ['setup_done']);
    return rows.isNotEmpty;
  }

  Future<void> setSetupDone() async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'setup_done', 'nilai': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getKendaraanNama() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['kendaraan_nama']);
    if (rows.isEmpty) return 'Kendaraan';
    return rows.first['nilai'] as String;
  }

  Future<void> setKendaraanNama(String nama) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'kendaraan_nama', 'nilai': nama},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── KONFIGURASI BARU (FR-2, FR-24) ──────────────────
  // jenis_kendaraan gantikan kendaraan_nama; baca fallback lama.

  Future<String> getJenisKendaraan() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['jenis_kendaraan']);
    if (rows.isNotEmpty) {
      return rows.first['nilai'] as String;
    }
    return getKendaraanNama();
  }

  Future<void> setJenisKendaraan(String v) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'jenis_kendaraan', 'nilai': v},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String> getPlatNomor() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['plat_nomor']);
    if (rows.isEmpty) return '';
    return rows.first['nilai'] as String;
  }

  Future<void> setPlatNomor(String v) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'plat_nomor', 'nilai': v},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getJumlahMingguan() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['jumlah_setoran_mingguan']);
    if (rows.isEmpty) return 0;
    return int.tryParse(
            rows.first['nilai'] as String) ?? 0;
  }

  Future<void> setJumlahMingguan(int v) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'jumlah_setoran_mingguan',
       'nilai': v.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 0=Minggu .. 6=Sabtu (tech-design §1), default 0.
  Future<int> getJadwalHari() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?',
        whereArgs: ['jadwal_hari']);
    if (rows.isEmpty) return 0;
    final v = int.tryParse(
        rows.first['nilai'] as String) ?? 0;
    return (v < 0 || v > 6) ? 0 : v;
  }

  Future<void> setJadwalHari(int v) async {
    final d = await db;
    await d.insert(
      'konfigurasi',
      {'kunci': 'jadwal_hari',
       'nilai': v.clamp(0, 6).toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> carryOverKeTahunDepan(int tahunAsal) async {
    final grand = await _hitungGrandTotal(tahunAsal);
    final d     = await db;
    // Bertanda asli (OQ-3): minus tetap minus, larang abs().
    await d.insert(
      'konfigurasi',
      {'kunci': 'sisa_tahun_lalu',
       'nilai': grand.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await d.insert(
      'konfigurasi',
      {
        'kunci': 'sisa_${tahunAsal}_to_${tahunAsal + 1}',
        'nilai': grand.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _hitungGrandTotal(int tahun) async {
    final sisa     = await getSisaTahunLalu();
    final perBulan = await getAllSisaPerBulan(tahun);
    final total    =
        perBulan.values.fold(0, (a, b) => a + b);
    final pbk      = await getTotalPerbaikan(tahun);
    return sisa + total - pbk;
  }

  // ─── BACKUP + FOTO ─────────────────────────────────

  Future<Map<String, dynamic>> exportToJson(int tahun) async {
    final setoran   = await getSetoranByBulanAll(tahun);
    final perbaikan = await getPerbaikanByTahun(tahun);
    final sisa      = await getSisaTahunLalu();

    // Log cicilan periode tahun itu (FR-13: backup wajib sertakan log).
    final ids = setoran
        .where((s) => s.id != null)
        .map((s) => s.id!)
        .toList();
    final logs = <Map<String, dynamic>>[];
    for (final id in ids) {
      for (final l in await getLogBySetoran(id)) {
        logs.add(l.toMap());
      }
    }

    // Kumpulkan semua nama file foto
    final allFileNames = <String>{};
    for (final s in setoran) {
      allFileNames.addAll(s.buktiBayar);
    }
    for (final l in logs) {
      allFileNames.addAll(ImageHelper.decodeList(
          l['bukti_bayar'] ?? ''));
    }
    for (final p in perbaikan) {
      allFileNames.addAll(p.buktiBayar);
    }

    // Encode semua foto ke base64
    final Map<String, String> imagesBase64 = {};
    for (final name in allFileNames) {
      if (name.isEmpty) continue;
      final b64 = await ImageHelper.toBase64(name);
      if (b64 != null) imagesBase64[name] = b64;
    }

    return {
      'versi':           2,
      'tahun':           tahun,
      'sisa_tahun_lalu': sisa,
      'setoran':   setoran.map((s) => s.toMap()).toList(),
      'pembayaran_log': logs,
      'perbaikan': perbaikan.map((p) => p.toMap()).toList(),
      'images':    imagesBase64,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importFromJson(
      Map<String, dynamic> json) async {
    // E-23: tolak versi tak dikenal sebelum menyentuh data.
    cekVersiBackup(json);
    final d     = await db;
    final tahun = json['tahun'] as int;
    final sisa  = json['sisa_tahun_lalu'] as int;

    // 1. Restore foto dulu
    final images =
        json['images'] as Map<String, dynamic>?;
    if (images != null) {
      for (final entry in images.entries) {
        final fileName = entry.key;
        final b64      = entry.value as String;
        await ImageHelper.fromBase64(fileName, b64);
      }
    }

    // 2. Restore data DB
    await d.transaction((txn) async {
      // Hapus log milik periode tahun itu dulu (jangan hapus
      // log tahun lain), lalu setoran + perbaikan tahun itu.
      final korban = await txn.query('setoran',
          columns: ['id'],
          where: 'tahun = ?',
          whereArgs: [tahun]);
      for (final r in korban) {
        await txn.delete('pembayaran_log',
            where: 'setoran_id = ?',
            whereArgs: [r['id']]);
      }
      await txn.delete('setoran',
          where: 'tahun = ?', whereArgs: [tahun]);
      await txn.delete('perbaikan',
          where: 'tahun = ?', whereArgs: [tahun]);

      // Petakan kunci periode → id baru untuk remap log.
      final idBaru = <String, int>{};
      for (final m in (json['setoran'] as List)) {
        final map =
            Map<String, dynamic>.from(m)..remove('id');
        final nid = await txn.insert('setoran', map);
        idBaru['${map['minggu_ke']}/${map['bulan']}'] = nid;
      }
      final daftarLog = json['pembayaran_log'] as List?;
      if (daftarLog != null) {
        // Ambil kunci lama dari payload setoran sebelum insert.
        final kunciLama = <int, String>{};
        for (final m in (json['setoran'] as List)) {
          final map = Map<String, dynamic>.from(m);
          if (map['id'] != null) {
            kunciLama[map['id'] as int] =
                '${map['minggu_ke']}/${map['bulan']}';
          }
        }
        for (final l in daftarLog) {
          final map =
              Map<String, dynamic>.from(l)..remove('id');
          final lama = map['setoran_id'] as int?;
          final kunci = lama == null ? null : kunciLama[lama];
          final nid = kunci == null ? null : idBaru[kunci];
          if (nid == null) continue;
          map['setoran_id'] = nid;
          await txn.insert('pembayaran_log', map);
        }
      }
      for (final m in (json['perbaikan'] as List)) {
        final map =
            Map<String, dynamic>.from(m)..remove('id');
        await txn.insert('perbaikan', map);
      }
      await txn.insert(
        'konfigurasi',
        {'kunci': 'sisa_tahun_lalu',
         'nilai': sisa.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Reset TOTAL (OQ-10): hapus setoran + perbaikan + log + foto +
  /// konfigurasi → kembali onboarding.
  Future<void> resetSemuaData() async {
    final d = await db;
    await d.delete('pembayaran_log');
    await d.delete('setoran');
    await d.delete('perbaikan');
    await d.delete('konfigurasi');
    await ImageHelper.hapusSemuaFoto();
  }
}
