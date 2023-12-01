#!/bin/bash
set +x
# set -e

required_python_version="3.6.9"

CHECK_TOOLS_PATH="$HOME/.esp_adf_check_tools"

function die() {
    echo "${1:-"Unknown Error"}" 1>&2
    exit 1
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

function tool_configure() {
    alias check-format="$CHECK_TOOLS_PATH/check_commit_format"

    if [ -n "$BASH_VERSION" ]; then
        CURRENT_SHELL="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        CURRENT_SHELL="$HOME/.zshrc"
    else
        echo "Unsupported shell"
    fi

    # Get python version
    alias python=python3
    python_version=$(python3 --version 2>&1 | awk '/Python/ {print $2}')
    version_compare $python_version $required_python_version
    if [ $? -ne 0 ]; then
        die "Python version needs to be $required_python_version version or above"
    fi
    python_minor_ver=$(python3 -c "import sys; print(str(sys.version_info.major)+'.'+str(sys.version_info.minor))")
    export PYTHONPATH="$HOME/.local/lib/python$python_minor_ver/site-packages:$PYTHONPATH"

    # Check if the line is already present in the shell configuration
    if ! grep -q "export PATH=$CHECK_TOOLS_PATH:\$PATH" "$CURRENT_SHELL"; then
        # Add the line to the shell configuration
        echo "export PATH=$CHECK_TOOLS_PATH:\$PATH" >> "$CURRENT_SHELL"
    fi

    export LD_LIBRARY_PATH=$CHECK_TOOLS_PATH:$LD_LIBRARY_PATH
    source $CURRENT_SHELL
}

tool_configure

if [ -z "$CHECK_REPO_PATH" ]; then
    if [ -n "$ADF_PATH" ]; then
        export CHECK_REPO_PATH=$ADF_PATH
    else
        echo -e "Please run command \033[33mexport CHECK_REPO_PATH=your_repo_path && . ./export.sh\033[0m"
        return 1
    fi
elif [ -e "$CHECK_REPO_PATH" ]; then
    cd $CHECK_REPO_PATH
    export CHECK_REPO_PATH=$(pwd)
    cd -
else
    echo -e "\033[91mPath does not exist.\033[0m"
    return 1;
fi

echo -e "Notes: If you want to use this tool in other repositories, please use the following command to export CHECK_REPO_PATH"
echo -e "       \033[33mexport CHECK_REPO_PATH=your_repo_path && . ./export.sh\033[0m"
echo -e ""
echo -e "All done! You can now run:"
echo -e ""
echo -e "  \033[32mcheck-format --help\033[0m"
echo -e ""
