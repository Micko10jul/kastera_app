import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _historiLogin = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistori();
  }

  Future<void> _fetchHistori() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final resLogin = await supabase.from('riwayat_login').select().eq('kelurahan_id', user.id);
      final resAktivitas = await supabase.from('notifikasi_aktivitas').select().eq('kelurahan_id', user.id);
      
      List<dynamic> combined = [];
      for(var item in resLogin) {
        combined.add({
          'type': 'login',
          'pesan': 'Aktivitas Login Baru',
          'waktu': item['waktu_login']
        });
      }
      for(var item in resAktivitas) {
        combined.add({
          'type': 'hapus',
          'pesan': item['pesan'],
          'waktu': item['created_at']
        });
      }

      combined.sort((a, b) {
        DateTime dA = DateTime.tryParse(a['waktu'] ?? '') ?? DateTime.now();
        DateTime dB = DateTime.tryParse(b['waktu'] ?? '') ?? DateTime.now();
        return dB.compareTo(dA); // descending
      });
      
      if (mounted) {
        setState(() {
          _historiLogin = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error fetching notifikasi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFCFB),
      appBar: AppBar(
        title: const Text('Riwayat Login', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6541)))
          : _historiLogin.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text("Bulum ada riwayat login terekam", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _historiLogin.length,
                  itemBuilder: (context, index) {
                    final data = _historiLogin[index];
                    DateTime date = DateTime.tryParse(data['waktu'] ?? '')?.toLocal() ?? DateTime.now();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (data['type'] == 'hapus' ? Colors.redAccent : const Color(0xFF4A6541)).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(data['type'] == 'hapus' ? Icons.delete_outline : Icons.login, color: data['type'] == 'hapus' ? Colors.redAccent : const Color(0xFF4A6541)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['pesan'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E392A))),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMMM yyyy, HH:mm').format(date),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
