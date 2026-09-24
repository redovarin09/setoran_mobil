import 'package:fl_chart/fl_chart.dart';
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

  int _sisaTahunLalu      = 0;
  Map<int, int> _perBulan = {};
  int _totalPerbaikan     = 0;
  String _namaKendaraan   = 'Kendaraan';
  bool _loading           = true;
  int? _touchedIndex;

  int get _totalSetoran =>
      _perBulan.values.fold(0, (a, b) => a + b);
  int get _grandTotal =>
      _sisaTahunLalu + _totalSetoran - _totalPerbaikan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _db.getSisaTahunLalu(),
      _db.getAllSisaPerBulan(_tahun),
      _db.getTotalPerbaikan(_tahun),
      _db.getKendaraanNama(),
    ]);
    setState(() {
      _sisaTahunLalu   = results[0] as int;
      _perBulan        = results[1] as Map<int, int>;
      _totalPerbaikan  = results[2] as int;
      _namaKendaraan   = results[3] as String;
      _loading         = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              _namaKendaraan,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _pilihTahun,
            child: Text('$_tahun',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGrandTotalCard(),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _buildMiniCard(
                        label: 'Sisa Tahun Lalu',
                        value: CurrencyFormatter.format(
                            _sisaTahunLalu),
                        icon: Icons.history,
                        color: AppColors.primary,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniCard(
                        label: 'Total Perbaikan',
                        value: CurrencyFormatter.format(
                            _totalPerbaikan),
                        icon: Icons.build,
                        color: const Color(0xFF6A1B9A),
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _buildMiniCard(
                        label: 'Total Sisa Setoran',
                        value: CurrencyFormatter.format(
                            _totalSetoran),
                        icon: Icons.receipt_long,
                        color: AppColors.warning,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMiniCard(
                        label: 'Grand Total',
                        value: CurrencyFormatter.format(
                            _grandTotal),
                        icon: Icons.account_balance_wallet,
                        color: _grandTotal >= 0
                            ? AppColors.success
                            : AppColors.danger,
                      )),
                    ]),
                    const SizedBox(height: 20),

                    // fl_chart Bar Chart
                    _sectionTitle('Grafik Sisa Per Bulan'),
                    const SizedBox(height: 10),
                    _buildFlChart(),
                    const SizedBox(height: 20),

                    // Rekap bulan
                    _sectionTitle('Rekap Sisa Per Bulan'),
                    const SizedBox(height: 10),
                    _buildRekapBulan(),
                    const SizedBox(height: 20),

                    // Detail kalkulasi
                    _buildKalkulasi(),
                    const SizedBox(height: 16),
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
                .withValues(alpha: 0.4),
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
                '$_namaKendaraan · $_tahun',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
              _gtItem('Sisa Lalu',
                  CurrencyFormatter.format(_sisaTahunLalu)),
              _gtItem('Total Setoran',
                  CurrencyFormatter.format(_totalSetoran)),
              _gtItem('Perbaikan',
                  CurrencyFormatter.format(_totalPerbaikan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gtItem(String label, String value) {
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
            color: color.withValues(alpha: 0.08),
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
              color: color.withValues(alpha: 0.1),
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

  Widget _buildFlChart() {
    if (_perBulan.isEmpty) {
      return Container(
        height: 180,
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

    final maxVal = _perBulan.values
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback:
                      (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        _touchedIndex = null;
                        return;
                      }
                      _touchedIndex = barTouchResponse
                          .spot!.touchedBarGroupIndex;
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primaryDark,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, gi, rod, ri) {
                      final bulan = group.x + 1;
                      final nilai = _perBulan[bulan] ?? 0;
                      return BarTooltipItem(
                        '${AppStrings.bulan[bulan - 1]}\n'
                        '${CurrencyFormatter.format(nilai)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final b = val.toInt() + 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            AppStrings.bulan[b - 1]
                                .substring(0, 1),
                            style: TextStyle(
                              fontSize: 10,
                              color: _touchedIndex == val.toInt()
                                  ? AppColors.primary
                                  : AppColors.textLight,
                              fontWeight:
                                  _touchedIndex == val.toInt()
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                      reservedSize: 20,
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(12, (i) {
                  final bulan = i + 1;
                  final sisa  =
                      (_perBulan[bulan] ?? 0).toDouble();
                  final isTouched = _touchedIndex == i;
                  final isThisMonth =
                      bulan == DateTime.now().month &&
                          _tahun == DateTime.now().year;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: sisa == 0 ? 0.5 : sisa,
                        color: isTouched
                            ? AppColors.accent
                            : isThisMonth
                                ? AppColors.primary
                                : AppColors.primaryLight
                                    .withValues(alpha: 0.6),
                        width: isTouched ? 18 : 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // Legend
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.primary, 'Bulan ini'),
              const SizedBox(width: 16),
              _legendDot(AppColors.accent, 'Dipilih'),
              const SizedBox(width: 16),
              _legendDot(
                  AppColors.primaryLight.withValues(alpha: 0.6),
                  'Lainnya'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textLight)),
      ],
    );
  }

  Widget _buildRekapBulan() {
    if (_perBulan.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(12, (i) {
          final bulan = i + 1;
          final sisa  = _perBulan[bulan] ?? 0;
          if (sisa == 0) return const SizedBox.shrink();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.1),
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
                    Expanded(
                      child: Text(
                        AppStrings.bulan[i],
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  Widget _buildKalkulasi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Kalkulasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              )),
          const SizedBox(height: 12),
          _kalRow('Sisa Tahun Lalu',
              CurrencyFormatter.format(_sisaTahunLalu)),
          _kalRow('+ Total Sisa Setoran',
              CurrencyFormatter.format(_totalSetoran)),
          const Divider(height: 16),
          _kalRow('Sub Total',
              CurrencyFormatter.format(
                  _sisaTahunLalu + _totalSetoran),
              bold: true),
          _kalRow('- Total Perbaikan',
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
      {bool bold = false, Color? color, double fontSize = 13}) {
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

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      );

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
