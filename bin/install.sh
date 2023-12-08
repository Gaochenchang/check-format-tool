#!/bin/bash
set +x
# set +e

required_python_version="3.6.9"
required_xz_version="5.2.2"
required_libtinfo5_version="6.1"

OS_TAG=""
CHECK_TOOLS_PATH="$HOME/.esp_adf_check_tools"
XZ_URL="https://tukaani.org/xz/xz-$required_xz_version.tar.gz"

function detect_os() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_TAG="$ID"
        LLVM_LIST="/etc/apt/sources.list.d/llvm.list"
        grep -qxF 'deb http://apt.llvm.org/focal/ llvm-toolchain-focal main' "$LLVM_LIST" || \
        echo 'deb http://apt.llvm.org/focal/ llvm-toolchain-focal main' | sudo tee -a "$LLVM_LIST"
        grep -qxF 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main' "$LLVM_LIST" || \
        echo 'deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main' | sudo tee -a "$LLVM_LIST"
        wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
        sudo apt-get update
    else
        os_type=$(uname)
        if [ "$os_type" == "Darwin" ]; then
            OS_TAG="macos"
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

function update_shell_profile() {
    local CURRENT_SHELL="$1"

    if [ -f "$CURRENT_SHELL" ]; then
        # Check if the line is already present in the shell configuration
        if grep -q "export CHECK_TOOLS_PATH=" "$CURRENT_SHELL"; then
            # Line exists, replace the value after '=' with the new path
            sed -i "s|export CHECK_TOOLS_PATH=.*|export CHECK_TOOLS_PATH=$CHECK_TOOLS_PATH|" "$CURRENT_SHELL"
        else
            echo "export CHECK_TOOLS_PATH=$CHECK_TOOLS_PATH" >> "$CURRENT_SHELL"
        fi
    else
        echo -e "\033[33mWarning: $CURRENT_SHELL does not exist.\033[0m"
    fi
}

function install_requirements() {
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
    check_and_install_tool "clang-format"; clang-format --version
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

    update_shell_profile $HOME/.bashrc
    update_shell_profile $HOME/.zshrc
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
