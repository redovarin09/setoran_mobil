import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/setoran_model.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/info_row.dart';
import 'input_setoran_sheet.dart';

class SetoranScreen extends StatefulWidget {
  const SetoranScreen({super.key});

  @override
  State<SetoranScreen> createState() => _SetoranScreenState();
}

class _SetoranScreenState extends State<SetoranScreen> {
  final _db = DbHelper();

  int _bulanDipilih = DateTime.now().month;
  int _tahun        = DateTime.now().year;
  List<SetoranModel> _data = [];
  int _totalSisa    = 0;
  bool _loading     = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data  = await _db.getSetoranByBulan(_bulanDipilih, _tahun);
    final total = await _db.getTotalSisaByBulan(_bulanDipilih, _tahun);
    setState(() {
      _data      = data;
      _totalSisa = total;
      _loading   = false;
    });
  }

  SetoranModel? _getByMinggu(int minggu) {
    try {
      return _data.firstWhere((s) => s.mingguKe == minggu);
    } catch (_) {
      return null;
    }
  }

  void _openSheet(int mingguKe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InputSetoranSheet(
        mingguKe: mingguKe,
        bulan:    _bulanDipilih,
        tahun:    _tahun,
        existing: _getByMinggu(mingguKe),
        onSaved:  _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Setoran'),
        actions: [
          // Pilih Tahun
          TextButton(
            onPressed: _pilihTahun,
            child: Text(
              '$_tahun',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pilih Bulan (horizontal scroll)
          _buildBulanSelector(),

          // Summary bar
          _buildSummaryBar(),

          // Week Cards
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: 4,
                    itemBuilder: (_, i) => _buildWeekCard(i + 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulanSelector() {
    return Container(
      color: AppColors.primary,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 12,
        itemBuilder: (_, i) {
          final bulan   = i + 1;
          final dipilih = bulan == _bulanDipilih;
          return GestureDetector(
            onTap: () {
              setState(() => _bulanDipilih = bulan);
              _load();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: dipilih
                    ? Colors.white
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                AppStrings.bulan[i].substring(0, 3),
                style: TextStyle(
                  color: dipilih
                      ? AppColors.primary
                      : Colors.white,
                  fontWeight: dipilih
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Sisa Setoran',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.bulan[_bulanDipilih - 1],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(_totalSisa),
            style: TextStyle(
              color: _totalSisa > 0
                  ? AppColors.accentLight
                  : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(int minggu) {
    final data    = _getByMinggu(minggu);
    final isEmpty = data == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEmpty
              ? AppColors.divider
              : data.isLunas
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.danger.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSheet(minggu),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Header card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isEmpty
                              ? AppColors.background
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$minggu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEmpty
                                  ? AppColors.textLight
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minggu ke-$minggu',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (!isEmpty)
                            Text(
                              data.tanggal,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (!isEmpty)
                    StatusBadge(status: data.keterangan)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Text(
                        '+ Input',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                ],
              ),

              // Detail (jika ada data)
              if (!isEmpty) ...[
                const Divider(height: 16),
                InfoRow(
                  label: 'Setoran',
                  value: CurrencyFormatter.format(data.setoran),
                ),
                if (data.potongan > 0)
                  InfoRow(
                    label: 'Potongan',
                    value: '- ${CurrencyFormatter.format(data.potongan)}',
                    valueColor: AppColors.warning,
                  ),
                InfoRow(
                  label: 'Dibayarkan',
                  value: CurrencyFormatter.format(data.dibayarkan),
                ),
                const Divider(height: 12),
                InfoRow(
                  label: 'Sisa',
                  value: CurrencyFormatter.format(data.sisa),
                  valueColor: data.isLunas
                      ? AppColors.success
                      : AppColors.danger,
                  isBold: true,
                ),
                if (data.catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.notes,
                          size: 12, color: AppColors.textLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.catatan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pilihTahun() async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Pilih Tahun'),
        children: [2024, 2025, 2026, 2027].map((y) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, y),
            child: Text(
              '$y',
              style: TextStyle(
                fontWeight: y == _tahun
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: y == _tahun
                    ? AppColors.primary
                    : AppColors.textDark,
              ),
            ),
          );
        }).toList(),
      ),
    );
    if (picked != null) {
      setState(() => _tahun = picked);
      _load();
    }
  }
}
