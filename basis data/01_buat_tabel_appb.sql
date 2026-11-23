CREATE TABLE provinsi (
    id_provinsi CHAR(2) PRIMARY KEY,
    nama_provinsi VARCHAR(100) NOT NULL
);

CREATE TABLE kota (
    id_kota CHAR(5) PRIMARY KEY,
    id_provinsi CHAR(2) NOT NULL,
    nama_kota VARCHAR(100) NOT NULL,
    CONSTRAINT fk_kota_provinsi FOREIGN KEY (id_provinsi) REFERENCES provinsi (id_provinsi)
);

CREATE TABLE kecamatan (
    id_kecamatan CHAR(8) PRIMARY KEY,
    id_kota CHAR(5) NOT NULL,
    nama_kecamatan VARCHAR(100) NOT NULL,
    CONSTRAINT fk_kecamatan_kota FOREIGN KEY (id_kota) REFERENCES kota (id_kota)
);

CREATE TABLE kelurahan (
    id_kelurahan CHAR(13) PRIMARY KEY,
    id_kecamatan CHAR(8) NOT NULL,
    nama_kelurahan VARCHAR(100) NOT NULL,
    CONSTRAINT fk_kelurahan_kecamatan FOREIGN KEY (id_kecamatan) REFERENCES kecamatan (id_kecamatan)
);

CREATE TABLE admin (
    id_admin INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama VARCHAR(150) NOT NULL,
    username VARCHAR(80) NOT NULL UNIQUE,
    password VARCHAR(72) NOT NULL
);

CREATE TABLE petugas (
    id_petugas INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    nama VARCHAR(150) NOT NULL,
    username VARCHAR(80) NOT NULL UNIQUE,
    password VARCHAR(72) NOT NULL,
    kontak VARCHAR(30),
    instansi VARCHAR(150) NOT NULL,
    status ENUM('Aktif', 'Nonaktif') NOT NULL DEFAULT 'Aktif',
    CONSTRAINT fk_petugas_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan)
);

CREATE TABLE relawan (
    id_relawan INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    nama VARCHAR(150) NOT NULL,
    username VARCHAR(80) NOT NULL UNIQUE,
    password VARCHAR(72) NOT NULL,
    kontak VARCHAR(30),
    instansi VARCHAR(150) NOT NULL,
    status ENUM('Aktif', 'Nonaktif') NOT NULL DEFAULT 'Aktif',
    CONSTRAINT fk_relawan_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan)
);

CREATE TABLE bencana (
    id_bencana INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nama_bencana VARCHAR(100) NOT NULL UNIQUE,
    deskripsi TEXT,
    status ENUM('Aktif', 'Nonaktif') NOT NULL DEFAULT 'Aktif'
);

CREATE TABLE laporan_bencana (
    id_laporan BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    id_bencana INT UNSIGNED NOT NULL,
    id_petugas INT UNSIGNED NULL,
    judul_laporan VARCHAR(180) NOT NULL,
    deskripsi TEXT NOT NULL,
    alamat VARCHAR(255) NOT NULL,
    status ENUM(
        'Tertunda', 'Ditolak', 'Belum Ditangani', 'Sedang Ditangani',
        'Selesai Ditangani', 'Tidak Memerlukan Tindak Lanjut', 'Case Closed'
    ) NOT NULL DEFAULT 'Tertunda',
    waktu_laporan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    waktu_verifikasi DATETIME NULL,
    alasan_penolakan TEXT,
    waktu_penutupan DATETIME NULL,
    ringkasan_penutupan TEXT,
    nama_pelapor VARCHAR(150) NULL,
    no_hp_pelapor VARCHAR(30) NULL,
    token_pelapor_hash BINARY(32) NULL,
    jumlah_luka INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_hilang INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_meninggal INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_mengungsi INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_selamat INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_korban BIGINT UNSIGNED GENERATED ALWAYS AS
        (jumlah_luka + jumlah_hilang + jumlah_meninggal) STORED,
    penanda_aktif TINYINT GENERATED ALWAYS AS
        (CASE WHEN status IN ('Ditolak', 'Case Closed') THEN NULL ELSE 1 END) STORED,
    CONSTRAINT fk_laporan_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan),
    CONSTRAINT fk_laporan_bencana FOREIGN KEY (id_bencana) REFERENCES bencana (id_bencana),
    CONSTRAINT fk_laporan_petugas FOREIGN KEY (id_petugas) REFERENCES petugas (id_petugas),
    CONSTRAINT ck_laporan_judul CHECK (CHAR_LENGTH(TRIM(judul_laporan)) > 0),
    CONSTRAINT ck_laporan_verifikasi CHECK (
        (status = 'Tertunda' AND id_petugas IS NULL AND waktu_verifikasi IS NULL)
        OR (status <> 'Tertunda' AND id_petugas IS NOT NULL
            AND waktu_verifikasi IS NOT NULL AND waktu_verifikasi >= waktu_laporan)
    ),
    CONSTRAINT ck_laporan_penolakan CHECK (
        status <> 'Ditolak'
        OR (alasan_penolakan IS NOT NULL AND CHAR_LENGTH(TRIM(alasan_penolakan)) > 0)
    ),
    CONSTRAINT ck_laporan_penutupan CHECK (
        status <> 'Case Closed'
        OR (waktu_penutupan IS NOT NULL AND waktu_penutupan >= waktu_verifikasi
            AND ringkasan_penutupan IS NOT NULL AND CHAR_LENGTH(TRIM(ringkasan_penutupan)) > 0)
    ),
    UNIQUE KEY uq_laporan_aktif (id_kelurahan, id_bencana, penanda_aktif),
    UNIQUE KEY uq_laporan_kelurahan (id_laporan, id_kelurahan),
    INDEX idx_laporan_wilayah_status (id_kelurahan, status, waktu_laporan),
    INDEX idx_laporan_status_waktu (status, waktu_laporan),
    INDEX idx_laporan_pelapor (token_pelapor_hash, waktu_laporan)
);

CREATE TABLE pembaruan_laporan (
    id_pembaruan BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_laporan BIGINT UNSIGNED NOT NULL,
    nama_pengirim VARCHAR(150) NULL,
    deskripsi TEXT NOT NULL,
    waktu_pembaruan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pembaruan_laporan FOREIGN KEY (id_laporan) REFERENCES laporan_bencana (id_laporan)
);

CREATE TABLE foto (
    id_foto BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_laporan BIGINT UNSIGNED NULL,
    id_pembaruan BIGINT UNSIGNED NULL,
    url_foto VARCHAR(2048) NOT NULL,
    CONSTRAINT fk_foto_laporan FOREIGN KEY (id_laporan) REFERENCES laporan_bencana (id_laporan),
    CONSTRAINT fk_foto_pembaruan FOREIGN KEY (id_pembaruan) REFERENCES pembaruan_laporan (id_pembaruan),
    CONSTRAINT ck_foto_pemilik CHECK (
        (id_laporan IS NOT NULL AND id_pembaruan IS NULL)
        OR (id_laporan IS NULL AND id_pembaruan IS NOT NULL)
    )
);

CREATE TABLE log_penanganan (
    id_log BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_laporan BIGINT UNSIGNED NULL,
    id_kelurahan CHAR(13) NULL,
    aktor VARCHAR(150) NOT NULL,
    peran_aktor ENUM('Warga', 'Petugas', 'Relawan', 'Admin', 'Sistem') NOT NULL,
    aksi VARCHAR(80) NOT NULL,
    detail TEXT NOT NULL,
    status_awal VARCHAR(40) NULL,
    status_akhir VARCHAR(40) NULL,
    waktu_log DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_laporan FOREIGN KEY (id_laporan) REFERENCES laporan_bencana (id_laporan),
    CONSTRAINT fk_log_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan),
    CONSTRAINT ck_log_wilayah CHECK (id_laporan IS NULL OR id_kelurahan IS NULL),
    INDEX idx_log_laporan_waktu (id_laporan, waktu_log)
);

CREATE TABLE pengumuman (
    id_pengumuman BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    id_laporan BIGINT UNSIGNED NULL,
    id_bencana INT UNSIGNED NOT NULL,
    id_petugas INT UNSIGNED NOT NULL,
    label ENUM('Informasi', 'Imbauan', 'Peringatan', 'Evakuasi') NOT NULL,
    judul VARCHAR(180) NOT NULL,
    deskripsi TEXT NOT NULL,
    waktu_diumumkan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pengumuman_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan),
    CONSTRAINT fk_pengumuman_laporan FOREIGN KEY (id_laporan, id_kelurahan)
        REFERENCES laporan_bencana (id_laporan, id_kelurahan),
    CONSTRAINT fk_pengumuman_bencana FOREIGN KEY (id_bencana) REFERENCES bencana (id_bencana),
    CONSTRAINT fk_pengumuman_petugas FOREIGN KEY (id_petugas) REFERENCES petugas (id_petugas)
);

CREATE TABLE bantuan (
    id_bantuan BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    id_laporan BIGINT UNSIGNED NULL,
    id_admin INT UNSIGNED NULL,
    id_petugas INT UNSIGNED NULL,
    sumber VARCHAR(150) NOT NULL,
    jenis_bantuan VARCHAR(150) NOT NULL,
    jumlah INT UNSIGNED NOT NULL,
    waktu_catat DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bantuan_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan),
    CONSTRAINT fk_bantuan_laporan FOREIGN KEY (id_laporan, id_kelurahan)
        REFERENCES laporan_bencana (id_laporan, id_kelurahan),
    CONSTRAINT fk_bantuan_admin FOREIGN KEY (id_admin) REFERENCES admin (id_admin),
    CONSTRAINT fk_bantuan_petugas FOREIGN KEY (id_petugas) REFERENCES petugas (id_petugas),
    CONSTRAINT ck_bantuan_pencatat CHECK (
        (id_admin IS NOT NULL AND id_petugas IS NULL)
        OR (id_admin IS NULL AND id_petugas IS NOT NULL)
    ),
    CONSTRAINT ck_bantuan_jumlah CHECK (jumlah > 0)
);

CREATE TABLE data_historis (
    id_historis BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_kelurahan CHAR(13) NOT NULL,
    id_laporan BIGINT UNSIGNED NULL UNIQUE,
    id_bencana INT UNSIGNED NOT NULL,
    id_admin INT UNSIGNED NOT NULL,
    jumlah_korban INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_meninggal INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_mengungsi INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_rumah_rusak INT UNSIGNED NOT NULL DEFAULT 0,
    sumber_data VARCHAR(180) NOT NULL,
    tanggal_kejadian DATE NOT NULL,
    CONSTRAINT fk_historis_kelurahan FOREIGN KEY (id_kelurahan) REFERENCES kelurahan (id_kelurahan),
    CONSTRAINT fk_historis_laporan FOREIGN KEY (id_laporan, id_kelurahan)
        REFERENCES laporan_bencana (id_laporan, id_kelurahan),
    CONSTRAINT fk_historis_bencana FOREIGN KEY (id_bencana) REFERENCES bencana (id_bencana),
    CONSTRAINT fk_historis_admin FOREIGN KEY (id_admin) REFERENCES admin (id_admin)
);

CREATE TABLE riwayat_impor (
    id_impor BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_admin INT UNSIGNED NOT NULL,
    jenis_impor ENUM('Wilayah', 'Petugas', 'Relawan', 'Historis') NOT NULL,
    nama_file VARCHAR(255) NOT NULL,
    jumlah_berhasil INT UNSIGNED NOT NULL DEFAULT 0,
    jumlah_gagal INT UNSIGNED NOT NULL DEFAULT 0,
    waktu_impor DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_impor_admin FOREIGN KEY (id_admin) REFERENCES admin (id_admin)
);

CREATE TRIGGER trg_log_tolak_update
BEFORE UPDATE ON log_penanganan FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Entri log tidak dapat diubah';

CREATE TRIGGER trg_log_tolak_delete
BEFORE DELETE ON log_penanganan FOR EACH ROW
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Entri log tidak dapat dihapus';
