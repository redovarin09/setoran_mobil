import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DbHelper();
  int _tahun = DateTime.now().year;

  int _sisaTahunLalu    = 0;
  Map<int, int> _sisaPerBulan = {};
  int _totalPerbaikan   = 0;
  bool _loading         = true;

  int get _totalSetoran =>
      _sisaPerBulan.values.fold(0, (a, b) => a + b);
  int get _totalKotor  => _sisaTahunLalu + _totalSetoran;
  int get _grandTotal  => _totalKotor - _totalPerbaikan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sisa     = await _db.getSisaTahunLalu();
    final perBulan = await _db.getAllSisaPerBulan(_tahun);
    final perbaikan= await _db.getTotalPerbaikan(_tahun);
    setState(() {
      _sisaTahunLalu  = sisa;
      _sisaPerBulan   = perBulan;
      _totalPerbaikan = perbaikan;
      _loading        = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Dashboard'),
        actions: [
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
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grand Total Card
                    _buildGrandTotalCard(),
                    const SizedBox(height: 16),

                    // Row 2 card kecil
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            label: 'Sisa Tahun Lalu',
                            value: CurrencyFormatter.format(_sisaTahunLalu),
                            icon: Icons.history,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniCard(
                            label: 'Total Perbaikan',
                            value: CurrencyFormatter.format(_totalPerbaikan),
                            icon: Icons.build,
                            color: const Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniCard(
                            label: 'Total Sisa Setoran',
                            value: CurrencyFormatter.format(_totalSetoran),
                            icon: Icons.receipt_long,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniCard(
                            label: 'Grand Total',
                            value: CurrencyFormatter.format(_grandTotal),
                            icon: Icons.account_balance_wallet,
                            color: _grandTotal >= 0
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Rekap per bulan
                    const Text(
                      'Rekap Sisa Per Bulan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRekapBulan(),
                    const SizedBox(height: 20),

                    // Bar chart sederhana
                    const Text(
                      'Grafik Sisa Setoran',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBarChart(),
                    const SizedBox(height: 20),

                    // Kalkulasi detail
                    _buildKalkulasiDetail(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGrandTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _grandTotal >= 0
              ? [AppColors.primary, AppColors.primaryDark]
              : [AppColors.danger, const Color(0xFF8B0000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (_grandTotal >= 0
                    ? AppColors.primary
                    : AppColors.danger)
                .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
  'Grand Total $_tahun',
  style: const TextStyle(     // ← const pindah ke sini
    color: Colors.white70,
    fontSize: 13,
  ),
),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _grandTotal >= 0 ? '✓ Positif' : '⚠ Minus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(_grandTotal.abs()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _grandTotalItem(
                  'Sisa Lalu', CurrencyFormatter.format(_sisaTahunLalu)),
              _grandTotalItem(
                  'Total Setoran', CurrencyFormatter.format(_totalSetoran)),
              _grandTotalItem(
                  'Perbaikan', CurrencyFormatter.format(_totalPerbaikan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _grandTotalItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildRekapBulan() {
    if (_sisaPerBulan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Belum ada data setoran',
              style: TextStyle(color: AppColors.textLight)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(12, (i) {
          final bulan = i + 1;
          final sisa  = _sisaPerBulan[bulan] ?? 0;
          if (sisa == 0) return const SizedBox.shrink();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text('$bulan',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppStrings.bulan[i],
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      CurrencyFormatter.format(sisa),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < 11)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_sisaPerBulan.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Belum ada data',
              style: TextStyle(color: AppColors.textLight)),
        ),
      );
    }

    final maxVal = _sisaPerBulan.values
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final bulan = i + 1;
                final sisa  = (_sisaPerBulan[bulan] ?? 0).toDouble();
                final ratio = maxVal > 0 ? sisa / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (sisa > 0)
                          Container(
                            height: 100 * ratio,
                            decoration: BoxDecoration(
                              color: bulan == DateTime.now().month
                                  ? AppColors.accent
                                  : AppColors.primary.withOpacity(0.7),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          )
                        else
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(12, (i) {
              return Expanded(
                child: Text(
                  AppStrings.bulan[i].substring(0, 1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildKalkulasiDetail() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Kalkulasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _kalRow('Sisa Tahun Lalu',
              CurrencyFormatter.format(_sisaTahunLalu)),
          _kalRow('+ Total Sisa Setoran $_tahun',
              CurrencyFormatter.format(_totalSetoran)),
          const Divider(height: 16),
          _kalRow('Sub Total',
              CurrencyFormatter.format(_totalKotor),
              bold: true),
          _kalRow('- Total Biaya Perbaikan',
              CurrencyFormatter.format(_totalPerbaikan),
              color: AppColors.danger),
          const Divider(height: 16),
          _kalRow(
            'Grand Total',
            CurrencyFormatter.format(_grandTotal),
            bold: true,
            color: _grandTotal >= 0
                ? AppColors.success
                : AppColors.danger,
            fontSize: 15,
          ),
        ],
      ),
    );
  }

  Widget _kalRow(String label, String value,
      {bool bold = false,
      Color? color,
      double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: fontSize,
                color: AppColors.textMedium,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.w500,
                color: color ?? AppColors.textDark,
              )),
        ],
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
            child: Text('$y',
                style: TextStyle(
                  fontWeight: y == _tahun
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: y == _tahun
                      ? AppColors.primary
                      : AppColors.textDark,
                )),
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
