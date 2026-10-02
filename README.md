# 🌾 Nông Trại Việt

Game mô phỏng nông trại 2D làm bằng **Godot 4.7**, hình ảnh pixel-art được **vẽ bằng code**; riêng **cây đã chín** dùng ảnh chính trong thư mục `picture/`. Gồm **16 loại cây Việt Nam** chia 3 nhóm, mở khóa dần **khi đủ tiền**.

## Cách chạy
1. Cài [Godot 4.7](https://godotengine.org/download) (bản thường, không cần bản .NET).
2. Mở Godot → **Import** → chọn file `project.godot` trong thư mục này.
3. Bấm **F5** (Run Project).

## 🎣 Câu cá (mới!)
- Gặp **Chú Hai** ở bờ ao (phía Đông Nam bản đồ): **mua cần câu** + bán cá.
- Cần câu có **số lượt câu giới hạn**: Sơ cấp **10 lượt** (100 xu) · Trung cấp **20 lượt** (500 xu) · Cao cấp **30 lượt** (1200 xu).
- Đứng bờ ao bấm **E** để thả câu → **chờ 15 giây** → tự động kéo cần.
- Tỷ lệ mỗi lượt: **30%** không cá · **40%** cá phổ thông · **20%** cá trung cấp · **9.99%** cá hiếm · **0.01%** Cá Chiên huyền thoại.
- 12 loại cá: Rô Đồng, Chép, Mè, Trắm · Lóc, Lăng, Bống, Diêu Hồng · **Trê Vàng (chỉ ban đêm!)**, Hồi Nước Ngọt, Tai Tượng · **Cá Chiên (huyền thoại)**.

## 🛠️ Cuốc (mới!)
- Cày đất **phải có cuốc** — mỗi cuốc chỉ cày được **1 ô** rồi hết.
- Bắt đầugame có **2 cuốc**; mua thêm **20 xu/cuốc** ở cửa hàng Bác Tư.
- Số cuốc hiển thị trên HUD (góc trái trên).

## 🐔 Chăn nuôi gia cầm (mới!)
- Gặp **Cô Tư** (cạnh chuồng phía Tây Nam): mua **chuồng** + **gia cầm giống** + thu mua sản phẩm.
- **Muốn nuôi phải mua chuồng trước**: Chuồng nhỏ 400 xu (Gà/Vịt/Ngan/Cút/Bồ câu) · Chuồng lớn 1200 xu (Ngỗng/Trĩ/Đà điểu). 1 chuồng nuôi 1 con.
- 11 loại: **Gà thịt, Gà đẻ trứng, Gà thả vườn, Vịt thịt, Vịt đẻ trứng, Ngan (Vịt xiêm), Ngỗng, Chim cút, Bồ câu, Chim trĩ, Đà điểu**.
- Con nào đủ thời gian tự cho sản phẩm (tối đa 3 con/sản phẩm chờ) — ra chuồng bấm **E** để thu → bán cho Cô Tư.

## 🗺️ Bản đồ nhỏ & chỉ đường (mới!)
- **Bản đồ nhỏ ở góc dưới phải**: hiển thị toàn bộ nông trại, các con đường và vị trí bạn đang đứng (chấm trắng nhấp nháy).
- **Bấm vào một địa điểm trên bản đồ** (Nhà, Nông trại, Chuồng, 3 quầy hàng, Ao cá) → dải **chấm trắng** chạy dọc lối đi dẫn tới nơi, kèm vòng sáng chỉ đích.
- **Nút "✕ HỦY CHỈ ĐƯỜNG"** bên dưới bản đồ (hoặc tự tắt khi đến nơi).
- Phím **+** phóng to bản đồ ra **giữa màn hình** (kèm tên từng địa điểm), phím **−** thu về như cũ.

## Điều khiển
| Phím | Chức năng |
|---|---|
| W A S D / mũi tên | Di chuyển |
| E / Space | Tương tác: cày đất, gieo hạt, tưới nước, thu hoạch, nói chuyện |
| I / Tab | Kho đồ — chọn hạt giống để gieo |
| R | Đổi nhanh loại hạt đang cầm |
| + / − | Phóng to bản đồ ra giữa màn hình / thu về như cũ |
| Esc | Tạm dừng / đóng cửa sổ |

## Vòng lặp chơi (đúng lộ trình 13 bước)
1. **Nhân vật đi lại** — WASD, nhân vật có nón lá 🌾
2. **Map nông trại** — nhà, quầy hàng Bác Tư, ao, cây, đường đi, bù nhìn, hàng rào quanh ruộng (2 cổng: lối đi phía Tây + mép dưới)
3. **Cày đất** — đứng cạnh ô cỏ, bấm E
4. **Gieo hạt** — chọn hạt ở kho đồ (I) rồi bấm E
5. **Tưới nước** — bấm E trên ô đã gieo (đất ẩm có màu đậm hơn). **Đất khô sau ~4 phút** — tưới lại để cây tiếp tục lớn
6. **Cây phát triển** — cây lớn dần **theo thời gian thật khi đất ẩm** (ví dụ lúa chín sau ~1 phút đất ẩm)
7. **Thu hoạch** — cây chín, bấm E
8. **Kho đồ** — I: xem hạt + nông sản, chọn hạt
9. **Tiền** — bán nông sản ở cửa hàng
10. **Cửa hàng** — nói chuyện Bác Tư: mua hạt, bán đồ, mở khóa cây
11. **NPC** — Bác Tư hướng dẫn và mở cửa hàng
12. **Ngày/đêm** — **1 ngày dài ~15 phút thật**, trời đổi màu sáng → chiều → tối; 2h sáng sẽ gục ngã; ngủ trong nhà để sang ngày mới
13. **Lưu game** — tự lưu mỗi khi ngủ, hoặc Esc → Lưu game; menu chính có nút "Tiếp tục"

## 16 loại cây & thứ tự mở khóa
Đủ tiền ở cửa hàng sẽ mở khóa **cây kế tiếp** trong danh sách. Thời gian lớn tính cho đất luôn đủ ẩm:

| # | Cây | Nhóm | Hạt | Bán | Lớn (~phút) | Mở khóa |
|---|-----|------|-----|-----|-------------|---------|
| 1 | Lúa gạo | Lương thực | 10 | 26 | 1 | Có sẵn |
| 2 | Lúa mì | Lương thực | 16 | 45 | 1,5 | 150 |
| 3 | Ngô (Bắp) | Lương thực | 22 | 70 | 2 | 350 |
| 4 | Khoai lang | Lương thực | 20 | 62 | 2 | 600 |
| 5 | Sắn (Khoai mì) | Lương thực | 26 | 95 | 2,5 | 900 |
| 6 | Khoai tây | Rau củ | 30 | 88 | 2 | 1.250 |
| 7 | Cà rốt | Rau củ | 24 | 66 | 1,5 | 1.650 |
| 8 | Bắp cải | Rau củ | 36 | 110 | 2 | 2.100 |
| 9 | Cà chua | Rau củ | 32 | 96 | 2 | 2.600 |
| 10 | Dưa hấu | Rau củ | 48 | 155 | 3 | 4.200 |
| 11 | Đậu tương | Công nghiệp | 34 | 92 | 2 | 3.100 |
| 12 | Lạc (Đậu phụng) | Công nghiệp | 30 | 84 | 2 | 3.600 |
| 13 | Mía | Công nghiệp | 55 | 175 | 3,5 | 5.200 |
| 14 | Cà phê | Công nghiệp | 65 | 225 | 4 | 6.800 |
| 15 | Hồ tiêu | Công nghiệp | 78 | 280 | 4,5 | 9.000 |
| 16 | Cao su | Công nghiệp | 95 | 330 | 5 | 12.000 |

## Xử lý sự cố
**Không bấm được nút "Bắt đầu mới"?** Thử lần lượt:
1. Bấm phím **Enter** (hoặc **C**) ngay trong cửa sổ game — luôn bắt đầu được.
2. Bấm chuột vào cửa sổ game trước để cửa sổ nhận focus, rồi bấm lại nút.
3. Chạy game **trực tiếp** bằng file `run_game.bat` (mở không qua editor — khắc phục lỗi chuột của cửa sổ game nhúng trong editor Godot).
4. Nếu chạy F5 trong Godot mà chuột không ăn: **Editor → Editor Settings → Run → Window Placement → Game Embed Mode = Disabled**, rồi F5 lại.
5. Vẫn lỗi? Nhìn tab **Output** phía dưới editor, chụp lại các dòng đỏ `SCRIPT ERROR` gửi mình.

## Cấu trúc code
```
scenes/main.tscn        — scene gốc (mọi thứ dựng bằng code)
scripts/
  boot.gd               — phím điều khiển + font tiếng Việt
  crop_db.gd            — dữ liệu 16 loại cây + bản đồ ảnh picture/ khi chín
  texture_gen.gd        — vẽ pixel-art bằng code; cây chín lấy ảnh từ picture/
  picture/              — ảnh chính của 16 loại cây (hiện khi cây chín)
  game_state.gd         — tiền / ngày / giờ / cây mở khóa
  inventory.gd          — kho đồ
  save_system.gd        — lưu/tải JSON (user://save.json)
  farm.gd, farm_tile.gd — lưới ô đất canh tác
  player.gd, npc.gd     — nhân vật, NPC
  main.gd               — điều phối + ngày/đêm + ngủ + debug
  ui/                   — HUD, cửa hàng, kho đồ, hội thoại, menu, bản đồ nhỏ chỉ đường
```
