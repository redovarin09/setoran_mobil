import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/perbaikan_model.dart';
import 'input_perbaikan_sheet.dart';

class PerbaikanScreen extends StatefulWidget {
  const PerbaikanScreen({super.key});

  @override
  State<PerbaikanScreen> createState() => _PerbaikanScreenState();
}

class _PerbaikanScreenState extends State<PerbaikanScreen> {
  final _db          = DbHelper();
  final _searchCtrl  = TextEditingController();
  int _tahun         = DateTime.now().year;
  List<PerbaikanModel> _data      = [];
  List<PerbaikanModel> _filtered  = [];
  int _totalBiaya    = 0;
  bool _loading      = true;
  bool _showSearch   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data  = await _db.getPerbaikanByTahun(_tahun);
    final total = await _db.getTotalPerbaikan(_tahun);
    setState(() {
      _data       = data;
      _totalBiaya = total;
      _loading    = false;
    });
    _applySearch(_searchCtrl.text);
  }

  void _applySearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_data)
          : _data.where((p) {
              return p.jenisPerbaikan.toLowerCase().contains(q) ||
                  p.namaBengkel.toLowerCase().contains(q) ||
                  p.keterangan.toLowerCase().contains(q) ||
                  p.tanggal.contains(q);
            }).toList();
    });
  }

  void _openSheet([PerbaikanModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InputPerbaikanSheet(
        tahun:    _tahun,
        existing: existing,
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
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari jenis, bengkel...',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: _applySearch,
              )
            : const Text('Rekap Perbaikan'),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  _applySearch('');
                }
              });
            },
          ),
          TextButton(
            onPressed: _pilihTahun,
            child: Text('$_tahun',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: AppColors.primary))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                              16, 4, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryBar() {
    final totalFilter = _filtered.fold(0, (s, p) => s + p.biaya);
    final isFiltered  = _searchCtrl.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
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
              Text(
                isFiltered
                    ? 'Hasil Filter'
                    : 'Total Biaya Perbaikan',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                isFiltered
                    ? '${_filtered.length} dari ${_data.length} item'
                    : '$_tahun · ${_data.length} item',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(
                isFiltered ? totalFilter : _totalBiaya),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(PerbaikanModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSheet(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.build,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p.jenisPerbaikan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Row(
			  children: [
			    if (p.hasBukti)
			      Container(
			        margin: const EdgeInsets.only(right: 6),
			        padding: const EdgeInsets.all(4),
			        decoration: BoxDecoration(
			          color: AppColors.success.withValues(alpha: 0.1),
			          borderRadius: BorderRadius.circular(6),
			        ),
			        child: const Icon(Icons.photo_camera,
			            size: 14, color: AppColors.success),
			      ),
			    Text(
			      CurrencyFormatter.format(p.biaya),
			      style: const TextStyle(
			        fontWeight: FontWeight.bold,
			        fontSize: 14,
			        color: AppColors.danger,
			      ),
			    ),
			  ],
			),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.store_outlined,
                            size: 12,
                            color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          p.namaBengkel.isEmpty
                              ? '—'
                              : p.namaBengkel,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today_outlined,
                            size: 12,
                            color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(p.tanggal,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMedium)),
                      ],
                    ),
                    if (p.km.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.speed_outlined,
                              size: 12,
                              color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text('${p.km} km',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                    if (p.keterangan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(p.keterangan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final isSearch = _searchCtrl.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.build_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isSearch
                ? 'Tidak ada hasil untuk\n"${_searchCtrl.text}"'
                : 'Belum ada data perbaikan',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textLight, fontSize: 14),
          ),
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
