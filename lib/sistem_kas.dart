import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Pastikan sudah ada di pubspec.yaml

class SistemKas extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const SistemKas({super.key, this.editData});

  @override
  State<SistemKas> createState() => _SistemKasState();
}

class _SistemKasState extends State<SistemKas> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _nominalController = TextEditingController();
  final _keteranganController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _tipeTransaksi; 
  String? _selectedKategori;
  bool _isLoading = false;

  List<String> _kategoriList = [
    'Belanja Tabung Gas', 'Belanja Alat Tulis Kantor', 'Belanja Kertas dan Cover',
    'Belanja Benda Pos', 'Belanja Bahan Komputer', 'Belanja Perabot Kantor',
    'Belanja Alat Listrik', 'Belanja Perlengkapan Dinas', 'Belanja Kegiatan Kantor Lainnya',
    'Belanja Barang Diserahkan Masyarakat', 'Belanja Natura Dan Pakan Natura',
    'Belanja Makan Minum Rapat', 'Belanja Tagihan Air, Listrik dan Internet',
    'Belanja Pembayaran Pajak', 'Belanja Pemeliharaan', 'Belanja Perjalanan Dinas'
  ];

  void _onNominalChanged() {
    String text = _nominalController.text.replaceAll('.', '');
    if (text.isEmpty) return;
    try {
      String newText = NumberFormat.decimalPattern('id_ID').format(int.parse(text));
      if (newText != _nominalController.text) {
        _nominalController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    } catch (e) {
      // Abaikan jika tidak bisa di-parse
    }
  }

  @override
  void initState() {
    super.initState();
    _nominalController.addListener(_onNominalChanged);
    _fetchKategori();
    _checkEditMode();
  }

  void _checkEditMode() {
    if (widget.editData != null) {
      final data = widget.editData!;
      _tipeTransaksi = data['tipe_transaksi'];
      _nominalController.text = data['jumlah_nominal'].toString();
      _onNominalChanged(); // format it
      _selectedDate = DateTime.tryParse(data['date'] ?? '') ?? DateTime.now();
      
      if (_tipeTransaksi == 'keluar') {
        _selectedKategori = data['kategori'] ?? data['judul_transaksi'];
        if (_selectedKategori != null && !_kategoriList.contains(_selectedKategori)) {
          _kategoriList.add(_selectedKategori!);
        }
        _keteranganController.text = data['keterangan'] ?? '';
      } else {
        _judulController.text = data['judul_transaksi'] ?? '';
      }
    }
  }

  Future<void> _fetchKategori() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client.from('kategori_kas').select().eq('kelurahan_id', user.id);
      List<String> customList = [];
      for (var item in res) {
        customList.add(item['nama_kategori'].toString());
      }
      if (mounted) {
        setState(() {
          _kategoriList.addAll(customList);
          _kategoriList = _kategoriList.toSet().toList(); // unique
          _kategoriList.sort((a, b) => a.compareTo(b)); // sort abjad
        });
      }
    } catch (e) {
      debugPrint("Error fetching kategori: $e");
    }
  }

  @override
  void dispose() {
    _nominalController.removeListener(_onNominalChanged);
    _nominalController.dispose();
    _judulController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // 2. Fungsi Date Picker Modern
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A6541), // Moss Green sesuai tema
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E392A),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4A6541)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _simpanTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipeTransaksi == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih Tipe Kas terlebih dahulu!'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    
    if (_tipeTransaksi == 'keluar' && _selectedKategori == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih Kategori pengeluaran!'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    try {
      final data = {
        'kelurahan_id': user!.id,
        'judul_transaksi': _tipeTransaksi == 'keluar' ? _selectedKategori : _judulController.text.trim(),
        'jumlah_nominal': int.parse(_nominalController.text.replaceAll('.', '')),
        'tipe_transaksi': _tipeTransaksi,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'kategori': _tipeTransaksi == 'keluar' ? _selectedKategori : 'Pemasukan',
        'keterangan': _tipeTransaksi == 'keluar' ? _keteranganController.text.trim() : null,
        'is_edited': widget.editData != null ? true : false,
      };

      if (widget.editData != null) {
        await Supabase.instance.client.from('transaksi_kas').update(data).eq('id', widget.editData!['id']);
      } else {
        await Supabase.instance.client.from('transaksi_kas').insert(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editData != null ? 'Transaksi Berhasil Diedit!' : 'Transaksi Berhasil Dicatat!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tambah Transaksi', style: TextStyle(color: Color(0xFF1E392A), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 32),
              
              if (_tipeTransaksi == 'keluar') ...[
                _buildCategoryDropdown(),
                const SizedBox(height: 20),
                _buildTextField(label: 'Keterangan Pengeluaran (Opsional)', hint: 'Misal: Beli pulsa listrik 100k', controller: _keteranganController, icon: Icons.description, isRequired: false),
                const SizedBox(height: 20),
              ] else if (_tipeTransaksi == 'masuk' || _tipeTransaksi == null) ...[
                _buildTextField(label: 'Judul Transaksi', hint: 'Misal: Iuran Warga RT 01', controller: _judulController, icon: Icons.edit_note),
                const SizedBox(height: 20),
              ],
              
              _buildTextField(label: 'Nominal (Rp)', hint: '0', controller: _nominalController, icon: Icons.money, isNumber: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    String current = _nominalController.text.replaceAll('.', '');
                    if (current.isEmpty) current = '0';
                    current += '000';
                    _nominalController.text = current; 
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A6541),
                    backgroundColor: const Color(0xFF4A6541).withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(' + 000 (Ribu)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              
              // 4. Field Input Tanggal (UI Modern)
              const Text("Tanggal Transaksi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E392A))),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFBFCFBB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF738A6E)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF738A6E)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          _typeBtn('masuk', 'Tambah Kas', Icons.add_circle_outline),
          _typeBtn('keluar', 'Kurang Kas', Icons.remove_circle_outline),
        ],
      ),
    );
  }

  Widget _typeBtn(String type, String label, IconData icon) {
    bool isSelected = _tipeTransaksi == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipeTransaksi = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A6541) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E392A))),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          validator: isRequired ? (v) => v!.isEmpty ? 'Tidak boleh kosong' : null : null,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF738A6E)),
            filled: true,
            fillColor: const Color(0xFFBFCFBB).withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _simpanTransaksi,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A6541),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: _isLoading 
        ? const CircularProgressIndicator(color: Colors.white)
        : Text(widget.editData != null ? 'Update Transaksi' : 'Simpan Transaksi', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Kategori Pengeluaran", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E392A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedKategori,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFBFCFBB).withOpacity(0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.category, color: Color(0xFF738A6E)),
                ),
                hint: const Text("Pilih Kategori"),
                items: _kategoriList.map((kat) => DropdownMenuItem(value: kat, child: Text(kat, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedKategori = val;
                  });
                },
                validator: (v) => v == null ? 'Pilih Kategori' : null,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _tambahKategoriDialog,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A6541),
                  borderRadius: BorderRadius.circular(15)
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            )
          ],
        )
      ],
    );
  }

  void _tambahKategoriDialog() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Tambah Kategori Baru"),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: "Nama Kategori (misal: Beli Snack)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A6541)),
            onPressed: () async {
              if (tc.text.trim().isEmpty) return;
              String newKat = tc.text.trim().toLowerCase();
              if (_kategoriList.contains(newKat)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kategori sudah ada!")));
                return;
              }
              // save to db
              try {
                final user = Supabase.instance.client.auth.currentUser;
                await Supabase.instance.client.from('kategori_kas').insert({
                  'kelurahan_id': user!.id,
                  'nama_kategori': newKat,
                });
                setState(() {
                  _kategoriList.add(newKat);
                  _selectedKategori = newKat;
                });
                Navigator.pop(context);
              } catch(e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            }, 
            child: const Text("Simpan")
          )
        ],
      )
    );
  }
}