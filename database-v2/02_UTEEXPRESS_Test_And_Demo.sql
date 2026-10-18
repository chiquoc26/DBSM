-- =========================================================================================
-- ĐỒ ÁN HỆ QUẢN TRỊ CƠ SỞ DỮ LIỆU: HỆ THỐNG QUẢN LÝ VẬN CHUYỂN UTEEXPRESS (SQL SERVER)
-- FILE 02: KỊCH BẢN KIỂM THỬ TỰ ĐỘNG (UNIT TEST) & MINH CHỨNG HIỆU NĂNG INDEX
-- Lưu ý: Toàn bộ kịch bản test chạy trong Transaction và tự động ROLLBACK ở cuối,
-- đảm bảo giữ nguyên vẹn 100% dữ liệu mẫu của hệ thống sau khi test.
-- =========================================================================================
USE UTEEXPRESS;
GO

CREATE OR ALTER PROCEDURE #assert_true @p_ten NVARCHAR(200), @p_dk BIT AS
BEGIN
    IF ISNULL(@p_dk, 0) = 1 PRINT N'[PASS] ' + @p_ten;
    ELSE PRINT N'[FAIL] ' + @p_ten;
END;
GO

CREATE OR ALTER PROCEDURE #expect_error @p_ten NVARCHAR(200), @p_sql NVARCHAR(MAX) AS
BEGIN
    BEGIN TRY
        EXEC sp_executesql @p_sql;
        PRINT N'[FAIL] ' + @p_ten + N' -- lẽ ra phải báo lỗi';
    END TRY
    BEGIN CATCH
        PRINT N'[PASS] ' + @p_ten + N' -> ' + ERROR_MESSAGE();
    END CATCH
END;
GO

SET NOCOUNT ON;
PRINT N'=== T1. KIỂM TRA RÀNG BUỘC DỮ LIỆU & TRIGGER ===';
EXEC #expect_error N'SĐT khách hàng sai định dạng', N'INSERT INTO khach_hang(ho_ten, sdt) VALUES (N''X'', ''12345'')';
EXEC #expect_error N'Trùng SĐT khách hàng', N'INSERT INTO khach_hang(ho_ten, sdt) VALUES (N''X'', ''0901000001'')';
EXEC #expect_error N'Tuyến cùng kho đi/đến', N'INSERT INTO tuyen_van_chuyen(ma_kho_di, ma_kho_den, khoang_cach, thoi_gian_du_kien_gio) VALUES (''KHO01'',''KHO01'',10,1)';
EXEC #expect_error N'Tuyến đã tồn tại', N'INSERT INTO tuyen_van_chuyen(ma_kho_di, ma_kho_den, khoang_cach, thoi_gian_du_kien_gio) VALUES (''KHO01'',''KHO03'',960,18)';
EXEC #expect_error N'Khoảng cách tuyến âm', N'INSERT INTO tuyen_van_chuyen(ma_kho_di, ma_kho_den, khoang_cach, thoi_gian_du_kien_gio) VALUES (''KHO02'',''KHO04'',-5,1)';
EXEC #expect_error N'Trạng thái tài khoản sai', N'UPDATE nguoi_dung SET trang_thai = N''Không rõ'' WHERE ma_nd = ''ND001''';
EXEC #expect_error N'Tải trọng phương tiện = 0', N'INSERT INTO phuong_tien(bien_so, loai_xe, tai_trong) VALUES (''99X-000.00'',N''Xe tải'',0)';
EXEC #expect_error N'Gắn tài khoản TÀI XẾ cho nhân viên bưu cục', N'INSERT INTO nhan_vien(ho_ten, chuc_vu, ma_nd) VALUES (N''X'',N''Nhân viên bưu cục'',''ND005'')';
EXEC #expect_error N'COD âm', N'INSERT INTO don_hang(ma_kh_gui, sdt_nhan, ten_nguoi_nhan, dia_chi_lay, dia_chi_giao, ma_kho_gui, ma_kho_nhan, cod) VALUES (''KH001'',''0901000002'',N''A'',N''a'',N''b'',''KHO01'',''KHO03'',-1)';
EXEC #expect_error N'Sửa bản ghi lịch sử trạng thái (bất biến)', N'UPDATE lich_su_trang_thai SET ghi_chu = N''Sửa'' WHERE ma_ls = ''LS00000001''';
EXEC #expect_error N'Xóa bản ghi lịch sử trạng thái (bất biến)', N'DELETE FROM lich_su_trang_thai WHERE ma_ls = ''LS00000001''';
GO

PRINT N'=== T2. KỊCH BẢN NGHIỆP VỤ ĐẦU–CUỐI (TRANSACTION END-TO-END) ===';
BEGIN TRAN;

DECLARE @v_kh VARCHAR(20), @v_dh1 VARCHAR(20), @v_dh2 VARCHAR(20), @v_dh3 VARCHAR(20),
        @v_cg1 VARCHAR(20), @v_cg2 VARCHAR(20), @v_cg3 VARCHAR(20), @v_ma_ttoan VARCHAR(20),
        @v_k1_1 VARCHAR(20), @v_k1_2 VARCHAR(20), @dk BIT;

-- 1. Đăng ký khách hàng (UC01)
EXEC sp_dang_ky_khach_hang N'Phạm Minh Tuấn', '0912345678', 'tuan@example.com', '$2a$10$PLACEHOLDER', @v_kh OUTPUT;
SET @dk = CASE WHEN EXISTS (SELECT 1 FROM khach_hang k JOIN nguoi_dung n ON n.ma_nd = k.ma_nd WHERE k.ma_kh = @v_kh AND n.ma_vai_tro = 'KHACH_HANG') THEN 1 ELSE 0 END;
EXEC #assert_true N'Đăng ký tạo khách hàng + tài khoản vai trò KHACH_HANG', @dk;

EXEC sp_dang_ky_khach_hang N'Lê Văn Cường', '0901000003', 'cuong@example.com', '$2a$10$PLACEHOLDER', @v_kh OUTPUT;
SET @dk = CASE WHEN @v_kh = 'KH003' AND (SELECT ma_nd FROM khach_hang WHERE ma_kh = 'KH003') IS NOT NULL THEN 1 ELSE 0 END;
EXEC #assert_true N'Đăng ký liên kết vào hồ sơ KH003 (người nhận cũ chưa có tài khoản)', @dk;

-- 2. Tạo đơn hàng (UC04)
EXEC sp_tao_don_hang 'KH001', N'Lê Văn Cường', '0901000003',
    N'12 Võ Văn Ngân, Thủ Đức, TP.HCM', N'45 Nguyễn Văn Linh, Đà Nẵng', 'KHO01', 'KHO03', 500000,
    N'[{"khoi_luong":2.5,"dai":30,"rong":20,"cao":15,"loai_hang":"Điện tử"},
       {"khoi_luong":1,"dai":20,"rong":20,"cao":10,"loai_hang":"Quần áo"}]', 'ND007', @v_dh1 OUTPUT;

SET @dk = CASE WHEN (SELECT phi_van_chuyen FROM don_hang WHERE ma_dh = @v_dh1) = 618500 THEN 1 ELSE 0 END;
EXEC #assert_true N'Đơn 1: phí tự động tính = 313000 + 305500 = 618500', @dk;

EXEC sp_tao_don_hang 'KH002', N'Nguyễn Thị Mai', '0901000001', N'34 Lê Lợi, Q1, TP.HCM', N'9 Hùng Vương, Đà Nẵng',
    'KHO01', 'KHO03', 0, N'[{"khoi_luong":50,"dai":60,"rong":40,"cao":40,"loai_hang":"Máy móc"}]', 'ND008', @v_dh2 OUTPUT;
EXEC sp_tao_don_hang 'KH001', N'Trần Thị Bích', '0901000002', N'12 Võ Văn Ngân, Thủ Đức', N'34 Lê Lợi, Q1, TP.HCM',
    'KHO01', 'KHO01', 0, N'[{"khoi_luong":1,"dai":20,"rong":20,"cao":10,"loai_hang":"Sách"}]', 'ND007', @v_dh3 OUTPUT;

SET @dk = CASE WHEN (SELECT phi_van_chuyen FROM don_hang WHERE ma_dh = @v_dh3) = 17500 THEN 1 ELSE 0 END;
EXEC #assert_true N'Đơn 3 (nội bưu cục, 0 km): phí = 17500', @dk;

-- 3. Tiếp nhận đơn tại bưu cục (UC08)
EXEC sp_tiep_nhan_don @v_dh1, 'NV001', 'ND002';
EXEC sp_tiep_nhan_don @v_dh2, 'NV001', 'ND002';
EXEC sp_tiep_nhan_don @v_dh3, 'NV001', 'ND002';

-- 4. Lập chuyến liên kho HCM -> Đà Nẵng (UC12)
-- Đặt lịch vào +100 giờ để không trùng lịch với các chuyến mẫu đang có trong seed_extra
DECLARE @t_xp1 DATETIME2 = DATEADD(HOUR, 100, SYSDATETIME());
EXEC sp_tao_chuyen_giao 'LIEN_KHO', 'TU01', NULL, 'TX001', 'PT002', @t_xp1, 'NV003', 'ND004', NULL, @v_cg1 OUTPUT;

SELECT TOP 1 @v_k1_1 = ma_kien FROM kien_hang WHERE ma_dh = @v_dh1 ORDER BY ma_kien ASC;
SELECT TOP 1 @v_k1_2 = ma_kien FROM kien_hang WHERE ma_dh = @v_dh1 ORDER BY ma_kien DESC;

EXEC sp_gan_kien_vao_chuyen @v_cg1, @v_k1_1, 'ND004';
EXEC sp_gan_kien_vao_chuyen @v_cg1, @v_k1_2, 'ND004';

SET @dk = CASE WHEN dbo.fn_tai_trong_con_lai(@v_cg1) = 4996.5 THEN 1 ELSE 0 END;
EXEC #assert_true N'Đã gán 2 kiện vào xe 5000kg, tải còn lại = 5000 - 3.5 = 4996.5', @dk;

EXEC sp_quet_kien @v_cg1, @v_k1_1, 'ND005', N'Nhận kiện điện tử';
EXEC sp_quet_kien @v_cg1, @v_k1_2, 'ND005';
EXEC sp_xuat_phat_chuyen @v_cg1, 'ND005';
EXEC sp_hoan_thanh_chuyen @v_cg1, 'ND005';

SET @dk = CASE WHEN (SELECT ma_tt FROM don_hang WHERE ma_dh = @v_dh1) = 'TT04' THEN 1 ELSE 0 END;
EXEC #assert_true N'Hoàn thành chuyến liên kho: đơn 1 chuyển sang TT04 (Đã đến kho KHO03)', @dk;

-- 5. Giao cuối đơn 1 + COD (UC14)
DECLARE @t_xp2 DATETIME2 = DATEADD(HOUR, 120, SYSDATETIME()), @t_den2 DATETIME2 = DATEADD(HOUR, 124, SYSDATETIME());
EXEC sp_tao_chuyen_giao 'GIAO_CUOI', NULL, 'KHO03', 'TX002', 'PT002', @t_xp2, 'NV003', 'ND004', @t_den2, @v_cg2 OUTPUT;
EXEC sp_gan_kien_vao_chuyen @v_cg2, @v_k1_1, 'ND004';
EXEC sp_gan_kien_vao_chuyen @v_cg2, @v_k1_2, 'ND004';
EXEC sp_quet_kien @v_cg2, @v_k1_1, 'ND006';
EXEC sp_quet_kien @v_cg2, @v_k1_2, 'ND006';
EXEC sp_xuat_phat_chuyen @v_cg2, 'ND006';

EXEC sp_giao_thanh_cong @v_cg2, @v_k1_1, 'ND006', N'Giao thành công lần 1';
EXEC sp_giao_that_bai   @v_cg2, @v_k1_2, 'ND006', N'Khách vắng mặt, hẹn giao lại';
EXEC sp_hoan_thanh_chuyen @v_cg2, 'ND006';

-- 6. Giao lại kiện thất bại
DECLARE @t_xp3 DATETIME2 = DATEADD(HOUR, 148, SYSDATETIME()), @t_den3 DATETIME2 = DATEADD(HOUR, 150, SYSDATETIME());
EXEC sp_tao_chuyen_giao 'GIAO_CUOI', NULL, 'KHO03', 'TX002', 'PT002', @t_xp3, 'NV003', 'ND004', @t_den3, @v_cg3 OUTPUT;
EXEC sp_gan_kien_vao_chuyen @v_cg3, @v_k1_2, 'ND004';
EXEC sp_quet_kien @v_cg3, @v_k1_2, 'ND006';
EXEC sp_xuat_phat_chuyen @v_cg3, 'ND006';
EXEC sp_giao_thanh_cong @v_cg3, @v_k1_2, 'ND006', N'Giao thành công lần 2';

SET @dk = CASE WHEN (SELECT ma_tt FROM don_hang WHERE ma_dh = @v_dh1) = 'TT06'
                AND EXISTS (SELECT 1 FROM thanh_toan WHERE ma_dh = @v_dh1 AND loai_khoan = 'COD' AND so_tien = 500000 AND trang_thai = N'Đã thanh toán')
          THEN 1 ELSE 0 END;
EXEC #assert_true N'Giao đủ tất cả kiện: đơn 1 -> TT06, tự tạo khoản thu COD 500000 đã thanh toán', @dk;

-- 7. Thanh toán phí vận chuyển (UC06)
EXEC sp_thanh_toan @v_dh1, 'PHI_VC', N'Chuyển khoản', N'Nguyễn Văn An', 'ND007', @v_ma_ttoan OUTPUT;
SET @dk = CASE WHEN (SELECT tinh_trang_thanh_toan FROM v_don_hang_chi_tiet WHERE ma_dh = @v_dh1) = N'Đã thanh toán đủ' THEN 1 ELSE 0 END;
EXEC #assert_true N'Sau khi thanh toán phí: v_don_hang_chi_tiet báo "Đã thanh toán đủ"', @dk;

-- 8. Kiểm tra View & Thống kê
PRINT N'=== T3. KIỂM TRA VIEW & HÀM THỐNG KÊ ===';
SET @dk = CASE WHEN (SELECT SUM(so_don) FROM v_thong_ke_don_theo_trang_thai) = (SELECT COUNT(*) FROM don_hang) THEN 1 ELSE 0 END;
EXEC #assert_true N'Tổng v_thong_ke_don_theo_trang_thai = tổng số đơn hàng', @dk;

SET @dk = CASE WHEN (SELECT kien_giao_thanh_cong FROM v_hieu_suat_tai_xe WHERE ma_tx = 'TX002') >= 2
                AND (SELECT kien_giao_that_bai FROM v_hieu_suat_tai_xe WHERE ma_tx = 'TX002') >= 1 THEN 1 ELSE 0 END;
EXEC #assert_true N'v_hieu_suat_tai_xe: TX002 có kiện giao thành công và giao thất bại', @dk;

SET @dk = CASE WHEN dbo.fn_ty_le_giao_thanh_cong(DATEADD(DAY, -7, CAST(SYSDATETIME() AS DATE)), CAST(SYSDATETIME() AS DATE)) BETWEEN 0 AND 100 THEN 1 ELSE 0 END;
EXEC #assert_true N'fn_ty_le_giao_thanh_cong trả về giá trị 0-100', @dk;

ROLLBACK TRAN;
SET NOCOUNT OFF;
PRINT N'=== HOÀN TẤT TOÀN BỘ TEST (ĐÃ ROLLBACK DỮ LIỆU TEST ĐỂ GIỮ SẠCH DB) ===';
GO

-- =========================================================================================
-- T4. MINH CHỨNG HIỆU NĂNG INDEX (DÙNG ĐỂ CHỤP ẢNH EXECUTION PLAN & STATISTICS IO)
-- =========================================================================================
SET STATISTICS IO, TIME ON;

SELECT ma_ls, ma_dh, ma_tt, thoi_gian, ghi_chu
FROM dbo.lich_su_trang_thai WITH (INDEX(ix_ls_dh))
WHERE ma_dh = 'DH000003'
ORDER BY thoi_gian ASC;

SET STATISTICS IO, TIME OFF;
GO