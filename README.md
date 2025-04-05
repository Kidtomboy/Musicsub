# MusicSub Pro Max - Trình Phát Nhạc Đa Nền Tảng

![GitHub](https://img.shields.io/github/license/kidtomboy/MusicSub)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011?style=flat&logo=gnu-bash&logoColor=white)
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![MusicSub Logo](https://i.imgur.com/wmNNw7m.jpeg)

**MusicSub Pro Max** là trình phát nhạc đa nền tảng mạnh mẽ với giao diện terminal ấn tượng, hỗ trợ phát nhạc từ nhiều nguồn khác nhau.

## 🌟 Tính Năng Nổi Bật

- 🎵 **Đa nguồn nhạc**: YouTube, Spotify, SoundCloud, Mixcloud, Deezer
- 💾 **Tải nhạc đa chất lượng**: 128k, 192k, 256k, 320k
- 📜 **Hiển thị lời bài hát** trực tiếp
- 🎨 **Visualizer âm thanh** (yêu cầu cava)
- 🎶 **Quản lý playlist** cá nhân
- ⭐ **Danh sách yêu thích** thông minh
- 🕒 **Lịch sử nghe** chi tiết
- ⚙️ **Hệ thống cache** và cấu hình linh hoạt
- 📱 **Đa nền tảng**: Linux, Windows, macOS, Android/Termux
- 🎨 **Giao diện đẹp** với nhiều theme màu sắc

## 📥 Cài Đặt

### Yêu Cầu Hệ Thống
- Bash 4.0+
- Các công cụ cần thiết: `curl`, `jq`, `fzf`, `mpv` (hoặc trình phát khác), `yt-dlp`

### Cài Đặt Tự Động
```bash
bash <(curl -s https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh)
```

### Cài Đặt Thủ Công
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

## 🚀 Cách Sử Dụng

### Chế Độ Tương Tác
```bash
./musicsub.sh
```
Sau đó chọn các tùy chọn từ menu

### Chế Độ Dòng Lệnh
- Phát trực tiếp:
```bash
./musicsub.sh --play "Tên Bài Hát"
```

- Tìm kiếm:
```bash
./musicsub.sh --search "Từ khóa"
```

- Tải nhạc:
```bash
./musicsub.sh --download "URL"
```

## ⚙️ Cấu Hình

Chương trình tự động tạo file cấu hình tại:
- Linux/macOS: `~/.config/musicsub_pro/config.cfg`
- Windows: `%APPDATA%/musicsub_pro/config.cfg`
- Termux: `~/.config/musicsub_pro/config.cfg`

Các tùy chọn chính:
- Trình phát mặc định (mpv/vlc)
- Chất lượng nhạc (128k/192k/256k/320k)
- Theme giao diện (dark/light/blue/green/red)
- Thư mục tải xuống
- Bật/tắt thông báo

## 📜 Lịch Sử Phiên Bản

### v2.0.0 (04/04/2025)
- [x] Thêm hỗ trợ Deezer và Mixcloud
- [x] Cải thiện hiệu năng tìm kiếm
- [x] Thêm tính năng visualizer âm thanh
- [x] Hỗ trợ Termux trên Android

### v1.0.0 (15/03/2025)
- [x] Phiên bản đầu tiên
- [x] Hệ thống cache thông minh
- [x] Giao diện terminal đa màu sắc (chưa cập nhật lại giao diện)

## 🐛 Báo Cáo Lỗi

Nếu gặp lỗi khi sử dụng, vui lòng:
1. Kiểm tra [mục Issues](https://github.com/kidtomboy/MusicSub/issues)
2. Thu thập thông tin:
   - Phiên bản MusicSub: `./musicsub.sh --version`
   - Hệ điều hành
   - Thông báo lỗi
   - File log (`~/.config/musicsub_pro/logs/`)
3. Tạo báo cáo mới trên GitHub

## 🛠 Tự Khắc Phục Lỗi Thường Gặp

### 1. Lỗi thiếu phụ thuộc
```bash
[ERROR] Thiếu package: yt-dlp
```
**Cách khắc phục**:
```bash
# Ubuntu/Debian
sudo apt install yt-dlp

# Arch Linux
sudo pacman -S yt-dlp

# Termux
pkg install yt-dlp
```

### 2. Lỗi phát nhạc
```bash
[ERROR] Không thể phát nhạc
```
**Cách khắc phục**:
1. Thử đổi trình phát trong cài đặt
2. Kiểm tra kết nối Internet
3. Xem file log để biết chi tiết lỗi

## 🤝 Đóng Góp

Chúng tôi hoan nghênh mọi đóng góp:
1. Fork repository
2. Tạo branch mới
3. Commit thay đổi
4. Push lên branch
5. Tạo Pull Request

## **Rất cần người thử nghiệm và báo cáo lỗi! Vì shell trên được dựa hoàn toàn vào [Anisub](https://github.com/kidtomboy/Anisub)**

## 👨‍💻 Tác Giả
Original: [Kidtomboy](https://github.com/kidtomboy)

## 💖 Donate

Ủng hộ tác giả qua:
- [GitHub Sponsors](https://github.com/sponsors/kidtomboy)
- Momo: 038.783.1869 | Cherry🍒

## 📄 Giấy Phép
Dự án được phân phối theo [Giấy Phép MIT](https://raw.githubusercontent.com/Kidtomboy/MusicSub/main/LICENSE)

---

🎶 **MusicSub Pro Max - Âm nhạc mọi lúc, mọi nơi!** 🎶
