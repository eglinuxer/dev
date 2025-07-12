#!/bin/bash

# 包名映射 - 处理不同平台包名差异
map_package_name() {
    local package="$1"
    
    case "$DETECTED_PKG_MANAGER" in
        apt)
            case "$package" in
                fd) echo "fd-find" ;;
                bat) echo "batcat" ;;
                eza) echo "exa" ;;  # Ubuntu 20.04 及更早版本
                *) echo "$package" ;;
            esac
            ;;
        pacman)
            case "$package" in
                python3) echo "python" ;;
                *) echo "$package" ;;
            esac
            ;;
        dnf|yum)
            case "$package" in
                fd) echo "fd-find" ;;
                eza) echo "exa" ;;
                *) echo "$package" ;;
            esac
            ;;
        brew)
            case "$package" in
                nodejs) echo "node" ;;
                *) echo "$package" ;;
            esac
            ;;
        *)
            echo "$package"
            ;;
    esac
}

# 安装 Homebrew (macOS)
install_homebrew() {
    if ! command_exists brew; then
        log_info "安装 Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # 添加到 PATH
        if [[ "$DETECTED_ARCH" == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log_success "Homebrew 安装完成"
    else
        log_info "Homebrew 已安装"
    fi
}

# 更新包管理器
update_package_manager() {
    case "$DETECTED_PKG_MANAGER" in
        brew)
            log_info "更新 Homebrew..."
            brew update
            ;;
        apt)
            log_info "更新 APT 包列表..."
            sudo apt update
            ;;
        pacman)
            log_info "更新 Pacman 包列表..."
            sudo pacman -Sy
            ;;
        dnf)
            log_info "更新 DNF 包列表..."
            sudo dnf check-update
            ;;
        yum)
            log_info "更新 YUM 包列表..."
            sudo yum check-update
            ;;
    esac
}

# 获取包的替代名称
get_package_alternatives() {
    local package="$1"
    
    case "$package" in
        eza)
            echo "exa"
            ;;
        bat)
            if [ "$DETECTED_PKG_MANAGER" = "apt" ]; then
                echo "batcat"
            fi
            ;;
        nodejs)
            if [ "$DETECTED_PKG_MANAGER" = "brew" ]; then
                echo "node"
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# 安装包（带重试机制）
install_package_with_retry() {
    local original_package="$1"
    local package="$(map_package_name "$original_package")"
    
    # 首先尝试安装映射后的包名
    if install_package "$package"; then
        return 0
    fi
    
    # 如果失败，尝试替代包名
    local alternative=$(get_package_alternatives "$original_package")
    if [ -n "$alternative" ]; then
        log_warning "尝试替代包: $alternative"
        alternative="$(map_package_name "$alternative")"
        install_package "$alternative"
    else
        return 1
    fi
}

# 检测包是否已安装
is_package_installed() {
    local package="$(map_package_name "$1")"
    
    case "$DETECTED_PKG_MANAGER" in
        brew)
            brew list --formula "$package" >/dev/null 2>&1
            ;;
        apt)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"
            ;;
        pacman)
            pacman -Q "$package" >/dev/null 2>&1
            ;;
        dnf)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        yum)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# 更新包
upgrade_package() {
    local package="$(map_package_name "$1")"
    
    case "$DETECTED_PKG_MANAGER" in
        brew)
            brew upgrade "$package"
            ;;
        apt)
            sudo apt install --only-upgrade -y "$package"
            ;;
        pacman)
            # pacman -S 会自动更新到最新版本
            sudo pacman -S --noconfirm "$package"
            ;;
        dnf)
            sudo dnf upgrade -y "$package"
            ;;
        yum)
            sudo yum update -y "$package"
            ;;
        *)
            log_error "不支持的包管理器: $DETECTED_PKG_MANAGER"
            return 1
            ;;
    esac
}

# 安装包
install_package() {
    local package="$(map_package_name "$1")"
    
    case "$DETECTED_PKG_MANAGER" in
        brew)
            brew install "$package"
            ;;
        apt)
            sudo apt install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        *)
            log_error "不支持的包管理器: $DETECTED_PKG_MANAGER"
            return 1
            ;;
    esac
}

# 从文件安装包列表
install_packages_from_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        log_warning "包列表文件不存在: $file"
        return 1
    fi
    
    log_info "从文件安装包: $file"
    
    while IFS= read -r package; do
        # 跳过空行和注释
        [[ -z "$package" || "$package" =~ ^#.*$ ]] && continue
        
        if is_package_installed "$package"; then
            log_info "更新: $package (已安装)"
            if ! upgrade_package "$package"; then
                log_error "更新失败: $package"
            else
                log_success "更新成功: $package"
            fi
        else
            log_info "安装: $package"
            if ! install_package_with_retry "$package"; then
                log_error "安装失败: $package"
            else
                log_success "安装成功: $package"
            fi
        fi
    done < "$file"
}

# 安装常用工具
install_common_tools() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local packages_dir="$script_dir/../packages"
    
    # 安装 Homebrew (仅 macOS)
    if [ "$DETECTED_OS" = "macos" ]; then
        install_homebrew
    fi
    
    # 更新包管理器
    update_package_manager
    
    # 安装通用包
    local common_file="$packages_dir/common.txt"
    if [ -f "$common_file" ]; then
        install_packages_from_file "$common_file"
    fi
    
    # 安装平台特定包
    local platform_file="$packages_dir/$DETECTED_OS.txt"
    if [ -f "$platform_file" ]; then
        install_packages_from_file "$platform_file"
    fi
}