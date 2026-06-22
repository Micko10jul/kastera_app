import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'sistem_kas.dart';

class RiwayatPengeluaranPage extends StatefulWidget {
  const RiwayatPengeluaranPage({super.key});

  @override
  State<RiwayatPengeluaranPage> createState() => _RiwayatPengeluaranPageState();
}

class _RiwayatPengeluaranPageState extends State<RiwayatPengeluaranPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _transaksi = [];
  bool _isLoading = true;
  double _totalPengeluaran = 0;

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );

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
          .gte('date', DateFormat('yyyy-MM-dd').format(_dateRange.start))
          .lte('date', DateFormat('yyyy-MM-dd').format(_dateRange.end))
          .order('created_at', ascending: false);

      double total = 0;
      for (var item in res) {
        total += (item['jumlah_nominal'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _transaksi = res;
          _totalPengeluaran = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetch pengeluaran: $e");
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A6541), 
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _fetchData();
    }
  }

  String _formatRp(double val) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
  }

  void _handleEdit(dynamic tx) async {
    final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => SistemKas(editData: tx)));
    if (res == true) {
      _fetchData();
    }
  }

  void _handleHapus(dynamic tx) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                final user = supabase.auth.currentUser;
                await supabase.from('transaksi_kas').delete().eq('id', tx['id']);
                
                String judul = tx['judul_transaksi'];
                String tgl = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());
                await supabase.from('notifikasi_aktivitas').insert({
                  'kelurahan_id': user!.id,
                  'pesan': "Transaksi '$judul' telah dihapus pada $tgl",
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dihapus!")));
                  await _fetchData();
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal menghapus: $e")));
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        title: const Text('Riwayat Pengeluaran', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Color(0xFF1E392A)),
            onPressed: _pickDateRange,
          )
        ],
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
                      '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text('Total Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_formatRp(_totalPengeluaran), style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: _transaksi.isEmpty 
                  ? const Center(child: Text("Belum ada data pengeluaran di rentang ini", style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _transaksi.length,
                      itemBuilder: (context, index) {
                        final tx = _transaksi[index];
                        DateTime txDate = DateTime.tryParse(tx['created_at'] ?? '')?.toLocal() ?? DateTime.now();

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
                                    Text(tx['judul_transaksi'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (tx['kategori'] != null && tx['kategori'] != tx['judul_transaksi'])
                                      Text(tx['kategori'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                    if (tx['keterangan'] != null && tx['keterangan'].toString().isNotEmpty)
                                      Text(tx['keterangan'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(DateFormat('dd MMMM yyyy, HH:mm').format(txDate), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        if (tx['is_edited'] == true) ...[
                                          const SizedBox(width: 6),
                                          Text("(telah di edit)", style: TextStyle(fontSize: 10, color: Colors.orange[700], fontStyle: FontStyle.italic)),
                                        ]
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text('- ${_formatRp((tx['jumlah_nominal'] as num).toDouble())}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    _handleEdit(tx);
                                  } else if (val == 'hapus') {
                                    _handleHapus(tx);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit Transaksi')),
                                  const PopupMenuItem(value: 'hapus', child: Text('Hapus Transaksi')),
                                ],
                              )
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
