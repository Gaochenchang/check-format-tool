#!/bin/bash
set +x
set +e

required_python_version="3.6.9"
required_xz_version="5.2.2"
required_libtinfo5_version="6.1"

OS_TAG=""
CHECK_TOOLS_PATH="$HOME/.esp_adf_check_tools"
XZ_URL="https://tukaani.org/xz/xz-$required_xz_version.tar.gz"
CLANG_FORMAT_16_URL="https://github.com/muttleyxd/clang-tools-static-binaries/releases/download/master-f4f85437/clang-format-16_linux-amd64"

function detect_os() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_TAG="$ID"
        CLANG_FORMAT_16_URL="https://github.com/muttleyxd/clang-tools-static-binaries/releases/download/master-f4f85437/clang-format-16_linux-amd64"
        sudo apt-get update
    else
        os_type=$(uname)
        if [ "$os_type" == "Darwin" ]; then
            OS_TAG="macos"
            CLANG_FORMAT_16_URL="https://github.com/muttleyxd/clang-tools-static-binaries/releases/download/master-f4f85437/clang-format-16_macosx-amd64"
        else
            OS_TAG="windows"
        fi
    fi
}

function die() {
    echo "${1:-"Unknown Error"}" 1>&2
    exit 1
}

# Function to check and install a command-line tool
function check_and_install_tool() {
    local tool_name="$1"
    local tool_version="$2"

    if ! command -v "$tool_name" &>/dev/null; then
        echo "$tool_name $tool_version version is not installed. Installing $tool_name..."
        if [[ "$OS_TAG" == "macos" ]]; then
            brew install "$tool_name"  # macOS (Homebrew)
        elif [[ "$OS_TAG" == "ubuntu" ]]; then
            sudo apt-get install -y "$tool_name"  # Debian/Ubuntu Linux
        else
            die "Unsupported package manager or operating system."
        fi
    else
        echo "$tool_name is already installed."
    fi
}

function version_compare() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        return 1
    fi

    if dpkg --compare-versions "$1" lt "$2"; then
        return 1
    else
        return 0
    fi
}

function install_requirements() {
    if [ -n "$BASH_VERSION" ]; then
        CURRENT_SHELL="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        CURRENT_SHELL="$HOME/.zshrc"
    else
        echo "Unsupported shell"
    fi

    # Get python version
    python_version=$(python3 --version 2>&1 | awk '/Python/ {print $2}')
    version_compare $python_version $required_python_version
    if [ $? -ne 0 ]; then
        die "Python version needs to be $required_python_version version or above"
    fi
    python_minor_ver=$(python3 -c "import sys; print(str(sys.version_info.major)+'.'+str(sys.version_info.minor))")
    export PYTHONPATH="$HOME/.local/lib/python$python_minor_ver/site-packages:$PYTHONPATH"

    check_and_install_tool "wget"
    check_and_install_tool "pip3"
    check_and_install_tool "dpkg"
    python3 -m pip install -r "$SCRIPT_PATH/requirements.txt"

    libtinfo5_version=$(dpkg -l | grep 'libtinfo5' | awk '{print $3}')
    version_compare "$libtinfo5_version" "$required_libtinfo5_version"
    if [ $? -ne 0 ]; then
        check_and_install_tool "libtinfo5"
    fi

    xz_version=$(xz --version | grep -oP 'xz \(XZ Utils\) \K\d+\.\d+\.\d+')
    version_compare "$xz_version" "$required_xz_version"
    if [ $? -ne 0 ]; then
        echo "Installing xz-utils version $required_xz_version"
        FILE_NAME=$(basename $XZ_URL)
        if [ ! -f "$FILE_NAME" ]; then
            wget $XZ_URL
            tar xvf $FILE_NAME
        fi
        cd xz-$required_xz_version
        ./configure
        make
        sudo make install
        cd -
    fi

    FILE_NAME="clang-format"
    if ! command -v $FILE_NAME &>/dev/null || [[ "$($FILE_NAME --version | head -n 1)" != *"16.0"* ]]; then
        if [ ! -f "$FILE_NAME" ]; then
            wget -O $FILE_NAME $CLANG_FORMAT_16_URL
        fi
        chmod +x $FILE_NAME
    fi
    $FILE_NAME --version
}

detect_os

export SCRIPT_PATH="$(cd "$(dirname ${BASH_SOURCE[0]:-$0})" && pwd)"
echo "script path: $SCRIPT_PATH"
mkdir -p "$CHECK_TOOLS_PATH"
cp -r "$SCRIPT_PATH"/* "$CHECK_TOOLS_PATH/"

dirs -c
pushd "$CHECK_TOOLS_PATH"
install_requirements
popd
dirs -c

echo ""
echo "Installation done! You can now run:"
echo ""
echo "  . ./export.sh"
echo ""
