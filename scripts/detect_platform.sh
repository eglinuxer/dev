#!/bin/bash

# 检测操作系统平台
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian)
                        echo "debian"
                        ;;
                    arch|manjaro)
                        echo "arch"
                        ;;
                    centos|rhel|fedora)
                        echo "redhat"
                        ;;
                    *)
                        echo "linux"
                        ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检测包管理器
detect_package_manager() {
    local os="$1"
    
    case "$os" in
        macos)
            if command_exists brew; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        debian)
            echo "apt"
            ;;
        arch)
            echo "pacman"
            ;;
        redhat)
            if command_exists dnf; then
                echo "dnf"
            elif command_exists yum; then
                echo "yum"
            else
                echo "none"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 检测架构
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 获取系统信息
get_system_info() {
    local os=$(detect_os)
    local pkg_manager=$(detect_package_manager "$os")
    local arch=$(detect_arch)
    
    export DETECTED_OS="$os"
    export DETECTED_PKG_MANAGER="$pkg_manager"
    export DETECTED_ARCH="$arch"
    
    log_info "检测到操作系统: $os"
    log_info "包管理器: $pkg_manager"
    log_info "系统架构: $arch"
}