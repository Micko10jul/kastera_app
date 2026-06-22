import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io'; 

import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); 
  
  bool _isLoading = true;
  bool _isUploading = false; 
  
  final String _bucketName = 'avatars'; 
  
  String _namaKelurahan = "Memuat...";
  String _alamatKelurahan = "Memuat...";
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _namaKelurahan = data['nama_kelurahan'] ?? "Kelurahan Tidak Terdaftar";
          // Perbaikan: Menggunakan 'alamat_kantor' sesuai struktur tabel database
          _alamatKelurahan = data['alamat_kantor'] ?? "Alamat belum diatur";
          _fotoUrl = data['foto_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error Fetch Profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (image == null) return;

    setState(() => _isUploading = true);
    
    final File file = File(image.path);
    final String fileExtension = image.path.split('.').last.toLowerCase();
    final String fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    try {
      await supabase.storage.from(_bucketName).upload(
        fileName,
        file,
        fileOptions: FileOptions(contentType: 'image/$fileExtension', upsert: true),
      );

      final String publicUrl = supabase.storage.from(_bucketName).getPublicUrl(fileName);

      await supabase.from('profiles').update({'foto_url': publicUrl}).eq('id', user.id);

      if (mounted) {
        setState(() {
          _fotoUrl = publicUrl;
          _showSnackBar("Foto profil berhasil diperbarui!", Colors.green);
        });
      }
    } on StorageException catch (error) {
      debugPrint("Storage Error: ${error.message}");
      _showSnackBar("Gagal mengunggah foto: ${error.message}", Colors.red);
    } on PostgrestException catch (error) {
      debugPrint("Database Error: ${error.message}");
      _showSnackBar("Gagal memperbarui database: ${error.message}", Colors.red);
    } catch (error) {
      debugPrint("General Error: $error");
      _showSnackBar("Terjadi kesalahan tak terduga.", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definisi warna sebagai variabel lokal untuk menghindari error 'const'
    const Color darkGreen = Color(0xFF1E392A);
    const Color midGreen = Color(0xFF4A6541);
    const Color lightGreen = Color(0xFF738A6E);
    const Color bgColor = Color(0xFFF8FAF8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: darkGreen, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Profil Kelurahan", 
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: midGreen))
        : SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeaderSection(darkGreen, midGreen),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    children: [
                      _buildInfoCard(darkGreen, lightGreen),
                      const SizedBox(height: 40),
                      _buildLogoutButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderSection(Color darkGreen, Color midGreen) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: const Color(0xFFE8F0E8),
                      backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                      child: _fotoUrl == null 
                        ? Icon(Icons.account_balance, size: 60, color: midGreen) 
                        : null,
                    ),
                  ),
                  if (_isUploading)
                    const Positioned.fill(
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.black26,
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _isUploading ? null : _uploadPhoto,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: midGreen, shape: BoxShape.circle),
                child: _isUploading 
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _namaKelurahan,
          textAlign: TextAlign.center,
          style: TextStyle(color: darkGreen, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: midGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            supabase.auth.currentUser?.email ?? "",
            style: TextStyle(color: midGreen, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Color darkGreen, Color lightGreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), 
            blurRadius: 30, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.domain, "Nama Kelurahan", _namaKelurahan, lightGreen, darkGreen),
          _buildDivider(),
          _buildInfoRow(Icons.location_on_outlined, "Alamat Kantor", _alamatKelurahan, lightGreen, darkGreen),
          _buildDivider(),
          _buildInfoRow(Icons.admin_panel_settings_outlined, "Role Akses", "Administrator", lightGreen, darkGreen),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Divider(color: Colors.grey.withValues(alpha: 0.15), height: 1),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                value, 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, height: 1.3)
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _handleLogout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2), width: 1)
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 22),
          SizedBox(width: 12),
          Text('Keluar Aplikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}