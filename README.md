# MusicSub Pro Max - Công cụ nghe và tải nhạc từ terminal

![GitHub](https://img.shields.io/github/license/kidtomboy/MusicSub)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![MusicSub Logo](https://i.imgur.com/wmNNw7m.jpeg)

**MusicSub Pro Max** là một công cụ mạnh mẽ giúp bạn tìm kiếm, nghe và tải nhạc trực tiếp từ terminal với nhiều tính năng ưu việt.

## 🌟 Tính năng nổi bật

- 🔍 **Tìm kiếm nhạc** từ nhiều nguồn: Spotify, YouTube, SoundCloud, Mixcloud, Deezer
- ▶️ **Phát nhạc** với trình phát yêu thích (mpv/vlc/ffplay)
- 💾 **Tải xuống** bài hát với nhiều tùy chọn chất lượng
- 🛠️ **Công cụ âm nhạc** mạnh mẽ: tạo playlist, xem lời bài hát
- 🕒 **Lịch sử nghe** chi tiết
- ⭐ **Danh sách yêu thích** thông minh
- ⚙️ **Hệ thống cache** và cấu hình linh hoạt
- 📱 **Hỗ trợ đa nền tảng**: Linux, Windows, macOS, Android/Termux
- 🎨 **Giao diện terminal** đẹp với nhiều theme
- 🎨 **Hiển thị lời bài hát** và visualizer âm thanh

## 📥 Cài đặt

### Yêu cầu hệ thống
- Bash 4.0+
- Các công cụ cần thiết: `curl`, `jq`, `fzf`, `mpv` (hoặc trình phát khác)

### Cài đặt tự động
```bash
bash <(curl -s https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh)
```

### Cài đặt thủ công
1. Tải script:
```bash
curl -o musicsub.sh https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh
```

2. Cấp quyền thực thi:
```bash
chmod +x musicsub.sh
```

3. Chạy chương trình:
```bash
./musicsub.sh
```

## 🚀 Cách sử dụng

### Chế độ tương tác
```bash
./musicsub.sh
```
Sau đó chọn các tùy chọn từ menu

### Chế độ dòng lệnh
- Phát trực tiếp:
```bash
./musicsub.sh --play "Tên Bài Hát"
```

- Tìm kiếm:
```bash
./musicsub.sh --search "Tìm Kiếm"
```

- Tải xuống:
```bash
./musicsub.sh --download "URL"
```

## 🛠 Công cụ tích hợp

1. **Chỉnh sửa playlist**:
   - Tạo, thêm và phát playlist cá nhân
   - Xem danh sách bài hát trong playlist

2. **Quản lý lịch sử**:
   - Xem lịch sử nghe chi tiết
   - Xóa lịch sử theo yêu cầu

3. **Dữ liệu yêu thích**:
   - Quản lý danh sách yêu thích bài hát

## ⚙️ Cấu hình

Chương trình tự động tạo file cấu hình tại:
- Linux/macOS: `~/.config/musicsub_pro/config.cfg`
- Windows: `%APPDATA%/musicsub_pro/config.cfg`
- Termux: `~/.config/musicsub_pro/config.cfg`

Các tùy chọn cấu hình chính:
- Trình phát mặc định (mpv/vlc/ffplay)
- Chất lượng nhạc (128k/192k/256k/320k)
- Theme giao diện (dark/light/blue/green/red)
- Thư mục tải xuống
- Bật/tắt thông báo

## 📜 Lịch sử phiên bản

### v2.0.0 (05-04-2025)
- [x] Thêm hỗ trợ nguồn Deezer và Mixcloud
- [x] Cải thiện hiệu năng tìm kiếm
- [x] Thêm tính năng quản lý playlist và lịch sử nghe

### v1.0.0 (Không rõ do không upload lên github)
- [x] Phiên bản đầu tiên
- [x] Cải thiện giao diện

---

## 🐛 Báo cáo lỗi (Bug Reports)

Nếu bạn gặp bất kỳ lỗi nào khi sử dụng MusicSub Pro Max, vui lòng làm theo các bước sau:

### Cách báo cáo lỗi
1. **Kiểm tra lỗi đã được báo cáo chưa**:
   - Xem qua [mục Issues](https://github.com/kidtomboy/MusicSub/issues) để chắc chắn lỗi chưa được báo cáo

2. **Thu thập thông tin**:
   - Phiên bản MusicSub: `./musicsub.sh --version`
   - Hệ điều hành và phiên bản
   - Các thông báo lỗi từ terminal
   - File log (nằm trong `~/.config/musicsub_pro/logs/`)

3. **Tạo báo cáo lỗi mới**:
   - Truy cập [trang Issues](https://github.com/kidtomboy/MusicSub/issues/new/choose)
   - Chọn "Bug Report"
   - Điền đầy đủ thông tin theo mẫu

### Mẫu báo cáo lỗi chuẩn
```markdown
**Mô tả lỗi**
Mô tả rõ ràng và chi tiết về lỗi gặp phải

**Các bước để tái tạo lỗi**
1. Bước 1...
2. Bước 2...
3. Xem lỗi xảy ra

**Kết quả mong đợi**
Bạn mong đợi điều gì sẽ xảy ra?

**Ảnh chụp màn hình/Ghi hình**
Nếu có thể, hãy đính kèm ảnh chụp hoặc video

**Thông tin hệ thống**
- OS: [e.g. Ubuntu 22.04]
- Version: [e.g. 2.0.0]
- Terminal: [e.g. Terminator, GNOME Terminal]

**File log**
Đính kèm file log hoặc paste nội dung lỗi (xóa thông tin nhạy cảm)
```

### Xử lý lỗi khẩn cấp
Đối với lỗi nghiêm trọng ảnh hưởng đến trải nghiệm, bạn có thể:
1. Tạm thời sử dụng phiên bản cũ:
```bash
git checkout tags/v1.0.0
```
2. Liên hệ trực tiếp qua email: iamkidtomboyreal@gmail.com

## 🛠 Tự khắc phục lỗi thường gặp

Một số lỗi phổ biến và cách khắc phục:

### 1. Lỗi thiếu phụ thuộc
```bash
[ERROR] Thiếu package: mpv
```
**Cách khắc phục**:
```bash
# Ubuntu/Debian
sudo apt install mpv

# Arch Linux
sudo pacman -S mpv

# Termux
pkg install mpv
```

### 2. Lỗi kết nối
```bash
[ERROR] Không thể kết nối đến nguồn
```
**Cách khắc phục**:
- Kiểm tra kết nối Internet
- Thử đổi DNS (8.8.8.8 hoặc 1.1.1.1)
- Chờ 5 phút và thử lại

### 3. Lỗi phát nhạc
```bash
[ERROR] Không thể phát nhạc
```
**Cách khắc phục**:
1. Thử đổi trình phát mặc định:
```bash
# Trong menu cài đặt
Chọn "Thay đổi trình phát mặc định"
```
2. Cập nhật driver âm thanh
3. Kiểm tra file cấu hình tại `~/.config/musicsub_pro/config.cfg`

### 4. Lỗi font chữ
```bash
[WARNING] Hiển thị font chữ không đúng
```
**Cách khắc phục**:
- Cài đặt font đầy đủ:
```bash
# Linux
sudo apt install fonts-noto

# Termux
pkg install fontconfig
```

## 🤝 Đóng góp sửa lỗi

Chúng tôi hoan nghênh mọi đóng góp để cải thiện MusicSub:
1. Fork repository
2. Tạo branch mới (`git checkout -b fix/bug-name`)
3. Commit thay đổi
4. Push lên branch
5. Tạo Pull Request

### **Hiện giờ rất cần mọi ý kiến đóng góp để hoàn thiện sản phẩm này! Đang có lỗi ở Spotify và Deezer nên có lẽ sẽ fix sau**

## 🙏 Cảm ơn

- **Cộng đồng mã nguồn mở** - Đóng góp ý tưởng và công cụ

## 👨‍💻 Tác giả
Original: [Kidtomboy](https://github.com/kidtomboy)

## 💖 Donate

Nếu thấy dự án hữu ích, bạn có thể ủng hộ tác giả qua:
- [GitHub Sponsors](https://raw.githubusercontent.com/Kidtomboy/Kidtomboy/refs/heads/main/images/bank/BIDV_Kidtomboy.jpg)
- Momo: 038.783.1869 | Cherry🍒

## 📄 Dự án này được phân phối theo giấy phép MIT.

- [Giấy Phép MIT](https://raw.githubusercontent.com/Kidtomboy/MusicSub/main/LICENSE)

---

**MusicSub Pro Max** - Nghe nhạc mọi lúc, mọi nơi! 🎉
