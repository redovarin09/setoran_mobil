import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/setoran_model.dart';
import '../../models/perbaikan_model.dart';

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
      version: 2,
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

    await db.insert('konfigurasi', {
      'kunci': 'sisa_tahun_lalu',
      'nilai': '2284584',
    });
  }

  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Tambah kolom bukti_bayar ke tabel yang sudah ada
      try {
        await db.execute(
          'ALTER TABLE setoran ADD COLUMN '
          'bukti_bayar TEXT NOT NULL DEFAULT ""',
        );
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE perbaikan ADD COLUMN '
          'bukti_bayar TEXT NOT NULL DEFAULT ""',
        );
      } catch (_) {}
    }
  }

  // ─── SETORAN CRUD ──────────────────────────────────

  Future<int> insertSetoran(SetoranModel s) async {
    final d = await db;
    return d.insert(
      'setoran',
      s.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateSetoran(SetoranModel s) async {
    final d = await db;
    return d.update('setoran', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteSetoran(int id) async {
    final d = await db;
    return d.delete('setoran', where: 'id = ?', whereArgs: [id]);
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
      map[row['bulan'] as int] = (row['total'] as int?) ?? 0;
    }
    return map;
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
    return d.delete('perbaikan', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PerbaikanModel>> getPerbaikanByTahun(int tahun) async {
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
      'SELECT SUM(biaya) as total FROM perbaikan WHERE tahun = ?',
      [tahun],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  // ─── KONFIGURASI ───────────────────────────────────

  Future<int> getSisaTahunLalu() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?', whereArgs: ['sisa_tahun_lalu']);
    if (rows.isEmpty) return 0;
    return int.tryParse(rows.first['nilai'] as String) ?? 0;
  }

  Future<void> setSisaTahunLalu(int nilai) async {
    final d = await db;
    await d.insert('konfigurasi',
        {'kunci': 'sisa_tahun_lalu', 'nilai': nilai.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> isSetupDone() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?', whereArgs: ['setup_done']);
    return rows.isNotEmpty;
  }

  Future<void> setSetupDone() async {
    final d = await db;
    await d.insert('konfigurasi',
        {'kunci': 'setup_done', 'nilai': '1'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String> getKendaraanNama() async {
    final d    = await db;
    final rows = await d.query('konfigurasi',
        where: 'kunci = ?', whereArgs: ['kendaraan_nama']);
    if (rows.isEmpty) return 'Kendaraan';
    return rows.first['nilai'] as String;
  }

  Future<void> setKendaraanNama(String nama) async {
    final d = await db;
    await d.insert('konfigurasi',
        {'kunci': 'kendaraan_nama', 'nilai': nama},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> carryOverKeTahunDepan(int tahunAsal) async {
    final grand = await _hitungGrandTotal(tahunAsal);
    final d     = await db;
    await d.insert('konfigurasi',
        {'kunci': 'sisa_tahun_lalu', 'nilai': grand.abs().toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await d.insert('konfigurasi', {
      'kunci': 'sisa_${tahunAsal}_to_${tahunAsal + 1}',
      'nilai': grand.toString()
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> _hitungGrandTotal(int tahun) async {
    final sisa    = await getSisaTahunLalu();
    final perBulan= await getAllSisaPerBulan(tahun);
    final total   = perBulan.values.fold(0, (a, b) => a + b);
    final pbk     = await getTotalPerbaikan(tahun);
    return sisa + total - pbk;
  }

  // ─── BACKUP & RESTORE ──────────────────────────────

  Future<Map<String, dynamic>> exportToJson(int tahun) async {
    final setoran   = await getSetoranByBulanAll(tahun);
    final perbaikan = await getPerbaikanByTahun(tahun);
    final sisa      = await getSisaTahunLalu();
    return {
      'versi':           1,
      'tahun':           tahun,
      'sisa_tahun_lalu': sisa,
      'setoran':  setoran.map((s) => s.toMap()).toList(),
      'perbaikan':perbaikan.map((p) => p.toMap()).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  Future<List<SetoranModel>> getSetoranByBulanAll(int tahun) async {
    final d    = await db;
    final rows = await d.query('setoran',
        where: 'tahun = ?',
        whereArgs: [tahun],
        orderBy: 'bulan ASC, minggu_ke ASC');
    return rows.map(SetoranModel.fromMap).toList();
  }

  Future<void> importFromJson(Map<String, dynamic> json) async {
    final d     = await db;
    final tahun = json['tahun'] as int;
    final sisa  = json['sisa_tahun_lalu'] as int;

    await d.transaction((txn) async {
      await txn.delete('setoran',
          where: 'tahun = ?', whereArgs: [tahun]);
      await txn.delete('perbaikan',
          where: 'tahun = ?', whereArgs: [tahun]);

      for (final m in (json['setoran'] as List)) {
        final map = Map<String, dynamic>.from(m)..remove('id');
        await txn.insert('setoran', map);
      }
      for (final m in (json['perbaikan'] as List)) {
        final map = Map<String, dynamic>.from(m)..remove('id');
        await txn.insert('perbaikan', map);
      }
      await txn.insert('konfigurasi',
          {'kunci': 'sisa_tahun_lalu', 'nilai': sisa.toString()},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<void> resetSemuaData() async {
    final d = await db;
    await d.delete('setoran');
    await d.delete('perbaikan');
  }
}
