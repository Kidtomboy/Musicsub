#!/bin/bash

###############################################################################
# MUSISUB PRO MAX
# Phiên bản: 1.0
# Tác giả: Remake by @Kidtomboy 1337
# Ngày cập nhật: 28/3/2025
#
# Tính năng chính:
# - Phát nhạc từ nhiều nguồn (SoundCloud, Spotify, Mixcloud, YouTube, Deezer)
# - Tải nhạc về thiết bị
# - Tạo playlist
# - Lịch sử nghe nhạc
# - Thêm bài hát vào danh sách yêu thích 
# - Hệ thống cấu hình và cache
# - Bật/tắt thông báo
###############################################################################

# Phiên bản script 
VERSION="1.0"

# Cấu hình
CONFIG_DIR="$HOME/.config/musisub_cli"
CONFIG_FILE="$CONFIG_DIR/config.cfg"
DOWNLOAD_DIR="$HOME/Downloads/music"
LOG_FILE="$CONFIG_DIR/musisub_cli.log"
CACHE_DIR="$CONFIG_DIR/cache"
HISTORY_FILE="$CONFIG_DIR/history.txt"
FAVORITES_FILE="$CONFIG_DIR/favorites.txt"
PLAYLISTS_DIR="$CONFIG_DIR/playlists"

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Cooldown thông báo
LAST_NOTIFICATION_TIME=2
NOTIFICATION_COOLDOWN=2

# Khởi tạo thư mục
init_dirs() {
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CACHE_DIR" "$PLAYLISTS_DIR"
    touch "$LOG_FILE" "$HISTORY_FILE" "$FAVORITES_FILE"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<- EOM
DEFAULT_PLAYER="mpv"
DEFAULT_QUALITY="high"
DEFAULT_SOURCE="youtube"
MAX_CACHE_AGE=86400
THEME="dark"
NOTIFICATIONS=true
UPDATE_URL="https://raw.githubusercontent.com/kidtomboy/musisub/main/musisub.sh"
EOM
    fi
    
    source "$CONFIG_FILE"
    log "SYSTEM" "Khởi tạo thư mục và file cấu hình"
}

# Thông báo
notify() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        local current_time=$(date +%s)
        if (( current_time - LAST_NOTIFICATION_TIME >= NOTIFICATION_COOLDOWN )); then
            LAST_NOTIFICATION_TIME=$current_time
            if command -v notify-send &> /dev/null; then
                notify-send "MusiSub" "$1"
            fi
        fi
    fi
    echo -e "${GREEN}[INFO]${NC} $1"
    log "INFO" "$1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
    log "WARN" "$1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    log "ERROR" "$1"
}

log() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$1] $2" >> "$LOG_FILE"
}

# Kiểm tra phụ thuộc
check_dependencies() {
    local -A pkg_manager=(
        ["apt"]="sudo apt-get install -y"
        ["pacman"]="sudo pacman -S --noconfirm"
        ["dnf"]="sudo dnf install -y"
        ["yum"]="sudo yum install -y"
        ["zypper"]="sudo zypper install -y"
        ["brew"]="brew install"
    )

    local manager
    for m in "${!pkg_manager[@]}"; do
        if command -v "$m" &>/dev/null; then
            manager="$m"
            break
        fi
    done

    if [[ -z "$manager" ]]; then
        error "Không thể xác định trình quản lý gói!"
        return 1
    fi

    local -A required_pkgs=(
        ["curl"]="curl"
        ["jq"]="jq"
        ["fzf"]="fzf"
        ["mpv"]="mpv"
        ["yt-dlp"]="yt-dlp"
    )

    local -A optional_pkgs=(
        ["ffmpeg"]="ffmpeg"
        ["notify-send"]="libnotify-bin"
        ["spotdl"]="spotdl"
    )

    local missing=()
    local optional_missing=()

    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("${required_pkgs[$cmd]}")
        fi
    done

    for cmd in "${!optional_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            optional_missing+=("${optional_pkgs[$cmd]}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Đang cài đặt các gói bắt buộc: ${missing[*]}"
        
        if [[ "$manager" == "pacman" ]] && [[ " ${missing[@]} " =~ " libnotify-bin " ]]; then
            missing=("${missing[@]/libnotify-bin/libnotify}")
        fi

        if ! ${pkg_manager[$manager]} "${missing[@]}"; then
            error "Không thể cài đặt các gói bắt buộc!"
            exit 1
        fi
    fi

    if [[ ${#optional_missing[@]} -gt 0 ]]; then
        warn "Các gói tùy chọn chưa có: ${optional_missing[*]}"
        read -p "Bạn có muốn cài đặt chúng không? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${pkg_manager[$manager]} "${optional_missing[@]}" || warn "Có lỗi khi cài gói tùy chọn"
        fi
    fi

    for cmd in "${!required_pkgs[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            error "Không thể cài đặt $cmd, script không thể chạy!"
            exit 1
        fi
    done
}

# Tìm kiếm nhạc từ YouTube
search_youtube() {
    local keyword="$1"
    local cache_file="$CACHE_DIR/youtube_search_${keyword}.cache"
    
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    notify "Đang tìm kiếm trên YouTube: $keyword..."
    local search_results=$(yt-dlp --flat-playlist "ytsearch10:$keyword" -j 2>/dev/null | jq -r '.title + "@@@" + .url' 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        warn "Không tìm thấy kết quả nào cho '$keyword'"
        return 1
    fi
    
    local processed_list=$(echo "$search_results" | awk -F '@@@' '{print NR ". " $1 " (" $2 ")"}')
    echo "$processed_list" > "$cache_file"
    echo "$processed_list"
}

# Tìm kiếm nhạc từ SoundCloud
search_soundcloud() {
    local keyword="$1"
    local cache_file="$CACHE_DIR/soundcloud_search_${keyword}.cache"
    
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    notify "Đang tìm kiếm trên SoundCloud: $keyword..."
    local search_results=$(yt-dlp --flat-playlist "scsearch10:$keyword" -j 2>/dev/null | jq -r '.title + "@@@" + .url' 2>/dev/null)
    
    if [[ -z "$search_results" ]]; then
        warn "Không tìm thấy kết quả nào cho '$keyword'"
        return 1
    fi
    
    local processed_list=$(echo "$search_results" | awk -F '@@@' '{print NR ". " $1 " (" $2 ")"}')
    echo "$processed_list" > "$cache_file"
    echo "$processed_list"
}

# Tìm kiếm từ Spotify (yêu cầu spotdl)
search_spotify() {
    if ! command -v spotdl &> /dev/null; then
        error "spotdl không được cài đặt. Không thể tìm kiếm trên Spotify."
        return 1
    fi
    
    local keyword="$1"
    local cache_file="$CACHE_DIR/spotify_search_${keyword}.cache"
    
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $MAX_CACHE_AGE ]]; then
            cat "$cache_file"
            return
        fi
    fi
    
    notify "Đang tìm kiếm trên Spotify: $keyword..."
    local search_results=$(spotdl search "$keyword" --limit 10 2>/dev/null | awk -F ' - ' '{print NR ". " $0}')
    
    if [[ -z "$search_results" ]]; then
        warn "Không tìm thấy kết quả nào cho '$keyword'"
        return 1
    fi
    
    echo "$search_results" > "$cache_file"
    echo "$search_results"
}

# Phát nhạc với MPV
play_with_mpv() {
    local url="$1"
    local title="$2"
    
    notify "Đang phát: $title"
    mpv "$url" \
        --force-media-title="$title" \
        --no-terminal \
        --audio-display=no \
        --title="MusiSub - $title"
}

# Thêm vào lịch sử
add_to_history() {
    local song="$1"
    local artist="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    local temp_file=$(mktemp)
    echo "$timestamp|$song|$artist" > "$temp_file"
    cat "$HISTORY_FILE" | head -n 49 >> "$temp_file"
    mv "$temp_file" "$HISTORY_FILE"
}

# Hiển thị lịch sử
show_history() {
    if [[ ! -s "$HISTORY_FILE" ]]; then
        echo "Không có lịch sử nghe nhạc."
        return
    fi
    
    cat "$HISTORY_FILE" | awk -F'|' '{print NR ". " $2 " - " $3 " (" $1 ")"}'
}

# Thêm vào yêu thích
add_to_favorites() {
    local song="$1"
    local artist="$2"
    local entry="$song - $artist"
    
    if grep -q "^$entry$" "$FAVORITES_FILE"; then
        warn "Bài hát đã có trong danh sách yêu thích"
        return
    fi
    
    echo "$entry" >> "$FAVORITES_FILE"
    notify "Đã thêm '$entry' vào danh sách yêu thích"
}

# Xóa khỏi yêu thích
remove_from_favorites() {
    local entry="$1"
    
    if ! grep -q "^$entry$" "$FAVORITES_FILE"; then
        warn "Bài hát không có trong danh sách yêu thích"
        return
    fi
    
    local temp_file=$(mktemp)
    grep -v "^$entry$" "$FAVORITES_FILE" > "$temp_file"
    mv "$temp_file" "$FAVORITES_FILE"
    notify "Đã xóa '$entry' khỏi danh sách yêu thích"
}

# Hiển thị yêu thích
show_favorites() {
    if [[ ! -s "$FAVORITES_FILE" ]]; then
        echo "Không có bài hát nào trong danh sách yêu thích."
        return
    fi
    
    cat "$FAVORITES_FILE" | awk '{print NR ". " $0}'
}

# Tải nhạc
download_music() {
    local url="$1"
    local title="$2"
    local output_dir="$3"
    
    if ! command -v yt-dlp &> /dev/null; then
        error "yt-dlp không được cài đặt. Không thể tải nhạc."
        return 1
    fi
    
    mkdir -p "$output_dir"
    notify "Đang tải: $title..."
    
    yt-dlp -x --audio-format mp3 -o "$output_dir/$title.%(ext)s" \
        --no-progress \
        --console-title \
        "$url"
    
    if [[ $? -eq 0 ]]; then
        notify "Đã tải xong: $title"
        log "DOWNLOAD" "Tải thành công: $title"
    else
        error "Tải nhạc thất bại"
        log "ERROR" "Tải nhạc thất bại: $title"
        return 1
    fi
}

# Tạo playlist mới
create_playlist() {
    read -r -p "Nhập tên playlist: " playlist_name
    if [[ -z "$playlist_name" ]]; then
        warn "Tên playlist không được để trống"
        return
    fi
    
    local playlist_file="$PLAYLISTS_DIR/$playlist_name.txt"
    if [[ -f "$playlist_file" ]]; then
        warn "Playlist đã tồn tại"
        return
    fi
    
    touch "$playlist_file"
    notify "Đã tạo playlist '$playlist_name'"
}

# Thêm vào playlist
add_to_playlist() {
    local song="$1"
    local artist="$2"
    local entry="$song - $artist"
    
    local playlists=$(ls "$PLAYLISTS_DIR" | grep ".txt$")
    if [[ -z "$playlists" ]]; then
        warn "Không có playlist nào. Hãy tạo playlist trước."
        return
    fi
    
    local selected_playlist=$(echo "$playlists" | fzf --prompt="Chọn playlist: ")
    if [[ -z "$selected_playlist" ]]; then
        warn "Không có playlist nào được chọn"
        return
    fi
    
    local playlist_file="$PLAYLISTS_DIR/$selected_playlist"
    if grep -q "^$entry$" "$playlist_file"; then
        warn "Bài hát đã có trong playlist này"
        return
    fi
    
    echo "$entry" >> "$playlist_file"
    notify "Đã thêm '$entry' vào playlist '$selected_playlist'"
}

# Hiển thị playlist
show_playlist() {
    local playlist_file="$1"
    
    if [[ ! -s "$playlist_file" ]]; then
        echo "Playlist trống."
        return
    fi
    
    cat "$playlist_file" | awk '{print NR ". " $0}'
}

# Menu chính
main_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│            ${MAGENTA}MUSISUB v$VERSION${CYAN}              │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Tìm kiếm và phát nhạc${CYAN}                   │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Lịch sử nghe nhạc${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Danh sách yêu thích${CYAN}                    │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Quản lý playlist${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}5. Cài đặt${CYAN}                                │${NC}"
        echo -e "${CYAN}│  ${YELLOW}6. Kiểm tra cập nhật${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${RED}0. Thoát${CYAN}                                    │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) search_and_play_menu ;;
            2) history_menu ;;
            3) favorites_menu ;;
            4) playlist_menu ;;
            5) settings_menu ;;
            6) check_for_updates ;;
            0) 
                log "SYSTEM" "Kết thúc chương trình"
                echo "Đã thoát MusiSub..."
                exit 0 
                ;;
            *) 
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# Menu tìm kiếm và phát nhạc
search_and_play_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│           ${MAGENTA}TÌM KIẾM VÀ PHÁT NHẠC${CYAN}           │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Tìm kiếm trên YouTube${CYAN}                  │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Tìm kiếm trên SoundCloud${CYAN}               │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Tìm kiếm trên Spotify${CYAN}                  │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Nhập URL trực tiếp${CYAN}                    │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) search_and_play "youtube" ;;
            2) search_and_play "soundcloud" ;;
            3) search_and_play "spotify" ;;
            4) play_from_url ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# Tìm kiếm và phát nhạc
search_and_play() {
    local source="$1"
    read -r -p "Nhập từ khóa tìm kiếm: " keyword
    if [[ -z "$keyword" ]]; then
        warn "Từ khóa không được để trống"
        return
    fi
    
    local search_results
    case "$source" in
        "youtube") search_results=$(search_youtube "$keyword") ;;
        "soundcloud") search_results=$(search_soundcloud "$keyword") ;;
        "spotify") search_results=$(search_spotify "$keyword") ;;
        *) warn "Nguồn không hợp lệ"; return ;;
    esac
    
    if [[ -z "$search_results" ]]; then
        warn "Không tìm thấy kết quả nào cho '$keyword'"
        return
    fi
    
    local selected_song=$(echo "$search_results" | fzf --prompt="Chọn bài hát: ")
    if [[ -z "$selected_song" ]]; then
        warn "Không có bài hát nào được chọn"
        return
    fi
    
    local song_title=$(echo "$selected_song" | sed 's/^[0-9]*\. //;s/ (.*)//')
    local song_url=$(echo "$selected_song" | grep -o '(http[^)]*)' | tr -d '()')
    local artist=$(echo "$song_title" | awk -F ' - ' '{print $2}')
    local song_name=$(echo "$song_title" | awk -F ' - ' '{print $1}')
    
    add_to_history "$song_name" "$artist"
    
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│         ${MAGENTA}ĐANG PHÁT: $song_name${CYAN}             │${NC}"
        echo -e "${CYAN}│         ${YELLOW}Nghệ sĩ: $artist${CYAN}                   │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Phát bài này${CYAN}                          │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Tải bài này xuống${CYAN}                     │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Thêm vào yêu thích${CYAN}                    │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Thêm vào playlist${CYAN}                     │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                play_with_mpv "$song_url" "$song_title"
                ;;
            2)
                download_music "$song_url" "$song_title" "$DOWNLOAD_DIR"
                ;;
            3)
                add_to_favorites "$song_name" "$artist"
                ;;
            4)
                add_to_playlist "$song_name" "$artist"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# Phát từ URL
play_from_url() {
    read -r -p "Nhập URL bài hát: " url
    if [[ -z "$url" ]]; then
        warn "URL không được để trống"
        return
    fi
    
    local title=$(yt-dlp --get-title "$url" 2>/dev/null)
    if [[ -z "$title" ]]; then
        title="Bài hát không tên"
    fi
    
    play_with_mpv "$url" "$title"
    add_to_history "$title" "Nghệ sĩ không xác định"
}

# Menu lịch sử
history_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│            ${MAGENTA}LỊCH SỬ NGHE NHẠC${CYAN}             │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        
        local history_list=$(show_history)
        if [[ -z "$history_list" ]]; then
            echo -e "${CYAN}│  ${YELLOW}Không có lịch sử nghe nhạc${CYAN}           │${NC}"
        else
            local i=1
            while IFS= read -r line; do
                if [[ $i -le 5 ]]; then
                    echo -e "${CYAN}│  ${YELLOW}$line${CYAN}" | awk '{printf "%-40s", $0}' | sed 's/$/│/'
                fi
                i=$((i + 1))
            done <<< "$history_list"
        fi
        
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Xem toàn bộ lịch sử${CYAN}                   │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Xóa lịch sử${CYAN}                           │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
                echo -e "${CYAN}│            ${MAGENTA}TOÀN BỘ LỊCH SỬ${CYAN}               │${NC}"
                echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
                echo "$history_list" | more
                echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                > "$HISTORY_FILE"
                notify "Đã xóa toàn bộ lịch sử"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# Menu yêu thích
favorites_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│          ${MAGENTA}DANH SÁCH YÊU THÍCH${CYAN}             │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        
        local favorites_list=$(show_favorites)
        if [[ -z "$favorites_list" ]]; then
            echo -e "${CYAN}│  ${YELLOW}Không có bài hát yêu thích${CYAN}           │${NC}"
        else
            local i=1
            while IFS= read -r line; do
                if [[ $i -le 5 ]]; then
                    echo -e "${CYAN}│  ${YELLOW}$line${CYAN}" | awk '{printf "%-40s", $0}' | sed 's/$/│/'
                fi
                i=$((i + 1))
            done <<< "$favorites_list"
        fi
        
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Xem toàn bộ yêu thích${CYAN}                 │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Phát bài hát từ yêu thích${CYAN}             │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Xóa bài hát khỏi yêu thích${CYAN}            │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
                echo -e "${CYAN}│          ${MAGENTA}TOÀN BỘ YÊU THÍCH${CYAN}               │${NC}"
                echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
                echo "$favorites_list" | more
                echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                if [[ -z "$favorites_list" ]]; then
                    warn "Không có bài hát nào trong danh sách yêu thích"
                    continue
                fi
                
                local selected_song=$(echo "$favorites_list" | fzf --prompt="Chọn bài hát: " | sed 's/^[0-9]*\. //')
                if [[ -z "$selected_song" ]]; then
                    warn "Không có bài hát nào được chọn"
                    continue
                fi
                
                local song_name=$(echo "$selected_song" | awk -F ' - ' '{print $1}')
                local artist=$(echo "$selected_song" | awk -F ' - ' '{print $2}')
                
                # Tìm kiếm bài hát trên YouTube
                local search_results=$(search_youtube "$selected_song")
                if [[ -z "$search_results" ]]; then
                    warn "Không tìm thấy bài hát trên YouTube"
                    continue
                fi
                
                local selected_result=$(echo "$search_results" | fzf --prompt="Chọn phiên bản: ")
                if [[ -z "$selected_result" ]]; then
                    warn "Không có phiên bản nào được chọn"
                    continue
                fi
                
                local song_url=$(echo "$selected_result" | grep -o '(http[^)]*)' | tr -d '()')
                play_with_mpv "$song_url" "$selected_song"
                add_to_history "$song_name" "$artist"
                ;;
            3)
                if [[ -z "$favorites_list" ]]; then
                    warn "Không có bài hát nào trong danh sách yêu thích"
                    continue
                fi
                
                local selected_song=$(echo "$favorites_list" | fzf --prompt="Chọn bài hát để xóa: " | sed 's/^[0-9]*\. //')
                if [[ -z "$selected_song" ]]; then
                    warn "Không có bài hát nào được chọn"
                    continue
                fi
                
                remove_from_favorites "$selected_song"
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# Menu playlist
playlist_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│             ${MAGENTA}QUẢN LÝ PLAYLIST${CYAN}             │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Tạo playlist mới${CYAN}                      │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Xem và phát playlist${CYAN}                 │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Xóa playlist${CYAN}                         │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) create_playlist ;;
            2) view_playlist ;;
            3) delete_playlist ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# Xem và phát playlist
view_playlist() {
    local playlists=$(ls "$PLAYLISTS_DIR" | grep ".txt$")
    if [[ -z "$playlists" ]]; then
        warn "Không có playlist nào"
        return
    fi
    
    local selected_playlist=$(echo "$playlists" | fzf --prompt="Chọn playlist: ")
    if [[ -z "$selected_playlist" ]]; then
        warn "Không có playlist nào được chọn"
        return
    fi
    
    local playlist_file="$PLAYLISTS_DIR/$selected_playlist"
    local playlist_content=$(show_playlist "$playlist_file")
    
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│         ${MAGENTA}PLAYLIST: $selected_playlist${CYAN}      │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        
        if [[ -z "$playlist_content" ]]; then
            echo -e "${CYAN}│  ${YELLOW}Playlist trống${CYAN}                       │${NC}"
        else
            local i=1
            while IFS= read -r line; do
                if [[ $i -le 5 ]]; then
                    echo -e "${CYAN}│  ${YELLOW}$line${CYAN}" | awk '{printf "%-40s", $0}' | sed 's/$/│/'
                fi
                i=$((i + 1))
            done <<< "$playlist_content"
        fi
        
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Xem toàn bộ playlist${CYAN}                  │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Phát playlist${CYAN}                        │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Xóa bài hát khỏi playlist${CYAN}            │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1)
                clear
                echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
                echo -e "${CYAN}│      ${MAGENTA}TOÀN BỘ PLAYLIST: $selected_playlist${CYAN} │${NC}"
                echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
                echo "$playlist_content" | more
                echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
                read -n 1 -s -r -p "Nhấn bất kỳ phím nào để tiếp tục..."
                ;;
            2)
                if [[ -z "$playlist_content" ]]; then
                    warn "Playlist trống"
                    continue
                fi
                
                local selected_song=$(echo "$playlist_content" | fzf --prompt="Chọn bài hát: " | sed 's/^[0-9]*\. //')
                if [[ -z "$selected_song" ]]; then
                    warn "Không có bài hát nào được chọn"
                    continue
                fi
                
                local song_name=$(echo "$selected_song" | awk -F ' - ' '{print $1}')
                local artist=$(echo "$selected_song" | awk -F ' - ' '{print $2}')
                
                # Tìm kiếm bài hát trên YouTube
                local search_results=$(search_youtube "$selected_song")
                if [[ -z "$search_results" ]]; then
                    warn "Không tìm thấy bài hát trên YouTube"
                    continue
                fi
                
                local selected_result=$(echo "$search_results" | fzf --prompt="Chọn phiên bản: ")
                if [[ -z "$selected_result" ]]; then
                    warn "Không có phiên bản nào được chọn"
                    continue
                fi
                
                local song_url=$(echo "$selected_result" | grep -o '(http[^)]*)' | tr -d '()')
                play_with_mpv "$song_url" "$selected_song"
                add_to_history "$song_name" "$artist"
                ;;
            3)
                if [[ -z "$playlist_content" ]]; then
                    warn "Playlist trống"
                    continue
                fi
                
                local selected_song=$(echo "$playlist_content" | fzf --prompt="Chọn bài hát để xóa: " | sed 's/^[0-9]*\. //')
                if [[ -z "$selected_song" ]]; then
                    warn "Không có bài hát nào được chọn"
                    continue
                fi
                
                local temp_file=$(mktemp)
                grep -v "^$selected_song$" "$playlist_file" > "$temp_file"
                mv "$temp_file" "$playlist_file"
                notify "Đã xóa '$selected_song' khỏi playlist"
                playlist_content=$(show_playlist "$playlist_file")
                ;;
            0)
                return
                ;;
            *)
                warn "Lựa chọn không hợp lệ, vui lòng chọn lại"
                ;;
        esac
    done
}

# Xóa playlist
delete_playlist() {
    local playlists=$(ls "$PLAYLISTS_DIR" | grep ".txt$")
    if [[ -z "$playlists" ]]; then
        warn "Không có playlist nào"
        return
    fi
    
    local selected_playlist=$(echo "$playlists" | fzf --prompt="Chọn playlist để xóa: ")
    if [[ -z "$selected_playlist" ]]; then
        warn "Không có playlist nào được chọn"
        return
    fi
    
    read -r -p "Bạn có chắc chắn muốn xóa playlist '$selected_playlist'? (y/N) " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -f "$PLAYLISTS_DIR/$selected_playlist"
        notify "Đã xóa playlist '$selected_playlist'"
    else
        notify "Hủy xóa playlist"
    fi
}

# Menu cài đặt
settings_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
        echo -e "${CYAN}│               ${MAGENTA}CÀI ĐẶT${CYAN}                     │${NC}"
        echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
        echo -e "${CYAN}│  ${YELLOW}1. Thay đổi thư mục tải xuống${CYAN}             │${NC}"
        echo -e "${CYAN}│  ${YELLOW}2. Thay đổi trình phát mặc định${CYAN}           │${NC}"
        echo -e "${CYAN}│  ${YELLOW}3. Thay đổi chất lượng mặc định${CYAN}           │${NC}"
        echo -e "${CYAN}│  ${YELLOW}4. Thay đổi chủ đề${CYAN}                       │${NC}"
        echo -e "${CYAN}│  ${YELLOW}5. Bật/tắt thông báo${CYAN}                     │${NC}"
        echo -e "${CYAN}│  ${YELLOW}6. Xóa cache${CYAN}                             │${NC}"
        echo -e "${CYAN}│  ${RED}0. Quay lại${CYAN}                                │${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        
        read -r -p "Chọn một tùy chọn: " choice
        
        case $choice in
            1) change_download_dir ;;
            2) change_default_player ;;
            3) change_default_quality ;;
            4) change_theme ;;
            5) toggle_notifications ;;
            6) clear_cache ;;
            0) return ;;
            *) warn "Lựa chọn không hợp lệ, vui lòng chọn lại" ;;
        esac
    done
}

# Thay đổi thư mục tải xuống
change_download_dir() {
    read -r -p "Nhập đường dẫn thư mục tải xuống mới: " new_dir
    if [[ -z "$new_dir" ]]; then
        warn "Đường dẫn không được để trống"
        return
    fi
    
    mkdir -p "$new_dir"
    if [[ ! -d "$new_dir" ]]; then
        error "Không thể tạo thư mục $new_dir"
        return
    fi
    
    sed -i "s|^DOWNLOAD_DIR=.*|DOWNLOAD_DIR=\"$new_dir\"|" "$CONFIG_FILE"
    DOWNLOAD_DIR="$new_dir"
    notify "Đã thay đổi thư mục tải xuống thành: $new_dir"
}

# Thay đổi trình phát mặc định
change_default_player() {
    local players=("mpv" "vlc" "ffplay")
    local selected=$(printf "%s\n" "${players[@]}" | fzf --prompt="Chọn trình phát mặc định: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có trình phát nào được chọn"
        return
    fi
    
    sed -i "s/^DEFAULT_PLAYER=.*/DEFAULT_PLAYER=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_PLAYER="$selected"
    notify "Đã thay đổi trình phát mặc định thành: $selected"
}

# Thay đổi chất lượng mặc định
change_default_quality() {
    local qualities=("low" "medium" "high" "best")
    local selected=$(printf "%s\n" "${qualities[@]}" | fzf --prompt="Chọn chất lượng mặc định: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có chất lượng nào được chọn"
        return
    fi
    
    sed -i "s/^DEFAULT_QUALITY=.*/DEFAULT_QUALITY=\"$selected\"/" "$CONFIG_FILE"
    DEFAULT_QUALITY="$selected"
    notify "Đã thay đổi chất lượng mặc định thành: $selected"
}

# Thay đổi chủ đề
change_theme() {
    local themes=("dark" "light" "blue" "green" "red")
    local selected=$(printf "%s\n" "${themes[@]}" | fzf --prompt="Chọn chủ đề: ")
    
    if [[ -z "$selected" ]]; then
        warn "Không có chủ đề nào được chọn"
        return
    fi
    
    sed -i "s/^THEME=.*/THEME=\"$selected\"/" "$CONFIG_FILE"
    THEME="$selected"
    notify "Đã thay đổi chủ đề thành: $selected"
}

# Bật/tắt thông báo
toggle_notifications() {
    if [[ "$NOTIFICATIONS" == "true" ]]; then
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=false/" "$CONFIG_FILE"
        NOTIFICATIONS="false"
        notify "Đã tắt thông báo"
    else
        sed -i "s/^NOTIFICATIONS=.*/NOTIFICATIONS=true/" "$CONFIG_FILE"
        NOTIFICATIONS="true"
        notify "Đã bật thông báo"
    fi
}

# Xóa cache
clear_cache() {
    rm -rf "$CACHE_DIR"/*
    notify "Đã xóa toàn bộ cache"
}

# Kiểm tra cập nhật
check_for_updates() {
    notify "Đang kiểm tra bản cập nhật..."
    
    if ! curl -Is https://github.com >/dev/null 2>&1; then
        error "Không thể kết nối đến GitHub. Vui lòng kiểm tra kết nối Internet."
        return 1
    fi

    local latest_content=$(curl -s "https://raw.githubusercontent.com/kidtomboy/musisub/main/musisub.sh")
    if [[ -z "$latest_content" ]]; then
        error "Không thể tải nội dung từ GitHub"
        return 1
    fi

    local latest_version=$(echo "$latest_content" | grep -m1 "VERSION=" | cut -d'"' -f2)
    
    if [[ -z "$latest_version" ]]; then
        error "Không thể xác định phiên bản mới nhất"
        return 1
    fi

    if [[ "$latest_version" != "$VERSION" ]]; then
        warn "Đã có bản cập nhật mới!"
        echo -e "${YELLOW}Bản hiện tại: $VERSION"
        echo -e "Bản mới nhất: $latest_version${NC}"
        
        read -p "Bạn có muốn cập nhật không? (Y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_script
        else
            notify "Bạn đã chọn không cập nhật."
        fi
    else
        notify "Bạn đang sử dụng phiên bản mới nhất ($VERSION)"
    fi
}

# Cập nhật script
update_script() {
    notify "Đang cập nhật script..."
    local tmp_file="/tmp/musisub_update.sh"
    
    if curl -s "https://raw.githubusercontent.com/kidtomboy/musisub/main/musisub.sh" -o "$tmp_file"; then
        if grep -q "MUSISUB PRO MAX" "$tmp_file"; then
            chmod +x "$tmp_file"
            mv "$tmp_file" "$0"
            notify "Cập nhật thành công! Vui lòng chạy lại script."
            exit 0
        else
            rm -f "$tmp_file"
            error "File tải về không hợp lệ"
            return 1
        fi
    else
        error "Không thể tải bản cập nhật. Vui lòng thử lại sau."
        return 1
    fi
}

# Hàm chính
main() {
    init_dirs
    check_dependencies
    
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│            ${MAGENTA}MUSISUB v$VERSION${CYAN}              │${NC}"
    echo -e "${CYAN}├──────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│  ${YELLOW}Đang khởi động...${CYAN}                          │${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
    
    log "SYSTEM" "Bắt đầu chương trình MusiSub v$VERSION"
    
    if ! curl -Is https://google.com | grep -q "HTTP/2"; then
        error "Không có kết nối Internet. Vui lòng kiểm tra kết nối của bạn."
        exit 1
    fi
    
    main_menu
}

trap 'log "SYSTEM" "Chương trình bị dừng đột ngột"; exit 1' SIGINT SIGTERM

# Chạy chương trình
main
