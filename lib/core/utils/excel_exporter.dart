import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_strings.dart';
import '../database/db_helper.dart';
import 'currency_formatter.dart';

class ExcelExporter {
  static Future<void> exportTahun(int tahun) async {
    final db         = DbHelper();
    final excel      = Excel.createExcel();
    final sisaLalu   = await db.getSisaTahunLalu();
    final perbaikan  = await db.getPerbaikanByTahun(tahun);
    final totalPbk   = await db.getTotalPerbaikan(tahun);
    final perBulan   = await db.getAllSisaPerBulan(tahun);

    // ── Sheet 1: Setoran Per Bulan ──────────────────
    excel.rename('Sheet1', 'Setoran $tahun');
    final sheetSetor = excel['Setoran $tahun'];

    // Header
    final headers = [
      'Bulan', 'Minggu', 'Tanggal',
      'Setoran', 'Potongan', 'Total Setoran',
      'Dibayarkan', 'Sisa', 'Keterangan', 'Catatan'
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheetSetor.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Data per bulan
    var row = 1;
    int totalSisaAll = 0;
    for (var b = 1; b <= 12; b++) {
      final data = await db.getSetoranByBulan(b, tahun);
      if (data.isEmpty) continue;

      for (final s in data) {
        final values = [
          AppStrings.bulan[b - 1],
          'Minggu ${s.mingguKe}',
          s.tanggal,
          s.setoran,
          s.potongan,
          s.totalSetoran,
          s.dibayarkan,
          s.sisa,
          s.keterangan,
          s.catatan,
        ];
        for (var c = 0; c < values.length; c++) {
          final cell = sheetSetor.cell(
            CellIndex.indexByColumnRow(
                columnIndex: c, rowIndex: row));
          final v = values[c];
          cell.value = v is int
              ? IntCellValue(v)
              : TextCellValue(v.toString());

          // Warna baris status
          if (c >= 0) {
            cell.cellStyle = CellStyle(
              backgroundColorHex: s.keterangan == 'Lunas'
                  ? ExcelColor.fromHexString('#E8F5E9')
                  : ExcelColor.fromHexString('#FFEBEE'),
            );
          }
        }
        totalSisaAll += s.sisa;
        row++;
      }
    }

    // Total row
    row++;
    sheetSetor
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: row))
        .value = TextCellValue('TOTAL SISA');
    final totalCell = sheetSetor.cell(
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row));
    totalCell.value  = IntCellValue(totalSisaAll);
    totalCell.cellStyle = CellStyle(bold: true);

    // ── Sheet 2: Rekap Perbaikan ────────────────────
    final sheetPbk = excel['Perbaikan $tahun'];
    final hdrPbk   = [
      'Tanggal', 'Jenis Perbaikan',
      'Nama Bengkel', 'Biaya', 'KM', 'Keterangan'
    ];
    for (var i = 0; i < hdrPbk.length; i++) {
      final cell = sheetPbk.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(hdrPbk[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#6A1B9A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    var rPbk = 1;
    for (final p in perbaikan) {
      final vals = [
        p.tanggal, p.jenisPerbaikan,
        p.namaBengkel, p.biaya, p.km, p.keterangan
      ];
      for (var c = 0; c < vals.length; c++) {
        final cell = sheetPbk.cell(
          CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: rPbk));
        final v = vals[c];
        cell.value = v is int
            ? IntCellValue(v)
            : TextCellValue(v.toString());
      }
      rPbk++;
    }

    // Total perbaikan
    rPbk++;
    sheetPbk
        .cell(CellIndex.indexByColumnRow(
            columnIndex: 0, rowIndex: rPbk))
        .value = TextCellValue('TOTAL BIAYA');
    final totPbkCell = sheetPbk.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rPbk));
    totPbkCell.value     = IntCellValue(totalPbk);
    totPbkCell.cellStyle = CellStyle(bold: true);

    // ── Sheet 3: Grand Total ────────────────────────
    final sheetGT  = excel['Grand Total'];
    final namaKend = await db.getKendaraanNama();
    final totalSet = perBulan.values.fold(0, (a, b) => a + b);
    final grandTot = sisaLalu + totalSet - totalPbk;

    final gtRows = [
      ['Laporan Keuangan', '$namaKend — $tahun'],
      [''],
      ['Sisa Tahun Lalu', CurrencyFormatter.format(sisaLalu)],
      ['Total Sisa Setoran $tahun',
          CurrencyFormatter.format(totalSet)],
      ['Sub Total',
          CurrencyFormatter.format(sisaLalu + totalSet)],
      [''],
      ['Total Biaya Perbaikan',
          CurrencyFormatter.format(totalPbk)],
      [''],
      ['GRAND TOTAL', CurrencyFormatter.format(grandTot)],
      [''],
      ['Dicetak pada', DateTime.now().toString()],
    ];

    for (var r = 0; r < gtRows.length; r++) {
      for (var c = 0; c < gtRows[r].length; c++) {
        final cell = sheetGT.cell(
          CellIndex.indexByColumnRow(
              columnIndex: c, rowIndex: r));
        cell.value = TextCellValue(gtRows[r][c]);
        if (r == 0 || r == 8) {
          cell.cellStyle = CellStyle(
            bold: true,
            fontSize: r == 8 ? 14 : 12,
          );
        }
      }
    }

    // Simpan & share
    final bytes   = excel.save()!;
    final dir     = await getApplicationDocumentsDirectory();
    final path    = '${dir.path}/Setoran_${namaKend}_$tahun.xlsx';
    await File(path).writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'Laporan Setoran $namaKend $tahun',
      subject: 'Setoran_${namaKend}_$tahun.xlsx',
    );
  }
}
