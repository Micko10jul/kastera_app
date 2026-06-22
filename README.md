# 🍃 Kastera (Kas Kelurahan Sejahtera)

Aplikasi mobile berbasis **Flutter** dan **Supabase** yang dirancang khusus untuk mendigitalisasi pengelolaan uang kas tingkat Kelurahan serta mempermudah monitoring arus kas (pemasukan & pengeluaran) secara transparan, akurat, dan real-time.

---

## ✨ Fitur Utama

- **🔐 Otentikasi & Profil Kelurahan**: Login dan Register aman menggunakan Supabase Auth yang terhubung langsung dengan profil spesifik masing-masing kelurahan.
- **📊 Dashboard Monitoring**: Tampilan dashboard modern dengan info total saldo kas, total pemasukan, total pengeluaran, persentase efisiensi, dan jumlah total transaksi.
- **💸 Pencatatan Kas Masuk & Keluar**: Form pencatatan kas yang responsif, dilengkapi format otomatis mata uang Rupiah (Rp) dan pemilih tanggal modern.
- **🏷️ Kategori Pengeluaran Dinamis**: Pilih dari daftar kategori belanja bawaan atau tambahkan kategori khusus kelurahan Anda secara langsung ke dalam basis data.
- **📜 Riwayat & Detail Transaksi**: Halaman riwayat lengkap dengan filter pencarian untuk mempermudah audit kas kelurahan.
- **🔔 Aktivitas & Log Login**: Pencatatan aktivitas otomatis untuk menjaga akuntabilitas penggunaan aplikasi.

---

## 🛠️ Tech Stack

*   **Frontend**: Flutter (Dart)
*   **Backend & Database**: Supabase (PostgreSQL, Auth, RLS Policies)
*   **State Management & Utilities**: StatefulWidgets, `intl` (Format Rupiah & Tanggal), `page_transition`
*   **Visualizations**: `fl_chart` (Monitoring data statistik kas)
*   **Media Picker**: `image_picker` (Upload logo/foto kelurahan)

---

## 💾 Struktur Database (Supabase SQL)

Aplikasi ini menggunakan skema database PostgreSQL di Supabase. Anda dapat menggunakan script SQL berikut untuk menginisialisasi tabel-tabel terkait:

```sql
-- Tabel Profil Kelurahan
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  nama_kelurahan text,
  alamat_kantor text,
  foto_url text,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- Tabel Transaksi Kas
CREATE TABLE public.transaksi_kas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  judul_transaksi text NOT NULL,
  jumlah_nominal bigint DEFAULT 0,
  tipe_transaksi text CHECK (tipe_transaksi = ANY (ARRAY['masuk'::text, 'keluar'::text])),
  date date DEFAULT CURRENT_DATE,
  kategori text,
  keterangan text,
  is_edited boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT transaksi_kas_pkey PRIMARY KEY (id),
  CONSTRAINT transaksi_kas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);

-- Tabel Kategori Kas Custom
CREATE TABLE public.kategori_kas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  nama_kategori text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT kategori_kas_pkey PRIMARY KEY (id),
  CONSTRAINT kategori_kas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);

-- Tabel Riwayat Aktivitas & Login
CREATE TABLE public.notifikasi_aktivitas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  pesan text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT notifikasi_aktivitas_pkey PRIMARY KEY (id),
  CONSTRAINT notifikasi_aktivitas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);

CREATE TABLE public.riwayat_login (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  waktu_login timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT riwayat_login_pkey PRIMARY KEY (id),
  CONSTRAINT riwayat_login_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);
```

> [!IMPORTANT]
> Untuk mengizinkan aksi **Edit** & **Hapus** berjalan dengan lancar pada aplikasi, pastikan Anda telah menonaktifkan Row Level Security (RLS) pada tabel `transaksi_kas` atau membuat Policy yang sesuai di SQL Editor Supabase Anda:
> ```sql
> ALTER TABLE public.transaksi_kas DISABLE ROW LEVEL SECURITY;
> ```
> *Atau jika ingin RLS tetap aktif:*
> ```sql
> CREATE POLICY "Izinkan Hapus" ON public.transaksi_kas FOR DELETE USING (auth.uid() = kelurahan_id);
> CREATE POLICY "Izinkan Edit" ON public.transaksi_kas FOR UPDATE USING (auth.uid() = kelurahan_id);
> ```

---

## 🚀 Cara Menjalankan Project Secara Lokal

1.  **Clone Repositori**:
    ```bash
    git clone https://github.com/USERNAME/REPO-NAME.git
    cd REPO-NAME
    ```

2.  **Pasang Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Konfigurasi Supabase**:
    Inisialisasikan Supabase Flutter Client pada fungsi `main()` di berkas `lib/main.dart` Anda menggunakan **Supabase URL** dan **Anon Key** milik project Anda:
    ```dart
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
    ```

4.  **Jalankan Aplikasi**:
    ```bash
    flutter run
    ```

---

## 📝 Kontributor & Lisensi

*   **Developer**: Micko10jul
*   **Email**: mickojunior1004@gmail.com
*   *Project ini dibuat untuk kepentingan pengelolaan dan monitoring kas kelurahan secara digital.*
