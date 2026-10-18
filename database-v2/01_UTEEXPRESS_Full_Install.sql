-- =========================================================================================
-- ĐỒ ÁN HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU: HỆ THỐNG QUẢN LÝ VẬN CHUYỂN UTEEXPRESS (SQL SERVER)
-- FILE 01: CÀI ĐẶT TOÀN DIỆN (SCHEMA + LOGIC + TRANSACTION + SECURITY + FULL SEED DATA)
-- Hướng dẫn: Chọn toàn bộ script và nhấn Execute (F5) một lần duy nhất.
-- =========================================================================================
USE master;
GO

IF DB_ID('UTEEXPRESS') IS NOT NULL
BEGIN
    ALTER DATABASE UTEEXPRESS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE UTEEXPRESS;
END
GO

CREATE DATABASE UTEEXPRESS;
GO
USE UTEEXPRESS;
GO

-- =========================================================================================
-- PHẦN 1. THIẾT KẾ DỮ LIỆU: SEQUENCES, 18 BẢNG (3NF), RÀNG BUỘC & 18 INDEXES (Mục 3.1 & 3.2)
-- =========================================================================================

-- 1.1. SEQUENCES SINH MÃ TỰ ĐỘNG
CREATE SEQUENCE seq_nd     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_kh     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_kho    AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_nv     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_tx     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_pt     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_tuyen  AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_chuyen AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dh     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_kien   AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ls     AS INT START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ttoan  AS INT START WITH 1 INCREMENT BY 1;
GO

-- 1.2. CÁC BẢNG DỮ LIỆU & RÀNG BUỘC TOÀN VẸN
-- Bảng 1: VAI TRÒ
CREATE TABLE vai_tro (
    ma_vai_tro  VARCHAR(20) PRIMARY KEY,
    ten_vai_tro NVARCHAR(50) NOT NULL,
    mo_ta       NVARCHAR(MAX)
);

-- Bảng 2: NGƯỜI DÙNG
CREATE TABLE nguoi_dung (
    ma_nd         VARCHAR(20) PRIMARY KEY DEFAULT ('ND' + RIGHT('000000' + CAST(NEXT VALUE FOR seq_nd AS VARCHAR(10)), 6)),
    ten_dang_nhap VARCHAR(50)  NOT NULL UNIQUE,
    mat_khau      VARCHAR(255) NOT NULL,
    trang_thai    NVARCHAR(20) NOT NULL DEFAULT N'Hoạt động'
                  CONSTRAINT ck_nd_trang_thai CHECK (trang_thai IN (N'Hoạt động', N'Bị khóa')),
    ma_vai_tro    VARCHAR(20)  NOT NULL REFERENCES vai_tro(ma_vai_tro)
);

-- Bảng 3: KHÁCH HÀNG
CREATE TABLE khach_hang (
    ma_kh            VARCHAR(20) PRIMARY KEY DEFAULT ('KH' + RIGHT('000000' + CAST(NEXT VALUE FOR seq_kh AS VARCHAR(10)), 6)),
    ho_ten           NVARCHAR(100) NOT NULL,
    sdt              VARCHAR(15)   NOT NULL
                     CONSTRAINT uq_kh_sdt UNIQUE
                     CONSTRAINT ck_kh_sdt CHECK (LEN(sdt) = 10 AND sdt NOT LIKE '%[^0-9]%'),
    email            VARCHAR(100)
                     CONSTRAINT ck_kh_email CHECK (email IS NULL OR (email LIKE '_%@_%._%' AND email NOT LIKE '% %')),
    dia_chi_mac_dinh NVARCHAR(MAX),
    ma_nd            VARCHAR(20) REFERENCES nguoi_dung(ma_nd)
);
CREATE UNIQUE INDEX uq_kh_email ON khach_hang(email) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX uq_kh_nd    ON khach_hang(ma_nd) WHERE ma_nd IS NOT NULL;

-- Bảng 4: KHO / BƯU CỤC
CREATE TABLE kho (
    ma_kho  VARCHAR(20) PRIMARY KEY DEFAULT ('KHO' + RIGHT('0000' + CAST(NEXT VALUE FOR seq_kho AS VARCHAR(10)), 4)),
    ten_kho NVARCHAR(100) NOT NULL,
    dia_chi NVARCHAR(MAX) NOT NULL,
    sdt     VARCHAR(15) CONSTRAINT ck_kho_sdt CHECK (sdt IS NULL OR (LEN(sdt) = 10 AND sdt NOT LIKE '%[^0-9]%'))
);

-- Bảng 5: NHÂN VIÊN
CREATE TABLE nhan_vien (
    ma_nv   VARCHAR(20) PRIMARY KEY DEFAULT ('NV' + RIGHT('00000' + CAST(NEXT VALUE FOR seq_nv AS VARCHAR(10)), 5)),
    ho_ten  NVARCHAR(100) NOT NULL,
    chuc_vu NVARCHAR(50)  NOT NULL
            CONSTRAINT ck_nv_chuc_vu CHECK (chuc_vu IN (N'Nhân viên bưu cục', N'Nhân viên điều phối')),
    sdt     VARCHAR(15) CONSTRAINT ck_nv_sdt CHECK (sdt IS NULL OR (LEN(sdt) = 10 AND sdt NOT LIKE '%[^0-9]%')),
    email   VARCHAR(100),
    ma_kho  VARCHAR(20) REFERENCES kho(ma_kho),
    ma_nd   VARCHAR(20) REFERENCES nguoi_dung(ma_nd)
);
CREATE UNIQUE INDEX uq_nv_nd ON nhan_vien(ma_nd) WHERE ma_nd IS NOT NULL;

-- Bảng 6: TÀI XẾ
CREATE TABLE tai_xe (
    ma_tx    VARCHAR(20) PRIMARY KEY DEFAULT ('TX' + RIGHT('00000' + CAST(NEXT VALUE FOR seq_tx AS VARCHAR(10)), 5)),
    ho_ten   NVARCHAR(100) NOT NULL,
    sdt      VARCHAR(15)   NOT NULL CONSTRAINT ck_tx_sdt CHECK (LEN(sdt) = 10 AND sdt NOT LIKE '%[^0-9]%'),
    bang_lai VARCHAR(20),
    ma_nd    VARCHAR(20) REFERENCES nguoi_dung(ma_nd)
);
CREATE UNIQUE INDEX uq_tx_nd ON tai_xe(ma_nd) WHERE ma_nd IS NOT NULL;

-- Bảng 7: PHƯƠNG TIỆN
CREATE TABLE phuong_tien (
    ma_pt      VARCHAR(20) PRIMARY KEY DEFAULT ('PT' + RIGHT('00000' + CAST(NEXT VALUE FOR seq_pt AS VARCHAR(10)), 5)),
    bien_so    VARCHAR(20)   NOT NULL UNIQUE,
    loai_xe    NVARCHAR(50),
    tai_trong  NUMERIC(10,2) NOT NULL CONSTRAINT ck_pt_tai_trong CHECK (tai_trong > 0),
    trang_thai NVARCHAR(20)  NOT NULL DEFAULT N'Sẵn sàng'
               CONSTRAINT ck_pt_trang_thai CHECK (trang_thai IN (N'Sẵn sàng', N'Đang chạy', N'Bảo trì'))
);

-- Bảng 8: TUYẾN VẬN CHUYỂN
CREATE TABLE tuyen_van_chuyen (
    ma_tuyen              VARCHAR(20) PRIMARY KEY DEFAULT ('TU' + RIGHT('0000' + CAST(NEXT VALUE FOR seq_tuyen AS VARCHAR(10)), 4)),
    ma_kho_di             VARCHAR(20) NOT NULL REFERENCES kho(ma_kho),
    ma_kho_den            VARCHAR(20) NOT NULL REFERENCES kho(ma_kho),
    khoang_cach           NUMERIC(10,2) NOT NULL CONSTRAINT ck_tuyen_kc CHECK (khoang_cach > 0),
    thoi_gian_du_kien_gio NUMERIC(6,2)  NOT NULL CONSTRAINT ck_tuyen_tg CHECK (thoi_gian_du_kien_gio > 0),
    CONSTRAINT ck_tuyen_khac_kho CHECK (ma_kho_di <> ma_kho_den),
    CONSTRAINT uq_tuyen_kho UNIQUE (ma_kho_di, ma_kho_den)
);

-- Bảng 9: CHUYẾN GIAO
CREATE TABLE chuyen_giao (
    ma_chuyen           VARCHAR(20) PRIMARY KEY DEFAULT ('CG' + RIGHT('000000' + CAST(NEXT VALUE FOR seq_chuyen AS VARCHAR(10)), 6)),
    loai_chuyen         VARCHAR(20) NOT NULL DEFAULT 'LIEN_KHO'
                        CONSTRAINT ck_cg_loai_val CHECK (loai_chuyen IN ('LIEN_KHO', 'GIAO_CUOI')),
    ma_tuyen            VARCHAR(20) REFERENCES tuyen_van_chuyen(ma_tuyen),
    ma_kho_giao         VARCHAR(20) REFERENCES kho(ma_kho),
    ma_tx               VARCHAR(20) NOT NULL REFERENCES tai_xe(ma_tx),
    ma_pt               VARCHAR(20) NOT NULL REFERENCES phuong_tien(ma_pt),
    ma_nv_dieu_phoi     VARCHAR(20) REFERENCES nhan_vien(ma_nv),
    ngay_xuat_phat      DATETIME2   NOT NULL,
    ngay_den_du_kien    DATETIME2   NOT NULL,
    ngay_xuat_phat_thuc DATETIME2,
    ngay_den            DATETIME2,
    trang_thai          NVARCHAR(50) NOT NULL DEFAULT N'Chưa đi'
                        CONSTRAINT ck_cg_trang_thai CHECK (trang_thai IN (N'Chưa đi', N'Đang đi', N'Hoàn thành', N'Đã hủy')),
    CONSTRAINT ck_cg_loai CHECK (
        (loai_chuyen = 'LIEN_KHO'  AND ma_tuyen IS NOT NULL AND ma_kho_giao IS NULL) OR
        (loai_chuyen = 'GIAO_CUOI' AND ma_tuyen IS NULL     AND ma_kho_giao IS NOT NULL)
    ),
    CONSTRAINT ck_cg_thoi_gian CHECK (ngay_den_du_kien > ngay_xuat_phat),
    CONSTRAINT ck_cg_thuc CHECK (ngay_den IS NULL OR ngay_xuat_phat_thuc IS NULL OR ngay_den >= ngay_xuat_phat_thuc)
);

-- Bảng 10: TRẠNG THÁI ĐƠN HÀNG
CREATE TABLE trang_thai_dh (
    ma_trang_thai  VARCHAR(20)  PRIMARY KEY,
    ten_trang_thai NVARCHAR(50) NOT NULL
);

-- Bảng 11: QUY TRÌNH CHUYỂN TRẠNG THÁI HỢP LỆ
CREATE TABLE quy_trinh_trang_thai (
    tt_tu  VARCHAR(20) NOT NULL REFERENCES trang_thai_dh(ma_trang_thai),
    tt_den VARCHAR(20) NOT NULL REFERENCES trang_thai_dh(ma_trang_thai),
    PRIMARY KEY (tt_tu, tt_den)
);

-- Bảng 12: ĐƠN HÀNG
CREATE TABLE don_hang (
    ma_dh          VARCHAR(20) PRIMARY KEY DEFAULT ('DH' + RIGHT('000000' + CAST(NEXT VALUE FOR seq_dh AS VARCHAR(10)), 6)),
    ma_kh_gui      VARCHAR(20)   NOT NULL REFERENCES khach_hang(ma_kh),
    ma_kh_nhan     VARCHAR(20)   REFERENCES khach_hang(ma_kh),
    sdt_nhan       VARCHAR(15)   NOT NULL CONSTRAINT ck_dh_sdt CHECK (LEN(sdt_nhan) = 10 AND sdt_nhan NOT LIKE '%[^0-9]%'),
    ten_nguoi_nhan NVARCHAR(100) NOT NULL,
    dia_chi_lay    NVARCHAR(MAX) NOT NULL,
    dia_chi_giao   NVARCHAR(MAX) NOT NULL,
    ma_kho_gui     VARCHAR(20)   NOT NULL REFERENCES kho(ma_kho),
    ma_kho_nhan    VARCHAR(20)   NOT NULL REFERENCES kho(ma_kho),
    ngay_tao       DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    phi_van_chuyen NUMERIC(12,2) NOT NULL DEFAULT 0 CONSTRAINT ck_dh_phi CHECK (phi_van_chuyen >= 0),
    cod            NUMERIC(12,2) NOT NULL DEFAULT 0 CONSTRAINT ck_dh_cod CHECK (cod >= 0),
    ma_tt          VARCHAR(20)   NOT NULL DEFAULT 'TT01' REFERENCES trang_thai_dh(ma_trang_thai),
    ma_nv          VARCHAR(20)   REFERENCES nhan_vien(ma_nv)
);

-- Bảng 13: KIỆN HÀNG
CREATE TABLE kien_hang (
    ma_kien         VARCHAR(20) PRIMARY KEY DEFAULT ('KI' + RIGHT('0000000' + CAST(NEXT VALUE FOR seq_kien AS VARCHAR(10)), 7)),
    ma_dh           VARCHAR(20)   NOT NULL REFERENCES don_hang(ma_dh),
    khoi_luong      NUMERIC(10,2) NOT NULL CONSTRAINT ck_kien_kl   CHECK (khoi_luong > 0),
    dai             NUMERIC(8,2)  NOT NULL CONSTRAINT ck_kien_dai  CHECK (dai > 0),
    rong            NUMERIC(8,2)  NOT NULL CONSTRAINT ck_kien_rong CHECK (rong > 0),
    cao             NUMERIC(8,2)  NOT NULL CONSTRAINT ck_kien_cao  CHECK (cao > 0),
    loai_hang       NVARCHAR(50),
    ma_kho_hien_tai VARCHAR(20)   REFERENCES kho(ma_kho)
);

-- Bảng 14: CHI TIẾT CHUYẾN GIAO
CREATE TABLE chi_tiet_chuyen_giao (
    ma_chuyen      VARCHAR(20)  NOT NULL REFERENCES chuyen_giao(ma_chuyen),
    ma_kien        VARCHAR(20)  NOT NULL REFERENCES kien_hang(ma_kien),
    thoi_gian_gan  DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    thoi_gian_quet DATETIME2,
    trang_thai     NVARCHAR(20) NOT NULL DEFAULT N'Đã gán'
                   CONSTRAINT ck_ctcg_trang_thai CHECK (trang_thai IN (N'Đã gán', N'Đã quét', N'Đã giao', N'Thất bại')),
    ghi_chu        NVARCHAR(MAX),
    PRIMARY KEY (ma_chuyen, ma_kien)
);

-- Bảng 15: LỊCH SỬ TRẠNG THÁI
CREATE TABLE lich_su_trang_thai (
    ma_ls     VARCHAR(20) PRIMARY KEY DEFAULT ('LS' + RIGHT('00000000' + CAST(NEXT VALUE FOR seq_ls AS VARCHAR(10)), 8)),
    ma_dh     VARCHAR(20) NOT NULL REFERENCES don_hang(ma_dh),
    ma_tt     VARCHAR(20) NOT NULL REFERENCES trang_thai_dh(ma_trang_thai),
    thoi_gian DATETIME2   NOT NULL DEFAULT SYSDATETIME(),
    ma_nd     VARCHAR(20) REFERENCES nguoi_dung(ma_nd),
    ghi_chu   NVARCHAR(MAX)
);

-- Bảng 16: THANH TOÁN
CREATE TABLE thanh_toan (
    ma_tt_toan       VARCHAR(20) PRIMARY KEY DEFAULT ('TTO' + RIGHT('0000000' + CAST(NEXT VALUE FOR seq_ttoan AS VARCHAR(10)), 7)),
    ma_dh            VARCHAR(20)   NOT NULL REFERENCES don_hang(ma_dh),
    loai_khoan       VARCHAR(10)   NOT NULL CONSTRAINT ck_tt_loai CHECK (loai_khoan IN ('PHI_VC', 'COD')),
    so_tien          NUMERIC(12,2) NOT NULL CONSTRAINT ck_tt_tien CHECK (so_tien > 0),
    phuong_thuc      NVARCHAR(50)  CONSTRAINT ck_tt_pt CHECK (phuong_thuc IN (N'Tiền mặt', N'Chuyển khoản', N'COD')),
    trang_thai       NVARCHAR(50)  NOT NULL DEFAULT N'Chưa thanh toán'
                     CONSTRAINT ck_tt_trang_thai CHECK (trang_thai IN (N'Chưa thanh toán', N'Đã thanh toán')),
    thoi_gian        DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    nguoi_thanh_toan NVARCHAR(100)
);
CREATE UNIQUE INDEX uq_thanh_toan_da_tt ON thanh_toan(ma_dh, loai_khoan) WHERE trang_thai = N'Đã thanh toán';

-- Bảng 17: CẤU HÌNH HỆ THỐNG
CREATE TABLE cau_hinh_he_thong (
    khoa    VARCHAR(50)   PRIMARY KEY,
    gia_tri NUMERIC(14,2) NOT NULL,
    mo_ta   NVARCHAR(MAX)
);

-- Bảng 18: NHẬT KÝ HỆ THỐNG
CREATE TABLE nhat_ky_he_thong (
    ma_nk       BIGINT IDENTITY(1,1) PRIMARY KEY,
    ten_bang    VARCHAR(50)   NOT NULL,
    hanh_dong   VARCHAR(10)   NOT NULL,
    khoa        VARCHAR(50),
    du_lieu_cu  NVARCHAR(MAX),
    du_lieu_moi NVARCHAR(MAX),
    ma_nd       VARCHAR(20),
    thoi_gian   DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

-- 1.3. NON-CLUSTERED INDEXES TỐI ƯU HÓA TRUY VẤN
CREATE INDEX ix_dh_kh_gui    ON don_hang(ma_kh_gui);
CREATE INDEX ix_dh_kh_nhan   ON don_hang(ma_kh_nhan);
CREATE INDEX ix_dh_tt        ON don_hang(ma_tt);
CREATE INDEX ix_dh_ngay_tao  ON don_hang(ngay_tao);
CREATE INDEX ix_dh_nv        ON don_hang(ma_nv);
CREATE INDEX ix_dh_kho       ON don_hang(ma_kho_gui, ma_kho_nhan);
CREATE INDEX ix_kien_dh      ON kien_hang(ma_dh);
CREATE INDEX ix_kien_kho     ON kien_hang(ma_kho_hien_tai);
CREATE INDEX ix_cg_tx        ON chuyen_giao(ma_tx);
CREATE INDEX ix_cg_pt        ON chuyen_giao(ma_pt);
CREATE INDEX ix_cg_tuyen     ON chuyen_giao(ma_tuyen);
CREATE INDEX ix_cg_tt        ON chuyen_giao(trang_thai);
CREATE INDEX ix_ctcg_kien    ON chi_tiet_chuyen_giao(ma_kien);
CREATE INDEX ix_ls_dh        ON lich_su_trang_thai(ma_dh, thoi_gian);
CREATE INDEX ix_tt_dh        ON thanh_toan(ma_dh);
CREATE INDEX ix_tt_thoi_gian ON thanh_toan(thoi_gian);
CREATE INDEX ix_nk_bang      ON nhat_ky_he_thong(ten_bang, khoa);
GO

-- =========================================================================================
-- PHẦN 2. HÀM PHIÊN & 16 USER-DEFINED FUNCTIONS (Mục 3.3)
-- =========================================================================================
CREATE OR ALTER PROCEDURE sp_dat_phien
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sys.sp_set_session_context @key = N'app_ma_nd',   @value = @p_ma_nd;
    EXEC sys.sp_set_session_context @key = N'app_ghi_chu', @value = @p_ghi_chu;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_phien_ma_nd() RETURNS VARCHAR(20)
AS
BEGIN
    RETURN NULLIF(CAST(SESSION_CONTEXT(N'app_ma_nd') AS VARCHAR(20)), '');
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_phien_ghi_chu() RETURNS NVARCHAR(4000)
AS
BEGIN
    RETURN NULLIF(CAST(SESSION_CONTEXT(N'app_ghi_chu') AS NVARCHAR(4000)), N'');
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_mask_sdt(@p_sdt VARCHAR(15)) RETURNS VARCHAR(15)
AS
BEGIN
    RETURN CASE WHEN @p_sdt IS NULL THEN NULL
                WHEN LEN(@p_sdt) < 7 THEN '***'
                ELSE LEFT(@p_sdt, 3) + REPLICATE('*', LEN(@p_sdt) - 6) + RIGHT(@p_sdt, 3) END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_cau_hinh(@p_khoa VARCHAR(50), @p_mac_dinh NUMERIC(14,2)) RETURNS NUMERIC(14,2)
AS
BEGIN
    RETURN COALESCE((SELECT gia_tri FROM cau_hinh_he_thong WHERE khoa = @p_khoa), @p_mac_dinh);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tinh_phi_van_chuyen(
    @p_khoi_luong NUMERIC(10,2),
    @p_dai NUMERIC(8,2),
    @p_rong NUMERIC(8,2),
    @p_cao NUMERIC(8,2),
    @p_khoang_cach NUMERIC(10,2)
) RETURNS NUMERIC(12,2)
AS
BEGIN
    IF COALESCE(@p_khoi_luong, 0) <= 0 OR COALESCE(@p_dai, 0) <= 0 OR COALESCE(@p_rong, 0) <= 0 OR COALESCE(@p_cao, 0) <= 0
        RETURN NULL;

    DECLARE @v_the_tich NUMERIC(14,4) = (@p_dai * @p_rong * @p_cao) / dbo.fn_cau_hinh('HE_SO_QUY_DOI', 5000);
    DECLARE @v_kl_qd NUMERIC(14,4) = CASE WHEN @p_khoi_luong >= @v_the_tich THEN @p_khoi_luong ELSE @v_the_tich END;
    DECLARE @v_kg_vuot NUMERIC(14,4) = @v_kl_qd - dbo.fn_cau_hinh('KG_MIEN_PHI', 0.5);
    IF @v_kg_vuot < 0 SET @v_kg_vuot = 0;

    DECLARE @v_phi NUMERIC(14,2) = dbo.fn_cau_hinh('PHI_CO_BAN', 15000)
                                 + @v_kg_vuot * dbo.fn_cau_hinh('PHI_MOI_KG', 5000)
                                 + COALESCE(@p_khoang_cach, 0) * dbo.fn_cau_hinh('PHI_MOI_KM', 300);
    RETURN ROUND(@v_phi, -2);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tim_tuyen(@p_kho_di VARCHAR(20), @p_kho_den VARCHAR(20)) RETURNS VARCHAR(20)
AS
BEGIN
    RETURN (SELECT ma_tuyen FROM tuyen_van_chuyen WHERE ma_kho_di = @p_kho_di AND ma_kho_den = @p_kho_den);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_khoang_cach_don(@p_kho_gui VARCHAR(20), @p_kho_nhan VARCHAR(20)) RETURNS NUMERIC(10,2)
AS
BEGIN
    RETURN CASE WHEN @p_kho_gui = @p_kho_nhan THEN CAST(0 AS NUMERIC(10,2))
                ELSE (SELECT khoang_cach FROM tuyen_van_chuyen WHERE ma_kho_di = @p_kho_gui AND ma_kho_den = @p_kho_nhan) END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tinh_phi_don(@p_ma_dh VARCHAR(20), @p_kho_gui VARCHAR(20), @p_kho_nhan VARCHAR(20)) RETURNS NUMERIC(12,2)
AS
BEGIN
    RETURN (
        SELECT COALESCE(SUM(dbo.fn_tinh_phi_van_chuyen(k.khoi_luong, k.dai, k.rong, k.cao,
                            COALESCE(dbo.fn_khoang_cach_don(@p_kho_gui, @p_kho_nhan), 0))), 0)
        FROM kien_hang k WHERE k.ma_dh = @p_ma_dh
    );
END;
GO

CREATE OR ALTER PROCEDURE sp_cap_nhat_phi_don(@p_ma_dh VARCHAR(20))
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE d
    SET phi_van_chuyen = dbo.fn_tinh_phi_don(d.ma_dh, d.ma_kho_gui, d.ma_kho_nhan)
    FROM don_hang d
    WHERE d.ma_dh = @p_ma_dh;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tong_thu(@p_ma_dh VARCHAR(20)) RETURNS NUMERIC(12,2)
AS
BEGIN
    RETURN (SELECT phi_van_chuyen + cod FROM don_hang WHERE ma_dh = @p_ma_dh);
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tong_khoi_luong_chuyen(@p_ma_chuyen VARCHAR(20)) RETURNS NUMERIC(12,2)
AS
BEGIN
    RETURN (
        SELECT COALESCE(SUM(k.khoi_luong), 0)
        FROM chi_tiet_chuyen_giao c JOIN kien_hang k ON k.ma_kien = c.ma_kien
        WHERE c.ma_chuyen = @p_ma_chuyen
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tai_trong_con_lai(@p_ma_chuyen VARCHAR(20)) RETURNS NUMERIC(12,2)
AS
BEGIN
    RETURN (
        SELECT p.tai_trong - dbo.fn_tong_khoi_luong_chuyen(c.ma_chuyen)
        FROM chuyen_giao c JOIN phuong_tien p ON p.ma_pt = c.ma_pt
        WHERE c.ma_chuyen = @p_ma_chuyen
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_chuyen_trang_thai_hop_le(@p_tu VARCHAR(20), @p_den VARCHAR(20)) RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (SELECT 1 FROM quy_trinh_trang_thai WHERE tt_tu = @p_tu AND tt_den = @p_den) THEN 1 ELSE 0 END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_la_tai_xe_cua_chuyen(@p_ma_chuyen VARCHAR(20), @p_ma_nd VARCHAR(20)) RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN EXISTS (
        SELECT 1 FROM chuyen_giao c JOIN tai_xe t ON t.ma_tx = c.ma_tx
        WHERE c.ma_chuyen = @p_ma_chuyen AND t.ma_nd = @p_ma_nd
    ) THEN 1 ELSE 0 END;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_tai_xe_ranh(@p_tu DATETIME2, @p_den DATETIME2)
RETURNS TABLE AS RETURN (
    SELECT t.ma_tx, t.ho_ten, t.sdt
    FROM tai_xe t LEFT JOIN nguoi_dung n ON n.ma_nd = t.ma_nd
    WHERE COALESCE(n.trang_thai, N'Hoạt động') = N'Hoạt động'
      AND NOT EXISTS (
          SELECT 1 FROM chuyen_giao c
          WHERE c.ma_tx = t.ma_tx AND c.trang_thai <> N'Đã hủy'
            AND c.ngay_xuat_phat < @p_den AND c.ngay_den_du_kien > @p_tu
      )
);
GO

CREATE OR ALTER FUNCTION dbo.fn_xe_ranh(@p_tu DATETIME2, @p_den DATETIME2)
RETURNS TABLE AS RETURN (
    SELECT p.ma_pt, p.bien_so, p.loai_xe, p.tai_trong
    FROM phuong_tien p
    WHERE p.trang_thai <> N'Bảo trì'
      AND NOT EXISTS (
          SELECT 1 FROM chuyen_giao c
          WHERE c.ma_pt = p.ma_pt AND c.trang_thai <> N'Đã hủy'
            AND c.ngay_xuat_phat < @p_den AND c.ngay_den_du_kien > @p_tu
      )
);
GO

CREATE OR ALTER FUNCTION dbo.fn_ty_le_giao_thanh_cong(@p_tu DATE, @p_den DATE) RETURNS NUMERIC(5,2)
AS
BEGIN
    RETURN (
        SELECT CAST(ROUND(
            100.0 * ISNULL(SUM(CASE WHEN ma_tt = 'TT06' THEN 1 ELSE 0 END), 0)
            / NULLIF(SUM(CASE WHEN ma_tt IN ('TT06', 'TT07') THEN 1 ELSE 0 END), 0)
        , 2) AS NUMERIC(5,2))
        FROM don_hang
        WHERE ngay_tao >= @p_tu AND ngay_tao < DATEADD(DAY, 1, @p_den)
    );
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_doanh_thu(@p_tu DATE, @p_den DATE, @p_kieu VARCHAR(10) = 'month')
RETURNS @Result TABLE (
    ky NVARCHAR(20),
    phi_van_chuyen NUMERIC(14,2),
    tong_cod NUMERIC(14,2),
    so_giao_dich BIGINT
)
AS
BEGIN
    INSERT INTO @Result
    SELECT 
        CASE @p_kieu
            WHEN 'day'     THEN FORMAT(t.thoi_gian, 'yyyy-MM-dd')
            WHEN 'month'   THEN FORMAT(t.thoi_gian, 'yyyy-MM')
            WHEN 'quarter' THEN CAST(YEAR(t.thoi_gian) AS VARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, t.thoi_gian) AS VARCHAR(1))
            ELSE CAST(YEAR(t.thoi_gian) AS VARCHAR(4))
        END AS ky,
        COALESCE(SUM(CASE WHEN t.loai_khoan = 'PHI_VC' THEN t.so_tien ELSE 0 END), 0) AS phi_van_chuyen,
        COALESCE(SUM(CASE WHEN t.loai_khoan = 'COD'    THEN t.so_tien ELSE 0 END), 0) AS tong_cod,
        COUNT(*) AS so_giao_dich
    FROM thanh_toan t
    WHERE t.trang_thai = N'Đã thanh toán'
      AND t.thoi_gian >= @p_tu AND t.thoi_gian < DATEADD(DAY, 1, @p_den)
    GROUP BY 
        CASE @p_kieu
            WHEN 'day'     THEN FORMAT(t.thoi_gian, 'yyyy-MM-dd')
            WHEN 'month'   THEN FORMAT(t.thoi_gian, 'yyyy-MM')
            WHEN 'quarter' THEN CAST(YEAR(t.thoi_gian) AS VARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, t.thoi_gian) AS VARCHAR(1))
            ELSE CAST(YEAR(t.thoi_gian) AS VARCHAR(4))
        END
    ORDER BY ky;
    RETURN;
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_so_viec_dang_xu_ly(@p_ma_nd VARCHAR(20)) RETURNS BIGINT
AS
BEGIN
    RETURN (
        SELECT
          (SELECT COUNT(DISTINCT d.ma_dh) FROM don_hang d
           WHERE d.ma_tt NOT IN ('TT06','TT07')
             AND (d.ma_kh_gui  IN (SELECT ma_kh FROM khach_hang WHERE ma_nd = @p_ma_nd)
               OR d.ma_kh_nhan IN (SELECT ma_kh FROM khach_hang WHERE ma_nd = @p_ma_nd)
               OR d.ma_nv      IN (SELECT ma_nv FROM nhan_vien  WHERE ma_nd = @p_ma_nd)))
        + (SELECT COUNT(*) FROM chuyen_giao c
           WHERE c.trang_thai IN (N'Chưa đi', N'Đang đi')
             AND (c.ma_tx IN (SELECT ma_tx FROM tai_xe WHERE ma_nd = @p_ma_nd)
               OR c.ma_nv_dieu_phoi IN (SELECT ma_nv FROM nhan_vien WHERE ma_nd = @p_ma_nd)))
    );
END;
GO

-- =========================================================================================
-- PHẦN 3. 12 KHUNG NHÌN (VIEWS) TRUY VẤN & BÁO CÁO TỔNG HỢP (Mục 3.2)
-- =========================================================================================
CREATE OR ALTER VIEW v_don_hang_chi_tiet AS
SELECT d.ma_dh, d.ngay_tao,
       d.ma_kh_gui, kg.ho_ten AS ten_nguoi_gui, kg.sdt AS sdt_nguoi_gui,
       d.ma_kh_nhan, d.ten_nguoi_nhan, d.sdt_nhan, d.dia_chi_lay, d.dia_chi_giao,
       d.ma_kho_gui, kho_g.ten_kho AS ten_kho_gui, d.ma_kho_nhan, kho_n.ten_kho AS ten_kho_nhan,
       d.ma_tt, tt.ten_trang_thai, d.ma_nv, nv.ho_ten AS ten_nhan_vien,
       COALESCE(k.so_kien, 0) AS so_kien, COALESCE(k.tong_kg, 0) AS tong_kg,
       d.phi_van_chuyen, d.cod, d.phi_van_chuyen + d.cod AS tong_thu,
       CAST(COALESCE(p.phi_da_tt, 0) AS BIT) AS phi_da_thanh_toan,
       CAST(COALESCE(p.cod_da_tt, 0) AS BIT) AS cod_da_thu,
       CASE WHEN d.ma_tt = 'TT07' THEN N'Không thu (hủy/trả)'
            WHEN COALESCE(p.phi_da_tt, 0) = 1 AND (d.cod = 0 OR COALESCE(p.cod_da_tt, 0) = 1) THEN N'Đã thanh toán đủ'
            WHEN COALESCE(p.phi_da_tt, 0) = 1 OR COALESCE(p.cod_da_tt, 0) = 1 THEN N'Thanh toán một phần'
            ELSE N'Chưa thanh toán' END AS tinh_trang_thanh_toan
FROM don_hang d
JOIN khach_hang kg      ON kg.ma_kh = d.ma_kh_gui
JOIN kho kho_g          ON kho_g.ma_kho = d.ma_kho_gui
JOIN kho kho_n          ON kho_n.ma_kho = d.ma_kho_nhan
JOIN trang_thai_dh tt   ON tt.ma_trang_thai = d.ma_tt
LEFT JOIN nhan_vien nv  ON nv.ma_nv = d.ma_nv
OUTER APPLY (
    SELECT COUNT(*) AS so_kien, COALESCE(SUM(khoi_luong), 0) AS tong_kg
    FROM kien_hang WHERE ma_dh = d.ma_dh
) k
OUTER APPLY (
    SELECT ISNULL(MAX(CASE WHEN loai_khoan = 'PHI_VC' AND trang_thai = N'Đã thanh toán' THEN 1 ELSE 0 END), 0) AS phi_da_tt,
           ISNULL(MAX(CASE WHEN loai_khoan = 'COD'    AND trang_thai = N'Đã thanh toán' THEN 1 ELSE 0 END), 0) AS cod_da_tt
    FROM thanh_toan WHERE ma_dh = d.ma_dh
) p;
GO

CREATE OR ALTER VIEW v_tra_cuu_cong_khai AS
SELECT d.ma_dh, d.ngay_tao, tt.ten_trang_thai,
       (SELECT MAX(thoi_gian) FROM lich_su_trang_thai l WHERE l.ma_dh = d.ma_dh) AS cap_nhat_luc,
       dbo.fn_mask_sdt(d.sdt_nhan) AS sdt_nhan_che,
       (SELECT COUNT(*) FROM kien_hang k WHERE k.ma_dh = d.ma_dh) AS so_kien
FROM don_hang d JOIN trang_thai_dh tt ON tt.ma_trang_thai = d.ma_tt;
GO

CREATE OR ALTER VIEW v_lich_su_van_chuyen AS
SELECT l.ma_ls, l.ma_dh, l.ma_tt, tt.ten_trang_thai, l.thoi_gian,
       l.ma_nd, nd.ten_dang_nhap AS nguoi_cap_nhat, l.ghi_chu
FROM lich_su_trang_thai l
JOIN trang_thai_dh tt ON tt.ma_trang_thai = l.ma_tt
LEFT JOIN nguoi_dung nd ON nd.ma_nd = l.ma_nd;
GO

CREATE OR ALTER VIEW v_ton_kho AS
SELECT k.ma_kho, k.ten_kho, COUNT(kh.ma_kien) AS so_kien, COALESCE(SUM(kh.khoi_luong), 0) AS tong_kg
FROM kho k LEFT JOIN kien_hang kh ON kh.ma_kho_hien_tai = k.ma_kho
GROUP BY k.ma_kho, k.ten_kho;
GO

CREATE OR ALTER VIEW v_chuyen_giao_chi_tiet AS
SELECT c.ma_chuyen, c.loai_chuyen, c.trang_thai, c.ma_tuyen,
       COALESCE(t.ma_kho_di, c.ma_kho_giao) AS ma_kho_xuat_phat, kdi.ten_kho AS ten_kho_xuat_phat,
       t.ma_kho_den, COALESCE(kden.ten_kho, N'Địa chỉ khách hàng') AS ten_diem_den,
       c.ma_tx, tx.ho_ten AS ten_tai_xe, c.ma_pt, pt.bien_so, pt.tai_trong,
       c.ma_nv_dieu_phoi, c.ngay_xuat_phat, c.ngay_den_du_kien, c.ngay_xuat_phat_thuc, c.ngay_den,
       COALESCE(ct.so_kien, 0) AS so_kien, COALESCE(ct.tong_kg, 0) AS tong_kg,
       CAST(ROUND(100.0 * COALESCE(ct.tong_kg, 0) / pt.tai_trong, 1) AS NUMERIC(6,1)) AS ty_le_tai
FROM chuyen_giao c
JOIN tai_xe tx ON tx.ma_tx = c.ma_tx
JOIN phuong_tien pt ON pt.ma_pt = c.ma_pt
LEFT JOIN tuyen_van_chuyen t ON t.ma_tuyen = c.ma_tuyen
LEFT JOIN kho kdi  ON kdi.ma_kho  = COALESCE(t.ma_kho_di, c.ma_kho_giao)
LEFT JOIN kho kden ON kden.ma_kho = t.ma_kho_den
OUTER APPLY (
    SELECT COUNT(*) AS so_kien, SUM(k.khoi_luong) AS tong_kg
    FROM chi_tiet_chuyen_giao x JOIN kien_hang k ON k.ma_kien = x.ma_kien
    WHERE x.ma_chuyen = c.ma_chuyen
) ct;
GO

CREATE OR ALTER VIEW v_kien_trong_chuyen AS
SELECT x.ma_chuyen, c.ma_tx, x.ma_kien, k.ma_dh, d.ten_nguoi_nhan, d.sdt_nhan, d.dia_chi_giao,
       k.khoi_luong, k.loai_hang, x.trang_thai, x.thoi_gian_gan, x.thoi_gian_quet, x.ghi_chu
FROM chi_tiet_chuyen_giao x
JOIN chuyen_giao c ON c.ma_chuyen = x.ma_chuyen
JOIN kien_hang k   ON k.ma_kien = x.ma_kien
JOIN don_hang d    ON d.ma_dh = k.ma_dh;
GO

CREATE OR ALTER VIEW v_thong_ke_don_theo_trang_thai AS
SELECT t.ma_trang_thai, t.ten_trang_thai, COUNT(d.ma_dh) AS so_don
FROM trang_thai_dh t LEFT JOIN don_hang d ON d.ma_tt = t.ma_trang_thai
GROUP BY t.ma_trang_thai, t.ten_trang_thai;
GO

CREATE OR ALTER VIEW v_doanh_thu_ngay AS
SELECT CAST(thoi_gian AS DATE) AS ngay,
       COALESCE(SUM(CASE WHEN loai_khoan = 'PHI_VC' THEN so_tien ELSE 0 END), 0) AS phi_van_chuyen,
       COALESCE(SUM(CASE WHEN loai_khoan = 'COD'    THEN so_tien ELSE 0 END), 0) AS tong_cod,
       COUNT(*) AS so_giao_dich
FROM thanh_toan WHERE trang_thai = N'Đã thanh toán'
GROUP BY CAST(thoi_gian AS DATE);
GO

CREATE OR ALTER VIEW v_doanh_thu_thang AS
SELECT DATEFROMPARTS(YEAR(thoi_gian), MONTH(thoi_gian), 1) AS thang,
       COALESCE(SUM(CASE WHEN loai_khoan = 'PHI_VC' THEN so_tien ELSE 0 END), 0) AS phi_van_chuyen,
       COALESCE(SUM(CASE WHEN loai_khoan = 'COD'    THEN so_tien ELSE 0 END), 0) AS tong_cod,
       COUNT(*) AS so_giao_dich
FROM thanh_toan WHERE trang_thai = N'Đã thanh toán'
GROUP BY DATEFROMPARTS(YEAR(thoi_gian), MONTH(thoi_gian), 1);
GO

CREATE OR ALTER VIEW v_cod_doi_soat AS
SELECT d.ma_dh, d.ma_kh_gui, d.ten_nguoi_nhan, d.cod, tt.ten_trang_thai,
       COALESCE(p.so_tien, 0) AS cod_da_thu, p.nguoi_thanh_toan, p.thoi_gian AS thoi_gian_thu,
       CASE WHEN p.ma_tt_toan IS NOT NULL THEN N'Đã thu'
            WHEN d.ma_tt = 'TT07' THEN N'Không thu (hủy/trả)'
            ELSE N'Chưa thu' END AS tinh_trang_cod
FROM don_hang d
JOIN trang_thai_dh tt ON tt.ma_trang_thai = d.ma_tt
LEFT JOIN thanh_toan p ON p.ma_dh = d.ma_dh AND p.loai_khoan = 'COD' AND p.trang_thai = N'Đã thanh toán'
WHERE d.cod > 0;
GO

CREATE OR ALTER VIEW v_thong_ke_chuyen AS
SELECT CAST(ngay_xuat_phat AS DATE) AS ngay,
       DATEFROMPARTS(YEAR(ngay_xuat_phat), MONTH(ngay_xuat_phat), 1) AS thang,
       loai_chuyen, ma_tuyen, ma_tx, ma_pt,
       COUNT(*) AS so_chuyen,
       ISNULL(SUM(CASE WHEN trang_thai = N'Hoàn thành' THEN 1 ELSE 0 END), 0) AS so_hoan_thanh,
       ISNULL(SUM(CASE WHEN trang_thai IN (N'Chưa đi', N'Đang đi') THEN 1 ELSE 0 END), 0) AS so_chua_hoan_thanh
FROM chuyen_giao
GROUP BY CAST(ngay_xuat_phat AS DATE), DATEFROMPARTS(YEAR(ngay_xuat_phat), MONTH(ngay_xuat_phat), 1),
         loai_chuyen, ma_tuyen, ma_tx, ma_pt;
GO

CREATE OR ALTER VIEW v_hieu_suat_tai_xe AS
SELECT t.ma_tx, t.ho_ten,
       COUNT(DISTINCT c.ma_chuyen) AS so_chuyen,
       COUNT(DISTINCT CASE WHEN c.trang_thai = N'Hoàn thành' THEN c.ma_chuyen END) AS so_chuyen_hoan_thanh,
       ISNULL(SUM(CASE WHEN ct.trang_thai = N'Đã giao'  THEN 1 ELSE 0 END), 0) AS kien_giao_thanh_cong,
       ISNULL(SUM(CASE WHEN ct.trang_thai = N'Thất bại' THEN 1 ELSE 0 END), 0) AS kien_giao_that_bai,
       CAST(ROUND(
           100.0 * ISNULL(SUM(CASE WHEN ct.trang_thai = N'Đã giao' THEN 1 ELSE 0 END), 0)
           / NULLIF(SUM(CASE WHEN ct.trang_thai IN (N'Đã giao', N'Thất bại') THEN 1 ELSE 0 END), 0)
       , 2) AS NUMERIC(5,2)) AS ty_le_thanh_cong
FROM tai_xe t
LEFT JOIN chuyen_giao c ON c.ma_tx = t.ma_tx AND c.trang_thai <> N'Đã hủy'
LEFT JOIN chi_tiet_chuyen_giao ct ON ct.ma_chuyen = c.ma_chuyen
GROUP BY t.ma_tx, t.ho_ten;
GO

CREATE OR ALTER VIEW v_hieu_suat_nhan_vien AS
SELECT n.ma_nv, n.ho_ten, n.chuc_vu, n.ma_kho,
       COALESCE(d.so_don, 0)    AS so_don_xu_ly,         COALESCE(d.so_kien, 0) AS so_kien_xu_ly,
       COALESCE(c.so_chuyen, 0) AS so_chuyen_dieu_phoi, COALESCE(c.so_kien, 0) AS so_kien_dieu_phoi
FROM nhan_vien n
OUTER APPLY (
    SELECT COUNT(DISTINCT dh.ma_dh) AS so_don, COUNT(k.ma_kien) AS so_kien
    FROM don_hang dh LEFT JOIN kien_hang k ON k.ma_dh = dh.ma_dh
    WHERE dh.ma_nv = n.ma_nv
) d
OUTER APPLY (
    SELECT COUNT(DISTINCT cg.ma_chuyen) AS so_chuyen, COUNT(x.ma_kien) AS so_kien
    FROM chuyen_giao cg LEFT JOIN chi_tiet_chuyen_giao x ON x.ma_chuyen = cg.ma_chuyen
    WHERE cg.ma_nv_dieu_phoi = n.ma_nv
) c;
GO

-- =========================================================================================
-- PHẦN 4. 14 TRIGGERS RÀNG BUỘC NGHIỆP VỤ & TỰ ĐỘNG HÓA (Mục 3.2)
-- =========================================================================================

-- 4.1. Kiểm tra vai trò tài khoản khớp bảng liên kết
CREATE OR ALTER TRIGGER trg_kh_vai_tro ON khach_hang AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN nguoi_dung n ON n.ma_nd = i.ma_nd
        WHERE i.ma_nd IS NOT NULL AND n.ma_vai_tro <> 'KHACH_HANG'
    )
        THROW 50001, N'Tài khoản không có vai trò Khách hàng', 1;
END;
GO

CREATE OR ALTER TRIGGER trg_tx_vai_tro ON tai_xe AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN nguoi_dung n ON n.ma_nd = i.ma_nd
        WHERE i.ma_nd IS NOT NULL AND n.ma_vai_tro <> 'TAI_XE'
    )
        THROW 50002, N'Tài khoản không có vai trò Tài xế', 1;
END;
GO

CREATE OR ALTER TRIGGER trg_nv_vai_tro ON nhan_vien AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN nguoi_dung n ON n.ma_nd = i.ma_nd
        WHERE i.ma_nd IS NOT NULL
          AND n.ma_vai_tro <> (CASE WHEN i.chuc_vu = N'Nhân viên bưu cục' THEN 'NVBC' ELSE 'NVDP' END)
    )
        THROW 50003, N'Vai trò tài khoản không khớp chức vụ nhân viên', 1;
END;
GO

-- 4.2. ĐƠN HÀNG: Ghi lịch sử + Kiểm tra quy trình chuyển trạng thái + Khóa sửa khi đã đi
CREATE OR ALTER TRIGGER trg_don_hang_ai ON don_hang AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO lich_su_trang_thai (ma_dh, ma_tt, ma_nd, ghi_chu)
    SELECT i.ma_dh, i.ma_tt, dbo.fn_phien_ma_nd(), COALESCE(dbo.fn_phien_ghi_chu(), N'Tạo đơn hàng')
    FROM inserted i;
END;
GO

CREATE OR ALTER TRIGGER trg_don_hang_au ON don_hang AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh WHERE i.ma_tt <> d.ma_tt)
    BEGIN
        IF EXISTS (
            SELECT 1 FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh
            WHERE i.ma_tt <> d.ma_tt AND dbo.fn_chuyen_trang_thai_hop_le(d.ma_tt, i.ma_tt) = 0
        )
            THROW 50004, N'Chuyển trạng thái đơn hàng không hợp lệ', 1;

        IF EXISTS (
            SELECT 1 FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh
            WHERE i.ma_tt <> d.ma_tt AND i.ma_tt = 'TT06' AND i.cod > 0
              AND NOT EXISTS (SELECT 1 FROM thanh_toan t WHERE t.ma_dh = i.ma_dh AND t.loai_khoan = 'COD' AND t.trang_thai = N'Đã thanh toán')
        )
            THROW 50005, N'Chưa thu tiền COD, không thể xác nhận giao thành công', 1;

        INSERT INTO lich_su_trang_thai (ma_dh, ma_tt, ma_nd, ghi_chu)
        SELECT i.ma_dh, i.ma_tt, dbo.fn_phien_ma_nd(), COALESCE(dbo.fn_phien_ghi_chu(), N'Cập nhật trạng thái')
        FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh
        WHERE i.ma_tt <> d.ma_tt;

        UPDATE k SET ma_kho_hien_tai = NULL
        FROM kien_hang k JOIN inserted i ON i.ma_dh = k.ma_dh JOIN deleted d ON d.ma_dh = i.ma_dh
        WHERE i.ma_tt <> d.ma_tt AND i.ma_tt = 'TT06';

        DELETE ctcg
        FROM chi_tiet_chuyen_giao ctcg
        JOIN kien_hang k ON k.ma_kien = ctcg.ma_kien
        JOIN inserted i ON i.ma_dh = k.ma_dh
        JOIN deleted d ON d.ma_dh = i.ma_dh
        JOIN chuyen_giao cg ON cg.ma_chuyen = ctcg.ma_chuyen
        WHERE i.ma_tt <> d.ma_tt AND i.ma_tt = 'TT07' AND cg.trang_thai = N'Chưa đi';
    END

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh
        WHERE i.ma_tt = d.ma_tt AND d.ma_tt NOT IN ('TT01', 'TT02')
          AND (
              i.dia_chi_lay <> d.dia_chi_lay OR i.dia_chi_giao <> d.dia_chi_giao OR
              i.cod <> d.cod OR i.phi_van_chuyen <> d.phi_van_chuyen OR
              i.ma_kho_gui <> d.ma_kho_gui OR i.ma_kho_nhan <> d.ma_kho_nhan OR
              i.ten_nguoi_nhan <> d.ten_nguoi_nhan OR i.sdt_nhan <> d.sdt_nhan
          )
    )
        THROW 50006, N'Đơn hàng đã vận chuyển, không được thay đổi thông tin/phí/COD', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN deleted d ON d.ma_dh = i.ma_dh
        WHERE i.ma_tt = d.ma_tt AND (i.ma_kho_gui <> d.ma_kho_gui OR i.ma_kho_nhan <> d.ma_kho_nhan)
    )
    BEGIN
        UPDATE dh
        SET phi_van_chuyen = dbo.fn_tinh_phi_don(dh.ma_dh, dh.ma_kho_gui, dh.ma_kho_nhan)
        FROM don_hang dh JOIN inserted i ON i.ma_dh = dh.ma_dh;
    END
END;
GO

-- 4.3. LỊCH SỬ TRẠNG THÁI: Bất biến
CREATE OR ALTER TRIGGER trg_lich_su_bat_bien ON lich_su_trang_thai AFTER UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    THROW 50007, N'Lịch sử trạng thái không được sửa hoặc xóa', 1;
END;
GO

-- 4.4. KIỆN HÀNG: Tự động tính lại phí đơn hàng
CREATE OR ALTER TRIGGER trg_kien_hang_tinh_phi ON kien_hang AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ds_dh TABLE (ma_dh VARCHAR(20));
    INSERT INTO @ds_dh
    SELECT ma_dh FROM inserted
    UNION
    SELECT ma_dh FROM deleted;

    UPDATE d
    SET phi_van_chuyen = dbo.fn_tinh_phi_don(d.ma_dh, d.ma_kho_gui, d.ma_kho_nhan)
    FROM don_hang d JOIN @ds_dh x ON x.ma_dh = d.ma_dh;
END;
GO

-- 4.5. CHUYẾN GIAO: Chống trùng lịch xe/tài xế & tự động luân chuyển kho/đơn hàng
CREATE OR ALTER TRIGGER trg_chuyen_giao_ai ON chuyen_giao AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN phuong_tien p ON p.ma_pt = i.ma_pt WHERE p.trang_thai = N'Bảo trì')
        THROW 50008, N'Phương tiện đang bảo trì', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN tai_xe t ON t.ma_tx = i.ma_tx
        LEFT JOIN nguoi_dung n ON n.ma_nd = t.ma_nd WHERE n.trang_thai = N'Bị khóa'
    )
        THROW 50009, N'Tài khoản tài xế đang bị khóa', 1;

    IF EXISTS (SELECT 1 FROM inserted WHERE trang_thai <> N'Chưa đi')
        THROW 50010, N'Chuyến mới phải ở trạng thái "Chưa đi"', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN chuyen_giao c ON c.ma_tx = i.ma_tx AND c.ma_chuyen <> i.ma_chuyen
        WHERE i.trang_thai IN (N'Chưa đi', N'Đang đi') AND c.trang_thai IN (N'Chưa đi', N'Đang đi')
          AND i.ngay_xuat_phat < c.ngay_den_du_kien AND i.ngay_den_du_kien > c.ngay_xuat_phat
    )
        THROW 50011, N'Tài xế đã được phân công chuyến khác trùng thời gian', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN chuyen_giao c ON c.ma_pt = i.ma_pt AND c.ma_chuyen <> i.ma_chuyen
        WHERE i.trang_thai IN (N'Chưa đi', N'Đang đi') AND c.trang_thai IN (N'Chưa đi', N'Đang đi')
          AND i.ngay_xuat_phat < c.ngay_den_du_kien AND i.ngay_den_du_kien > c.ngay_xuat_phat
    )
        THROW 50012, N'Phương tiện đã được phân công chuyến khác trùng thời gian', 1;
END;
GO

CREATE OR ALTER TRIGGER trg_chuyen_giao_au ON chuyen_giao AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted) RETURN;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN chuyen_giao c ON c.ma_tx = i.ma_tx AND c.ma_chuyen <> i.ma_chuyen
        WHERE i.trang_thai IN (N'Chưa đi', N'Đang đi') AND c.trang_thai IN (N'Chưa đi', N'Đang đi')
          AND i.ngay_xuat_phat < c.ngay_den_du_kien AND i.ngay_den_du_kien > c.ngay_xuat_phat
    )
        THROW 50011, N'Tài xế đã được phân công chuyến khác trùng thời gian', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN chuyen_giao c ON c.ma_pt = i.ma_pt AND c.ma_chuyen <> i.ma_chuyen
        WHERE i.trang_thai IN (N'Chưa đi', N'Đang đi') AND c.trang_thai IN (N'Chưa đi', N'Đang đi')
          AND i.ngay_xuat_phat < c.ngay_den_du_kien AND i.ngay_den_du_kien > c.ngay_xuat_phat
    )
        THROW 50012, N'Phương tiện đã được phân công chuyến khác trùng thời gian', 1;

    DECLARE @ma_chuyen VARCHAR(20), @old_tt NVARCHAR(50), @new_tt NVARCHAR(50),
            @loai VARCHAR(20), @ma_tuyen VARCHAR(20), @ma_kho_giao VARCHAR(20), @ma_pt VARCHAR(20);

    SELECT TOP 1 @ma_chuyen = i.ma_chuyen, @old_tt = d.trang_thai, @new_tt = i.trang_thai,
                 @loai = i.loai_chuyen, @ma_tuyen = i.ma_tuyen, @ma_kho_giao = i.ma_kho_giao, @ma_pt = i.ma_pt
    FROM inserted i JOIN deleted d ON d.ma_chuyen = i.ma_chuyen;

    IF @new_tt <> @old_tt
    BEGIN
        IF NOT ((@old_tt = N'Chưa đi' AND @new_tt IN (N'Đang đi', N'Đã hủy'))
             OR (@old_tt = N'Đang đi' AND @new_tt = N'Hoàn thành'))
            THROW 50013, N'Chuyển trạng thái chuyến giao không hợp lệ', 1;

        IF @new_tt = N'Đang đi'
        BEGIN
            DECLARE @v_so INT, @v_chua INT;
            SELECT @v_so = COUNT(*),
                   @v_chua = ISNULL(SUM(CASE WHEN trang_thai <> N'Đã quét' THEN 1 ELSE 0 END), 0)
            FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen;

            IF @v_so = 0 THROW 50014, N'Chuyến chưa có kiện hàng nào', 1;
            IF @v_chua > 0 THROW 50015, N'Còn kiện hàng chưa được quét lên xe', 1;

            UPDATE chuyen_giao SET ngay_xuat_phat_thuc = SYSDATETIME() WHERE ma_chuyen = @ma_chuyen;

            DECLARE @ghi_chu_xp NVARCHAR(200) = N'Chuyến ' + @ma_chuyen + N' xuất phát';
            EXEC sys.sp_set_session_context @key = N'app_ghi_chu', @value = @ghi_chu_xp;

            UPDATE phuong_tien SET trang_thai = N'Đang chạy' WHERE ma_pt = @ma_pt;
            UPDATE kien_hang SET ma_kho_hien_tai = NULL
            WHERE ma_kien IN (SELECT ma_kien FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen);

            DECLARE @v_tt_moi VARCHAR(20) = CASE WHEN @loai = 'LIEN_KHO' THEN 'TT03' ELSE 'TT05' END;
            UPDATE don_hang SET ma_tt = @v_tt_moi
            WHERE ma_dh IN (
                SELECT k.ma_dh FROM kien_hang k JOIN chi_tiet_chuyen_giao c ON c.ma_kien = k.ma_kien
                WHERE c.ma_chuyen = @ma_chuyen
            ) AND dbo.fn_chuyen_trang_thai_hop_le(ma_tt, @v_tt_moi) = 1;
        END
        ELSE IF @new_tt = N'Hoàn thành'
        BEGIN
            IF @loai = 'GIAO_CUOI' AND EXISTS (
                SELECT 1 FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen AND trang_thai NOT IN (N'Đã giao', N'Thất bại')
            )
                THROW 50016, N'Còn kiện chưa có kết quả giao', 1;

            UPDATE chuyen_giao SET ngay_den = SYSDATETIME() WHERE ma_chuyen = @ma_chuyen;

            DECLARE @ghi_chu_ht NVARCHAR(200) = N'Chuyến ' + @ma_chuyen + N' hoàn thành';
            EXEC sys.sp_set_session_context @key = N'app_ghi_chu', @value = @ghi_chu_ht;

            UPDATE phuong_tien SET trang_thai = N'Sẵn sàng' WHERE ma_pt = @ma_pt;

            IF @loai = 'LIEN_KHO'
            BEGIN
                DECLARE @v_kho_den VARCHAR(20) = (SELECT ma_kho_den FROM tuyen_van_chuyen WHERE ma_tuyen = @ma_tuyen);
                UPDATE kien_hang SET ma_kho_hien_tai = @v_kho_den
                WHERE ma_kien IN (SELECT ma_kien FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen);

                UPDATE don_hang SET ma_tt = 'TT04'
                WHERE ma_dh IN (
                    SELECT k.ma_dh FROM kien_hang k JOIN chi_tiet_chuyen_giao c ON c.ma_kien = k.ma_kien
                    WHERE c.ma_chuyen = @ma_chuyen
                ) AND dbo.fn_chuyen_trang_thai_hop_le(ma_tt, 'TT04') = 1;
            END
            ELSE
            BEGIN
                UPDATE kien_hang SET ma_kho_hien_tai = @ma_kho_giao
                WHERE ma_kien IN (
                    SELECT ma_kien FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen AND trang_thai = N'Thất bại'
                );
            END
        END
        ELSE IF @new_tt = N'Đã hủy'
        BEGIN
            DELETE FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @ma_chuyen;
        END
    END
    ELSE
    BEGIN
        IF EXISTS (
            SELECT 1 FROM inserted i JOIN deleted d ON d.ma_chuyen = i.ma_chuyen
            WHERE d.trang_thai <> N'Chưa đi'
              AND (i.loai_chuyen <> d.loai_chuyen OR ISNULL(i.ma_tuyen,'') <> ISNULL(d.ma_tuyen,'')
                   OR ISNULL(i.ma_kho_giao,'') <> ISNULL(d.ma_kho_giao,'') OR i.ma_tx <> d.ma_tx OR i.ma_pt <> d.ma_pt)
        )
            THROW 50017, N'Chuyến đã xuất phát hoặc kết thúc, không được đổi tuyến/tài xế/phương tiện', 1;

        IF EXISTS (
            SELECT 1 FROM inserted i JOIN deleted d ON d.ma_chuyen = i.ma_chuyen
            JOIN phuong_tien p ON p.ma_pt = i.ma_pt
            WHERE i.ma_pt <> d.ma_pt AND dbo.fn_tong_khoi_luong_chuyen(i.ma_chuyen) > p.tai_trong
        )
            THROW 50018, N'Phương tiện mới không đủ tải trọng cho các kiện đã gán', 1;
    END
END;
GO

-- 4.6. CHI TIẾT CHUYẾN GIAO: Kiểm tra tải trọng, kho xuất phát, trạng thái đơn
CREATE OR ALTER TRIGGER trg_ctcg_ai ON chi_tiet_chuyen_giao AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ma_chuyen VARCHAR(20), @ma_kien VARCHAR(20);
    SELECT TOP 1 @ma_chuyen = ma_chuyen, @ma_kien = ma_kien FROM inserted;

    DECLARE @cg_tt NVARCHAR(50), @cg_loai VARCHAR(20), @cg_tuyen VARCHAR(20), @cg_kho_giao VARCHAR(20), @cg_pt VARCHAR(20);
    SELECT @cg_tt = trang_thai, @cg_loai = loai_chuyen, @cg_tuyen = ma_tuyen, @cg_kho_giao = ma_kho_giao, @cg_pt = ma_pt
    FROM chuyen_giao WITH (UPDLOCK) WHERE ma_chuyen = @ma_chuyen;

    IF @cg_tt <> N'Chưa đi' THROW 50019, N'Chỉ được gán kiện vào chuyến chưa xuất phát', 1;

    DECLARE @k_dh VARCHAR(20), @k_kho VARCHAR(20), @k_kl NUMERIC(10,2);
    SELECT @k_dh = ma_dh, @k_kho = ma_kho_hien_tai, @k_kl = khoi_luong FROM kien_hang WHERE ma_kien = @ma_kien;

    DECLARE @dh_tt VARCHAR(20), @dh_kho_nhan VARCHAR(20);
    SELECT @dh_tt = ma_tt, @dh_kho_nhan = ma_kho_nhan FROM don_hang WHERE ma_dh = @k_dh;

    DECLARE @v_kho_xuat VARCHAR(20);
    IF @cg_loai = 'LIEN_KHO'
    BEGIN
        IF @dh_tt NOT IN ('TT02', 'TT04') THROW 50020, N'Đơn chưa sẵn sàng vận chuyển liên kho', 1;
        SELECT @v_kho_xuat = ma_kho_di FROM tuyen_van_chuyen WHERE ma_tuyen = @cg_tuyen;
    END
    ELSE
    BEGIN
        IF @dh_tt NOT IN ('TT02', 'TT04', 'TT08') THROW 50021, N'Đơn chưa sẵn sàng giao hàng', 1;
        IF @dh_kho_nhan <> @cg_kho_giao THROW 50022, N'Kho giao của chuyến không phải kho nhận của đơn', 1;
        SET @v_kho_xuat = @cg_kho_giao;
    END

    IF ISNULL(@k_kho, '') <> ISNULL(@v_kho_xuat, '')
        THROW 50023, N'Kiện không nằm ở kho xuất phát của chuyến', 1;

    IF EXISTS (
        SELECT 1 FROM chi_tiet_chuyen_giao c JOIN chuyen_giao g ON g.ma_chuyen = c.ma_chuyen
        WHERE c.ma_kien = @ma_kien AND c.ma_chuyen <> @ma_chuyen AND g.trang_thai IN (N'Chưa đi', N'Đang đi')
    )
        THROW 50024, N'Kiện đã thuộc một chuyến giao khác chưa hoàn thành', 1;

    DECLARE @v_tai_trong NUMERIC(10,2) = (SELECT tai_trong FROM phuong_tien WHERE ma_pt = @cg_pt);
    IF dbo.fn_tong_khoi_luong_chuyen(@ma_chuyen) > @v_tai_trong
        THROW 50025, N'Vượt tải trọng phương tiện', 1;

    UPDATE chi_tiet_chuyen_giao
    SET trang_thai = N'Đã gán', thoi_gian_quet = NULL
    WHERE ma_chuyen = @ma_chuyen AND ma_kien = @ma_kien;
END;
GO

-- 4.7. THANH TOÁN
CREATE OR ALTER TRIGGER trg_thanh_toan_ai_au ON thanh_toan AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i JOIN don_hang d ON d.ma_dh = i.ma_dh WHERE d.ma_tt = 'TT07'
    )
        THROW 50026, N'Đơn hàng đã hủy/trả, không thể thanh toán', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN don_hang d ON d.ma_dh = i.ma_dh
        WHERE i.loai_khoan = 'COD' AND (d.cod <= 0 OR i.so_tien <> d.cod)
    )
        THROW 50027, N'Số tiền COD không hợp lệ hoặc đơn không có COD', 1;

    IF NOT EXISTS (SELECT 1 FROM deleted) AND EXISTS (
        SELECT 1 FROM inserted i JOIN don_hang d ON d.ma_dh = i.ma_dh
        WHERE i.loai_khoan = 'COD' AND i.trang_thai = N'Đã thanh toán' AND d.ma_tt <> 'TT05'
    )
        THROW 50028, N'COD chỉ được thu khi đơn đang ở trạng thái "Đang giao hàng"', 1;

    IF EXISTS (
        SELECT 1 FROM inserted i JOIN don_hang d ON d.ma_dh = i.ma_dh
        WHERE i.loai_khoan = 'PHI_VC' AND i.so_tien <> d.phi_van_chuyen
    )
        THROW 50029, N'Số tiền phí vận chuyển không khớp với đơn hàng', 1;
END;
GO

-- 4.8. NHẬT KÝ HỆ THỐNG (Audit Log JSON, tự động ẩn mật khẩu)
CREATE OR ALTER TRIGGER trg_nhat_ky_nguoi_dung ON nguoi_dung AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @act VARCHAR(10) = CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
                                    WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO nhat_ky_he_thong (ten_bang, hanh_dong, khoa, du_lieu_cu, du_lieu_moi, ma_nd)
    SELECT 'nguoi_dung', @act, COALESCE(i.ma_nd, d.ma_nd),
           (SELECT d.ma_nd, d.ten_dang_nhap, d.trang_thai, d.ma_vai_tro FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.ma_nd, i.ten_dang_nhap, i.trang_thai, i.ma_vai_tro FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           dbo.fn_phien_ma_nd()
    FROM inserted i FULL OUTER JOIN deleted d ON i.ma_nd = d.ma_nd;
END;
GO

CREATE OR ALTER TRIGGER trg_nhat_ky_don_hang ON don_hang AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @act VARCHAR(10) = CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
                                    WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO nhat_ky_he_thong (ten_bang, hanh_dong, khoa, du_lieu_cu, du_lieu_moi, ma_nd)
    SELECT 'don_hang', @act, COALESCE(i.ma_dh, d.ma_dh),
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           dbo.fn_phien_ma_nd()
    FROM inserted i FULL OUTER JOIN deleted d ON i.ma_dh = d.ma_dh;
END;
GO

CREATE OR ALTER TRIGGER trg_nhat_ky_thanh_toan ON thanh_toan AFTER INSERT, UPDATE, DELETE AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @act VARCHAR(10) = CASE WHEN EXISTS(SELECT 1 FROM inserted) AND EXISTS(SELECT 1 FROM deleted) THEN 'UPDATE'
                                    WHEN EXISTS(SELECT 1 FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    INSERT INTO nhat_ky_he_thong (ten_bang, hanh_dong, khoa, du_lieu_cu, du_lieu_moi, ma_nd)
    SELECT 'thanh_toan', @act, COALESCE(i.ma_tt_toan, d.ma_tt_toan),
           (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
           dbo.fn_phien_ma_nd()
    FROM inserted i FULL OUTER JOIN deleted d ON i.ma_tt_toan = d.ma_tt_toan;
END;
GO

-- =========================================================================================
-- PHẦN 5. 15 STORED PROCEDURES TÍCH HỢP TRANSACTION & TRY...CATCH (Mục 3.3 & 3.4)
-- =========================================================================================

-- 5.1. UC01: Đăng ký khách hàng (Có Transaction + Savepoint + Try...Catch)
CREATE OR ALTER PROCEDURE sp_dang_ky_khach_hang
    @p_ho_ten NVARCHAR(100),
    @p_sdt VARCHAR(15),
    @p_email VARCHAR(100),
    @p_mat_khau_hash VARCHAR(255),
    @p_ma_kh VARCHAR(20) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_dang_ky_khach_hang;

        IF COALESCE(TRIM(@p_ho_ten), N'') = N'' OR @p_sdt IS NULL OR COALESCE(@p_mat_khau_hash, '') = ''
            THROW 50101, N'Thiếu thông tin bắt buộc (họ tên, số điện thoại, mật khẩu)', 1;

        IF LEN(@p_sdt) <> 10 OR @p_sdt LIKE '%[^0-9]%'
            THROW 50102, N'Số điện thoại phải gồm 10 chữ số', 1;

        IF EXISTS (SELECT 1 FROM nguoi_dung WITH (UPDLOCK, HOLDLOCK) WHERE ten_dang_nhap = @p_sdt)
            THROW 50103, N'Tài khoản đã tồn tại!', 1;

        DECLARE @v_ma_kh_cu VARCHAR(20), @v_ma_nd_cu VARCHAR(20);
        SELECT @v_ma_kh_cu = ma_kh, @v_ma_nd_cu = ma_nd FROM khach_hang WITH (UPDLOCK, HOLDLOCK) WHERE sdt = @p_sdt;

        IF @v_ma_kh_cu IS NOT NULL AND @v_ma_nd_cu IS NOT NULL
            THROW 50103, N'Tài khoản đã tồn tại!', 1;

        IF @p_email IS NOT NULL AND EXISTS (
            SELECT 1 FROM khach_hang
            WHERE LOWER(email) = LOWER(@p_email) AND ISNULL(ma_kh, '') <> ISNULL(@v_ma_kh_cu, '') AND ma_nd IS NOT NULL
        )
            THROW 50104, N'Email đã được sử dụng bởi tài khoản khác', 1;

        DECLARE @t_nd TABLE (ma_nd VARCHAR(20));
        INSERT INTO nguoi_dung (ten_dang_nhap, mat_khau, ma_vai_tro)
        OUTPUT inserted.ma_nd INTO @t_nd
        VALUES (@p_sdt, @p_mat_khau_hash, 'KHACH_HANG');

        DECLARE @v_ma_nd VARCHAR(20) = (SELECT TOP 1 ma_nd FROM @t_nd);

        IF @v_ma_kh_cu IS NULL
        BEGIN
            DECLARE @t_kh TABLE (ma_kh VARCHAR(20));
            INSERT INTO khach_hang (ho_ten, sdt, email, ma_nd)
            OUTPUT inserted.ma_kh INTO @t_kh
            VALUES (TRIM(@p_ho_ten), @p_sdt, @p_email, @v_ma_nd);
            SELECT TOP 1 @p_ma_kh = ma_kh FROM @t_kh;
        END
        ELSE
        BEGIN
            UPDATE khach_hang
            SET ho_ten = TRIM(@p_ho_ten), email = COALESCE(@p_email, email), ma_nd = @v_ma_nd
            WHERE ma_kh = @v_ma_kh_cu;
            SET @p_ma_kh = @v_ma_kh_cu;
        END

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_dang_ky_khach_hang;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.2. UC04: Tạo đơn hàng và danh sách kiện hàng (Có Transaction + Try...Catch)
CREATE OR ALTER PROCEDURE sp_tao_don_hang
    @p_ma_kh_gui VARCHAR(20),
    @p_ten_nguoi_nhan NVARCHAR(100),
    @p_sdt_nhan VARCHAR(15),
    @p_dia_chi_lay NVARCHAR(MAX),
    @p_dia_chi_giao NVARCHAR(MAX),
    @p_ma_kho_gui VARCHAR(20),
    @p_ma_kho_nhan VARCHAR(20),
    @p_cod NUMERIC(12,2),
    @p_kien NVARCHAR(MAX),
    @p_ma_nd VARCHAR(20),
    @p_ma_dh VARCHAR(20) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_tao_don_hang;

        IF NOT EXISTS (SELECT 1 FROM khach_hang WHERE ma_kh = @p_ma_kh_gui)
            THROW 50105, N'Không tìm thấy khách hàng gửi', 1;

        IF COALESCE(TRIM(@p_ten_nguoi_nhan), N'') = N'' OR COALESCE(TRIM(@p_dia_chi_lay), N'') = N'' OR COALESCE(TRIM(@p_dia_chi_giao), N'') = N''
            THROW 50106, N'Thiếu thông tin bắt buộc (người nhận, địa chỉ lấy/giao)', 1;

        IF @p_sdt_nhan IS NULL OR LEN(@p_sdt_nhan) <> 10 OR @p_sdt_nhan LIKE '%[^0-9]%'
            THROW 50107, N'Số điện thoại người nhận phải gồm 10 chữ số', 1;

        IF COALESCE(@p_cod, 0) < 0 THROW 50108, N'Tiền COD không được âm', 1;

        IF NOT EXISTS (SELECT 1 FROM kho WHERE ma_kho = @p_ma_kho_gui) OR NOT EXISTS (SELECT 1 FROM kho WHERE ma_kho = @p_ma_kho_nhan)
            THROW 50109, N'Kho gửi/kho nhận không tồn tại', 1;

        IF @p_ma_kho_gui <> @p_ma_kho_nhan AND dbo.fn_tim_tuyen(@p_ma_kho_gui, @p_ma_kho_nhan) IS NULL
            THROW 50110, N'Chưa hỗ trợ tuyến này', 1;

        IF @p_kien IS NULL OR ISJSON(@p_kien) = 0 OR NOT EXISTS (SELECT 1 FROM OPENJSON(@p_kien))
            THROW 50111, N'Đơn hàng phải có ít nhất một kiện hàng', 1;

        IF EXISTS (
            SELECT 1 FROM OPENJSON(@p_kien) WITH (
                khoi_luong NUMERIC(10,2) '$.khoi_luong',
                dai NUMERIC(8,2) '$.dai',
                rong NUMERIC(8,2) '$.rong',
                cao NUMERIC(8,2) '$.cao'
            ) WHERE khoi_luong IS NULL OR dai IS NULL OR rong IS NULL OR cao IS NULL
        )
            THROW 50112, N'Mỗi kiện cần đủ khối lượng, dài, rộng, cao', 1;

        EXEC sp_dat_phien @p_ma_nd, N'Tạo đơn hàng';
        DECLARE @v_ma_kh_nhan VARCHAR(20) = (SELECT ma_kh FROM khach_hang WHERE sdt = @p_sdt_nhan);

        DECLARE @t_dh TABLE (ma_dh VARCHAR(20));
        INSERT INTO don_hang (ma_kh_gui, ma_kh_nhan, sdt_nhan, ten_nguoi_nhan, dia_chi_lay, dia_chi_giao, ma_kho_gui, ma_kho_nhan, cod)
        OUTPUT inserted.ma_dh INTO @t_dh
        VALUES (@p_ma_kh_gui, @v_ma_kh_nhan, @p_sdt_nhan, TRIM(@p_ten_nguoi_nhan), @p_dia_chi_lay, @p_dia_chi_giao, @p_ma_kho_gui, @p_ma_kho_nhan, COALESCE(@p_cod, 0));

        SELECT TOP 1 @p_ma_dh = ma_dh FROM @t_dh;

        INSERT INTO kien_hang (ma_dh, khoi_luong, dai, rong, cao, loai_hang)
        SELECT @p_ma_dh, khoi_luong, dai, rong, cao, loai_hang
        FROM OPENJSON(@p_kien) WITH (
            khoi_luong NUMERIC(10,2) '$.khoi_luong',
            dai        NUMERIC(8,2)  '$.dai',
            rong       NUMERIC(8,2)  '$.rong',
            cao        NUMERIC(8,2)  '$.cao',
            loai_hang  NVARCHAR(50)  '$.loai_hang'
        );

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_tao_don_hang;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.3. UC08: Tiếp nhận đơn tại bưu cục (Có Transaction + UPDLOCK + Try...Catch)
CREATE OR ALTER PROCEDURE sp_tiep_nhan_don
    @p_ma_dh VARCHAR(20),
    @p_ma_nv VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_tiep_nhan_don;

        DECLARE @v_kho_gui VARCHAR(20), @v_tt VARCHAR(20);
        SELECT @v_kho_gui = ma_kho_gui, @v_tt = ma_tt FROM don_hang WITH (UPDLOCK, ROWLOCK) WHERE ma_dh = @p_ma_dh;
        IF @v_tt IS NULL THROW 50113, N'Không tìm thấy đơn hàng!', 1;

        DECLARE @v_chuc_vu NVARCHAR(50), @v_kho_nv VARCHAR(20);
        SELECT @v_chuc_vu = chuc_vu, @v_kho_nv = ma_kho FROM nhan_vien WHERE ma_nv = @p_ma_nv;
        IF @v_chuc_vu IS NULL OR @v_chuc_vu <> N'Nhân viên bưu cục'
            THROW 50114, N'Chỉ nhân viên bưu cục mới được tiếp nhận đơn', 1;

        IF ISNULL(@v_kho_nv, '') <> ISNULL(@v_kho_gui, '')
            THROW 50115, N'Nhân viên không thuộc bưu cục gửi của đơn hàng', 1;

        IF @v_tt <> 'TT01' THROW 50116, N'Đơn hàng không ở trạng thái "Mới tạo"', 1;

        DECLARE @gc NVARCHAR(4000) = COALESCE(@p_ghi_chu, N'Tiếp nhận đơn tại bưu cục');
        EXEC sp_dat_phien @p_ma_nd, @gc;
        UPDATE kien_hang SET ma_kho_hien_tai = @v_kho_nv WHERE ma_dh = @p_ma_dh;
        UPDATE don_hang  SET ma_tt = 'TT02', ma_nv = @p_ma_nv WHERE ma_dh = @p_ma_dh;

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_tiep_nhan_don;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.4. UC10: Cập nhật trạng thái thủ công
CREATE OR ALTER PROCEDURE sp_cap_nhat_trang_thai
    @p_ma_dh VARCHAR(20),
    @p_ma_tt_moi VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_cap_nhat_trang_thai;

        DECLARE @v_tt VARCHAR(20) = (SELECT ma_tt FROM don_hang WITH (UPDLOCK, ROWLOCK) WHERE ma_dh = @p_ma_dh);
        IF @v_tt IS NULL THROW 50113, N'Không tìm thấy đơn hàng!', 1;
        IF NOT EXISTS (SELECT 1 FROM trang_thai_dh WHERE ma_trang_thai = @p_ma_tt_moi)
            THROW 50117, N'Trạng thái không tồn tại', 1;
        IF @v_tt = @p_ma_tt_moi THROW 50118, N'Đơn hàng đã ở trạng thái này', 1;

        EXEC sp_dat_phien @p_ma_nd, @p_ghi_chu;
        UPDATE don_hang SET ma_tt = @p_ma_tt_moi WHERE ma_dh = @p_ma_dh;

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_cap_nhat_trang_thai;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.5. UC09: Nhập kho / xuất kho thủ công cho kiện
CREATE OR ALTER PROCEDURE sp_nhap_kho_kien
    @p_ma_kien VARCHAR(20),
    @p_ma_kho VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_nhap_kho_kien;

        DECLARE @v_dh VARCHAR(20), @v_kho_ht VARCHAR(20), @v_found BIT = 0;
        SELECT @v_dh = ma_dh, @v_kho_ht = ma_kho_hien_tai, @v_found = 1 FROM kien_hang WITH (UPDLOCK, ROWLOCK) WHERE ma_kien = @p_ma_kien;
        IF @v_found = 0 THROW 50119, N'Không tìm thấy kiện hàng!', 1;
        IF NOT EXISTS (SELECT 1 FROM kho WHERE ma_kho = @p_ma_kho) THROW 50120, N'Kho không tồn tại', 1;
        IF @v_kho_ht IS NOT NULL THROW 50121, N'Kiện đang ở trong kho, hãy xuất kho trước', 1;

        DECLARE @gc NVARCHAR(4000) = COALESCE(@p_ghi_chu, N'Nhập kho ' + @p_ma_kho);
        EXEC sp_dat_phien @p_ma_nd, @gc;
        UPDATE kien_hang SET ma_kho_hien_tai = @p_ma_kho WHERE ma_kien = @p_ma_kien;
        UPDATE don_hang  SET ma_tt = 'TT04' WHERE ma_dh = @v_dh AND ma_tt = 'TT03';

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_nhap_kho_kien;
        END;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_xuat_kho_kien
    @p_ma_kien VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_xuat_kho_kien;

        DECLARE @v_dh VARCHAR(20), @v_kho_ht VARCHAR(20), @v_found BIT = 0;
        SELECT @v_dh = ma_dh, @v_kho_ht = ma_kho_hien_tai, @v_found = 1 FROM kien_hang WITH (UPDLOCK, ROWLOCK) WHERE ma_kien = @p_ma_kien;
        IF @v_found = 0 THROW 50119, N'Không tìm thấy kiện hàng!', 1;
        IF @v_kho_ht IS NULL THROW 50122, N'Kiện hiện không nằm trong kho nào', 1;

        DECLARE @gc NVARCHAR(4000) = COALESCE(@p_ghi_chu, N'Xuất kho ' + @v_kho_ht);
        EXEC sp_dat_phien @p_ma_nd, @gc;
        UPDATE kien_hang SET ma_kho_hien_tai = NULL WHERE ma_kien = @p_ma_kien;
        UPDATE don_hang  SET ma_tt = 'TT03' WHERE ma_dh = @v_dh AND dbo.fn_chuyen_trang_thai_hop_le(ma_tt, 'TT03') = 1;

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_xuat_kho_kien;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.6. UC12: Lập chuyến giao
CREATE OR ALTER PROCEDURE sp_tao_chuyen_giao
    @p_loai VARCHAR(20),
    @p_ma_tuyen VARCHAR(20),
    @p_ma_kho_giao VARCHAR(20),
    @p_ma_tx VARCHAR(20),
    @p_ma_pt VARCHAR(20),
    @p_ngay_xuat_phat DATETIME2,
    @p_ma_nv_dp VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ngay_den_du_kien DATETIME2 = NULL,
    @p_ma_chuyen VARCHAR(20) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_tao_chuyen_giao;

        IF @p_loai NOT IN ('LIEN_KHO', 'GIAO_CUOI') THROW 50123, N'Loại chuyến không hợp lệ', 1;
        IF @p_ngay_xuat_phat IS NULL THROW 50124, N'Thiếu ngày xuất phát', 1;

        DECLARE @v_den DATETIME2 = @p_ngay_den_du_kien;
        IF @p_loai = 'LIEN_KHO'
        BEGIN
            IF @p_ma_tuyen IS NULL THROW 50125, N'Chuyến liên kho phải chọn tuyến vận chuyển', 1;
            DECLARE @v_gio NUMERIC(6,2) = (SELECT thoi_gian_du_kien_gio FROM tuyen_van_chuyen WHERE ma_tuyen = @p_ma_tuyen);
            IF @v_gio IS NULL THROW 50126, N'Không tìm thấy tuyến vận chuyển', 1;
            SET @v_den = COALESCE(@v_den, DATEADD(SECOND, CAST(@v_gio * 3600 AS INT), @p_ngay_xuat_phat));
        END
        ELSE
        BEGIN
            IF @p_ma_kho_giao IS NULL THROW 50127, N'Chuyến giao cuối phải chọn kho xuất phát', 1;
            IF @v_den IS NULL THROW 50128, N'Chuyến giao cuối phải có ngày đến dự kiến', 1;
        END

        IF NOT EXISTS (SELECT 1 FROM nhan_vien WHERE ma_nv = @p_ma_nv_dp AND chuc_vu = N'Nhân viên điều phối')
            THROW 50129, N'Chỉ nhân viên điều phối mới được lập chuyến', 1;
        IF NOT EXISTS (SELECT 1 FROM tai_xe WHERE ma_tx = @p_ma_tx) THROW 50130, N'Không tìm thấy tài xế', 1;
        IF NOT EXISTS (SELECT 1 FROM phuong_tien WHERE ma_pt = @p_ma_pt) THROW 50131, N'Không tìm thấy phương tiện', 1;

        EXEC sp_dat_phien @p_ma_nd, N'Lập chuyến giao';
        DECLARE @t_cg TABLE (ma_chuyen VARCHAR(20));
        INSERT INTO chuyen_giao (loai_chuyen, ma_tuyen, ma_kho_giao, ma_tx, ma_pt, ma_nv_dieu_phoi, ngay_xuat_phat, ngay_den_du_kien)
        OUTPUT inserted.ma_chuyen INTO @t_cg
        VALUES (@p_loai,
                CASE WHEN @p_loai = 'LIEN_KHO'  THEN @p_ma_tuyen END,
                CASE WHEN @p_loai = 'GIAO_CUOI' THEN @p_ma_kho_giao END,
                @p_ma_tx, @p_ma_pt, @p_ma_nv_dp, @p_ngay_xuat_phat, @v_den);

        SELECT TOP 1 @p_ma_chuyen = ma_chuyen FROM @t_cg;

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_tao_chuyen_giao;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.7. Gán kiện vào chuyến (Có Transaction + Khóa UPDLOCK chống Concurrency)
CREATE OR ALTER PROCEDURE sp_gan_kien_vao_chuyen
    @p_ma_chuyen VARCHAR(20),
    @p_ma_kien VARCHAR(20),
    @p_ma_nd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_gan_kien_vao_chuyen;

        DECLARE @v_dummy VARCHAR(20);
        SELECT @v_dummy = ma_chuyen FROM chuyen_giao WITH (UPDLOCK, ROWLOCK) WHERE ma_chuyen = @p_ma_chuyen;
        SELECT @v_dummy = ma_kien   FROM kien_hang   WITH (UPDLOCK, ROWLOCK) WHERE ma_kien = @p_ma_kien;

        IF EXISTS (SELECT 1 FROM chi_tiet_chuyen_giao WHERE ma_chuyen = @p_ma_chuyen AND ma_kien = @p_ma_kien)
            THROW 50132, N'Kiện đã có trong chuyến giao này', 1;

        DECLARE @gc NVARCHAR(4000) = N'Gán kiện vào chuyến ' + @p_ma_chuyen;
        EXEC sp_dat_phien @p_ma_nd, @gc;
        INSERT INTO chi_tiet_chuyen_giao (ma_chuyen, ma_kien) VALUES (@p_ma_chuyen, @p_ma_kien);

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_gan_kien_vao_chuyen;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.8. UC14: Tài xế quét kiện lên xe
CREATE OR ALTER PROCEDURE sp_quet_kien
    @p_ma_chuyen VARCHAR(20),
    @p_ma_kien VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF dbo.fn_la_tai_xe_cua_chuyen(@p_ma_chuyen, @p_ma_nd) = 0
        THROW 50133, N'Bạn không được phân công chuyến này', 1;

    DECLARE @v_tt NVARCHAR(50) = (SELECT trang_thai FROM chuyen_giao WHERE ma_chuyen = @p_ma_chuyen);
    IF @v_tt <> N'Chưa đi' THROW 50134, N'Chỉ quét kiện lên xe khi chuyến chưa xuất phát', 1;

    UPDATE chi_tiet_chuyen_giao
    SET trang_thai = N'Đã quét', thoi_gian_quet = SYSDATETIME(), ghi_chu = COALESCE(@p_ghi_chu, ghi_chu)
    WHERE ma_chuyen = @p_ma_chuyen AND ma_kien = @p_ma_kien;

    IF @@ROWCOUNT = 0 THROW 50135, N'Kiện không thuộc chuyến này', 1;
END;
GO

CREATE OR ALTER PROCEDURE sp_xuat_phat_chuyen
    @p_ma_chuyen VARCHAR(20),
    @p_ma_nd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_dat_phien @p_ma_nd;
    UPDATE chuyen_giao SET trang_thai = N'Đang đi' WHERE ma_chuyen = @p_ma_chuyen;
    IF @@ROWCOUNT = 0 THROW 50136, N'Không tìm thấy chuyến giao', 1;
END;
GO

CREATE OR ALTER PROCEDURE sp_hoan_thanh_chuyen
    @p_ma_chuyen VARCHAR(20),
    @p_ma_nd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_dat_phien @p_ma_nd;
    UPDATE chuyen_giao SET trang_thai = N'Hoàn thành' WHERE ma_chuyen = @p_ma_chuyen;
    IF @@ROWCOUNT = 0 THROW 50136, N'Không tìm thấy chuyến giao', 1;
END;
GO

CREATE OR ALTER PROCEDURE sp_huy_chuyen
    @p_ma_chuyen VARCHAR(20),
    @p_ma_nd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC sp_dat_phien @p_ma_nd;
    UPDATE chuyen_giao SET trang_thai = N'Đã hủy' WHERE ma_chuyen = @p_ma_chuyen;
    IF @@ROWCOUNT = 0 THROW 50136, N'Không tìm thấy chuyến giao', 1;
END;
GO

-- 5.9. UC14: Giao kiện thành công (Có Transaction + Tự động thu COD + Hoàn tất đơn)
CREATE OR ALTER PROCEDURE sp_giao_thanh_cong
    @p_ma_chuyen VARCHAR(20),
    @p_ma_kien VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ghi_chu NVARCHAR(4000) = NULL,
    @p_nguoi_thu NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_giao_thanh_cong;

        IF dbo.fn_la_tai_xe_cua_chuyen(@p_ma_chuyen, @p_ma_nd) = 0
            THROW 50133, N'Bạn không được phân công chuyến này', 1;

        DECLARE @v_loai VARCHAR(20), @v_tt NVARCHAR(50);
        SELECT @v_loai = loai_chuyen, @v_tt = trang_thai FROM chuyen_giao WHERE ma_chuyen = @p_ma_chuyen;
        IF @v_loai <> 'GIAO_CUOI' OR @v_tt <> N'Đang đi'
            THROW 50137, N'Chỉ giao hàng khi chuyến giao cuối đang chạy', 1;

        DECLARE @v_ma_dh VARCHAR(20), @v_cod NUMERIC(12,2), @v_ten_nhan NVARCHAR(100);
        SELECT @v_ma_dh = d.ma_dh, @v_cod = d.cod, @v_ten_nhan = d.ten_nguoi_nhan
        FROM don_hang d WITH (UPDLOCK, ROWLOCK) JOIN kien_hang k ON k.ma_dh = d.ma_dh
        WHERE k.ma_kien = @p_ma_kien;

        IF @v_ma_dh IS NULL THROW 50119, N'Không tìm thấy kiện hàng!', 1;

        DECLARE @gc NVARCHAR(4000) = COALESCE(@p_ghi_chu, N'Giao hàng thành công');
        EXEC sp_dat_phien @p_ma_nd, @gc;

        UPDATE chi_tiet_chuyen_giao
        SET trang_thai = N'Đã giao', ghi_chu = COALESCE(@p_ghi_chu, ghi_chu)
        WHERE ma_chuyen = @p_ma_chuyen AND ma_kien = @p_ma_kien;
        IF @@ROWCOUNT = 0 THROW 50135, N'Kiện không thuộc chuyến này', 1;

        IF NOT EXISTS (
            SELECT 1 FROM kien_hang k WHERE k.ma_dh = @v_ma_dh
              AND NOT EXISTS (SELECT 1 FROM chi_tiet_chuyen_giao c WHERE c.ma_kien = k.ma_kien AND c.trang_thai = N'Đã giao')
        )
        BEGIN
            IF @v_cod > 0 AND NOT EXISTS (
                SELECT 1 FROM thanh_toan WHERE ma_dh = @v_ma_dh AND loai_khoan = 'COD' AND trang_thai = N'Đã thanh toán'
            )
            BEGIN
                INSERT INTO thanh_toan (ma_dh, loai_khoan, so_tien, phuong_thuc, trang_thai, nguoi_thanh_toan)
                VALUES (@v_ma_dh, 'COD', @v_cod, N'COD', N'Đã thanh toán', COALESCE(@p_nguoi_thu, @v_ten_nhan));
            END
            UPDATE don_hang SET ma_tt = 'TT06' WHERE ma_dh = @v_ma_dh;
        END

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_giao_thanh_cong;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.10. UC14: Giao không thành công
CREATE OR ALTER PROCEDURE sp_giao_that_bai
    @p_ma_chuyen VARCHAR(20),
    @p_ma_kien VARCHAR(20),
    @p_ma_nd VARCHAR(20),
    @p_ly_do NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_giao_that_bai;

        IF dbo.fn_la_tai_xe_cua_chuyen(@p_ma_chuyen, @p_ma_nd) = 0
            THROW 50133, N'Bạn không được phân công chuyến này', 1;

        IF COALESCE(TRIM(@p_ly_do), N'') = N''
            THROW 50138, N'Phải nhập lý do giao không thành công', 1;

        DECLARE @v_loai VARCHAR(20), @v_tt NVARCHAR(50);
        SELECT @v_loai = loai_chuyen, @v_tt = trang_thai FROM chuyen_giao WHERE ma_chuyen = @p_ma_chuyen;
        IF @v_loai <> 'GIAO_CUOI' OR @v_tt <> N'Đang đi'
            THROW 50137, N'Chỉ cập nhật kết quả giao khi chuyến giao cuối đang chạy', 1;

        DECLARE @v_ma_dh VARCHAR(20) = (SELECT ma_dh FROM kien_hang WHERE ma_kien = @p_ma_kien);
        IF @v_ma_dh IS NULL THROW 50119, N'Không tìm thấy kiện hàng!', 1;

        DECLARE @gc NVARCHAR(4000) = LEFT(N'Giao không thành công: ' + @p_ly_do, 4000);
        EXEC sp_dat_phien @p_ma_nd, @gc;

        UPDATE chi_tiet_chuyen_giao SET trang_thai = N'Thất bại', ghi_chu = @p_ly_do
        WHERE ma_chuyen = @p_ma_chuyen AND ma_kien = @p_ma_kien;
        IF @@ROWCOUNT = 0 THROW 50135, N'Kiện không thuộc chuyến này', 1;

        UPDATE don_hang SET ma_tt = 'TT08' WHERE ma_dh = @v_ma_dh AND ma_tt = 'TT05';

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_giao_that_bai;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.11. UC07: Người nhận xác nhận đã nhận hàng
CREATE OR ALTER PROCEDURE sp_xac_nhan_nhan_hang
    @p_ma_dh VARCHAR(20),
    @p_ma_nd VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @v_tt VARCHAR(20);
    SELECT @v_tt = d.ma_tt
    FROM don_hang d WITH (UPDLOCK) JOIN khach_hang k ON k.ma_kh = d.ma_kh_nhan
    WHERE d.ma_dh = @p_ma_dh AND k.ma_nd = @p_ma_nd;

    IF @v_tt IS NULL THROW 50139, N'Bạn không phải người nhận của đơn hàng này', 1;
    IF @v_tt <> 'TT05' THROW 50140, N'Đơn hàng chưa ở trạng thái "Đang giao hàng"', 1;

    EXEC sp_dat_phien @p_ma_nd, N'Người nhận xác nhận đã nhận hàng';
    UPDATE don_hang SET ma_tt = 'TT06' WHERE ma_dh = @p_ma_dh;
END;
GO

-- 5.12. UC06: Thanh toán (Có Transaction + UPDLOCK + Try...Catch)
CREATE OR ALTER PROCEDURE sp_thanh_toan
    @p_ma_dh VARCHAR(20),
    @p_loai_khoan VARCHAR(10),
    @p_phuong_thuc NVARCHAR(50),
    @p_nguoi_thanh_toan NVARCHAR(100),
    @p_ma_nd VARCHAR(20),
    @p_ma_ttoan VARCHAR(20) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @trancount INT = @@TRANCOUNT;
    BEGIN TRY
        IF @trancount = 0 BEGIN TRAN;
        ELSE SAVE TRAN sp_thanh_toan;

        DECLARE @v_phi NUMERIC(12,2), @v_cod NUMERIC(12,2), @v_found BIT = 0;
        SELECT @v_phi = phi_van_chuyen, @v_cod = cod, @v_found = 1 FROM don_hang WITH (UPDLOCK, ROWLOCK) WHERE ma_dh = @p_ma_dh;
        IF @v_found = 0 THROW 50113, N'Không tìm thấy đơn hàng!', 1;

        DECLARE @v_so_tien NUMERIC(12,2);
        IF @p_loai_khoan = 'PHI_VC' SET @v_so_tien = @v_phi;
        ELSE IF @p_loai_khoan = 'COD' SET @v_so_tien = @v_cod;
        ELSE THROW 50141, N'Loại khoản không hợp lệ (PHI_VC | COD)', 1;

        IF @v_so_tien <= 0 THROW 50142, N'Không có khoản cần thanh toán', 1;

        DECLARE @gc NVARCHAR(4000) = N'Thanh toán ' + @p_loai_khoan;
        EXEC sp_dat_phien @p_ma_nd, @gc;

        DECLARE @t_tt TABLE (ma_tt_toan VARCHAR(20));
        INSERT INTO thanh_toan (ma_dh, loai_khoan, so_tien, phuong_thuc, trang_thai, nguoi_thanh_toan)
        OUTPUT inserted.ma_tt_toan INTO @t_tt
        VALUES (@p_ma_dh, @p_loai_khoan, @v_so_tien, @p_phuong_thuc, N'Đã thanh toán', @p_nguoi_thanh_toan);

        SELECT TOP 1 @p_ma_ttoan = ma_tt_toan FROM @t_tt;

        IF @trancount = 0 COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 AND @trancount = 0 ROLLBACK TRAN;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @trancount = 0 ROLLBACK TRAN;
            ELSE ROLLBACK TRAN sp_thanh_toan;
        END;
        THROW;
    END CATCH
END;
GO

-- 5.13. UC15: Khóa / mở khóa tài khoản
CREATE OR ALTER PROCEDURE sp_khoa_tai_khoan
    @p_ma_nd VARCHAR(20),
    @p_khoa BIT,
    @p_xac_nhan BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM nguoi_dung WHERE ma_nd = @p_ma_nd)
        THROW 50143, N'Không tìm thấy tài khoản', 1;

    IF @p_khoa = 1
    BEGIN
        DECLARE @v_so BIGINT = dbo.fn_so_viec_dang_xu_ly(@p_ma_nd);
        IF @v_so > 0 AND @p_xac_nhan = 0
        BEGIN
            DECLARE @msg NVARCHAR(300) = FORMATMESSAGE(N'Cảnh báo: tài khoản còn %I64d công việc dở dang. Gọi lại với @p_xac_nhan = 1 để xác nhận khóa.', @v_so);
            THROW 50144, @msg, 1;
        END
    END

    UPDATE nguoi_dung SET trang_thai = CASE WHEN @p_khoa = 1 THEN N'Bị khóa' ELSE N'Hoạt động' END
    WHERE ma_nd = @p_ma_nd;
END;
GO

-- =========================================================================================
-- PHẦN 6. BẢO MẬT & PHÂN QUYỀN: 5 LOGINS, 5 ROLES, GRANT / DENY / REVOKE (Mục 3.5)
-- =========================================================================================
USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_ute_admin')
    CREATE LOGIN login_ute_admin WITH PASSWORD = 'UteAdmin@2026!', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_ute_nvbc')
    CREATE LOGIN login_ute_nvbc  WITH PASSWORD = 'UteNvbc@2026!',  CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_ute_nvdp')
    CREATE LOGIN login_ute_nvdp  WITH PASSWORD = 'UteNvdp@2026!',  CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_ute_taixe')
    CREATE LOGIN login_ute_taixe WITH PASSWORD = 'UteTaixe@2026!', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'login_ute_khach')
    CREATE LOGIN login_ute_khach WITH PASSWORD = 'UteKhach@2026!', CHECK_POLICY = OFF;
GO

USE UTEEXPRESS;
GO
CREATE ROLE role_quan_tri;
CREATE ROLE role_nv_buu_cuc;
CREATE ROLE role_nv_dieu_phoi;
CREATE ROLE role_tai_xe;
CREATE ROLE role_khach_hang;

CREATE USER user_ute_admin FOR LOGIN login_ute_admin;
CREATE USER user_ute_nvbc  FOR LOGIN login_ute_nvbc;
CREATE USER user_ute_nvdp  FOR LOGIN login_ute_nvdp;
CREATE USER user_ute_taixe FOR LOGIN login_ute_taixe;
CREATE USER user_ute_khach FOR LOGIN login_ute_khach;

ALTER ROLE role_quan_tri      ADD MEMBER user_ute_admin;
ALTER ROLE role_nv_buu_cuc    ADD MEMBER user_ute_nvbc;
ALTER ROLE role_nv_dieu_phoi  ADD MEMBER user_ute_nvdp;
ALTER ROLE role_tai_xe        ADD MEMBER user_ute_taixe;
ALTER ROLE role_khach_hang    ADD MEMBER user_ute_khach;

-- 1. Quyền Quản trị viên
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO role_quan_tri;
DENY UPDATE, DELETE ON dbo.lich_su_trang_thai TO role_quan_tri;
DENY UPDATE, DELETE ON dbo.nhat_ky_he_thong   TO role_quan_tri;

-- 2. Quyền Nhân viên bưu cục
GRANT SELECT ON dbo.v_don_hang_chi_tiet   TO role_nv_buu_cuc;
GRANT SELECT ON dbo.v_ton_kho             TO role_nv_buu_cuc;
GRANT SELECT ON dbo.v_lich_su_van_chuyen  TO role_nv_buu_cuc;
GRANT SELECT ON dbo.don_hang              TO role_nv_buu_cuc;
GRANT SELECT ON dbo.kien_hang             TO role_nv_buu_cuc;
GRANT EXECUTE ON dbo.sp_tao_don_hang      TO role_nv_buu_cuc;
GRANT EXECUTE ON dbo.sp_tiep_nhan_don     TO role_nv_buu_cuc;
GRANT EXECUTE ON dbo.sp_nhap_kho_kien     TO role_nv_buu_cuc;
GRANT EXECUTE ON dbo.sp_xuat_kho_kien     TO role_nv_buu_cuc;
GRANT EXECUTE ON dbo.sp_thanh_toan        TO role_nv_buu_cuc;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.nguoi_dung       TO role_nv_buu_cuc;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.nhat_ky_he_thong TO role_nv_buu_cuc;

-- 3. Quyền Nhân viên điều phối
GRANT SELECT ON dbo.v_chuyen_giao_chi_tiet  TO role_nv_dieu_phoi;
GRANT SELECT ON dbo.v_kien_trong_chuyen     TO role_nv_dieu_phoi;
GRANT SELECT ON dbo.v_ton_kho               TO role_nv_dieu_phoi;
GRANT SELECT ON dbo.tuyen_van_chuyen        TO role_nv_dieu_phoi;
GRANT SELECT ON dbo.fn_tai_xe_ranh          TO role_nv_dieu_phoi;
GRANT SELECT ON dbo.fn_xe_ranh              TO role_nv_dieu_phoi;
GRANT EXECUTE ON dbo.sp_tao_chuyen_giao     TO role_nv_dieu_phoi;
GRANT EXECUTE ON dbo.sp_gan_kien_vao_chuyen TO role_nv_dieu_phoi;
GRANT EXECUTE ON dbo.sp_huy_chuyen          TO role_nv_dieu_phoi;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.nguoi_dung TO role_nv_dieu_phoi;

-- 4. Quyền Tài xế
GRANT SELECT ON dbo.v_chuyen_giao_chi_tiet  TO role_tai_xe;
GRANT SELECT ON dbo.v_kien_trong_chuyen     TO role_tai_xe;
GRANT EXECUTE ON dbo.sp_quet_kien           TO role_tai_xe;
GRANT EXECUTE ON dbo.sp_xuat_phat_chuyen    TO role_tai_xe;
GRANT EXECUTE ON dbo.sp_giao_thanh_cong     TO role_tai_xe;
GRANT EXECUTE ON dbo.sp_giao_that_bai       TO role_tai_xe;
GRANT EXECUTE ON dbo.sp_hoan_thanh_chuyen   TO role_tai_xe;
DENY INSERT, UPDATE, DELETE ON dbo.don_hang   TO role_tai_xe;
DENY INSERT, UPDATE, DELETE ON dbo.thanh_toan TO role_tai_xe;

-- 5. Quyền Khách hàng
GRANT SELECT ON dbo.v_tra_cuu_cong_khai       TO role_khach_hang;
GRANT SELECT ON dbo.v_don_hang_chi_tiet       TO role_khach_hang;
GRANT SELECT ON dbo.v_lich_su_van_chuyen      TO role_khach_hang;
GRANT EXECUTE ON dbo.fn_tinh_phi_van_chuyen   TO role_khach_hang;
GRANT EXECUTE ON dbo.sp_dang_ky_khach_hang    TO role_khach_hang;
GRANT EXECUTE ON dbo.sp_tao_don_hang          TO role_khach_hang;
GRANT EXECUTE ON dbo.sp_xac_nhan_nhan_hang    TO role_khach_hang;
GRANT EXECUTE ON dbo.sp_thanh_toan            TO role_khach_hang;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.nguoi_dung TO role_khach_hang;
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.nhan_vien  TO role_khach_hang;

-- 6. Minh họa cấp rồi thu hồi quyền bằng REVOKE
GRANT EXECUTE ON dbo.sp_cap_nhat_trang_thai TO role_nv_buu_cuc;
REVOKE EXECUTE ON dbo.sp_cap_nhat_trang_thai FROM role_nv_buu_cuc;
GO

-- =========================================================================================
-- PHẦN 7. NẠP TOÀN BỘ DỮ LIỆU DANH MỤC & DỮ LIỆU MẪU MỞ RỘNG (SEED + SEED_EXTRA)
-- =========================================================================================

-- Tạm tắt Trigger để nạp nhanh dữ liệu lịch sử mẫu và trạng thái có sẵn
EXEC sp_msforeachtable 'DISABLE TRIGGER ALL ON ?';
GO

BEGIN TRAN;

-- 7.1. Danh mục Vai trò, Trạng thái, Quy trình trạng thái, Cấu hình hệ thống
INSERT INTO vai_tro (ma_vai_tro, ten_vai_tro, mo_ta) VALUES
('ADMIN',      N'Quản trị viên',       N'Quản lý toàn bộ hệ thống'),
('NVBC',       N'Nhân viên bưu cục',   N'Tiếp nhận và xử lý đơn tại kho'),
('NVDP',       N'Nhân viên điều phối', N'Quản lý tuyến và chuyến giao'),
('TAI_XE',     N'Tài xế',              N'Thực hiện vận chuyển và giao hàng'),
('KHACH_HANG', N'Khách hàng',          N'Người gửi và người nhận hàng');

INSERT INTO trang_thai_dh (ma_trang_thai, ten_trang_thai) VALUES
('TT01', N'Mới tạo'), ('TT02', N'Đã tiếp nhận'), ('TT03', N'Đang vận chuyển'), ('TT04', N'Đã đến kho'),
('TT05', N'Đang giao hàng'), ('TT06', N'Giao thành công'), ('TT07', N'Hủy / Trả hàng'), ('TT08', N'Giao thất bại');

INSERT INTO quy_trinh_trang_thai (tt_tu, tt_den) VALUES
('TT01','TT02'), ('TT02','TT03'), ('TT03','TT04'), ('TT04','TT03'),
('TT04','TT05'), ('TT05','TT06'), ('TT05','TT08'), ('TT08','TT05'),
('TT02','TT05'),
('TT01','TT07'), ('TT02','TT07'), ('TT03','TT07'), ('TT04','TT07'), ('TT05','TT07'), ('TT08','TT07');

INSERT INTO cau_hinh_he_thong (khoa, gia_tri, mo_ta) VALUES
('PHI_CO_BAN',    15000, N'Cước cơ bản mỗi kiện (VNĐ)'),
('KG_MIEN_PHI',   0.5,   N'Khối lượng (kg) đã gồm trong cước cơ bản'),
('PHI_MOI_KG',    5000,  N'Đơn giá mỗi kg vượt (VNĐ/kg)'),
('PHI_MOI_KM',    300,   N'Đơn giá mỗi km (VNĐ/km)'),
('HE_SO_QUY_DOI', 5000,  N'Hệ số quy đổi thể tích: (D×R×C cm³) / hệ số = kg');

-- 7.2. Kho & Tuyến vận chuyển
INSERT INTO kho (ma_kho, ten_kho, dia_chi, sdt) VALUES
('KHO01', N'Bưu cục Thủ Đức',  N'12 Võ Văn Ngân, TP. Thủ Đức, TP.HCM',   '0281111111'),
('KHO02', N'Bưu cục Cầu Giấy', N'25 Trần Thái Tông, Cầu Giấy, Hà Nội',   '0242222222'),
('KHO03', N'Bưu cục Đà Nẵng',  N'45 Nguyễn Văn Linh, Hải Châu, Đà Nẵng', '0236333333'),
('KHO04', N'Bưu cục Cần Thơ',  N'88 Nguyễn Trãi, Ninh Kiều, Cần Thơ',    '0292444444');

INSERT INTO tuyen_van_chuyen (ma_tuyen, ma_kho_di, ma_kho_den, khoang_cach, thoi_gian_du_kien_gio) VALUES
('TU01', 'KHO01', 'KHO03', 960, 18),
('TU02', 'KHO03', 'KHO01', 960, 18),
('TU03', 'KHO03', 'KHO02', 770, 14),
('TU04', 'KHO01', 'KHO04', 170, 4),
('TU05', 'KHO04', 'KHO01', 170, 4);

-- 7.3. Người dùng, Nhân viên, Khách hàng, Tài xế, Phương tiện
INSERT INTO nguoi_dung (ma_nd, ten_dang_nhap, mat_khau, ma_vai_tro, trang_thai) VALUES
('ND001', 'admin',      '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'ADMIN',      N'Hoạt động'),
('ND002', 'nvbc01',     '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'NVBC',       N'Hoạt động'),
('ND003', 'nvbc02',     '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'NVBC',       N'Hoạt động'),
('ND004', 'nvdp01',     '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'NVDP',       N'Hoạt động'),
('ND009', 'nvdp02',     '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'NVDP',       N'Hoạt động'),
('ND005', 'tx01',       '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'TAI_XE',     N'Hoạt động'),
('ND006', 'tx02',       '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'TAI_XE',     N'Hoạt động'),
('ND010', 'tx03',       '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'TAI_XE',     N'Hoạt động'),
('ND011', 'tx04',       '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'TAI_XE',     N'Hoạt động'),
('ND012', 'tx05',       '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'TAI_XE',     N'Hoạt động'),
('ND007', '0901000001', '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'KHACH_HANG', N'Hoạt động'),
('ND008', '0901000002', '$2a$10$BaxCyj/IY6CxGzc7aG2WauO0rOSnphOXftgCMNQDjMt2R24eUOgAi', 'KHACH_HANG', N'Hoạt động');

INSERT INTO nhan_vien (ma_nv, ho_ten, chuc_vu, sdt, email, ma_kho, ma_nd) VALUES
('NV001', N'Phạm Hoàng Nam',    N'Nhân viên bưu cục',   '0902000001', 'nam@uteexpress.vn',  'KHO01', 'ND002'),
('NV002', N'Võ Thị Lan',        N'Nhân viên bưu cục',   '0902000002', 'lan@uteexpress.vn',  'KHO03', 'ND003'),
('NV003', N'Đặng Quốc Huy',     N'Nhân viên điều phối', '0902000003', 'huy@uteexpress.vn',  'KHO01', 'ND004'),
('NV004', N'Nguyễn Thanh Tùng', N'Nhân viên điều phối', '0902000004', 'tung@uteexpress.vn', 'KHO03', 'ND009');

INSERT INTO khach_hang (ma_kh, ho_ten, sdt, email, dia_chi_mac_dinh, ma_nd) VALUES
('KH001', N'Nguyễn Văn An', '0901000001', 'an@example.com',    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM', 'ND007'),
('KH002', N'Trần Thị Bích', '0901000002', 'bich@example.com',  N'34 Lê Lợi, Quận 1, TP.HCM',       'ND008'),
('KH003', N'Lê Văn Cường',  '0901000003', NULL,                N'45 Nguyễn Văn Linh, Đà Nẵng',     NULL);

INSERT INTO tai_xe (ma_tx, ho_ten, sdt, bang_lai, ma_nd) VALUES
('TX001', N'Huỳnh Văn Tài',   '0903000001', 'C',  'ND005'),
('TX002', N'Ngô Minh Đức',    '0903000002', 'E',  'ND006'),
('TX003', N'Lê Hoàng Long',   '0903000003', 'C',  'ND010'),
('TX004', N'Trần Quốc Toản',  '0903000004', 'B2', 'ND011'),
('TX005', N'Nguyễn Văn Dũng', '0903000005', 'E',  'ND012');

INSERT INTO phuong_tien (ma_pt, bien_so, loai_xe, tai_trong, trang_thai) VALUES
('PT001', '51C-123.45',  N'Xe tải', 1500, N'Đang chạy'),
('PT002', '51D-678.90',  N'Xe tải', 5000, N'Sẵn sàng'),
('PT003', '59H1-111.22', N'Xe máy',   30, N'Sẵn sàng'),
('PT004', '51E-999.88',  N'Xe tải', 8000, N'Sẵn sàng'),
('PT005', '51C-456.78',  N'Xe tải', 2500, N'Đang chạy'),
('PT006', '59H1-888.99', N'Xe máy',   30, N'Sẵn sàng'),
('PT007', '43C-333.44',  N'Xe tải', 3500, N'Sẵn sàng');

-- 7.4. 17 Đơn hàng mẫu & 19 Kiện hàng mẫu
INSERT INTO don_hang (ma_dh, ma_kh_gui, ma_kh_nhan, sdt_nhan, ten_nguoi_nhan, dia_chi_lay, dia_chi_giao, ma_kho_gui, ma_kho_nhan, ngay_tao, phi_van_chuyen, cod, ma_tt, ma_nv) VALUES
('DH000001', 'KH001', 'KH002', '0901000002', N'Trần Thị Bích',    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'25 Trần Thái Tông, Cầu Giấy, Hà Nội',    'KHO01', 'KHO02', DATEADD(HOUR, -3, SYSDATETIME()),    35000,  150000, 'TT01', NULL),
('DH000002', 'KH001', 'KH002', '0901000002', N'Trần Thị Bích',    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'25 Trần Thái Tông, Cầu Giấy, Hà Nội',    'KHO01', 'KHO02', DATEADD(DAY, -1, SYSDATETIME()),     45000,  300000, 'TT02', 'NV001'),
('DH000003', 'KH001', 'KH002', '0901000002', N'Trần Thị Bích',    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'25 Trần Thái Tông, Cầu Giấy, Hà Nội',    'KHO01', 'KHO02', DATEADD(DAY, -2, SYSDATETIME()),     50000,  500000, 'TT06', 'NV001'),
('DH000004', 'KH001', 'KH003', '0901000001', N'Nguyễn Thị Hoa',   N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'100 Hải Phòng, Hải Châu, Đà Nẵng',       'KHO01', 'KHO03', DATEADD(HOUR, -4, SYSDATETIME()),    701000, 150000, 'TT03', 'NV001'),
('DH000005', 'KH002', 'KH001', '0901000002', N'Trần Văn Nam',     N'34 Lê Lợi, Quận 1, TP.HCM',          N'20 Đại lộ Hòa Bình, Ninh Kiều, Cần Thơ', 'KHO01', 'KHO04', DATEADD(HOUR, -6, SYSDATETIME()),    138500, 0,      'TT03', 'NV001'),
('DH000006', 'KH001', 'KH002', '0901000003', N'Lê Hữu Phước',     N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'50 Đặng Văn Bi, Thủ Đức, TP.HCM',        'KHO01', 'KHO01', DATEADD(HOUR, -2, SYSDATETIME()),    30000,  80000,  'TT02', 'NV001'),
('DH000007', 'KH002', 'KH003', '0901000001', N'Đỗ Thanh Tùng',    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'75 Bạch Đằng, Hải Châu, Đà Nẵng',        'KHO01', 'KHO03', DATEADD(DAY, -1, SYSDATETIME()),     330500, 250000, 'TT05', 'NV001'),
('DH000008', 'KH001', 'KH003', '0901000002', N'Phạm Quỳnh Anh',   N'34 Lê Lợi, Quận 1, TP.HCM',          N'12 Lê Duẩn, Hải Châu, Đà Nẵng',          'KHO01', 'KHO03', DATEADD(DAY, -1, SYSDATETIME()),     310500, 0,      'TT05', 'NV001'),
('DH000009', 'KH003', 'KH001', '0901000001', N'Nguyễn Văn An',    N'45 Nguyễn Văn Linh, Đà Nẵng',        N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',        'KHO03', 'KHO01', DATEADD(HOUR, -5, SYSDATETIME()),    425500, 0,      'TT02', 'NV002'),
('DH000010', 'KH002', 'KH001', '0901000002', N'Trần Thị Mai',     N'88 Nguyễn Trãi, Ninh Kiều, Cần Thơ', N'34 Lê Lợi, Quận 1, TP.HCM',              'KHO04', 'KHO01', DATEADD(HOUR, -5, SYSDATETIME()),    153500, 300000, 'TT02', 'NV001'),
('DH000011', 'KH001', 'KH003', '0901000001', N'Hoàng Minh Tuấn',  N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'150 Hùng Vương, Hải Châu, Đà Nẵng',      'KHO01', 'KHO03', DATEADD(HOUR, -1, SYSDATETIME()),    120000, 200000, 'TT02', 'NV001'),
('DH000012', 'KH002', 'KH001', '0901000002', N'Vũ Thị Hạnh',      N'34 Lê Lợi, Quận 1, TP.HCM',          N'45 Mậu Thân, Ninh Kiều, Cần Thơ',        'KHO01', 'KHO04', DATEADD(HOUR, -2, SYSDATETIME()),    95000,  0,      'TT02', 'NV001'),
('DH000013', 'KH003', 'KH001', '0901000001', N'Lê Bích Ngọc',     N'45 Nguyễn Văn Linh, Đà Nẵng',        N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',        'KHO03', 'KHO01', DATEADD(HOUR, -3, SYSDATETIME()),    180000, 150000, 'TT02', 'NV002'),
('DH000014', 'KH003', 'KH002', '0901000002', N'Nguyễn Tiến Dũng', N'45 Nguyễn Văn Linh, Đà Nẵng',        N'25 Trần Thái Tông, Cầu Giấy, Hà Nội',    'KHO03', 'KHO02', DATEADD(HOUR, -4, SYSDATETIME()),    210000, 0,      'TT02', 'NV002'),
('DH000015', 'KH002', 'KH001', '0901000002', N'Phan Văn Hậu',     N'88 Nguyễn Trãi, Ninh Kiều, Cần Thơ', N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',        'KHO04', 'KHO01', DATEADD(HOUR, -2, SYSDATETIME()),    85000,  100000, 'TT02', 'NV001'),
('DH000016', 'KH001', 'KH003', '0901000003', N'Đặng Quốc Bảo',    N'100 Hải Phòng, Đà Nẵng',             N'200 Nguyễn Hữu Thọ, Cẩm Lệ, Đà Nẵng',    'KHO03', 'KHO03', DATEADD(HOUR, -1, SYSDATETIME()),    25000,  400000, 'TT02', 'NV002'),
('DH000017', 'KH002', 'KH001', '0901000002', N'Lý Gia Hân',       N'12 Võ Văn Ngân, Thủ Đức, TP.HCM',    N'88 Hoàng Diệu 2, Linh Chiểu, Thủ Đức',   'KHO01', 'KHO01', DATEADD(MINUTE, -30, SYSDATETIME()), 22000,  120000, 'TT02', 'NV001');

INSERT INTO kien_hang (ma_kien, ma_dh, khoi_luong, dai, rong, cao, loai_hang, ma_kho_hien_tai) VALUES
('KI0000001', 'DH000001',  2.5, 30, 20, 15, N'Đồ dùng học tập',     'KHO01'),
('KI0000002', 'DH000002',  2.0, 30, 20, 15, N'Đồ gia dụng',         'KHO01'),
('KI0000003', 'DH000003',  3.5, 40, 25, 20, N'Thiết bị điện tử',    'KHO02'),
('KI0000004', 'DH000004', 12.0, 40, 30, 20, N'Thiết bị điện tử',    NULL),
('KI0000005', 'DH000004',  8.0, 30, 25, 15, N'Quần áo thời trang',  NULL),
('KI0000006', 'DH000005', 15.0, 35, 30, 25, N'Đồ gia dụng',         NULL),
('KI0000007', 'DH000006',  3.5, 25, 20, 15, N'Thực phẩm hoa quả',   'KHO01'),
('KI0000008', 'DH000007',  6.0, 30, 20, 15, N'Giày thể thao',       'KHO03'),
('KI0000009', 'DH000008',  2.0, 20, 15, 10, N'Sách và tài liệu',    'KHO03'),
('KI0000010', 'DH000009', 25.0, 50, 40, 30, N'Hải sản khô Đà Nẵng', 'KHO03'),
('KI0000011', 'DH000010', 18.0, 45, 35, 25, N'Trái cây đặc sản',    'KHO04'),
('KI0000012', 'DH000011',  5.0, 25, 20, 15, N'Linh kiện máy tính',  'KHO01'),
('KI0000013', 'DH000011',  3.0, 20, 15, 10, N'Phụ kiện điện tử',    'KHO01'),
('KI0000014', 'DH000012',  4.0, 30, 20, 15, N'Mỹ phẩm dưỡng da',    'KHO01'),
('KI0000015', 'DH000013',  8.0, 35, 25, 20, N'Trà sâm cao cấp',     'KHO03'),
('KI0000016', 'DH000014', 10.0, 40, 30, 25, N'Thủ công mỹ nghệ',    'KHO03'),
('KI0000017', 'DH000015',  6.0, 30, 20, 15, N'Bánh pía Sóc Trăng',  'KHO04'),
('KI0000018', 'DH000016',  4.5, 25, 20, 15, N'Hàng tiêu dùng',      'KHO03'),
('KI0000019', 'DH000017',  1.8, 20, 15, 10, N'Tài liệu hợp đồng',   'KHO01');

-- 7.5. 8 Chuyến giao, Chi tiết chuyến giao, Thanh toán & Lịch sử trạng thái
INSERT INTO chuyen_giao (ma_chuyen, loai_chuyen, ma_tuyen, ma_kho_giao, ma_tx, ma_pt, ma_nv_dieu_phoi, ngay_xuat_phat, ngay_den_du_kien, ngay_xuat_phat_thuc, ngay_den, trang_thai) VALUES
('CG000001', 'LIEN_KHO',  'TU01', NULL,    'TX001', 'PT001', 'NV003', DATEADD(HOUR, -2, SYSDATETIME()),   DATEADD(HOUR, 16, SYSDATETIME()),  DATEADD(HOUR, -2, SYSDATETIME()), NULL,                              N'Đang đi'),
('CG000002', 'GIAO_CUOI', NULL,   'KHO01', 'TX002', 'PT003', 'NV003', DATEADD(MINUTE, 30, SYSDATETIME()), DATEADD(HOUR, 4, SYSDATETIME()),   NULL,                             NULL,                              N'Chưa đi'),
('CG000003', 'LIEN_KHO',  'TU01', NULL,    'TX001', 'PT002', 'NV003', DATEADD(DAY, -3, SYSDATETIME()),    DATEADD(DAY, -2, SYSDATETIME()),   DATEADD(DAY, -3, SYSDATETIME()),  DATEADD(DAY, -2, SYSDATETIME()),   N'Hoàn thành'),
('CG000004', 'GIAO_CUOI', NULL,   'KHO02', 'TX002', 'PT006', 'NV003', DATEADD(DAY, -2, SYSDATETIME()),    DATEADD(HOUR, -45, SYSDATETIME()), DATEADD(DAY, -2, SYSDATETIME()),  DATEADD(HOUR, -45, SYSDATETIME()), N'Hoàn thành'),
('CG000005', 'LIEN_KHO',  'TU04', NULL,    'TX003', 'PT005', 'NV003', DATEADD(HOUR, -1, SYSDATETIME()),   DATEADD(HOUR, 3, SYSDATETIME()),   DATEADD(HOUR, -1, SYSDATETIME()), NULL,                              N'Đang đi'),
('CG000006', 'GIAO_CUOI', NULL,   'KHO03', 'TX004', 'PT007', 'NV004', DATEADD(HOUR, 1, SYSDATETIME()),    DATEADD(HOUR, 5, SYSDATETIME()),   NULL,                             NULL,                              N'Chưa đi'),
('CG000007', 'LIEN_KHO',  'TU02', NULL,    'TX005', 'PT004', 'NV004', DATEADD(HOUR, 2, SYSDATETIME()),    DATEADD(HOUR, 20, SYSDATETIME()),  NULL,                             NULL,                              N'Chưa đi'),
('CG000008', 'LIEN_KHO',  'TU05', NULL,    'TX001', 'PT001', 'NV003', DATEADD(HOUR, 24, SYSDATETIME()),   DATEADD(HOUR, 28, SYSDATETIME()),  NULL,                             NULL,                              N'Chưa đi');

INSERT INTO chi_tiet_chuyen_giao (ma_chuyen, ma_kien, thoi_gian_gan, thoi_gian_quet, trang_thai, ghi_chu) VALUES
('CG000001', 'KI0000004', DATEADD(HOUR, -2, SYSDATETIME()),    DATEADD(HOUR, -2, SYSDATETIME()), N'Đã quét', N'Đã xếp lên xe tải 51C-123.45'),
('CG000001', 'KI0000005', DATEADD(HOUR, -2, SYSDATETIME()),    DATEADD(HOUR, -2, SYSDATETIME()), N'Đã quét', N'Đã xếp lên xe tải 51C-123.45'),
('CG000002', 'KI0000007', DATEADD(MINUTE, -15, SYSDATETIME()), NULL,                             N'Đã gán',  N'Chờ tài xế TX002 nhận hàng giao cuối'),
('CG000003', 'KI0000003', DATEADD(DAY, -3, SYSDATETIME()),     DATEADD(DAY, -3, SYSDATETIME()),  N'Đã giao', N'Giao thành công tại kho Cầu Giấy'),
('CG000005', 'KI0000006', DATEADD(HOUR, -1, SYSDATETIME()),    DATEADD(HOUR, -1, SYSDATETIME()), N'Đã quét', N'Đang vận chuyển về bưu cục Cần Thơ'),
('CG000006', 'KI0000008', DATEADD(MINUTE, -30, SYSDATETIME()), NULL,                             N'Đã gán',  N'Phân công giao nội thành Hải Châu'),
('CG000006', 'KI0000009', DATEADD(MINUTE, -30, SYSDATETIME()), NULL,                             N'Đã gán',  N'Phân công giao lại địa chỉ cơ quan'),
('CG000007', 'KI0000010', DATEADD(MINUTE, -10, SYSDATETIME()), NULL,                             N'Đã gán',  N'Chờ xếp kiện hải sản khô lên xe tải 8T'),
('CG000008', 'KI0000011', DATEADD(MINUTE, -5, SYSDATETIME()),  NULL,                             N'Đã gán',  N'Lập kế hoạch vận chuyển trái cây Cần Thơ');

INSERT INTO thanh_toan (ma_tt_toan, ma_dh, loai_khoan, so_tien, phuong_thuc, trang_thai, thoi_gian, nguoi_thanh_toan) VALUES
('GD000001', 'DH000003', 'PHI_VC', 50000,  N'Chuyển khoản', N'Đã thanh toán', DATEADD(DAY, -2, SYSDATETIME()),  N'Nguyễn Văn An'),
('GD000002', 'DH000003', 'COD',    500000, N'Tiền mặt',     N'Đã thanh toán', DATEADD(HOUR, -3, SYSDATETIME()), N'Trần Thị Bích'),
('GD000003', 'DH000004', 'PHI_VC', 701000, N'Chuyển khoản', N'Đã thanh toán', DATEADD(HOUR, -4, SYSDATETIME()), N'Nguyễn Văn An'),
('GD000004', 'DH000007', 'PHI_VC', 330500, N'Chuyển khoản', N'Đã thanh toán', DATEADD(DAY, -1, SYSDATETIME()),  N'Trần Thị Bích'),
('GD000005', 'DH000005', 'PHI_VC', 138500, N'Chuyển khoản', N'Đã thanh toán', DATEADD(HOUR, -6, SYSDATETIME()), N'Trần Văn Nam');

INSERT INTO lich_su_trang_thai (ma_ls, ma_dh, ma_tt, thoi_gian, ma_nd, ghi_chu) VALUES
('LS00000001', 'DH000001', 'TT01', DATEADD(HOUR, -3, SYSDATETIME()),  'ND007', N'Khách hàng tạo đơn qua ứng dụng'),
('LS00000002', 'DH000002', 'TT01', DATEADD(DAY, -1, SYSDATETIME()),   'ND007', N'Khách hàng tạo đơn qua ứng dụng'),
('LS00000003', 'DH000002', 'TT02', DATEADD(HOUR, -20, SYSDATETIME()), 'ND002', N'Bưu cục Thủ Đức tiếp nhận và nhập kho'),
('LS00000004', 'DH000003', 'TT01', DATEADD(DAY, -2, SYSDATETIME()),   'ND007', N'Khách hàng tạo đơn qua ứng dụng'),
('LS00000005', 'DH000003', 'TT02', DATEADD(HOUR, -40, SYSDATETIME()), 'ND002', N'Bưu cục Thủ Đức tiếp nhận kiện'),
('LS00000006', 'DH000003', 'TT03', DATEADD(HOUR, -30, SYSDATETIME()), 'ND004', N'Xuất kho và vận chuyển liên kho'),
('LS00000007', 'DH000003', 'TT04', DATEADD(HOUR, -10, SYSDATETIME()), 'ND003', N'Đến kho Cầu Giấy Hà Nội'),
('LS00000008', 'DH000003', 'TT05', DATEADD(HOUR, -5, SYSDATETIME()),  'ND006', N'Tài xế nhận hàng đi giao'),
('LS00000009', 'DH000003', 'TT06', DATEADD(HOUR, -3, SYSDATETIME()),  'ND006', N'Giao hàng và thu COD thành công'),
('LS00000010', 'DH000004', 'TT01', DATEADD(HOUR, -4, SYSDATETIME()),  'ND007', N'Khách hàng tạo đơn qua ứng dụng'),
('LS00000011', 'DH000004', 'TT02', DATEADD(HOUR, -3, SYSDATETIME()),  'ND002', N'Bưu cục Thủ Đức tiếp nhận 2 kiện'),
('LS00000012', 'DH000004', 'TT03', DATEADD(HOUR, -2, SYSDATETIME()),  'ND004', N'Đã xếp lên chuyến xe liên kho CG000001'),
('LS00000013', 'DH000005', 'TT01', DATEADD(HOUR, -6, SYSDATETIME()),  'ND008', N'Khách hàng tạo đơn qua ứng dụng'),
('LS00000014', 'DH000005', 'TT02', DATEADD(HOUR, -5, SYSDATETIME()),  'ND002', N'Bưu cục Thủ Đức tiếp nhận đơn'),
('LS00000015', 'DH000005', 'TT03', DATEADD(HOUR, -1, SYSDATETIME()),  'ND004', N'Đã xếp lên chuyến xe liên kho CG000005');

COMMIT TRAN;
GO

-- Đồng bộ lại các Sequences tránh trùng mã khi tạo mới từ ứng dụng
ALTER SEQUENCE seq_dh     RESTART WITH 20;
ALTER SEQUENCE seq_kien   RESTART WITH 25;
ALTER SEQUENCE seq_chuyen RESTART WITH 15;
ALTER SEQUENCE seq_ttoan  RESTART WITH 15;
ALTER SEQUENCE seq_ls     RESTART WITH 25;
ALTER SEQUENCE seq_tx     RESTART WITH 10;
ALTER SEQUENCE seq_pt     RESTART WITH 10;
ALTER SEQUENCE seq_nv     RESTART WITH 10;
ALTER SEQUENCE seq_nd     RESTART WITH 20;
ALTER SEQUENCE seq_kh     RESTART WITH 10;
ALTER SEQUENCE seq_kho    RESTART WITH 10;
ALTER SEQUENCE seq_tuyen  RESTART WITH 10;
GO

-- Bật lại toàn bộ Trigger như bình thường
EXEC sp_msforeachtable 'ENABLE TRIGGER ALL ON ?';
GO

PRINT N'=================================================================================';
PRINT N'CÀI ĐẶT CƠ SỞ DỮ LIỆU UTEEXPRESS (SQL SERVER) THÀNH CÔNG 100%!';
PRINT N'=================================================================================';
GO