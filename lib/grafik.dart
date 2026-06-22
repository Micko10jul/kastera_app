import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class GrafikPage extends StatelessWidget {
  final double totalMasuk;
  final double totalKeluar;
  final DateTimeRange dateRange;
  final List<dynamic> allTransactions;

  const GrafikPage({
    super.key,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.dateRange,
    required this.allTransactions,
  });

  String _formatRp(double val) {
    try {
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(val);
    } catch (e) {
      return 'Rp ${val.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalSaldo = totalMasuk - totalKeluar;
    
    // Group pengeluaran
    Map<String, double> groupedKeluar = {};
    for (var tx in allTransactions) {
      if (tx['tipe_transaksi'] == 'keluar') {
        String kat = tx['kategori'] ?? tx['judul_transaksi'] ?? 'Lainnya';
        double nom = (tx['jumlah_nominal'] as num).toDouble();
        groupedKeluar[kat] = (groupedKeluar[kat] ?? 0) + nom;
      }
    }

    // Buat List warna untuk kategori
    List<Color> colorPalette = [
      Colors.redAccent, Colors.orange, Colors.blueAccent, 
      Colors.purpleAccent, Colors.pinkAccent, Colors.teal, 
      Colors.deepOrange, Colors.indigo
    ];

    List<PieChartSectionData> pieSections = [];
    List<Widget> legendItems = [];
    
    // Slice Pemasukan
    pieSections.add(PieChartSectionData(
      color: const Color(0xFF4A6541),
      value: totalMasuk > 0 ? totalMasuk : 0.1, // hindari 0
      showTitle: false,
      radius: 40,
    ));
    legendItems.add(_buildLegendItem(const Color(0xFF4A6541), 'Pemasukan', totalMasuk));

    // Slices Kategori Pengeluaran
    int colorIndex = 0;
    groupedKeluar.forEach((key, val) {
      Color c = colorPalette[colorIndex % colorPalette.length];
      pieSections.add(PieChartSectionData(
        color: c,
        value: val,
        showTitle: false,
        radius: 45,
      ));
      legendItems.add(_buildLegendItem(c, key, val));
      colorIndex++;
    });

    double rasio = totalMasuk > 0 ? totalKeluar / totalMasuk : 0;
    double persentaseKeluar = totalMasuk > 0 ? (totalKeluar / totalMasuk) * 100 : 0;
    
    String strDateRange = '${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}';

    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        title: const Text('Analisa Kas', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
              ),
              child: Column(
                children: [
                  Text('Struktur Kas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E392A))),
                  Text(strDateRange, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 200,
                    child: (totalMasuk == 0 && totalKeluar == 0)
                        ? const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey)))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 50,
                              sections: pieSections,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (totalMasuk > 0 || totalKeluar > 0) ...[
                    Column(
                      children: legendItems,
                    ),
                  ],
                  const SizedBox(height: 32),

                  _buildInsightNotification(rasio),
                  
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF1F1F1)),
                  const SizedBox(height: 20),

                  _buildSummaryRow('Total Tambah Kas', _formatRp(totalMasuk), Colors.black87),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Total Pengurangan', _formatRp(totalKeluar), Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Sisa Kas Bulan Ini', _formatRp(totalSaldo), const Color(0xFF4A6541)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Persentase Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('${persentaseKeluar.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
          Text(_formatRp(amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInsightNotification(double rasio) {
    String status;
    String message;
    Color color;
    IconData icon;

    if (rasio <= 0.7) {
      status = "Stabil";
      message = "Kondisi kas kelurahan dalam zona aman.";
      color = const Color(0xFF4A6541);
      icon = Icons.check_circle;
    } else if (rasio <= 1.0) {
      status = "Waspada";
      message = "Pengeluaran mendekati total pemasukan.";
      color = Colors.orange;
      icon = Icons.warning_rounded;
    } else {
      status = "Defisit";
      message = "Pengeluaran melampaui total kas yang tersedia!";
      color = Colors.redAccent;
      icon = Icons.dangerous;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                Text(message, style: TextStyle(fontSize: 11, color: color.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
