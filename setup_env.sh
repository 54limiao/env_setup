#!/bin/bash

# Exit on error
set -e

# Check if running as root (sudo)
if [[ $EUID -eq 0 ]]; then
    echo "Error: This script must not be run as root. Run it as a regular user with 'bash setup_environment.sh'."
    exit 1
fi

# Function to detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Linux"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to check network connectivity to GitHub
check_network() {
    echo "Checking connectivity to GitHub for Homebrew..."
    if ! curl -I --connect-timeout 5 https://github.com &> /dev/null; then
        echo "Warning: Cannot reach GitHub. Installation may be slow or fail. Consider using a VPN or checking your network."
    else
        echo "GitHub is accessible."
    fi
}

# Function to check and prompt for Xcode Command Line Tools (macOS only)
check_xcode_clt() {
    if [[ "$OS" == "macOS" ]] && ! xcode-select -p &> /dev/null; then
        echo "Xcode Command Line Tools are not installed. Installing them now..."
        xcode-select --install
        echo "Please follow the prompts to install Xcode Command Line Tools, then rerun this script."
        exit 1
    fi
}

# Function to install Homebrew
install_brew() {
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH
        if [[ "$OS" == "macOS" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ "$OS" == "Linux" ]]; then
            echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
        # Update Homebrew to ensure repositories are set up
        brew update
    else
        echo "Homebrew already installed"
    fi
}

# Function to install Miniconda
install_miniconda() {
    if ! command -v conda &> /dev/null; then
        echo "Installing Miniconda..."
        if [[ "$OS" == "macOS" ]]; then
            MINICONDA_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        else
            MINICONDA_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        fi
        
        curl -L "$MINICONDA_URL" -o miniconda.sh
        bash miniconda.sh -b -p $HOME/miniconda
        rm miniconda.sh
        
        $HOME/miniconda/bin/conda init
    else
        echo "Miniconda already installed"
    fi
}

# Function to configure pip to use Tsinghua mirror
configure_pip_mirror() {
    echo "Configuring pip to use Tsinghua mirror..."
    PIP_CONFIG_DIR="$HOME/.pip"
    PIP_CONFIG_FILE="$PIP_CONFIG_DIR/pip.conf"
    
    # Check and fix permissions for ~/.pip directory
    if [[ -d "$PIP_CONFIG_DIR" ]] && ! [[ -w "$PIP_CONFIG_DIR" ]]; then
        echo "Fixing permissions for $PIP_CONFIG_DIR..."
        chmod -R u+w "$PIP_CONFIG_DIR"
        if [[ $? -ne 0 ]]; then
            echo "Error: Cannot fix permissions for $PIP_CONFIG_DIR. Try running 'sudo chown -R $(whoami) $PIP_CONFIG_DIR' and rerun the script."
            exit 1
        fi
    fi
    
    mkdir -p "$PIP_CONFIG_DIR"
    cat > "$PIP_CONFIG_FILE" << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to write to $PIP_CONFIG_FILE. Check permissions and try again."
        exit 1
    fi
}

# Function to install packages via Homebrew
install_packages() {
    echo "Installing Helix, Fish, and Tmux..."
    brew install helix fish tmux
}

# Function to configure Helix
configure_helix() {
    echo "Configuring Helix..."
    HELIX_CONFIG_DIR="$HOME/.config/helix"
    mkdir -p "$HELIX_CONFIG_DIR/themes"
    
    # Write config.toml directly
    cat > "$HELIX_CONFIG_DIR/config.toml" << 'EOF'
# Helix Configuration File

# Theme settings
theme = "dark_plus_transparent"

# Editor settings
[editor]
line-number = "relative"  # Show relative line numbers for easier navigation
bufferline = "multiple"   # Display multiple buffer tabs

# Cursor appearance
[editor.cursor-shape]
insert = "bar"            # Use a thin bar cursor in insert mode

# Keybindings for normal mode
[keys.normal]
esc = ["collapse_selection", "keep_primary_selection"]  # Clear selection but keep primary
C-e = ["scroll_down", "move_line_down"]                # Scroll and move cursor down
C-y = ["scroll_up", "move_line_up"]                    # Scroll and move cursor up

# Keybindings for insert mode
[keys.insert]
j = { k = "normal_mode" }  # Exit insert mode with 'jk'
EOF

    # Write dark_plus_transparent.toml directly
    cat > "$HELIX_CONFIG_DIR/themes/dark_plus_transparent.toml" << 'EOF'
# Dark Plus Transparent Theme
inherits = "dark_plus"
"ui.background" = {}
EOF
}

# Main execution
OS=$(detect_os)
echo "Detected OS: $OS"

check_network
check_xcode_clt
install_brew
install_miniconda
# configure_pip_mirror
install_packages
configure_helix

echo "Setup complete! Please restart your terminal or source your shell configuration file."
echo "To use Fish shell, run 'fish' or set it as your default shell with 'chsh -s $(which fish)'"
