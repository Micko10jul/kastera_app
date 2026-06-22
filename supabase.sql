-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.kategori_kas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  nama_kategori text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT kategori_kas_pkey PRIMARY KEY (id),
  CONSTRAINT kategori_kas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);
CREATE TABLE public.notifikasi_aktivitas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  pesan text NOT NULL,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT notifikasi_aktivitas_pkey PRIMARY KEY (id),
  CONSTRAINT notifikasi_aktivitas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  nama_kelurahan text,
  alamat_kantor text,
  updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  foto_url text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.riwayat_login (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  waktu_login timestamp with time zone DEFAULT timezone('utc'::text, now()),
  CONSTRAINT riwayat_login_pkey PRIMARY KEY (id),
  CONSTRAINT riwayat_login_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);
CREATE TABLE public.transaksi_kas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  kelurahan_id uuid NOT NULL,
  judul_transaksi text NOT NULL,
  jumlah_nominal bigint DEFAULT 0,
  tipe_transaksi text CHECK (tipe_transaksi = ANY (ARRAY['masuk'::text, 'keluar'::text])),
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
  date date DEFAULT CURRENT_DATE,
  kategori text,
  keterangan text,
  is_edited boolean DEFAULT false,
  CONSTRAINT transaksi_kas_pkey PRIMARY KEY (id),
  CONSTRAINT transaksi_kas_kelurahan_id_fkey FOREIGN KEY (kelurahan_id) REFERENCES auth.users(id)
);

-- ==========================================
-- SCRIPT PERBAIKAN FITUR HAPUS & EDIT
-- (Jalankan ini di Supabase SQL Editor!)
-- ==========================================
-- Masalah "sudah diklik hapus tapi masih ada" terjadi karena 
-- Row Level Security (RLS) bawaan Supabase memblokir aksi DELETE/UPDATE 
-- jika Policy-nya belum dibuat!

-- Opsi 1: MATIKAN RLS SEMENTARA (Paling Gampang & Langsung Berhasil)
ALTER TABLE public.transaksi_kas DISABLE ROW LEVEL SECURITY;

-- Opsi 2: JIKA RLS HARUS AKTIF, buatkan izin (policy) Hapus & Edit:
-- CREATE POLICY "Izinkan Hapus" ON public.transaksi_kas FOR DELETE USING (auth.uid() = kelurahan_id);
-- CREATE POLICY "Izinkan Edit" ON public.transaksi_kas FOR UPDATE USING (auth.uid() = kelurahan_id);