import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/db_helper.dart';
import '../../core/utils/currency_formatter.dart';
import '../dashboard/dashboard_screen.dart';
import '../setoran/setoran_screen.dart';
import '../perbaikan/perbaikan_screen.dart';
import '../pengaturan/pengaturan_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _db          = DbHelper();
  final _pageCtrl    = PageController();
  final _namaCtrl    = TextEditingController();
  final _sisaCtrl    = TextEditingController();
  int _page          = 0;
  bool _loading      = false;
  int _tahun         = DateTime.now().year;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _namaCtrl.dispose();
    _sisaCtrl.dispose();
    super.dispose();
  }

  Future<void> _selesai() async {
    setState(() => _loading = true);

    final nama = _namaCtrl.text.trim().isEmpty
        ? 'Kendaraan Saya'
        : _namaCtrl.text.trim();
    final sisa = int.tryParse(
            _sisaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
        0;

    await _db.setKendaraanNama(nama);
    await _db.setSisaTahunLalu(sisa);
    await _db.setSetupDone();

    setState(() => _loading = false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const _MainNav()),
    );
  }

  void _nextPage() {
    if (_page < 2) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _selesai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 24, horizontal: 24),
              child: Row(
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),

            // Tombol next
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary))
                      : Text(
                          _page < 2 ? 'Lanjut →' : '🚀  Mulai Gunakan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_car,
              size: 80, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'Selamat Datang!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aplikasi ini membantu Anda mencatat setoran '
            'mingguan dan rekap perbaikan kendaraan dengan mudah.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _featureItem(Icons.receipt_long, 'Catat setoran per minggu'),
          _featureItem(Icons.build, 'Rekap biaya perbaikan'),
          _featureItem(Icons.dashboard, 'Dashboard grand total'),
          _featureItem(Icons.backup, 'Backup & restore data'),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.garage,
              size: 80, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'Nama Kendaraan',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Beri nama kendaraan Anda agar lebih mudah dikenali.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _namaCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Contoh: Avanza Putih, B 1234 ABC',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.white, width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              prefixIcon: const Icon(Icons.directions_car,
                  color: Colors.white70),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Boleh dikosongkan, bisa diubah nanti di Pengaturan.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet,
              size: 80, color: Colors.white),
          const SizedBox(height: 24),
          const Text(
            'Sisa Tahun Lalu',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan sisa hutang/tagihan dari tahun sebelumnya '
            'sebagai saldo awal.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),

          // Pilih tahun
          Row(
            children: [
              Text('Tahun mulai: ',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _tahun,
                dropdownColor: AppColors.primaryDark,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                underline: Container(height: 1, color: Colors.white54),
                items: [2024, 2025, 2026, 2027].map((y) {
                  return DropdownMenuItem(
                      value: y, child: Text('$y'));
                }).toList(),
                onChanged: (y) => setState(() => _tahun = y!),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _sisaCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5)),
              prefixText: 'Rp  ',
              prefixStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.white, width: 2),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Jika tidak ada, biarkan 0. '
            'Nilai ini bisa diubah kapan saja di Pengaturan.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

// Navigasi utama (dipindah ke sini agar onboarding bisa push replace)
class _MainNav extends StatefulWidget {
  const _MainNav();

  @override
  State<_MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<_MainNav> {
  int _idx = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    SetoranScreen(),
    PerbaikanScreen(),
    PengaturanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A1565C0),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: (i) => setState(() => _idx = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.navSelected,
          unselectedItemColor: AppColors.navUnselected,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Setoran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Perbaikan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      ),
    );
  }
}
