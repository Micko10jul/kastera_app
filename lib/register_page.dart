import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController(); 
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscure = true;
  bool _isObscureConfirm = true;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  Future<void> _handleRegister() async {
    if (_namaController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Mohon isi semua field utama', Colors.orange);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Password dan konfirmasi tidak cocok!', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Perubahan Utama: Mengirim metadata ke Supabase Auth
      // Data ini akan ditangkap oleh Database Function 'handle_new_user' kamu
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'nama_kelurahan': _namaController.text.trim(),
          'alamat_kantor': _alamatController.text.trim(),
        },
      );

      // Bagian insert manual ke 'profiles' dihapus untuk menghindari error duplicate key
      // karena database trigger kamu sudah melakukan tugas ini secara otomatis.

      if (mounted) {
        _showSnackBar('Registrasi Berhasil! Silakan Login.', const Color(0xFF4A6541));
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const LoginPage())
        );
      }
    } on AuthException catch (error) {
      _showSnackBar(error.message, Colors.red);
    } catch (error) {
      _showSnackBar('Terjadi kesalahan: $error', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E392A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Daftar Akun Baru',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E392A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftarkan entitas kelurahan Anda untuk akses KASTERA.',
                style: TextStyle(
                  fontSize: 16,
                  color: const Color(0xFF738A6E).withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 40),
              _buildInputField(
                label: 'Nama Kelurahan',
                hint: 'Contoh: Kelurahan Lowokwaru',
                icon: Icons.account_balance_outlined,
                controller: _namaController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Email Kelurahan',
                hint: 'kelurahan@domain.go.id',
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Alamat Kantor Kelurahan',
                hint: 'Jl. Raya No. 123, Malang',
                icon: Icons.location_on_outlined,
                controller: _alamatController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Password',
                hint: 'Buat password kuat',
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                label: 'Ketik Ulang Password',
                hint: 'Konfirmasi password anda',
                icon: Icons.lock_reset_outlined,
                isPassword: true,
                isConfirm: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A6541),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: const Color(0xFF4A6541).withOpacity(0.3),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Daftar Sekarang',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Sudah memiliki akun? "),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Masuk",
                      style: TextStyle(
                        color: Color(0xFF1E392A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E392A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword ? (isConfirm ? _isObscureConfirm : _isObscure) : false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF738A6E)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (isConfirm ? _isObscureConfirm : _isObscure)
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF738A6E),
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          _isObscureConfirm = !_isObscureConfirm;
                        } else {
                          _isObscure = !_isObscure;
                        }
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFBFCFBB).withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF738A6E), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}