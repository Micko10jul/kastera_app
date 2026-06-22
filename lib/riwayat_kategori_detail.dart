import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class RiwayatKategoriDetailPage extends StatefulWidget {
  final String kategori;
  final DateTimeRange dateRange;

  const RiwayatKategoriDetailPage({super.key, required this.kategori, required this.dateRange});

  @override
  State<RiwayatKategoriDetailPage> createState() => _RiwayatKategoriDetailPageState();
}

class _RiwayatKategoriDetailPageState extends State<RiwayatKategoriDetailPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _transaksi = [];
  bool _isLoading = true;
  double _totalPengeluaran = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('transaksi_kas')
          .select()
          .eq('kelurahan_id', user.id)
          .eq('tipe_transaksi', 'keluar')
          .gte('date', DateFormat('yyyy-MM-dd').format(widget.dateRange.start))
          .lte('date', DateFormat('yyyy-MM-dd').format(widget.dateRange.end))
          .order('created_at', ascending: false);

      List<dynamic> filtered = [];
      double total = 0;
      for (var item in res) {
        String kat = item['kategori'] ?? item['judul_transaksi'] ?? 'Lainnya';
        if (kat == widget.kategori) {
          filtered.add(item);
          total += (item['jumlah_nominal'] as num).toDouble();
        }
      }

      if (mounted) {
        setState(() {
          _transaksi = filtered;
          _totalPengeluaran = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetch detail kategori: $e");
    }
  }

  String _formatRp(double val) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        title: const Text('Detail Pengeluaran', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6541)))
        : Column(
            children: [
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E4326),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.kategori,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(widget.dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(widget.dateRange.end)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Text(_formatRp(_totalPengeluaran), style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _transaksi.isEmpty 
                  ? const Center(child: Text("Tidak ada transaksi", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _transaksi.length,
                      itemBuilder: (context, index) {
                        final item = _transaksi[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.redAccent),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['judul_transaksi'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (item['keterangan'] != null && item['keterangan'].toString().isNotEmpty)
                                      Text(item['keterangan'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                    const SizedBox(height: 4),
                                    Text(DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(item['created_at']).toLocal()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('- ${_formatRp((item['jumlah_nominal'] as num).toDouble())}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
    );
  }
}
