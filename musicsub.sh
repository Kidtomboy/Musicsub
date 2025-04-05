#!/bin/bash

###############################################################################
# MUSICSUB BY CHERRY | KIDTOMBOY
# Phiên bản: 2.0.0
# Tác giả: 
#   - Original: @NiyakiPham 
#   - Remake & Enhance: @Kidtomboy
# Ngày cập nhật: 04-04-2025
#
# Tính năng chính:
# - Phát nhạc từ nhiều nguồn (Spotify, YouTube, SoundCloud, Mixcloud, Deezer)
# - Tải xuống bài hát với nhiều tùy chọn chất lượng
# - Công cụ âm nhạc mạnh mẽ (tạo playlist, xem lời bài hát)
# - Lịch sử nghe chi tiết
# - Danh sách yêu thích thông minh
# - Hệ thống cache và cấu hình linh hoạt
# - Hỗ trợ đa nền tảng (Linux, Windows, macOS, Android/Termux)
# - Giao diện terminal đẹp với nhiều theme
# - Hiển thị lời bài hát và visualizer âm thanh
###############################################################################

# ============================ CẤU HÌNH HỆ THỐNG ============================
VERSION="2.0.0"
AUTHORS=("Kidtomboy (Remake & Enhance)" "NiyakiPham (Original)")
DONATION_LINK="https://github.com/kidtomboy"

# ============================ BIỂU TƯỢNG UNICODE ============================
SYM_SEARCH="🔍" 
SYM_HIST="🕒"  
SYM_FAV="⭐"   
SYM_TOOLS="🛠️"  
SYM_SETTINGS="⚙️" 
SYM_UPDATE="🔄" 
SYM_INFO="ℹ️"  
SYM_EXIT="🚪"  
SYM_DOWNLOAD="💾" 
SYM_PLAY="▶️"   
SYM_LYRICS="📜"
SYM_VISUAL="🎨"
SYM_PLAYLIST="🎵"
SYM_PROMPT="#️⃣"
SYM_NEXT="⏭" 
SYM_PREV="⏮" 
SYM_SELECT="🔢"
SYM_FOLDER="📁"
SYM_WARNING="⚠️"
SYM_ERROR="❌"
SYM_SUCCESS="✅"

# Unicode box-drawing characters
BOX_HORIZ="─"
BOX_VERT="│"
BOX_CORNER_TL="┌"
BOX_CORNER_TR="┐"
BOX_CORNER_BL="└"
BOX_CORNER_BR="┘"
BOX_T="┬"
BOX_B="┴"
BOX_L="├"
BOX_R="┤"
BOX_CROSS="┼"

# Phát hiện hệ điều hành
detect_os() {
    case "$(uname -s)" in
        Linux*)     
            OS="Linux"
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                OS_DISTRO="$ID"
            elif [[ -f /etc/debian_version ]]; then
                OS_DISTRO="debian"
            elif [[ -f /etc/arch-release ]]; then
                OS_DISTRO="arch"
            elif [[ -f /etc/gentoo-release ]]; then
                OS_DISTRO="gentoo"
            else
                OS_DISTRO="unknown"
            fi
            ;;
        Darwin*)    
            OS="macOS"
            OS_DISTRO="macos"
            ;;
        CYGWIN*|MINGW*|MSYS*) 
            OS="Windows"
            OS_DISTRO="windows"
            ;;
        *)          
            OS="Unknown"
            OS_DISTRO="unknown"
    esac

    # Kiểm tra Termux trên Android
    if [[ "$OS" == "Linux" ]] && [[ -d "/data/data/com.termux/files" ]]; then
        OS="Android/Termux"
        OS_DISTRO="termux"
    fi
}

detect_os

# ============================ CẤU HÌNH THƯ MỤC ============================
init_dirs() {
    log "SYSTEM" "Đang khởi tạo thư mục..."
    case "$OS" in
        "Linux"|"macOS")
            CONFIG_DIR="$HOME/.config/musicsub_pro"
            DOWNLOAD_DIR="$HOME/Downloads/musicsub_downloads"
            ;;
        "Windows")
            CONFIG_DIR="$APPDATA/musicsub_pro"
            DOWNLOAD_DIR="$USERPROFILE/Downloads/musicsub_downloads"
            ;;
        "Android/Termux")
            CONFIG_DIR="$HOME/.config/musicsub_pro"
            DOWNLOAD_DIR="/sdcard/Download/musicsub_downloads"
            ;;
        *)
            CONFIG_DIR="$HOME/.musicsub_pro"
            DOWNLOAD_DIR="$HOME/musicsub_downloads"
            ;;
    esac

    # Tạo các thư mục cần thiết
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR/cache" "$CONFIG_DIR/logs" \
             "$CONFIG_DIR/backups" "$CONFIG_DIR/playlists"

    # File cấu hình
    CONFIG_FILE="$CONFIG_DIR/config.cfg"
    LOG_FILE="$CONFIG_DIR/logs/musicsub_$(date +%Y%m%d).log"
    HISTORY_FILE="$CONFIG_DIR/history.json"
    FAVORITES_FILE="$CONFIG_DIR/favorites.json"
    CACHE_DIR="$CONFIG_DIR/cache"
    BACKUP_DIR="$CONFIG_DIR/backups"
    PLAYLIST_DIR="$CONFIG_DIR/playlists"

    # Tạo file cấu hình mặc định nếu chưa có
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "CONFIG" "Tạo file cấu hình mới"
    cat > "$CONFIG_FILE" <<- EOM
# CẤU HÌNH MẶC ĐỊNH MUSICSUB PRO
DEFAULT_PLAYER="mpv"
DEFAULT_QUALITY="320k"
DEFAULT_SOURCE="youtube"
THEME="dark"
NOTIFICATIONS="true"
MAX_CACHE_AGE=86400
UPDATE_URL="https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh"
AUTO_BACKUP=true
AUTO_CLEANUP=true
PLAYER_ARGS="--no-terminal --force-window --quiet"
SKIP_DEPENDENCY_CHECK=false
LOG_LEVEL="info" 
LOG_TO_FILE=true  
SKIP_OPTIONAL_PKGS=false
TERMINAL_NOTIFY=true
SHOW_LYRICS=true
SHOW_VISUALIZER=false
EOM
    fi

    # Load cấu hình
    source "$CONFIG_FILE"
    log "CONFIG" "Đã tải cấu hình từ $CONFIG_FILE"
    
    # Sao lưu tự động nếu được bật
    if [[ "$AUTO_BACKUP" == "true" ]]; then
        local backup_file="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).cfg"
        cp "$CONFIG_FILE" "$backup_file"
        log "BACKUP" "Đã sao lưu cấu hình tại $backup_file"
        # Giữ tối đa 5 bản sao lưu
        ls -t "$BACKUP_DIR"/config_backup_*.cfg | tail -n +6 | xargs rm -f --
    fi
    
    # Dọn dẹp cache tự động nếu được bật
    if [[ "$AUTO_CLEANUP" == "true" ]]; then
        log "CLEANUP" "Đang dọn dẹp cache cũ..."
        find "$CACHE_DIR" -type f -mtime +7 -exec rm -f {} \;
    fi
}

# ============================ CẤU HÌNH MÀU SẮC & GIAO DIỆN ============================
init_ui() {
    log "UI" "Đang khởi tạo giao diện..."
    # Màu sắc theo theme
    case "$THEME" in
        "dark")
            PRIMARY='\033[0;35m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[40m'
            ;;
        "light")
            PRIMARY='\033[0;34m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;35m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;30m'
            BG='\033[47m'
            ;;
        "blue")
            PRIMARY='\033[0;34m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[44m'
            ;;
        "green")
            PRIMARY='\033[0;32m'
            SECONDARY='\033[1;32m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;34m'
            TEXT='\033[0;37m'
            BG='\033[42m'
            ;;
        "red")
            PRIMARY='\033[0;31m'
            SECONDARY='\033[1;31m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;34m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[41m'
            ;;
        *)
            PRIMARY='\033[0;35m'
            SECONDARY='\033[0;36m'
            ACCENT='\033[1;33m'
            WARNING='\033[0;31m'
            INFO='\033[0;32m'
            TEXT='\033[0;37m'
            BG='\033[40m'
            ;;
    esac
    
    NC='\033[0m' # No Color
}

# ============================ HÀM HIỂN THỊ GIAO DIỆN ============================
draw_box() {
    local width=$1
    local title=$2
    local color=$3
    local content=$4
    
    echo -ne "${color}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_TR}${NC}\n"
    
    if [[ -n "$title" ]]; then
        local title_len=${#title}
        local left_pad=$(( (width - title_len - 2) / 2 ))
        local right_pad=$(( width - title_len - 2 - left_pad ))
        
        echo -ne "${color}${BOX_VERT}${NC}"
        for ((i=0; i<left_pad; i++)); do echo -ne " "; done
        echo -ne "${ACCENT}${title}${NC}"
        for ((i=0; i<right_pad; i++)); do echo -ne " "; done
        echo -ne "${color}${BOX_VERT}${NC}\n"
        
        echo -ne "${color}${BOX_L}"
        for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
        echo -ne "${BOX_R}${NC}\n"
    fi
    
    while IFS= read -r line; do
        echo -ne "${color}${BOX_VERT}${NC} ${TEXT}${line}"
        for ((i=${#line}; i<width-3; i++)); do echo -ne " "; done
        echo -ne "${color}${BOX_VERT}${NC}\n"
    done <<< "$content"
    
    echo -ne "${color}${BOX_CORNER_BL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_BR}${NC}\n"
}

show_header() {
    clear
    local width=60
    local title=" MUSICSUB v$VERSION "
    
    echo -ne "${PRIMARY}${BOX_CORNER_TL}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_CORNER_TR}${NC}\n"
    
    echo -ne "${PRIMARY}${BOX_VERT}${NC}"
    for ((i=0; i<(width-${#title}-2)/2; i++)); do echo -ne " "; done
    echo -ne "${ACCENT}${title}${NC}"
    for ((i=0; i<(width-${#title}-2)/2; i++)); do echo -ne " "; done
    echo -ne "${PRIMARY}${BOX_VERT}${NC}\n"
    
    echo -ne "${PRIMARY}${BOX_L}"
    for ((i=0; i<width-2; i++)); do echo -ne "${BOX_HORIZ}"; done
    echo -ne "${BOX_R}${NC}\n"
}

show_menu() {
    local options=("$@")
    local width=60
    local content=""
    
    for i in "${!options[@]}"; do
        if [[ $((i%2)) -eq 0 ]]; then
            # Menu item
            content+="${PRIMARY}${options[i]}${NC}\n"
        else
            # Description
            content+="  ${TEXT}${options[i]}${NC}\n"
        fi
    done
    
    draw_box $width "" "$PRIMARY" "$content"
}

# ============================ GHI LOG (NHẬT KÝ) ============================
log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local log_type="${1^^}"  # Chuyển thành chữ hoa
    local message="$2"
    local user_input="$3"
    
    # Xác định mức độ log
    local log_level_num=0
    case "$LOG_LEVEL" in
        "debug") log_level_num=0 ;;
        "info") log_level_num=1 ;;
        "warn") log_level_num=2 ;;
        "error") log_level_num=3 ;;
        *) log_level_num=1 ;;
    esac
    
    # Xác định mức độ log hiện tại
    local current_level_num=0
    case "$log_type" in
        "DEBUG") current_level_num=0 ;;
        "INFO") current_level_num=1 ;;
        "WARN") current_level_num=2 ;;
        "ERROR") current_level_num=3 ;;
        *) current_level_num=1 ;;
    esac
    
    # Chỉ ghi log nếu mức độ hiện tại >= mức độ cấu hình
    if [[ $current_level_num -lt $log_level_num ]]; then
        return
    fi
    
    # Tạo thông điệp log
    local log_entry="[$timestamp] [$log_type] $message"
    [[ -n "$user_input" ]] && log_entry+=" | Input: $user_input"
    
    # Hiển thị log ra console nếu ở chế độ debug
    if [[ "$DEBUG_MODE" == "true" || "$log_type" == "ERROR" || "$log_type" == "WARN" ]]; then
        case "$log_type" in
            "ERROR") echo -e "${WARNING}$log_entry${NC}" >&2 ;;
            "WARN") echo -e "${ACCENT}$log_entry${NC}" >&2 ;;
            *) echo -e "${SECONDARY}$log_entry${NC}" >&2 ;;
        esac
    fi
    
    # Ghi vào file log nếu được bật
    if [[ "$LOG_TO_FILE" == "true" ]]; then
        echo "$log_entry" >> "$CONFIG_DIR/musicsub.log"
    fi
    
    # Giới hạn kích thước file log (tối đa 1MB)
    if [[ -f "$CONFIG_DIR/musicsub.log" ]]; then
        local log_size=$(stat -c %s "$CONFIG_DIR/musicsub.log" 2>/dev/null || stat -f %z "$CONFIG_DIR/musicsub.log")
        if [[ $log_size -gt 1048576 ]]; then  # 1MB
            tail -n 500 "$CONFIG_DIR/musicsub.log" > "$CONFIG_DIR/musicsub.log.tmp"
            mv "$CONFIG_DIR/musicsub.log.tmp" "$CONFIG_DIR/musicsub.log"
        fi
    fi
}

# ============================ HIỂN THỊ CÁC THÔNG BÁO ============================
notify() {
    local message="$1"
    local icon="${2:-$SYM_INFO}"
    
    if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
        echo -e "${INFO}[${icon}]${NC} $message"
    fi
    
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        case "$OS" in
            "Linux")
                notify-send -i "audio-headphones" "MusicSub" "$icon $message" 2>/dev/null
                ;;
            "macOS")
                osascript -e "display notification \"$message\" with title \"MusicSub\" subtitle \"$icon\"" 2>/dev/null
                ;;
            "Windows")
                # TODO: Implement Windows notification
                ;;
            "Android/Termux")
                termux-notification -t "MusicSub" -c "$icon $message" 2>/dev/null
                ;;
        esac
    fi
    log "INFO" "$message"
}

warn() {
    local message="$1"
    echo -e "${WARNING}[${SYM_WARNING}]${NC} $message" >&2
    log "WARN" "$message"
}

error() {
    local message="$1"
    echo -e "${WARNING}[${SYM_ERROR}]${NC} $message" >&2
    log "ERROR" "$message"
}

# ============================ KIỂM TRA VÀ TỰ ĐỘNG CÀI ĐẶT CÁC GÓI ============================
check_dependencies() {
    log "SYSTEM" "Kiểm tra phụ thuộc..."
    
    # Bỏ qua nếu có flag --version hoặc SKIP_DEPENDENCY_CHECK=true
    if [[ "$1" == "--version" || "$SKIP_DEPENDENCY_CHECK" == "true" ]]; then
        log "SYSTEM" "Bỏ qua kiểm tra phụ thuộc"
        return 0
    fi

    local -A pkg_manager=(
        ["apt"]="sudo apt-get install -y"
        ["pacman"]="sudo pacman -S --noconfirm"
        ["dnf"]="sudo dnf install -y"
        ["yum"]="sudo yum install -y"
        ["zypper"]="sudo zypper install -y"
        ["brew"]="brew install"
        ["termux"]="pkg install -y"
    )

    # Xác định trình quản lý gói
    local manager
    if [[ "$OS_DISTRO" == "termux" ]]; then
        manager="termux"
    else
        for m in "${!pkg_manager[@]}"; do
            if command -v "$m" &>/dev/null; then
                manager="$m"
                break
            fi
        done
    fi

    if [[ -z "$manager" ]]; then
        error "Không thể xác định trình quản lý gói!"
        log "ERROR" "Không thể xác định trình quản lý gói"
        return 1
    fi

    # Các gói bắt buộc theo hệ điều hành
    local -A required_pkgs
    if [[ "$OS_DISTRO" == "termux" ]]; then
        required_pkgs=(
            ["curl"]="curl"
            ["jq"]="jq"
            ["fzf"]="fzf"
            ["mpv"]="mpv-x"
            ["yt-dlp"]="yt-dlp"
        )
    else
        required_pkgs=(
            ["curl"]="curl"
            ["jq"]="jq"
            ["fzf"]="fzf"
            ["mpv"]="mpv"
            ["yt-dlp"]="yt-dlp"
        )
    fi

    # Các gói tùy chọn theo hệ điều hành
    local -A optional_pkgs
    if [[ "$OS_DISTRO" == "termux" ]]; then
        optional_pkgs=(
            ["ffmpeg"]="ffmpeg"
            ["termux-api"]="termux-api"
            ["cava"]="cava"
            ["python"]="python"
            ["spotdl"]="spotdl"
        )
    else
        optional_pkgs=(
            ["ffmpeg"]="ffmpeg"
            ["notify-send"]="libnotify-bin"
            ["cava"]="cava"
            ["python"]="python3"
            ["spotdl"]="spotdl"
            ["spotify-cli"]="spotify-cli"
        )
    fi

    local missing=()
    local optional_missing=()

    # Kiểm tra gói bắt buộc
    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("${required_pkgs[$cmd]}")
            log "DEPENDENCY" "Thiếu gói bắt buộc: $cmd"
        fi
    done

    # Kiểm tra gói tùy chọn (chỉ nếu SKIP_OPTIONAL_PKGS=false)
    if [[ "$SKIP_OPTIONAL_PKGS" != "true" ]]; then
        for cmd in "${!optional_pkgs[@]}"; do
            if ! command -v "$cmd" &>/dev/null; then
                optional_missing+=("${optional_pkgs[$cmd]}")
                log "DEPENDENCY" "Thiếu gói tùy chọn: $cmd"
            fi
        done
    else
        log "SYSTEM" "Bỏ qua kiểm tra gói tùy chọn do SKIP_OPTIONAL_PKGS=true"
    fi

    # Cài đặt các gói bắt buộc
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "${SYM_WARNING} Đang cài đặt các gói bắt buộc: ${missing[*]}"
        log "SYSTEM" "Cài đặt gói bắt buộc: ${missing[*]}"
        
        if ! ${pkg_manager[$manager]} "${missing[@]}"; then
            error "${SYM_ERROR} Không thể cài đặt các gói bắt buộc!"
            log "ERROR" "Không thể cài đặt gói bắt buộc: ${missing[*]}"
            exit 1
        fi
        log "SYSTEM" "Đã cài đặt gói bắt buộc: ${missing[*]}"
    fi

    # Cài đặt các gói tùy chọn (chỉ nếu SKIP_OPTIONAL_PKGS=false)
    if [[ "$SKIP_OPTIONAL_PKGS" != "true" && ${#optional_missing[@]} -gt 0 ]]; then
        warn "${SYM_WARNING} Các gói tùy chọn chưa có: ${optional_missing[*]}"
        log "SYSTEM" "Gói tùy chọn chưa có: ${optional_missing[*]}"
        
        read -p "Bạn có muốn cài đặt chúng không? (y/N) " -n 1 -r
        echo
        log "USER" "Lựa chọn cài đặt gói tùy chọn" "$REPLY"
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! ${pkg_manager[$manager]} "${optional_missing[@]}"; then
                warn "${SYM_WARNING} Có lỗi khi cài gói tùy chọn"
                log "ERROR" "Có lỗi khi cài gói tùy chọn: ${optional_missing[*]}"
            else
                log "SYSTEM" "Đã cài đặt gói tùy chọn: ${optional_missing[*]}"
            fi
        fi
    fi

    # Kiểm tra lại sau khi cài đặt
    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "${SYM_ERROR} Không thể cài đặt $cmd, script không thể chạy!"
            log "ERROR" "Không thể cài đặt $cmd, script không thể chạy"
            exit 1
        fi
    done
    
    log "SYSTEM" "Kiểm tra phụ thuộc hoàn tất"
}

# ============================ HÀM TÌM KIẾM TRÊN YOUTUBE ============================
search_youtube() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên YouTube: $query"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/youtube_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên YouTube: $query..."
    
    # Sử dụng yt-dlp để tìm kiếm và lấy thông tin chi tiết
    local search_results=$(yt-dlp --flat-playlist --print "%(title)s@@@%(id)s@@@%(duration)s@@@%(view_count)s@@@%(uploader)s" "ytsearch10:$query" 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên YouTube"
        log "ERROR" "Không tìm thấy kết quả YouTube cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F'@@@' '{
        split($3, time, ":");
        if (length(time) == 3) { duration = time[1]"h "time[2]"m "time[3]"s" }
        else if (length(time) == 2) { duration = time[1]"m "time[2]"s" }
        else { duration = time[1]"s" }
        
        views = $4;
        if (views >= 1000000) { views = sprintf("%.1fM", views/1000000) }
        else if (views >= 1000) { views = sprintf("%.1fK", views/1000) }
        
        printf "%s | %s | %s | %s views | Kênh: %s\n", NR, $1, duration, views, $5
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm YouTube vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ HÀM TÌM KIẾM TRÊN SPOTIFY ============================
search_spotify() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên Spotify: $query"
    
    if ! command -v spotdl &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt spotdl để sử dụng tính năng này"
        log "ERROR" "Thiếu spotdl"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/spotify_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên Spotify: $query..."
    
    # Sử dụng spotdl để tìm kiếm
    local search_results=$(spotdl search "$query" --limit 10 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên Spotify"
        log "ERROR" "Không tìm thấy kết quả Spotify cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F' - ' '{
        printf "%s | %s | %s\n", NR, $1, $2
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm Spotify vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ HÀM TÌM KIẾM TRÊN SOUNDCLOUD ============================
search_soundcloud() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên SoundCloud: $query"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/soundcloud_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên SoundCloud: $query..."
    
    # Sử dụng yt-dlp để tìm kiếm trên SoundCloud
    local search_results=$(yt-dlp --flat-playlist --print "%(title)s@@@%(id)s@@@%(duration)s@@@%(view_count)s" "scsearch10:$query" 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên SoundCloud"
        log "ERROR" "Không tìm thấy kết quả SoundCloud cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F'@@@' '{
        split($3, time, ":");
        if (length(time) == 3) { duration = time[1]"h "time[2]"m "time[3]"s" }
        else if (length(time) == 2) { duration = time[1]"m "time[2]"s" }
        else { duration = time[1]"s" }
        
        printf "%s | %s | %s\n", NR, $1, duration
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm SoundCloud vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ HÀM TÌM KIẾM TRÊN MIXCLOUD ============================
search_mixcloud() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên Mixcloud: $query"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/mixcloud_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên Mixcloud: $query..."
    
    # Sử dụng yt-dlp để tìm kiếm trên Mixcloud
    local search_results=$(yt-dlp --flat-playlist --print "%(title)s@@@%(id)s@@@%(duration)s" "mixcloudsearch10:$query" 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên Mixcloud"
        log "ERROR" "Không tìm thấy kết quả Mixcloud cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F'@@@' '{
        split($3, time, ":");
        if (length(time) == 3) { duration = time[1]"h "time[2]"m "time[3]"s" }
        else if (length(time) == 2) { duration = time[1]"m "time[2]"s" }
        else { duration = time[1]"s" }
        
        printf "%s | %s | %s\n", NR, $1, duration
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm Mixcloud vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ HÀM TÌM KIẾM TRÊN DEEZER ============================
search_deezer() {
    local query="$1"
    log "SEARCH" "Tìm kiếm trên Deezer: $query"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt yt-dlp để sử dụng tính năng này"
        log "ERROR" "Thiếu yt-dlp"
        return 1
    fi
    
    local cache_file="$CACHE_DIR/deezer_search_${query}.cache"
    
    # Kiểm tra cache
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng kết quả từ cache cho: $query"
            cat "$cache_file"
            return
        fi
    fi
    
    notify "${SYM_SEARCH} Đang tìm kiếm trên Deezer: $query..."
    
    # Sử dụng yt-dlp để tìm kiếm trên Deezer
    local search_results=$(yt-dlp --flat-playlist --print "%(title)s@@@%(id)s@@@%(duration)s" "dzsearch10:$query" 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy kết quả nào trên Deezer"
        log "ERROR" "Không tìm thấy kết quả Deezer cho: $query"
        return 1
    fi
    
    # Xử lý kết quả
    local processed_results=$(echo "$search_results" | awk -F'@@@' '{
        split($3, time, ":");
        if (length(time) == 3) { duration = time[1]"h "time[2]"m "time[3]"s" }
        else if (length(time) == 2) { duration = time[1]"m "time[2]"s" }
        else { duration = time[1]"s" }
        
        printf "%s | %s | %s\n", NR, $1, duration
    }')
    
    # Lưu vào cache
    echo "$processed_results" > "$cache_file"
    log "CACHE" "Lưu kết quả tìm kiếm Deezer vào cache: $cache_file"
    echo "$processed_results"
}

# ============================ HÀM LƯU VÀO NHẬT KÝ ============================
add_to_history() {
    local song="$1"
    local artist="$2"
    local source="$3"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    log "HISTORY" "Thêm vào lịch sử: $song - $artist ($source)"
    
    # Sử dụng JSON cho lịch sử
    local history_entry="{\"timestamp\":\"$timestamp\",\"song\":\"$song\",\"artist\":\"$artist\",\"source\":\"$source\"}"
    
    # Giới hạn lịch sử 50 mục
    if [[ ! -f "$HISTORY_FILE" ]]; then
        echo "[$history_entry]" > "$HISTORY_FILE"
    else
        local temp_file=$(mktemp)
        jq --argjson entry "$history_entry" 'limit(50; [$entry] + .)' "$HISTORY_FILE" > "$temp_file"
        mv "$temp_file" "$HISTORY_FILE"
    fi
}

# ============================ HÀM THÊM VÀO DANH SÁCH YÊU THÍCH ============================
add_to_favorites() {
    local song="$1"
    local artist="$2"
    local source="$3"
    log "FAVORITE" "Thêm vào yêu thích: $song - $artist ($source)"
    
    # Sử dụng JSON cho danh sách yêu thích
    local favorite_entry="{\"song\":\"$song\",\"artist\":\"$artist\",\"source\":\"$source\"}"
    
    if [[ ! -f "$FAVORITES_FILE" ]]; then
        echo "[$favorite_entry]" > "$FAVORITES_FILE"
    else
        if jq -e --arg song "$song" --arg artist "$artist" '.[] | select(.song == $song and .artist == $artist)' "$FAVORITES_FILE" >/dev/null; then
            warn "Bài hát đã có trong danh sách yêu thích"
            log "WARN" "Bài hát đã có trong yêu thích: $song - $artist"
            return
        fi
        
        local temp_file=$(mktemp)
        jq --argjson entry "$favorite_entry" '. + [$entry]' "$FAVORITES_FILE" > "$temp_file"
        mv "$temp_file" "$FAVORITES_FILE"
    fi
    
    notify "${SYM_FAV} Đã thêm '$song - $artist' vào danh sách yêu thích"
}

# ============================ HÀM XÓA KHỎI DANH SÁCH YÊU THÍCH ============================
remove_from_favorites() {
    local song="$1"
    local artist="$2"
    log "FAVORITE" "Xóa khỏi yêu thích: $song - $artist"
    
    if [[ ! -f "$FAVORITES_FILE" ]]; then
        warn "Danh sách yêu thích trống"
        log "WARN" "Danh sách yêu thích trống"
        return
    fi
    
    if ! jq -e --arg song "$song" --arg artist "$artist" '.[] | select(.song == $song and .artist == $artist)' "$FAVORITES_FILE" >/dev/null; then
        warn "Bài hát không có trong danh sách yêu thích"
        log "WARN" "Bài hát không có trong yêu thích: $song - $artist"
        return
    fi
    
    local temp_file=$(mktemp)
    jq --arg song "$song" --arg artist "$artist" 'del(.[] | select(.song == $song and .artist == $artist))' "$FAVORITES_FILE" > "$temp_file"
    mv "$temp_file" "$FAVORITES_FILE"
    
    notify "${SYM_FAV} Đã xóa '$song - $artist' khỏi danh sách yêu thích"
}

# ============================ HÀM XEM DANH SÁCH YÊU THÍCH ============================
show_favorites() {
    log "FAVORITE" "Hiển thị danh sách yêu thích"
    if [[ ! -s "$FAVORITES_FILE" ]]; then
        echo "Không có bài hát nào trong danh sách yêu thích."
        return
    fi
    
    local favorites_list=$(jq -r '.[] | "\(.song) | \(.artist) | \(.source)"' "$FAVORITES_FILE" | awk '{print NR ". " $0}')
    echo "$favorites_list"
}

# ============================ PHÁT NHẠC BẰNG TRÌNH PHÁT ============================
play_music() {
    local url="$1"
    local title="$2"
    log "PLAYER" "Phát nhạc: $title (URL: $url)"
    
    notify "${SYM_PLAY} Đang phát: $title"
    
    # Kiểm tra xem có nên hiển thị visualizer không
    local player_cmd=""
    if [[ "$SHOW_VISUALIZER" == "true" ]] && command -v cava &>/dev/null; then
        # Mở terminal mới cho visualizer
        case "$OS" in
            "Linux"|"Android/Termux")
                x-terminal-emulator -e "cava" &
                ;;
            "macOS")
                osascript -e "tell app \"Terminal\" to do script \"cava\"" &
                ;;
            "Windows")
                start cmd /c "cava" &
                ;;
        esac
        player_cmd="$DEFAULT_PLAYER $PLAYER_ARGS --title=\"MusicSub - $title\" \"$url\""
    else
        player_cmd="$DEFAULT_PLAYER $PLAYER_ARGS --title=\"MusicSub - $title\" \"$url\""
    fi
    
    # Phát nhạc
    eval "$player_cmd"
    
    if [[ $? -ne 0 ]]; then
        error "${SYM_ERROR} Có lỗi khi phát nhạc"
        log "ERROR" "Lỗi khi phát nhạc: $title (URL: $url)"
        return 1
    fi
}

# ============================ HIỂN THỊ LỜI BÀI HÁT ============================
show_lyrics() {
    local song="$1"
    local artist="$2"
    log "LYRICS" "Tìm lời bài hát: $song - $artist"
    
    if [[ "$SHOW_LYRICS" != "true" ]]; then
        return
    fi
    
    # Kiểm tra cache lời bài hát
    local cache_file="$CACHE_DIR/lyrics_$(echo "$song $artist" | tr ' ' '_').cache"
    
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            log "CACHE" "Sử dụng lời bài hát từ cache"
            clear
            draw_box 80 "LỜI BÀI HÁT: $song - $artist" "$INFO" "$(cat "$cache_file")"
            read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
            return
        fi
    fi
    
    # Sử dụng API để lấy lời bài hát (ví dụ sử dụng lyrics.ovh)
    notify "${SYM_SEARCH} Đang tìm lời bài hát: $song - $artist..."
    local lyrics=$(curl -s "https://api.lyrics.ovh/v1/$artist/$song" | jq -r '.lyrics')
    
    if [[ -z "$lyrics" || "$lyrics" == "null" ]]; then
        warn "${SYM_WARNING} Không tìm thấy lời bài hát cho '$song - $artist'"
        log "WARN" "Không tìm thấy lời bài hát: $song - $artist"
        return
    fi
    
    # Lưu vào cache
    echo "$lyrics" > "$cache_file"
    log "CACHE" "Lưu lời bài hát vào cache: $cache_file"
    
    # Hiển thị lời bài hát
    clear
    draw_box 80 "LỜI BÀI HÁT: $song - $artist" "$INFO" "$lyrics"
    read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
}

# ============================ HÀM TẢI NHẠC VỀ THIẾT BỊ ============================
download_music() {
    local url="$1"
    local title="$2"
    local output_dir="$3"
    local artist="$4"
    log "DOWNLOAD" "Bắt đầu tải nhạc: $title - $artist (URL: $url)"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "${SYM_ERROR} yt-dlp không được cài đặt. Không thể tải nhạc."
        log "ERROR" "yt-dlp không được cài đặt"
        return 1
    fi
    
    mkdir -p "$output_dir"
    notify "${SYM_DOWNLOAD} Đang tải: $title - $artist"
    
    # Tải với chất lượng được chọn
    local quality_option=""
    case "$DEFAULT_QUALITY" in
        "128k") quality_option="-x --audio-format mp3 --audio-quality 128K" ;;
        "192k") quality_option="-x --audio-format mp3 --audio-quality 192K" ;;
        "256k") quality_option="-x --audio-format mp3 --audio-quality 256K" ;;
        "320k") quality_option="-x --audio-format mp3 --audio-quality 320K" ;;
        *) quality_option="-x --audio-format mp3 --audio-quality 320K" ;;
    esac
    
    yt-dlp $quality_option \
        -o "$output_dir/$title - $artist.%(ext)s" \
        --no-progress \
        --console-title \
        "$url"
    
    if [[ $? -eq 0 ]]; then
        notify "${SYM_SUCCESS} Đã tải xong: $title - $artist"
        log "DOWNLOAD" "Tải thành công: $title - $artist"
        
        # Thêm menu sau khi tải xong
        while true; do
            clear
            show_header
            
            local options=(
                "${SYM_PLAY} 1. Phát bài hát vừa tải" "Phát bài hát đã tải xuống"
                "${SYM_PLAY} 2. Quay lại phát bài hiện tại" "Tiếp tục nghe bài hiện tại"
                "${SYM_FOLDER} 3. Mở thư mục chứa nhạc" "Mở thư mục chứa file đã tải"
                "${SYM_EXIT} 0. Quay lại menu trước" "Quay lại menu trước đó"
            )
            
            show_menu "${options[@]}"
            
            read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
            log "USER" "Lựa chọn sau khi tải" "$choice"
            
            case $choice in
                1)
                    local music_file=$(find "$output_dir" -name "$title - $artist*.mp3" | head -n 1)
                    if [[ -f "$music_file" ]]; then
                        play_music "$music_file" "$title - $artist (Đã tải)"
                        log "PLAY" "Phát nhạc đã tải: $title - $artist"
                    else
                        error "${SYM_ERROR} Không tìm thấy file nhạc đã tải"
                        log "ERROR" "Không tìm thấy file nhạc: $title - $artist"
                    fi
                    ;;
                2)
                    # Quay lại phát bài hiện tại
                    log "NAVIGATE" "Quay lại phát bài hiện tại"
                    return 2
                    ;;
                3)
                    log "SYSTEM" "Mở thư mục chứa nhạc"
                    case "$OS" in
                        "Linux"|"Android/Termux")
                            xdg-open "$output_dir" || open "$output_dir"
                            ;;
                        "macOS")
                            open "$output_dir"
                            ;;
                        "Windows")
                            explorer "$(cygpath -w "$output_dir")"
                            ;;
                        *)
                            echo "Thư mục chứa nhạc: $output_dir"
                            ;;
                    esac
                    ;;
                0)
                    log "NAVIGATE" "Quay lại menu trước"
                    return
                    ;;
                *)
                    warn "${SYM_WARNING} Lựa chọn không hợp lệ"
                    log "WARN" "Lựa chọn không hợp lệ: $choice"
                    ;;
            esac
        done
    else
        error "${SYM_ERROR} Tải nhạc thất bại"
        log "ERROR" "Tải nhạc thất bại: $title - $artist (URL: $url)"
        return 1
    fi
}

# ============================ TẠO PLAYLIST ============================
create_playlist() {
    local playlist_name="$1"
    log "PLAYLIST" "Tạo playlist mới: $playlist_name"
    
    local playlist_file="$PLAYLIST_DIR/$playlist_name.json"
    
    if [[ -f "$playlist_file" ]]; then
        warn "${SYM_WARNING} Playlist đã tồn tại"
        log "WARN" "Playlist đã tồn tại: $playlist_name"
        return 1
    fi
    
    echo '[]' > "$playlist_file"
    notify "${SYM_SUCCESS} Đã tạo playlist: $playlist_name"
    log "PLAYLIST" "Tạo playlist thành công: $playlist_name"
}

# ============================ THÊM BÀI HÁT VÀO PLAYLIST ============================
add_to_playlist() {
    local playlist_name="$1"
    local song="$2"
    local artist="$3"
    local source="$4"
    log "PLAYLIST" "Thêm vào playlist: $playlist_name - $song - $artist"
    
    local playlist_file="$PLAYLIST_DIR/$playlist_name.json"
    
    if [[ ! -f "$playlist_file" ]]; then
        error "${SYM_ERROR} Playlist không tồn tại"
        log "ERROR" "Playlist không tồn tại: $playlist_name"
        return 1
    fi
    
    local song_entry="{\"song\":\"$song\",\"artist\":\"$artist\",\"source\":\"$source\"}"
    local temp_file=$(mktemp)
    
    jq --argjson entry "$song_entry" '. + [$entry]' "$playlist_file" > "$temp_file"
    mv "$temp_file" "$playlist_file"
    
    notify "${SYM_SUCCESS} Đã thêm '$song - $artist' vào playlist '$playlist_name'"
    log "PLAYLIST" "Thêm bài hát vào playlist thành công"
}

# ============================ XEM PLAYLIST ============================
show_playlist() {
    local playlist_name="$1"
    log "PLAYLIST" "Hiển thị playlist: $playlist_name"
    
    local playlist_file="$PLAYLIST_DIR/$playlist_name.json"
    
    if [[ ! -f "$playlist_file" ]]; then
        error "${SYM_ERROR} Playlist không tồn tại"
        log "ERROR" "Playlist không tồn tại: $playlist_name"
        return 1
    fi
    
    local playlist_content=$(jq -r '.[] | "\(.song) | \(.artist) | \(.source)"' "$playlist_file" | awk '{print NR ". " $0}')
    echo "$playlist_content"
}

# ============================ PHÁT PLAYLIST ============================
play_playlist() {
    local playlist_name="$1"
    log "PLAYLIST" "Phát playlist: $playlist_name"
    
    local playlist_file="$PLAYLIST_DIR/$playlist_name.json"
    
    if [[ ! -f "$playlist_file" ]]; then
        error "${SYM_ERROR} Playlist không tồn tại"
        log "ERROR" "Playlist không tồn tại: $playlist_name"
        return 1
    fi
    
    local songs=()
    while IFS= read -r line; do
        songs+=("$line")
    done < <(jq -r '.[] | "\(.song)@@@\(.artist)@@@\(.source)"' "$playlist_file")
    
    if [[ ${#songs[@]} -eq 0 ]]; then
        warn "${SYM_WARNING} Playlist trống"
        log "WARN" "Playlist trống: $playlist_name"
        return 1
    fi
    
    for song_info in "${songs[@]}"; do
        local song=$(echo "$song_info" | awk -F'@@@' '{print $1}')
        local artist=$(echo "$song_info" | awk -F'@@@' '{print $2}')
        local source=$(echo "$song_info" | awk -F'@@@' '{print $3}')
        
        case "$source" in
            "youtube")
                play_from_youtube "$song $artist"
                ;;
            "spotify")
                play_from_spotify "$song $artist"
                ;;
            "soundcloud")
                play_from_soundcloud "$song $artist"
                ;;
            "mixcloud")
                play_from_mixcloud "$song $artist"
                ;;
            "deezer")
                play_from_deezer "$song $artist"
                ;;
            *)
                warn "${SYM_WARNING} Nguồn không được hỗ trợ: $source"
                log "WARN" "Nguồn không được hỗ trợ: $source"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CHÍNH CỦA MUSICSUB ============================
main_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_SEARCH} 1. Tìm kiếm và phát nhạc" "Tìm kiếm và nghe nhạc từ nhiều nguồn"
            "${SYM_HIST} 2. Lịch sử nghe" "Xem lịch sử các bài đã nghe"
            "${SYM_FAV} 3. Danh sách yêu thích" "Quản lý danh sách bài hát yêu thích"
            "${SYM_PLAYLIST} 4. Quản lý Playlist" "Tạo và quản lý playlist cá nhân"
            "${SYM_TOOLS} 5. Công cụ âm nhạc" "Xem lời bài hát, visualizer"
            "${SYM_SETTINGS} 6. Cài đặt" "Thay đổi cấu hình hệ thống"
            "${SYM_UPDATE} 7. Kiểm tra cập nhật" "Kiểm tra và cập nhật phiên bản mới"
            "${SYM_INFO} 8. Thông tin tác giả" "Thông tin về nhà phát triển"
            "${SYM_EXIT} 0. Thoát" "Thoát chương trình"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu chính" "$choice"
        
        case $choice in
            1) 
                log "MENU" "Vào menu Tìm kiếm và phát nhạc"
                search_and_play_menu 
                ;;
            2) 
                log "MENU" "Vào menu Lịch sử nghe"
                history_menu 
                ;;
            3) 
                log "MENU" "Vào menu Danh sách yêu thích"
                favorites_menu 
                ;;
            4) 
                log "MENU" "Vào menu Quản lý Playlist"
                playlist_menu 
                ;;
            5) 
                log "MENU" "Vào menu Công cụ âm nhạc"
                music_tools_menu 
                ;;
            6) 
                log "MENU" "Vào menu Cài đặt"
                settings_menu 
                ;;
            7) 
                log "MENU" "Vào menu Kiểm tra cập nhật"
                check_for_updates 
                ;;
            8) 
                log "MENU" "Vào menu Thông tin tác giả"
                show_authors 
                ;;
            0) 
                log "SYSTEM" "Kết thúc chương trình"
                echo "Đã thoát MusicSub..."
                exit 0 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU TÌM KIẾM VÀ PHÁT NHẠC ============================
search_and_play_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_SEARCH} 1. Tìm kiếm trên YouTube" "Tìm kiếm nhạc từ YouTube"
            "${SYM_SEARCH} 2. Tìm kiếm trên Spotify" "Tìm kiếm nhạc từ Spotify"
            "${SYM_SEARCH} 3. Tìm kiếm trên SoundCloud" "Tìm kiếm nhạc từ SoundCloud"
            "${SYM_SEARCH} 4. Tìm kiếm trên Mixcloud" "Tìm kiếm nhạc từ Mixcloud"
            "${SYM_SEARCH} 5. Tìm kiếm trên Deezer" "Tìm kiếm nhạc từ Deezer"
            "${SYM_PLAY} 6. Nhập URL trực tiếp" "Phát trực tiếp từ URL"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu tìm kiếm" "$choice"
        
        case $choice in
            1) 
                read -p "Nhập từ khóa tìm kiếm trên YouTube: " query
                log "USER" "Tìm kiếm YouTube" "$query"
                play_from_youtube "$query" 
                ;;
            2) 
                read -p "Nhập từ khóa tìm kiếm trên Spotify: " query
                log "USER" "Tìm kiếm Spotify" "$query"
                play_from_spotify "$query" 
                ;;
            3) 
                read -p "Nhập từ khóa tìm kiếm trên SoundCloud: " query
                log "USER" "Tìm kiếm SoundCloud" "$query"
                play_from_soundcloud "$query" 
                ;;
            4) 
                read -p "Nhập từ khóa tìm kiếm trên Mixcloud: " query
                log "USER" "Tìm kiếm Mixcloud" "$query"
                play_from_mixcloud "$query" 
                ;;
            5) 
                read -p "Nhập từ khóa tìm kiếm trên Deezer: " query
                log "USER" "Tìm kiếm Deezer" "$query"
                play_from_deezer "$query" 
                ;;
            6) 
                play_from_url 
                ;;
            0) 
                log "NAVIGATE" "Quay lại menu chính"
                return 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ YOUTUBE ============================
play_from_youtube() {
    local query="$1"
    log "STREAM" "Phát nhạc từ YouTube: $query"
    
    local search_results=$(search_youtube "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy bài hát phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm YouTube"
        return 1
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: " --preview "echo {} | cut -d'|' -f2-")
    log "USER" "Chọn bài hát YouTube" "$selected_song"
    
    if [[ -z "$selected_song" ]]; then
        warn "${SYM_WARNING} Không có bài hát nào được chọn"
        log "WARN" "Không chọn bài hát YouTube"
        return
    fi
    
    local song_title=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local song_artist=$(echo "$selected_song" | cut -d'|' -f5 | sed 's/^Kênh: //')
    local song_id=$(yt-dlp --get-id "ytsearch1:$song_title" 2>/dev/null)
    local song_url="https://youtu.be/$song_id"
    
    add_to_history "$song_title" "$song_artist" "youtube"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát bài hát" "Phát bài hát đã chọn"
            "${SYM_NEXT} 2. Phát bài liên quan" "Phát bài hát liên quan tiếp theo"
            "${SYM_DOWNLOAD} 3. Tải bài hát xuống" "Tải bài hát về thiết bị"
            "${SYM_FAV} 4. Thêm vào yêu thích" "Thêm bài hát vào danh sách yêu thích"
            "${SYM_LYRICS} 5. Xem lời bài hát" "Hiển thị lời bài hát (nếu có)"
            "${SYM_PLAYLIST} 6. Thêm vào playlist" "Thêm bài hát vào playlist"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi nghe YouTube" "$choice"
        
        case $choice in
            1)
                play_music "$song_url" "YouTube: $song_title - $song_artist"
                ;;
            2)
                # Phát bài hát liên quan
                local next_url=$(yt-dlp --flat-playlist --get-url "https://www.youtube.com/watch?v=$song_id" 2>/dev/null | head -n 1)
                if [[ -n "$next_url" ]]; then
                    song_url="$next_url"
                    song_title=$(yt-dlp --get-title "$next_url" 2>/dev/null)
                    song_artist=$(yt-dlp --get-description "$next_url" 2>/dev/null | head -n 1)
                    add_to_history "$song_title" "$song_artist" "youtube"
                    play_music "$song_url" "YouTube: $song_title - $song_artist"
                else
                    warn "${SYM_WARNING} Không tìm thấy bài hát liên quan"
                    log "WARN" "Không tìm thấy bài hát liên quan"
                fi
                ;;
            3)
                download_music "$song_url" "$song_title" "$DOWNLOAD_DIR/YouTube" "$song_artist"
                if [[ $? -eq 2 ]]; then
                    play_music "$song_url" "YouTube: $song_title - $song_artist"
                fi
                ;;
            4)
                add_to_favorites "$song_title" "$song_artist" "youtube"
                ;;
            5)
                show_lyrics "$song_title" "$song_artist"
                ;;
            6)
                read -p "Nhập tên playlist: " playlist_name
                log "USER" "Nhập tên playlist" "$playlist_name"
                add_to_playlist "$playlist_name" "$song_title" "$song_artist" "youtube"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ SPOTIFY ============================
play_from_spotify() {
    local query="$1"
    log "STREAM" "Phát nhạc từ Spotify: $query"
    
    if ! command -v spotdl &> /dev/null; then
        error "${SYM_ERROR} Cần cài đặt spotdl để sử dụng tính năng này"
        log "ERROR" "Thiếu spotdl"
        return 1
    fi
    
    local search_results=$(search_spotify "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy bài hát phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm Spotify"
        return 1
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: ")
    log "USER" "Chọn bài hát Spotify" "$selected_song"
    
    if [[ -z "$selected_song" ]]; then
        warn "${SYM_WARNING} Không có bài hát nào được chọn"
        log "WARN" "Không chọn bài hát Spotify"
        return
    fi
    
    local song_title=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local song_artist=$(echo "$selected_song" | cut -d'|' -f3 | sed 's/^ //;s/ $//')
    local song_url=$(spotdl search "$song_title $song_artist" --limit 1 --output url 2>/dev/null)
    
    if [[ -z "$song_url" ]]; then
        error "${SYM_ERROR} Không thể lấy URL bài hát"
        log "ERROR" "Không lấy được URL từ Spotify"
        return 1
    fi
    
    add_to_history "$song_title" "$song_artist" "spotify"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát bài hát" "Phát bài hát đã chọn"
            "${SYM_DOWNLOAD} 2. Tải bài hát xuống" "Tải bài hát về thiết bị"
            "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm bài hát vào danh sách yêu thích"
            "${SYM_LYRICS} 4. Xem lời bài hát" "Hiển thị lời bài hát (nếu có)"
            "${SYM_PLAYLIST} 5. Thêm vào playlist" "Thêm bài hát vào playlist"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi nghe Spotify" "$choice"
        
        case $choice in
            1)
                # Sử dụng yt-dlp để phát bài hát từ Spotify (thông qua YouTube)
                local yt_url=$(yt-dlp --flat-playlist --get-url "ytsearch:$song_title $song_artist" 2>/dev/null)
                if [[ -n "$yt_url" ]]; then
                    play_music "$yt_url" "Spotify: $song_title - $song_artist"
                else
                    error "${SYM_ERROR} Không thể tìm thấy bài hát trên YouTube"
                    log "ERROR" "Không tìm thấy bài hát trên YouTube"
                fi
                ;;
            2)
                if spotdl download "$song_url" --output "$DOWNLOAD_DIR/Spotify/{artist} - {title}.{output-ext}"; then
                    notify "${SYM_SUCCESS} Đã tải xong: $song_title - $song_artist"
                    log "DOWNLOAD" "Tải thành công từ Spotify: $song_title - $song_artist"
                else
                    error "${SYM_ERROR} Tải bài hát thất bại"
                    log "ERROR" "Tải bài hát từ Spotify thất bại"
                fi
                ;;
            3)
                add_to_favorites "$song_title" "$song_artist" "spotify"
                ;;
            4)
                show_lyrics "$song_title" "$song_artist"
                ;;
            5)
                read -p "Nhập tên playlist: " playlist_name
                log "USER" "Nhập tên playlist" "$playlist_name"
                add_to_playlist "$playlist_name" "$song_title" "$song_artist" "spotify"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ SOUNDCLOUD ============================
play_from_soundcloud() {
    local query="$1"
    log "STREAM" "Phát nhạc từ SoundCloud: $query"
    
    local search_results=$(search_soundcloud "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy bài hát phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm SoundCloud"
        return 1
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: ")
    log "USER" "Chọn bài hát SoundCloud" "$selected_song"
    
    if [[ -z "$selected_song" ]]; then
        warn "${SYM_WARNING} Không có bài hát nào được chọn"
        log "WARN" "Không chọn bài hát SoundCloud"
        return
    fi
    
    local song_title=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local song_url=$(yt-dlp --get-url "scsearch1:$song_title" 2>/dev/null)
    
    if [[ -z "$song_url" ]]; then
        error "${SYM_ERROR} Không thể lấy URL bài hát"
        log "ERROR" "Không lấy được URL từ SoundCloud"
        return 1
    fi
    
    add_to_history "$song_title" "SoundCloud Artist" "soundcloud"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát bài hát" "Phát bài hát đã chọn"
            "${SYM_DOWNLOAD} 2. Tải bài hát xuống" "Tải bài hát về thiết bị"
            "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm bài hát vào danh sách yêu thích"
            "${SYM_LYRICS} 4. Xem lời bài hát" "Hiển thị lời bài hát (nếu có)"
            "${SYM_PLAYLIST} 5. Thêm vào playlist" "Thêm bài hát vào playlist"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi nghe SoundCloud" "$choice"
        
        case $choice in
            1)
                play_music "$song_url" "SoundCloud: $song_title"
                ;;
            2)
                download_music "$song_url" "$song_title" "$DOWNLOAD_DIR/SoundCloud" "SoundCloud Artist"
                if [[ $? -eq 2 ]]; then
                    play_music "$song_url" "SoundCloud: $song_title"
                fi
                ;;
            3)
                add_to_favorites "$song_title" "SoundCloud Artist" "soundcloud"
                ;;
            4)
                show_lyrics "$song_title" "SoundCloud Artist"
                ;;
            5)
                read -p "Nhập tên playlist: " playlist_name
                log "USER" "Nhập tên playlist" "$playlist_name"
                add_to_playlist "$playlist_name" "$song_title" "SoundCloud Artist" "soundcloud"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ MIXCLOUD ============================
play_from_mixcloud() {
    local query="$1"
    log "STREAM" "Phát nhạc từ Mixcloud: $query"
    
    local search_results=$(search_mixcloud "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy bài hát phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm Mixcloud"
        return 1
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: ")
    log "USER" "Chọn bài hát Mixcloud" "$selected_song"
    
    if [[ -z "$selected_song" ]]; then
        warn "${SYM_WARNING} Không có bài hát nào được chọn"
        log "WARN" "Không chọn bài hát Mixcloud"
        return
    fi
    
    local song_title=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local song_url=$(yt-dlp --get-url "mixcloudsearch1:$song_title" 2>/dev/null)
    
    if [[ -z "$song_url" ]]; then
        error "${SYM_ERROR} Không thể lấy URL bài hát"
        log "ERROR" "Không lấy được URL từ Mixcloud"
        return 1
    fi
    
    add_to_history "$song_title" "Mixcloud Artist" "mixcloud"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát bài hát" "Phát bài hát đã chọn"
            "${SYM_DOWNLOAD} 2. Tải bài hát xuống" "Tải bài hát về thiết bị"
            "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm bài hát vào danh sách yêu thích"
            "${SYM_PLAYLIST} 4. Thêm vào playlist" "Thêm bài hát vào playlist"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi nghe Mixcloud" "$choice"
        
        case $choice in
            1)
                play_music "$song_url" "Mixcloud: $song_title"
                ;;
            2)
                download_music "$song_url" "$song_title" "$DOWNLOAD_DIR/Mixcloud" "Mixcloud Artist"
                if [[ $? -eq 2 ]]; then
                    play_music "$song_url" "Mixcloud: $song_title"
                fi
                ;;
            3)
                add_to_favorites "$song_title" "Mixcloud Artist" "mixcloud"
                ;;
            4)
                read -p "Nhập tên playlist: " playlist_name
                log "USER" "Nhập tên playlist" "$playlist_name"
                add_to_playlist "$playlist_name" "$song_title" "Mixcloud Artist" "mixcloud"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ DEEZER ============================
play_from_deezer() {
    local query="$1"
    log "STREAM" "Phát nhạc từ Deezer: $query"
    
    local search_results=$(search_deezer "$query")
    if [[ -z "$search_results" ]]; then
        error "${SYM_ERROR} Không tìm thấy bài hát phù hợp"
        log "ERROR" "Không có kết quả tìm kiếm Deezer"
        return 1
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: ")
    log "USER" "Chọn bài hát Deezer" "$selected_song"
    
    if [[ -z "$selected_song" ]]; then
        warn "${SYM_WARNING} Không có bài hát nào được chọn"
        log "WARN" "Không chọn bài hát Deezer"
        return
    fi
    
    local song_title=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
    local song_url=$(yt-dlp --get-url "dzsearch1:$song_title" 2>/dev/null)
    
    if [[ -z "$song_url" ]]; then
        error "${SYM_ERROR} Không thể lấy URL bài hát"
        log "ERROR" "Không lấy được URL từ Deezer"
        return 1
    fi
    
    add_to_history "$song_title" "Deezer Artist" "deezer"
    
    while true; do
        show_header
        
        local options=(
            "${SYM_PLAY} 1. Phát bài hát" "Phát bài hát đã chọn"
            "${SYM_DOWNLOAD} 2. Tải bài hát xuống" "Tải bài hát về thiết bị"
            "${SYM_FAV} 3. Thêm vào yêu thích" "Thêm bài hát vào danh sách yêu thích"
            "${SYM_LYRICS} 4. Xem lời bài hát" "Hiển thị lời bài hát (nếu có)"
            "${SYM_PLAYLIST} 5. Thêm vào playlist" "Thêm bài hát vào playlist"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu tìm kiếm"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn khi nghe Deezer" "$choice"
        
        case $choice in
            1)
                play_music "$song_url" "Deezer: $song_title"
                ;;
            2)
                download_music "$song_url" "$song_title" "$DOWNLOAD_DIR/Deezer" "Deezer Artist"
                if [[ $? -eq 2 ]]; then
                    play_music "$song_url" "Deezer: $song_title"
                fi
                ;;
            3)
                add_to_favorites "$song_title" "Deezer Artist" "deezer"
                ;;
            4)
                show_lyrics "$song_title" "Deezer Artist"
                ;;
            5)
                read -p "Nhập tên playlist: " playlist_name
                log "USER" "Nhập tên playlist" "$playlist_name"
                add_to_playlist "$playlist_name" "$song_title" "Deezer Artist" "deezer"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu tìm kiếm"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ PHÁT NHẠC TỪ URL TRỰC TIẾP ============================
play_from_url() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập URL bài hát (YouTube, Spotify, SoundCloud, Mixcloud hoặc Deezer): " url
    log "USER" "Nhập URL trực tiếp" "$url"
    
    if [[ -z "$url" ]]; then
        warn "${SYM_WARNING} URL không được để trống"
        log "WARN" "URL trống"
        return
    fi
    
    if [[ "$url" == *"youtube.com"* || "$url" == *"youtu.be"* ]]; then
        local song_title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "YouTube Music")
        local song_artist=$(yt-dlp --get-description "$url" 2>/dev/null | head -n 1 || echo "Unknown Artist")
        add_to_history "$song_title" "$song_artist" "youtube"
        
        play_music "$url" "YouTube: $song_title - $song_artist"
    elif [[ "$url" == *"spotify.com"* ]]; then
        if ! command -v spotdl &> /dev/null; then
            error "${SYM_ERROR} Cần cài đặt spotdl để phát nhạc từ Spotify"
            log "ERROR" "Thiếu spotdl"
            return 1
        fi
        
        local song_info=$(spotdl "$url" --print-only 2>/dev/null)
        if [[ -z "$song_info" ]]; then
            error "${SYM_ERROR} Không thể lấy thông tin bài hát từ Spotify"
            log "ERROR" "Không lấy được thông tin từ Spotify"
            return 1
        fi
        
        local song_title=$(echo "$song_info" | awk -F' - ' '{print $1}')
        local song_artist=$(echo "$song_info" | awk -F' - ' '{print $2}')
        add_to_history "$song_title" "$song_artist" "spotify"
        
        # Sử dụng yt-dlp để phát bài hát từ Spotify (thông qua YouTube)
        local yt_url=$(yt-dlp --flat-playlist --get-url "ytsearch:$song_title $song_artist" 2>/dev/null)
        if [[ -n "$yt_url" ]]; then
            play_music "$yt_url" "Spotify: $song_title - $song_artist"
        else
            error "${SYM_ERROR} Không thể tìm thấy bài hát trên YouTube"
            log "ERROR" "Không tìm thấy bài hát trên YouTube"
        fi
    elif [[ "$url" == *"soundcloud.com"* ]]; then
        local song_title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "SoundCloud Track")
        add_to_history "$song_title" "SoundCloud Artist" "soundcloud"
        
        play_music "$url" "SoundCloud: $song_title"
    elif [[ "$url" == *"mixcloud.com"* ]]; then
        local song_title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "Mixcloud Track")
        add_to_history "$song_title" "Mixcloud Artist" "mixcloud"
        
        play_music "$url" "Mixcloud: $song_title"
    elif [[ "$url" == *"deezer.com"* ]]; then
        local song_title=$(yt-dlp --get-title "$url" 2>/dev/null || echo "Deezer Track")
        add_to_history "$song_title" "Deezer Artist" "deezer"
        
        play_music "$url" "Deezer: $song_title"
    else
        warn "${SYM_WARNING} URL không được hỗ trợ. Chỉ hỗ trợ YouTube, Spotify, SoundCloud, Mixcloud và Deezer."
        log "WARN" "URL không được hỗ trợ: $url"
    fi
}

# ============================ HIỂN THỊ MENU LỊCH SỬ NGHE ============================
history_menu() {
    while true; do
        show_header
        
        local history_list=$(show_history)
        local content=""
        
        if [[ -z "$history_list" ]]; then
            content="Không có lịch sử nghe."
        else
            content="$history_list"
        fi
        
        draw_box 60 "LỊCH SỬ NGHE" "$SECONDARY" "$content"
        
        local options=(
            "${SYM_SEARCH} 1. Xem toàn bộ lịch sử" "Hiển thị toàn bộ lịch sử nghe"
            "${SYM_DELETE} 2. Xóa lịch sử" "Xóa toàn bộ lịch sử nghe"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu lịch sử" "$choice"
        
        case $choice in
            1)
                clear
                draw_box 80 "TOÀN BỘ LỊCH SỬ" "$SECONDARY" "$history_list"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                log "HISTORY" "Xem toàn bộ lịch sử"
                ;;
            2)
                > "$HISTORY_FILE"
                notify "${SYM_SUCCESS} Đã xóa toàn bộ lịch sử"
                log "HISTORY" "Xóa toàn bộ lịch sử"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ LỊCH SỬ NGHE ============================
show_history() {
    log "HISTORY" "Hiển thị lịch sử nghe"
    if [[ ! -s "$HISTORY_FILE" ]]; then
        echo "Không có lịch sử nghe."
        return
    fi
    
    local history_list=$(jq -r '.[] | "\(.timestamp) | \(.song) | \(.artist) | \(.source)"' "$HISTORY_FILE" | \
        awk '{print NR ". " $0}')
    echo "$history_list"
}

# ============================ HIỂN THỊ MENU YÊU THÍCH ============================
favorites_menu() {
    while true; do
        show_header
        
        local favorites_list=$(show_favorites)
        local content=""
        
        if [[ -z "$favorites_list" ]]; then
            content="Không có bài hát nào trong danh sách yêu thích."
        else
            content="$favorites_list"
        fi
        
        draw_box 60 "DANH SÁCH YÊU THÍCH" "$SECONDARY" "$content"
        
        local options=(
            "${SYM_SEARCH} 1. Xem toàn bộ yêu thích" "Hiển thị toàn bộ danh sách yêu thích"
            "${SYM_PLAY} 2. Phát bài hát từ yêu thích" "Chọn và phát bài hát từ danh sách yêu thích"
            "${SYM_DELETE} 3. Xóa bài hát khỏi yêu thích" "Xóa bài hát khỏi danh sách yêu thích"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu yêu thích" "$choice"
        
        case $choice in
            1)
                clear
                draw_box 80 "TOÀN BỘ YÊU THÍCH" "$SECONDARY" "$favorites_list"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                log "FAVORITE" "Xem toàn bộ yêu thích"
                ;;
            2)
                if [[ -z "$favorites_list" ]]; then
                    warn "${SYM_WARNING} Không có bài hát nào trong danh sách yêu thích"
                    log "WARN" "Danh sách yêu thích trống"
                    continue
                fi
                
                local selected_song=$(echo "$favorites_list" | fzf --prompt="Chọn bài hát từ yêu thích: " | sed 's/^[0-9]*\. //')
                log "USER" "Chọn bài hát từ yêu thích" "$selected_song"
                
                if [[ -z "$selected_song" ]]; then
                    warn "${SYM_WARNING} Không có bài hát nào được chọn"
                    log "WARN" "Không chọn bài hát từ yêu thích"
                    continue
                fi
                
                local song_title=$(echo "$selected_song" | cut -d'|' -f1 | sed 's/^ //;s/ $//')
                local song_artist=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
                local source=$(echo "$selected_song" | cut -d'|' -f3 | sed 's/^ //;s/ $//')
                
                case "$source" in
                    "youtube")
                        play_from_youtube "$song_title $song_artist"
                        ;;
                    "spotify")
                        play_from_spotify "$song_title $song_artist"
                        ;;
                    "soundcloud")
                        play_from_soundcloud "$song_title"
                        ;;
                    "mixcloud")
                        play_from_mixcloud "$song_title"
                        ;;
                    "deezer")
                        play_from_deezer "$song_title"
                        ;;
                    *)
                        warn "${SYM_WARNING} Nguồn không được hỗ trợ: $source"
                        log "WARN" "Nguồn không được hỗ trợ: $source"
                        ;;
                esac
                ;;
            3)
                if [[ -z "$favorites_list" ]]; then
                    warn "${SYM_WARNING} Không có bài hát nào trong danh sách yêu thích"
                    log "WARN" "Danh sách yêu thích trống"
                    continue
                fi
                
                local selected_song=$(echo "$favorites_list" | fzf --prompt="Chọn bài hát để xóa: " | sed 's/^[0-9]*\. //')
                log "USER" "Chọn bài hát để xóa" "$selected_song"
                
                if [[ -z "$selected_song" ]]; then
                    warn "${SYM_WARNING} Không có bài hát nào được chọn"
                    log "WARN" "Không chọn bài hát để xóa"
                    continue
                fi
                
                local song_title=$(echo "$selected_song" | cut -d'|' -f1 | sed 's/^ //;s/ $//')
                local song_artist=$(echo "$selected_song" | cut -d'|' -f2 | sed 's/^ //;s/ $//')
                
                remove_from_favorites "$song_title" "$song_artist"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU PLAYLIST ============================
playlist_menu() {
    while true; do
        show_header
        
        local playlists=($(ls "$PLAYLIST_DIR"/*.json 2>/dev/null | xargs -n1 basename | sed 's/\.json$//'))
        local playlist_count=${#playlists[@]}
        
        local content=""
        if [[ $playlist_count -eq 0 ]]; then
            content="Không có playlist nào."
        else
            content=$(printf "%s\n" "${playlists[@]}" | awk '{print NR ". " $0}')
        fi
        
        draw_box 60 "QUẢN LÝ PLAYLIST" "$SECONDARY" "$content"
        
        local options=(
            "${SYM_PLAYLIST} 1. Tạo playlist mới" "Tạo một playlist mới"
            "${SYM_PLAY} 2. Phát playlist" "Phát toàn bộ playlist"
            "${SYM_SEARCH} 3. Xem nội dung playlist" "Xem các bài hát trong playlist"
            "${SYM_DELETE} 4. Xóa playlist" "Xóa playlist đã chọn"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu playlist" "$choice"
        
        case $choice in
            1)
                read -p "Nhập tên playlist mới: " playlist_name
                log "USER" "Nhập tên playlist mới" "$playlist_name"
                
                if [[ -z "$playlist_name" ]]; then
                    warn "${SYM_WARNING} Tên playlist không được để trống"
                    log "WARN" "Tên playlist trống"
                    continue
                fi
                
                create_playlist "$playlist_name"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                if [[ $playlist_count -eq 0 ]]; then
                    warn "${SYM_WARNING} Không có playlist nào để phát"
                    log "WARN" "Không có playlist để phát"
                    continue
                fi
                
                local selected_playlist=$(printf "%s\n" "${playlists[@]}" | fzf --prompt="Chọn playlist để phát: ")
                log "USER" "Chọn playlist để phát" "$selected_playlist"
                
                if [[ -z "$selected_playlist" ]]; then
                    warn "${SYM_WARNING} Không có playlist nào được chọn"
                    log "WARN" "Không chọn playlist"
                    continue
                fi
                
                play_playlist "$selected_playlist"
                ;;
            3)
                if [[ $playlist_count -eq 0 ]]; then
                    warn "${SYM_WARNING} Không có playlist nào để xem"
                    log "WARN" "Không có playlist để xem"
                    continue
                fi
                
                local selected_playlist=$(printf "%s\n" "${playlists[@]}" | fzf --prompt="Chọn playlist để xem: ")
                log "USER" "Chọn playlist để xem" "$selected_playlist"
                
                if [[ -z "$selected_playlist" ]]; then
                    warn "${SYM_WARNING} Không có playlist nào được chọn"
                    log "WARN" "Không chọn playlist"
                    continue
                fi
                
                local playlist_content=$(show_playlist "$selected_playlist")
                clear
                draw_box 80 "NỘI DUNG PLAYLIST: $selected_playlist" "$INFO" "$playlist_content"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            4)
                if [[ $playlist_count -eq 0 ]]; then
                    warn "${SYM_WARNING} Không có playlist nào để xóa"
                    log "WARN" "Không có playlist để xóa"
                    continue
                fi
                
                local selected_playlist=$(printf "%s\n" "${playlists[@]}" | fzf --prompt="Chọn playlist để xóa: ")
                log "USER" "Chọn playlist để xóa" "$selected_playlist"
                
                if [[ -z "$selected_playlist" ]]; then
                    warn "${SYM_WARNING} Không có playlist nào được chọn"
                    log "WARN" "Không chọn playlist"
                    continue
                fi
                
                rm -f "$PLAYLIST_DIR/$selected_playlist.json"
                notify "${SYM_SUCCESS} Đã xóa playlist: $selected_playlist"
                log "PLAYLIST" "Xóa playlist: $selected_playlist"
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CÔNG CỤ ÂM NHẠC ============================
music_tools_menu() {
    while true; do
        show_header
        
        local options=(
            "${SYM_LYRICS} 1. Tìm lời bài hát" "Tìm kiếm lời bài hát theo tên"
            "${SYM_VISUAL} 2. Bật/tắt visualizer" "Bật hoặc tắt hiển thị visualizer âm thanh"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu công cụ âm nhạc" "$choice"
        
        case $choice in
            1)
                read -p "Nhập tên bài hát: " song_name
                read -p "Nhập tên nghệ sĩ: " artist_name
                log "USER" "Nhập thông tin tìm lời bài hát" "Bài hát: $song_name, Nghệ sĩ: $artist_name"
                
                if [[ -z "$song_name" ]]; then
                    warn "${SYM_WARNING} Tên bài hát không được để trống"
                    log "WARN" "Tên bài hát trống"
                    continue
                fi
                
                show_lyrics "$song_name" "$artist_name"
                ;;
            2)
                if [[ "$SHOW_VISUALIZER" == "true" ]]; then
                    sed -i "s/^SHOW_VISUALIZER=.*/SHOW_VISUALIZER=false/" "$CONFIG_FILE"
                    SHOW_VISUALIZER="false"
                    notify "${SYM_SUCCESS} Đã tắt visualizer"
                    log "SETTINGS" "Tắt visualizer"
                else
                    if ! command -v cava &>/dev/null; then
                        error "${SYM_ERROR} Cần cài đặt cava để sử dụng visualizer"
                        log "ERROR" "Thiếu cava"
                        continue
                    fi
                    sed -i "s/^SHOW_VISUALIZER=.*/SHOW_VISUALIZER=true/" "$CONFIG_FILE"
                    SHOW_VISUALIZER="true"
                    notify "${SYM_SUCCESS} Đã bật visualizer"
                    log "SETTINGS" "Bật visualizer"
                fi
                ;;
            0)
                log "NAVIGATE" "Quay lại menu chính"
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ HIỂN THỊ MENU CÀI ĐẶT ============================
settings_menu() {
    while true; do
        show_header
        
        local current_log_level="${LOG_LEVEL^^}"
        local log_status=$([[ "$LOG_TO_FILE" == "true" ]] && echo "BẬT" || echo "TẮT")
        local notify_status=$([[ "$TERMINAL_NOTIFY" == "true" ]] && echo "BẬT" || echo "TẮT")
        local visualizer_status=$([[ "$SHOW_VISUALIZER" == "true" ]] && echo "BẬT" || echo "TẮT")
        local lyrics_status=$([[ "$SHOW_LYRICS" == "true" ]] && echo "BẬT" || echo "TẮT")
        local optional_pkgs_status=$([[ "$SKIP_OPTIONAL_PKGS" == "true" ]] && echo "TẮT" || echo "BẬT")
        local dependency_check_status=$([[ "$SKIP_DEPENDENCY_CHECK" == "true" ]] && echo "TẮT" || echo "BẮT")
        
        local options=(
            "${SYM_FOLDER} 1. Thay đổi thư mục tải xuống" "Thay đổi nơi lưu nhạc tải về"
            "${SYM_PLAY} 2. Thay đổi trình phát mặc định" "Chọn trình phát nhạc (mpv/vlc/ffplay)"
            "${SYM_SETTINGS} 3. Thay đổi chất lượng mặc định" "Chọn chất lượng nhạc (128k/192k/256k/320k)"
            "${SYM_SETTINGS} 4. Thay đổi chủ đề" "Thay đổi giao diện màu sắc"
            "${SYM_SETTINGS} 5. Bật/tắt thông báo" "Bật hoặc tắt thông báo hệ thống"
            "${SYM_SETTINGS} 6. Bật/tắt thông báo terminal" "Bật hoặc tắt thông báo trên terminal"
            "${SYM_SETTINGS} 7. Bật/tắt hiển thị lời bài hát" "Hiện tại: $lyrics_status"
            "${SYM_SETTINGS} 8. Bật/tắt visualizer" "Hiện tại: $visualizer_status"
            "${SYM_SETTINGS} 9. Xóa cache" "Xóa toàn bộ dữ liệu cache"
            "${SYM_SETTINGS} 10. Sao lưu cấu hình" "Sao lưu cấu hình hiện tại"
            "${SYM_SETTINGS} 11. Khôi phục cấu hình" "Khôi phục từ bản sao lưu"
            "${SYM_SETTINGS} 12. Bật/tắt kiểm tra phụ thuộc: $dependency_check_status" "Bật hoặc tắt kiểm tra gói khi khởi động"
            "${SYM_SETTINGS} 13. Cấu hình log" "Thay đổi cấu hình ghi log"
            "${SYM_SETTINGS} 14. Bật/tắt gói tùy chọn: $optional_pkgs_status" "Bật hoặc tắt cài đặt gói tùy chọn"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu chính"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn menu cài đặt" "$choice"
        
        case $choice in
            1) change_download_dir ;;
            2) change_default_player ;;
            3) change_default_quality ;;
            4) change_theme ;;
            5) toggle_notifications ;;
            6) toggle_terminal_notify ;;
            7) toggle_lyrics ;;
            8) toggle_visualizer ;;
            9) clear_cache ;;
            10) backup_config ;;
            11) restore_config ;;
            12) toggle_dependency_check ;;
            13) configure_logging ;;
            14) toggle_optional_packages ;;
            0) 
                log "NAVIGATE" "Quay lại menu chính"
                return 
                ;;
            *) 
                warn "${SYM_WARNING} Lựa chọn không hợp lệ, vui lòng chọn lại"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ THAY ĐỔI THƯ MỤC TẢI XUỐNG ============================
change_download_dir() {
    read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập đường dẫn thư mục tải xuống mới: " new_dir
    log "USER" "Nhập thư mục tải xuống mới" "$new_dir"
    
    if [[ -z "$new_dir" ]]; then
        warn "${SYM_WARNING} Đường dẫn không được để trống"
        log "WARN" "Thư mục tải xuống trống"
        return
    fi
    
    mkdir -p "$new_dir"
    if [[ ! -d "$new_dir" ]]; then
        error "${SYM_ERROR} Không thể tạo thư mục $new_dir"
        log "ERROR" "Không thể tạo thư mục: $new_dir"
        return
    fi
    
    sed -i "s|^DOWNLOAD_DIR=.*|DOWNLOAD_DIR=\"$new_dir\"|" "$CONFIG_FILE"
    DOWNLOAD_DIR="$new_dir"
    notify "${SYM_SUCCESS} Đã thay đổi thư mục tải xuống thành: $new_dir"
    log "SETTINGS" "Thay đổi thư mục tải xuống thành: $new_dir"
}

# ============================ THAY ĐỔI TRÌNH PHÁT MẶC ĐỊNH ============================
change_default_player() {
    local players=("mpv" "vlc" "ffplay")
    local selected=$(printf "%s\n" "${players[@]}" | fzf --prompt="Chọn trình phát mặc định: ")
    log "USER" "Chọn trình phát mặc định" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có trình phát nào được chọn"
        log "WARN" "Không chọn trình phát"
        return
    fi
    
    sed -i "s/^DEFAULT_PLAYER=.*/DEFAULT_PLAYER=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_PLAYER="$selected"
    notify "${SYM_SUCCESS} Đã thay đổi trình phát mặc định thành: $selected"
    log "SETTINGS" "Thay đổi trình phát mặc định thành: $selected"
}

# ============================ THAY ĐỔI CHẤT LƯỢNG MẶC ĐỊNH ============================
change_default_quality() {
    local qualities=("128k" "192k" "256k" "320k")
    local selected=$(printf "%s\n" "${qualities[@]}" | fzf --prompt="Chọn chất lượng mặc định: ")
    log "USER" "Chọn chất lượng mặc định" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có chất lượng nào được chọn"
        log "WARN" "Không chọn chất lượng"
        return
    fi
    
    sed -i "s/^DEFAULT_QUALITY=.*/DEFAULT_QUALITY=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_QUALITY="$selected"
    notify "${SYM_SUCCESS} Đã thay đổi chất lượng mặc định thành: $selected"
    log "SETTINGS" "Thay đổi chất lượng mặc định thành: $selected"
}

# ============================ THAY ĐỔI CHỦ ĐỀ ============================
change_theme() {
    local themes=("dark" "light" "blue" "green" "red")
    local selected=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Chọn chủ đề: ")
    log "USER" "Chọn chủ đề" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có chủ đề nào được chọn"
        log "WARN" "Không chọn chủ đề"
        return
    fi
    
    sed -i "s/^THEME=.*/THEME=\"$selected\"/" "$CONFIG_FILE"
    THEME="$selected"
    init_ui
    notify "${SYM_SUCCESS} Đã thay đổi chủ đề thành: $selected"
    log "SETTINGS" "Thay đổi chủ đề thành: $selected"
}

# ============================ BẬT/TẮT THÔNG BÁO ============================
toggle_notifications() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=false/" "$CONFIG_FILE"
        NOTIFICATIONS="false"
        notify "${SYM_SUCCESS} Đã tắt thông báo"
        log "SETTINGS" "Tắt thông báo"
    else
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=true/" "$CONFIG_FILE"
        NOTIFICATIONS="true"
        notify "${SYM_SUCCESS} Đã bật thông báo"
        log "SETTINGS" "Bật thông báo"
    fi
}

# ============================ BẬT/TẮT THÔNG BÁO TERMINAL ============================
toggle_terminal_notify() {
    if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
        sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=false/" "$CONFIG_FILE"
        TERMINAL_NOTIFY="false"
        notify "${SYM_SUCCESS} Đã tắt thông báo terminal"
        log "SETTINGS" "Tắt thông báo terminal"
    else
        sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=true/" "$CONFIG_FILE"
        TERMINAL_NOTIFY="true"
        notify "${SYM_SUCCESS} Đã bật thông báo terminal"
        log "SETTINGS" "Bật thông báo terminal"
    fi
}

# ============================ BẬT/TẮT HIỂN THỊ LỜI BÀI HÁT ============================
toggle_lyrics() {
    if [[ "$SHOW_LYRICS" == "true" ]]; then
        sed -i "s/^SHOW_LYRICS=.*/SHOW_LYRICS=false/" "$CONFIG_FILE"
        SHOW_LYRICS="false"
        notify "${SYM_SUCCESS} Đã tắt hiển thị lời bài hát"
        log "SETTINGS" "Tắt hiển thị lời bài hát"
    else
        sed -i "s/^SHOW_LYRICS=.*/SHOW_LYRICS=true/" "$CONFIG_FILE"
        SHOW_LYRICS="true"
        notify "${SYM_SUCCESS} Đã bật hiển thị lời bài hát"
        log "SETTINGS" "Bật hiển thị lời bài hát"
    fi
}

# ============================ BẬT/TẮT VISUALIZER ============================
toggle_visualizer() {
    if [[ "$SHOW_VISUALIZER" == "true" ]]; then
        sed -i "s/^SHOW_VISUALIZER=.*/SHOW_VISUALIZER=false/" "$CONFIG_FILE"
        SHOW_VISUALIZER="false"
        notify "${SYM_SUCCESS} Đã tắt visualizer"
        log "SETTINGS" "Tắt visualizer"
    else
        sed -i "s/^SHOW_VISUALIZER=.*/SHOW_VISUALIZER=true/" "$CONFIG_FILE"
        SHOW_VISUALIZER="true"
        notify "${SYM_SUCCESS} Đã bật visualizer"
        log "SETTINGS" "Bật visualizer"
    fi
}

# ============================ BẬT/TẮT KIỂM TRA PHỤ THUỘC ============================
toggle_dependency_check() {
    if [[ "$SKIP_DEPENDENCY_CHECK" == "true" ]]; then
        sed -i "s/^SKIP_DEPENDENCY_CHECK=.*/SKIP_DEPENDENCY_CHECK=false/" "$CONFIG_FILE"
        SKIP_DEPENDENCY_CHECK="false"
        notify "${SYM_SUCCESS} Đã bật kiểm tra phụ thuộc"
        log "SETTINGS" "Bật kiểm tra phụ thuộc"
    else
        sed -i "s/^SKIP_DEPENDENCY_CHECK=.*/SKIP_DEPENDENCY_CHECK=true/" "$CONFIG_FILE"
        SKIP_DEPENDENCY_CHECK="true"
        notify "${SYM_SUCCESS} Đã tắt kiểm tra phụ thuộc"
        log "SETTINGS" "Tắt kiểm tra phụ thuộc"
    fi
}

# ============================ BẬT/TẮT GÓI TÙY CHỌN ============================
toggle_optional_packages() {
    if [[ "$SKIP_OPTIONAL_PKGS" == "true" ]]; then
        sed -i "s/^SKIP_OPTIONAL_PKGS=.*/SKIP_OPTIONAL_PKGS=false/" "$CONFIG_FILE"
        SKIP_OPTIONAL_PKGS="false"
        notify "${SYM_SUCCESS} Đã bật cài đặt gói tùy chọn"
        log "SETTINGS" "Bật cài đặt gói tùy chọn"
    else
        sed -i "s/^SKIP_OPTIONAL_PKGS=.*/SKIP_OPTIONAL_PKGS=true/" "$CONFIG_FILE"
        SKIP_OPTIONAL_PKGS="true"
        notify "${SYM_SUCCESS} Đã tắt cài đặt gói tùy chọn"
        log "SETTINGS" "Tắt cài đặt gói tùy chọn"
    fi
}

# ============================ XÓA CACHE ============================
clear_cache() {
    rm -rf "$CACHE_DIR"/*
    notify "${SYM_SUCCESS} Đã xóa toàn bộ cache"
    log "SETTINGS" "Xóa toàn bộ cache"
}

# ============================ SAO LƯU CẤU HÌNH ============================
backup_config() {
    local backup_file="$BACKUP_DIR/config_backup_$(date +%Y%m%d_%H%M%S).cfg"
    cp "$CONFIG_FILE" "$backup_file"
    notify "${SYM_SUCCESS} Đã sao lưu cấu hình tại: $backup_file"
    log "SETTINGS" "Sao lưu cấu hình tại: $backup_file"
}

# ============================ KHÔI PHỤC CẤU HÌNH ============================
restore_config() {
    local backup_files=($(ls -t "$BACKUP_DIR"/config_backup_*.cfg 2>/dev/null))
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        warn "${SYM_WARNING} Không có bản sao lưu nào được tìm thấy"
        log "WARN" "Không tìm thấy bản sao lưu"
        return
    fi
    
    local selected=$(printf "%s\n" "${backup_files[@]}" | fzf --prompt="Chọn bản sao lưu: ")
    log "USER" "Chọn bản sao lưu" "$selected"
    
    if [[ -z "$selected" ]]; then
        warn "${SYM_WARNING} Không có bản sao lưu nào được chọn"
        log "WARN" "Không chọn bản sao lưu"
        return
    fi
    
    cp "$selected" "$CONFIG_FILE"
    source "$CONFIG_FILE"
    notify "${SYM_SUCCESS} Đã khôi phục cấu hình từ: $selected"
    log "SETTINGS" "Khôi phục cấu hình từ: $selected"
}

# ============================ CẤU HÌNH LOGGING ============================
configure_logging() {
    while true; do
        show_header
        
        local current_log_level="${LOG_LEVEL^^}"
        local log_status=$([[ "$LOG_TO_FILE" == "true" ]] && echo "BẬT" || echo "TẮT")
        local notify_status=$([[ "$TERMINAL_NOTIFY" == "true" ]] && echo "BẬT" || echo "TẮT")
        
        local options=(
            "${SYM_SETTINGS} 1. Mức độ log hiện tại: $current_log_level" "Chọn mức độ ghi log (debug/info/warn/error)"
            "${SYM_SETTINGS} 2. Ghi log ra file: $log_status" "Bật/tắt ghi log ra file musicsub.log"
            "${SYM_SETTINGS} 3. Thông báo trên terminal: $notify_status" "Bật/tắt thông báo trên terminal"
            "${SYM_FOLDER} 4. Xem log file" "Hiển thị nội dung file log"
            "${SYM_EXIT} 0. Quay lại" "Quay lại menu cài đặt"
        )
        
        show_menu "${options[@]}"
        
        read -r -p "${PRIMARY}${SYM_PROMPT}${NC} Chọn một tùy chọn: " choice
        log "USER" "Lựa chọn cấu hình log" "$choice"
        
        case $choice in
            1)
                local levels=("debug" "info" "warn" "error")
                local selected=$(printf "%s\n" "${levels[@]}" | fzf --prompt="Chọn mức độ log: ")
                
                if [[ -n "$selected" ]]; then
                    sed -i "s/^LOG_LEVEL=.*/LOG_LEVEL=\"$selected\"/" "$CONFIG_FILE"
                    LOG_LEVEL="$selected"
                    notify "${SYM_SUCCESS} Đã thay đổi mức độ log thành: $selected"
                    log "SETTINGS" "Thay đổi mức độ log thành: $selected"
                fi
                ;;
            2)
                if [[ "$LOG_TO_FILE" == "true" ]]; then
                    sed -i "s/^LOG_TO_FILE=.*/LOG_TO_FILE=false/" "$CONFIG_FILE"
                    LOG_TO_FILE="false"
                    notify "${SYM_SUCCESS} Đã tắt ghi log ra file"
                    log "SETTINGS" "Tắt ghi log ra file"
                else
                    sed -i "s/^LOG_TO_FILE=.*/LOG_TO_FILE=true/" "$CONFIG_FILE"
                    LOG_TO_FILE="true"
                    notify "${SYM_SUCCESS} Đã bật ghi log ra file"
                    log "SETTINGS" "Bật ghi log ra file"
                fi
                ;;
            3)
                if [[ "$TERMINAL_NOTIFY" == "true" ]]; then
                    sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=false/" "$CONFIG_FILE"
                    TERMINAL_NOTIFY="false"
                    notify "${SYM_SUCCESS} Đã tắt thông báo trên terminal"
                    log "SETTINGS" "Tắt thông báo trên terminal"
                else
                    sed -i "s/^TERMINAL_NOTIFY=.*/TERMINAL_NOTIFY=true/" "$CONFIG_FILE"
                    TERMINAL_NOTIFY="true"
                    notify "${SYM_SUCCESS} Đã bật thông báo trên terminal"
                    log "SETTINGS" "Bật thông báo trên terminal"
                fi
                ;;
            4)
                if [[ -f "$CONFIG_DIR/musicsub.log" ]]; then
                    less "$CONFIG_DIR/musicsub.log"
                else
                    warn "${SYM_WARNING} Không tìm thấy file log"
                    log "WARN" "Không tìm thấy file log để xem"
                fi
                ;;
            0)
                return
                ;;
            *)
                warn "${SYM_WARNING} Lựa chọn không hợp lệ"
                log "WARN" "Lựa chọn không hợp lệ: $choice"
                ;;
        esac
    done
}

# ============================ XỬ LÝ CLI ARGUMENTS ============================
process_cli_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--update)
                log "SYSTEM" "Cập nhật script từ CLI"
                update_script
                exit 0
                ;;
            -v|--version)
                log "SYSTEM" "Hiển thị phiên bản từ CLI"
                echo "MusicSub version $VERSION"
                exit 0
                ;;
            -h|--help)
                log "SYSTEM" "Hiển thị trợ giúp từ CLI"
                show_help
                exit 0
                ;;
            --play)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu tên bài hát cần phát"
                    log "ERROR" "Thiếu tên bài hát từ CLI"
                    exit 1
                fi
                DIRECT_PLAY="$2"
                log "SYSTEM" "Phát trực tiếp từ CLI: $DIRECT_PLAY"
                shift
                ;;
            --search)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu từ khóa tìm kiếm"
                    log "ERROR" "Thiếu từ khóa tìm kiếm từ CLI"
                    exit 1
                fi
                DIRECT_SEARCH="$2"
                log "SYSTEM" "Tìm kiếm trực tiếp từ CLI: $DIRECT_SEARCH"
                shift
                ;;
            --download)
                if [[ -z "$2" ]]; then
                    error "${SYM_ERROR} Thiếu URL nhạc cần tải"
                    log "ERROR" "Thiếu URL tải từ CLI"
                    exit 1
                fi
                DIRECT_DOWNLOAD="$2"
                log "SYSTEM" "Tải trực tiếp từ CLI: $DIRECT_DOWNLOAD"
                shift
                ;;
            *)
                error "${SYM_ERROR} Argument không hợp lệ: $1"
                log "ERROR" "Argument không hợp lệ từ CLI: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# ============================ HIỂN THỊ TRỢ GIÚP ============================
show_help() {
    draw_box 80 "TRỢ GIÚP MUSICSUB" "$PRIMARY" "\
${ACCENT}Usage:${NC} $0 [OPTION]

${ACCENT}Options:${NC}
  -u, --update        Cập nhật script lên phiên bản mới nhất
  -v, --version       Hiển thị phiên bản hiện tại
  -h, --help          Hiển thị thông tin trợ giúp này
  --play \"TÊN\"       Phát trực tiếp bài hát không qua menu
  --search \"TỪ KHÓA\"  Tìm kiếm nhanh bài hát
  --download \"URL\"    Tải nhạc từ URL

${ACCENT}Ví dụ:${NC}
  $0 --play \"Shape of You\"
  $0 --search \"Ed Sheeran\"
  $0 --download \"https://youtu.be/JGwWNGJdvx8\"

${ACCENT}Tác giả:${NC} ${AUTHORS[*]}
${ACCENT}Donate:${NC} $DONATION_LINK"
    exit 0
}

# ============================ KIỂM TRA BẢN CẬP NHẬT ============================
check_for_updates() {
    log "SYSTEM" "Kiểm tra bản cập nhật"
    notify "${SYM_UPDATE} Đang kiểm tra bản cập nhật..."
    
    # Thêm kiểm tra kết nối Internet trước
    if ! curl -Is https://github.com >/dev/null 2>&1; then
        error "${SYM_ERROR} Không thể kết nối đến GitHub. Vui lòng kiểm tra kết nối Internet."
        log "ERROR" "Không có kết nối Internet để kiểm tra cập nhật"
        return 1
    fi

    # Sử dụng URL raw chính xác 
    local latest_content=$(curl -s "https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh")
    if [[ -z "$latest_content" ]]; then
        error "${SYM_ERROR} Không thể tải nội dung từ GitHub"
        log "ERROR" "Không thể tải nội dung từ GitHub"
        return 1
    fi

    local latest_version=$(echo "$latest_content" | grep -m1 "VERSION=" | cut -d'"' -f2)
    
    if [[ -z "$latest_version" ]]; then
        error "${SYM_ERROR} Không thể xác định phiên bản mới nhất"
        log "ERROR" "Không thể xác định phiên bản mới nhất"
        return 1
    fi

    if [[ "$latest_version" != "$VERSION" ]]; then
        warn "${SYM_WARNING} Đã có bản cập nhật mới!"
        log "UPDATE" "Phát hiện phiên bản mới: $latest_version (Hiện tại: $VERSION)"
        draw_box 60 "CẬP NHẬT MỚI" "$WARNING" "\
${ACCENT}Bản hiện tại:${NC} $VERSION
${ACCENT}Bản mới nhất:${NC} $latest_version

${TEXT}Bạn có muốn cập nhật không?${NC}"
        
        read -p "${PRIMARY}${SYM_PROMPT}${NC} Nhập lựa chọn (y/N): " -n 1 -r
        echo
        log "USER" "Lựa chọn cập nhật" "$REPLY"
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_script
        else
            notify "${SYM_INFO} Bạn đã chọn không cập nhật. Có thể có lỗi tiềm ẩn khi sử dụng bản cũ."
            log "UPDATE" "Người dùng từ chối cập nhật"
        fi
    else
        notify "${SYM_SUCCESS} Bạn đang sử dụng phiên bản mới nhất ($VERSION)"
        log "UPDATE" "Đang sử dụng phiên bản mới nhất: $VERSION"
    fi
}

# ============================ CẬP NHẬT SCRIPT ============================
update_script() {
    log "SYSTEM" "Bắt đầu cập nhật script"
    notify "${SYM_UPDATE} Đang cập nhật script..."
    local tmp_file="/tmp/musicsub_update.sh"
    
    if curl -s "https://raw.githubusercontent.com/kidtomboy/MusicSub/main/musicsub.sh" -o "$tmp_file"; then
        # Kiểm tra xem file tải về có hợp lệ không
        if grep -q "MUSICSUB PRO MAX" "$tmp_file"; then
            chmod +x "$tmp_file"
            mv "$tmp_file" "$0"
            notify "${SYM_SUCCESS} Cập nhật thành công! Vui lòng chạy lại script."
            log "UPDATE" "Cập nhật thành công"
            exit 0
        else
            rm -f "$tmp_file"
            error "${SYM_ERROR} File tải về không hợp lệ"
            log "ERROR" "File cập nhật không hợp lệ"
            return 1
        fi
    else
        error "${SYM_ERROR} Không thể tải bản cập nhật. Vui lòng thử lại sau."
        log "ERROR" "Không thể tải bản cập nhật"
        return 1
    fi
}

# ============================ HIỂN THỊ THÔNG TIN TÁC GIẢ ============================
show_authors() {
    log "SYSTEM" "Hiển thị thông tin tác giả"
    clear
    draw_box 60 "THÔNG TIN TÁC GIẢ" "$PRIMARY" "\
${ACCENT}Tác giả:${NC} ${AUTHORS[*]}

${ACCENT}Donate:${NC} $DONATION_LINK

${ACCENT}Github:${NC} https://github.com/kidtomboy

${TEXT}Cảm ơn bạn đã sử dụng MusicSub!${NC}"
    
    read -n 1 -s -r -p "${PRIMARY}${SYM_PROMPT}${NC} Nhấn bất kỳ phím nào để tiếp tục..."
}

# ============================ XỬ LÝ KHI NGƯỜI DÙNG NHẤN CTRL+C HOẶC CTRL+Z ============================
handle_interrupt() {
    case $1 in
        SIGINT)
            echo
            warn "${SYM_WARNING} Bạn có chắc muốn thoát? (y/N) "
            read -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log "SYSTEM" "Người dùng chọn thoát khi nhấn Ctrl+C"
                echo
                exit 0
            else
                log "SYSTEM" "Người dùng chọn tiếp tục sau khi nhấn Ctrl+C"
                echo
                main_menu
            fi
            ;;
        SIGTSTP)
            echo
            log "SYSTEM" "Phát hiện dừng đột ngột (Ctrl+Z)"
            exit 0
            ;;
    esac
}

# ============================ HÀM CHÍNH ============================
main() {
    # Bắt lỗi và thoát
    trap 'handle_interrupt SIGINT' SIGINT
    trap 'handle_interrupt SIGTSTP' SIGTSTP
    trap 'log "SYSTEM" "Chương trình bị dừng đột ngột"; exit 1' SIGTERM
    
    init_dirs
    init_ui
    check_dependencies "$1"
    
    # Xử lý CLI arguments nếu có
    if [[ $# -gt 0 ]]; then
        process_cli_arguments "$@"
    fi
    
    # Xử lý các lệnh trực tiếp
    if [[ -n "$DIRECT_PLAY" ]]; then
        log "SYSTEM" "Phát trực tiếp: $DIRECT_PLAY"
        play_from_youtube "$DIRECT_PLAY"
        exit 0
    fi
    
    if [[ -n "$DIRECT_SEARCH" ]]; then
        log "SYSTEM" "Tìm kiếm trực tiếp: $DIRECT_SEARCH"
        search_youtube "$DIRECT_SEARCH"
        exit 0
    fi
    
    if [[ -n "$DIRECT_DOWNLOAD" ]]; then
        log "SYSTEM" "Tải trực tiếp: $DIRECT_DOWNLOAD"
        
        if [[ "$DIRECT_DOWNLOAD" == *"youtube.com"* || "$DIRECT_DOWNLOAD" == *"youtu.be"* ]]; then
            local song_title=$(yt-dlp --get-title "$DIRECT_DOWNLOAD" 2>/dev/null || echo "YouTube Music")
            local song_artist=$(yt-dlp --get-description "$DIRECT_DOWNLOAD" 2>/dev/null | head -n 1 || echo "Unknown Artist")
            download_music "$DIRECT_DOWNLOAD" "$song_title" "$DOWNLOAD_DIR/YouTube" "$song_artist"
            exit $?
        else
            download_music "$DIRECT_DOWNLOAD" "Music_$(date +%s)" "$DOWNLOAD_DIR" "Direct_Download"
            exit $?
        fi
    fi
    
    # Hiển thị thông báo khởi động
    show_header
    
    local content="\
${SYM_SUCCESS} Đang khởi động MusicSub Pro Max...
${SYM_SUCCESS} Hệ điều hành: $OS ($OS_DISTRO)
${SYM_SUCCESS} Thư mục cấu hình: $CONFIG_DIR
${SYM_SUCCESS} Thư mục tải xuống: $DOWNLOAD_DIR"
    
    draw_box 60 "THÔNG TIN HỆ THỐNG" "$INFO" "$content"
    sleep 2
    
    # Kiểm tra kết nối Internet
    if ! curl -Is https://google.com | grep -q "HTTP/2"; then
        error "${SYM_ERROR} Không có kết nối Internet. Vui lòng kiểm tra kết nối của bạn."
        log "ERROR" "Không có kết nối Internet"
        exit 1
    fi
    
    # Chạy menu chính
    main_menu
}

# Chạy chương trình
main "$@"

# Kết thúc
exit 0
