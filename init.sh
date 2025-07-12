#!/bin/bash

set -e  # 遇到错误立即退出

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 导入工具函数
source "$SCRIPT_DIR/scripts/utils.sh"
source "$SCRIPT_DIR/scripts/detect_platform.sh"

# 主函数
main() {
    log_info "开始初始化开发环境..."
    
    # 检测系统信息
    get_system_info
    
    # 检查是否支持当前系统
    if [ "$DETECTED_OS" = "unknown" ] || [ "$DETECTED_PKG_MANAGER" = "unknown" ]; then
        log_error "不支持的操作系统或包管理器"
        exit 1
    fi
    
    # 导入安装脚本
    source "$SCRIPT_DIR/scripts/install_packages.sh"
    
    # 安装基础工具
    if ask_confirmation "是否安装基础开发工具？"; then
        install_common_tools
    fi
    
    # 设置 tmux
    if ask_confirmation "是否配置 tmux？"; then
        if [ -f "$SCRIPT_DIR/scripts/setup_tmux.sh" ]; then
            source "$SCRIPT_DIR/scripts/setup_tmux.sh"
            setup_tmux
        else
            log_warning "tmux 配置脚本不存在，跳过"
        fi
    fi
    
    # 设置 neovim
    if ask_confirmation "是否配置 neovim？"; then
        if [ -f "$SCRIPT_DIR/scripts/setup_neovim.sh" ]; then
            source "$SCRIPT_DIR/scripts/setup_neovim.sh"
            setup_neovim
        else
            log_warning "neovim 配置脚本不存在，跳过"
        fi
    fi
    
    # 设置 shell 配置
    if ask_confirmation "是否配置 shell 环境？"; then
        if [ -f "$SCRIPT_DIR/scripts/setup_shell.sh" ]; then
            source "$SCRIPT_DIR/scripts/setup_shell.sh"
            setup_shell
        else
            log_warning "shell 配置脚本不存在，跳过"
        fi
    fi
    
    log_success "开发环境初始化完成！"
    log_info "请重新打开终端或执行 'source ~/.zshrc' (或 ~/.bashrc) 使配置生效"
}

# 显示帮助信息
show_help() {
    cat << EOF
开发环境初始化脚本

用法: $0 [选项]

选项:
    -h, --help      显示此帮助信息
    --packages-only 仅安装软件包，不进行配置
    --config-only   仅进行配置，不安装软件包
    --tmux-only     仅配置 tmux
    --nvim-only     仅配置 neovim
    --shell-only    仅配置 shell

示例:
    $0                  # 完整初始化
    $0 --packages-only  # 仅安装软件包
    $0 --tmux-only      # 仅配置 tmux

支持的系统:
    - macOS (使用 Homebrew)
    - Ubuntu/Debian (使用 apt)
    - Arch Linux (使用 pacman)
    - CentOS/RHEL/Fedora (使用 dnf/yum)

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --packages-only)
                PACKAGES_ONLY=true
                shift
                ;;
            --config-only)
                CONFIG_ONLY=true
                shift
                ;;
            --tmux-only)
                TMUX_ONLY=true
                shift
                ;;
            --nvim-only)
                NVIM_ONLY=true
                shift
                ;;
            --shell-only)
                SHELL_ONLY=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 根据参数执行相应功能
run_with_args() {
    get_system_info
    source "$SCRIPT_DIR/scripts/install_packages.sh"
    
    if [ "$PACKAGES_ONLY" = true ]; then
        install_common_tools
        return
    fi
    
    if [ "$CONFIG_ONLY" = true ]; then
        # 跳过包安装，仅进行配置
        :
    elif [ -z "$TMUX_ONLY" ] && [ -z "$NVIM_ONLY" ] && [ -z "$SHELL_ONLY" ]; then
        # 默认安装包
        install_common_tools
    fi
    
    # 执行特定配置
    if [ "$TMUX_ONLY" = true ]; then
        [ -f "$SCRIPT_DIR/scripts/setup_tmux.sh" ] && source "$SCRIPT_DIR/scripts/setup_tmux.sh" && setup_tmux
    elif [ "$NVIM_ONLY" = true ]; then
        [ -f "$SCRIPT_DIR/scripts/setup_neovim.sh" ] && source "$SCRIPT_DIR/scripts/setup_neovim.sh" && setup_neovim
    elif [ "$SHELL_ONLY" = true ]; then
        [ -f "$SCRIPT_DIR/scripts/setup_shell.sh" ] && source "$SCRIPT_DIR/scripts/setup_shell.sh" && setup_shell
    elif [ "$CONFIG_ONLY" = true ]; then
        # 执行所有配置
        [ -f "$SCRIPT_DIR/scripts/setup_tmux.sh" ] && source "$SCRIPT_DIR/scripts/setup_tmux.sh" && setup_tmux
        [ -f "$SCRIPT_DIR/scripts/setup_neovim.sh" ] && source "$SCRIPT_DIR/scripts/setup_neovim.sh" && setup_neovim
        [ -f "$SCRIPT_DIR/scripts/setup_shell.sh" ] && source "$SCRIPT_DIR/scripts/setup_shell.sh" && setup_shell
    fi
}

# 主程序入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_args "$@"
    
    if [ $# -gt 0 ]; then
        run_with_args
    else
        main
    fi
fi
