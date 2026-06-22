import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'sistem_kas.dart';
import 'history_kas.dart'; 
import 'profile_page.dart';
import 'notifikasi.dart';
import 'riwayat_pemasukan.dart';
import 'riwayat_pengeluaran.dart';

class MenuUtama extends StatefulWidget {
  const MenuUtama({super.key});

  @override
  State<MenuUtama> createState() => _MenuUtamaState();
}

class _MenuUtamaState extends State<MenuUtama> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  double _totalSaldo = 0;
  double _totalMasuk = 0;
  double _totalKeluar = 0;
  int _countTransaksi = 0;
  String _efisiensi = "0%";
  List<dynamic> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser!.id;

    try {
      final saldoData = await supabase.from('total_kas_kelurahan').select().eq('kelurahan_id', userId).maybeSingle();
      final allTx = await supabase.from('transaksi_kas').select().eq('kelurahan_id', userId).order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          if (saldoData != null) {
            _totalSaldo = (saldoData['saldo_neto'] ?? 0).toDouble();
            _totalMasuk = (saldoData['total_masuk'] ?? 0).toDouble();
            _totalKeluar = (saldoData['total_keluar'] ?? 0).toDouble();
            if (_totalMasuk > 0) {
              _efisiensi = "${((_totalSaldo / _totalMasuk) * 100).toStringAsFixed(0)}%";
            }
          }
          _recentTransactions = allTx;
          _countTransaksi = allTx.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRp(double val) => NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      body: RefreshIndicator(
        onRefresh: _fetchAllData,
        color: const Color(0xFF4A6541),
        child: Stack(
          children: [
            _buildBodyContent(),
            _buildFloatingNavbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildBalanceCard(),
          const SizedBox(height: 24),
          _buildQuickStatsClear(),
          const SizedBox(height: 32),
          _buildRecentHistory(),
        ],
      ),
    );
  }



  Widget _buildRecentHistory() {
    final displayList = _recentTransactions.take(3).toList();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('History Terkini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E392A))),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
                _fetchAllData();
              },
              child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF4A6541), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentTransactions.isEmpty)
          _buildEmptyState()
        else
          Column(children: displayList.map((tx) => _buildTxTile(tx)).toList()),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Halo, Admin!', style: TextStyle(fontSize: 16, color: Color(0xFF738A6E))),
          Text('Dashboard Kas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E392A))),
        ]),
        _buildIconBtn(Icons.notifications_none),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF738A6E), Color(0xFF344C3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF738A6E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saldo Kas', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(_formatRp(_totalSaldo), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPemasukanPage()));
                _fetchAllData();
              },
              child: _buildMiniInfo(Icons.arrow_downward, 'Masuk', _formatRp(_totalMasuk)),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatPengeluaranPage()));
                _fetchAllData();
              },
              child: _buildMiniInfo(Icons.arrow_upward, 'Keluar', _formatRp(_totalKeluar)),
            ),
          ])
        ],
      ),
    );
  }

  Widget _buildQuickStatsClear() {
    return Row(children: [
      _buildStatItemClear('Efisiensi', _efisiensi, Colors.blue),
      const SizedBox(width: 16),
      _buildStatItemClear('Transaksi', _countTransaksi.toString(), Colors.orange),
    ]);
  }

  Widget _buildTxTile(dynamic tx) {
    bool isMasuk = tx['tipe_transaksi'] == 'masuk';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(children: [
        CircleAvatar(backgroundColor: isMasuk ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), child: Icon(isMasuk ? Icons.add : Icons.remove, color: isMasuk ? Colors.green : Colors.red, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tx['judul_transaksi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tx['created_at']).toLocal()), style: TextStyle(fontSize: 12, color: Colors.grey[500]))])),
        Text((isMasuk ? '+' : '-') + _formatRp((tx['jumlah_nominal'] as num).toDouble()), style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red, fontSize: 14)),
      ]),
    );
  }

  Widget _buildStatItemClear(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.withOpacity(0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String label, String amt) {
    return Row(children: [
      CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Icon(icon, size: 14, color: Colors.white)),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)), Text(amt, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))])
    ]);
  }

  Widget _buildEmptyState() => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 30), child: Column(children: [Icon(Icons.history_toggle_off, color: Colors.grey[300], size: 40), const Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))]));

  Widget _buildIconBtn(IconData icon) => GestureDetector(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotifikasiPage()));
    },
    child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Icon(icon, color: const Color(0xFF738A6E))),
  );

  Widget _buildFloatingNavbar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Container(
          height: 70, width: 280,
          decoration: BoxDecoration(color: const Color(0xFF4A6541), borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            IconButton(icon: const Icon(Icons.home_filled, color: Colors.white), onPressed: () {}),
            _buildAddButtonCenter(),
            // Logika pindah ke halaman profil saat ikon person diklik
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white70), 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildAddButtonCenter() {
    return GestureDetector(
      onTap: () async {
        final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SistemKas()));
        if (res == true) _fetchAllData();
      },
      child: Container(height: 52, width: 52, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.add, color: Color(0xFF4A6541), size: 30)),
    );
  }
}