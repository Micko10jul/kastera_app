import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'grafik.dart';
import 'sistem_kas.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;
  
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
  );
  List<dynamic> _allTransactions = [];
  double _monthlyMasuk = 0;
  double _monthlyKeluar = 0;
  bool _isLoading = true;

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
      final data = await supabase
          .from('transaksi_kas')
          .select()
          .eq('kelurahan_id', user.id)
          .gte('date', DateFormat('yyyy-MM-dd').format(_dateRange.start))
          .lte('date', DateFormat('yyyy-MM-dd').format(_dateRange.end))
          .order('created_at', ascending: false);

      double tempMasuk = 0;
      double tempKeluar = 0;

      for (var tx in data) {
        double nominal = (tx['jumlah_nominal'] as num).toDouble();
        if (tx['tipe_transaksi'] == 'masuk') {
          tempMasuk += nominal;
        } else {
          tempKeluar += nominal;
        }
      }

      if (mounted) {
        setState(() {
          _allTransactions = data;
          _monthlyMasuk = tempMasuk;
          _monthlyKeluar = tempKeluar;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error History: $e");
    }
  }

  // Fungsi pembantu untuk memformat Rupiah dengan aman
  String _formatRp(double val) {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
    } catch (e) {
      return 'Rp ${val.toStringAsFixed(0)}'; // Fallback jika locale gagal
    }
  }

  // Fungsi pembantu untuk memformat Tanggal dengan aman
  String _safeDateFormat(String pattern, DateTime date) {
    try {
      return DateFormat(pattern, 'id_ID').format(date);
    } catch (e) {
      return DateFormat(pattern).format(date); // Fallback ke default (English) jika id_ID gagal
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A6541)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _fetchData();
      });
    }
  }

  void _showPieChart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GrafikPage(
          totalMasuk: _monthlyMasuk,
          totalKeluar: _monthlyKeluar,
          dateRange: _dateRange,
          allTransactions: _allTransactions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _showPieChart(),
            icon: const Icon(Icons.pie_chart, color: Color(0xFF4A6541)),
          ),
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, color: Color(0xFF4A6541)),
          )
        ],
      ),
      body: Column(
        children: [
          _buildMonthlySummaryCard(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6541)))
              : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E392A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(
            '${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem("Pemasukan", _monthlyMasuk, Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.white24),
              _summaryItem("Pengeluaran", _monthlyKeluar, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(_formatRp(val), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTransactionList() {
    if (_allTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("Tidak ada transaksi di bulan ini", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _allTransactions.length,
      itemBuilder: (context, index) {
        final tx = _allTransactions[index];
        bool isMasuk = tx['tipe_transaksi'] == 'masuk';
        return _buildHistoryTile(tx, isMasuk);
      },
    );
  }

  Widget _buildHistoryTile(dynamic tx, bool isMasuk) {
    DateTime txDate;
    try {
      txDate = DateTime.parse(tx['created_at'] ?? DateTime.now().toString()).toLocal();
    } catch (e) {
      txDate = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(isMasuk ? Icons.arrow_downward : Icons.arrow_upward, color: isMasuk ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['judul_transaksi'] ?? 'Tanpa Judul', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (tx['kategori'] != null && tx['kategori'] != 'Pemasukan' && tx['kategori'] != tx['judul_transaksi'])
                  Text(tx['kategori'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                if (tx['keterangan'] != null && tx['keterangan'].toString().isNotEmpty)
                  Text(tx['keterangan'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(_safeDateFormat('dd MMMM yyyy, HH:mm', txDate), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    if (tx['is_edited'] == true) ...[
                      const SizedBox(width: 6),
                      Text("(telah di edit)", style: TextStyle(fontSize: 10, color: Colors.orange[700], fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Text(
            (isMasuk ? '+ ' : '- ') + _formatRp((tx['jumlah_nominal'] as num).toDouble()),
            style: TextStyle(fontWeight: FontWeight.bold, color: isMasuk ? Colors.green : Colors.red),
          ),
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
                String tgl = _safeDateFormat('dd MMM yyyy, HH:mm', DateTime.now());
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
}