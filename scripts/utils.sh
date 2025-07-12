#!/bin/bash

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查文件是否存在
file_exists() {
    [ -f "$1" ]
}

# 检查目录是否存在
dir_exists() {
    [ -d "$1" ]
}

# 创建符号链接（安全）
safe_symlink() {
    local src="$1"
    local dest="$2"
    
    if [ -L "$dest" ]; then
        log_warning "符号链接已存在: $dest"
        rm "$dest"
    elif [ -f "$dest" ] || [ -d "$dest" ]; then
        log_warning "备份现有文件: $dest -> $dest.backup"
        mv "$dest" "$dest.backup"
    fi
    
    ln -s "$src" "$dest"
    log_success "创建符号链接: $src -> $dest"
}

# 询问用户确认
ask_confirmation() {
    local message="$1"
    local default="${2:-y}"
    
    if [ "$default" = "y" ]; then
        read -p "$message [Y/n]: " -n 1 -r
    else
        read -p "$message [y/N]: " -n 1 -r
    fi
    
    echo
    
    if [ "$default" = "y" ]; then
        [[ $REPLY =~ ^[Nn]$ ]] && return 1 || return 0
    else
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}