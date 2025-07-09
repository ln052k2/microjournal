#!/bin/bash
set -e

INSTALL_DIR="$HOME/.local/bin"

detect_shell_rc() {
    case "$SHELL" in
        */bash) echo "$HOME/.bashrc" ;;
        */zsh)  echo "$HOME/.zshrc" ;;
        */fish) echo "$HOME/.config/fish/config.fish" ;;
        *)      echo "$HOME/.profile" ;;
    esac
}

add_path() {
    local rc_file
    rc_file=$(detect_shell_rc)
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        {
            echo ""
            echo "# Added by cmd.sh on $(date)"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        } >> "$rc_file"
        echo "Added $INSTALL_DIR to PATH in $rc_file"
        echo "Run: source \"$rc_file\" or restart your terminal"
    fi
}

remove_path() {
    local rc_file
    rc_file=$(detect_shell_rc)
    sed -i '/# Added by cmd.sh/,/export PATH="\$HOME\/.local\/bin:\$PATH"/d' "$rc_file"
    echo "Removed $INSTALL_DIR from PATH in $rc_file (if added by this script)"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ----------------------------
# INSTALL
# ----------------------------
if [[ "$1" == "install" ]]; then
    if [ "$#" -ne 3 ]; then
        echo "Error: Missing command name or source file."
        echo "Usage: ./cmd.sh install <command_name> <source_file>"
        exit 1
    fi

    # Parse arguments
    COMMAND_NAME="$2"
    SOURCE_FILE="$3"
    EXT="${SOURCE_FILE##*.}"
    TARGET="$INSTALL_DIR/$COMMAND_NAME"

    if [ ! -f "$SOURCE_FILE" ]; then
        echo "Error: Source file '$SOURCE_FILE' does not exist."
        exit 1
    fi

    mkdir -p "$INSTALL_DIR"

    # Check file extension
    case "$EXT" in
        c)
            if ! command_exists gcc; then
                echo "Error: gcc compiler not found."
                exit 1
            fi
            gcc "$SOURCE_FILE" -o "$TARGET"
            ;;
        cpp|cc|cxx)
            if ! command_exists g++; then
                echo "Error: g++ compiler not found."
                exit 1
            fi
            g++ "$SOURCE_FILE" -o "$TARGET"
            ;;
        py)
            if ! head -n 1 "$SOURCE_FILE" | grep -q "^#\!"; then
                echo "Warning: Python script has no shebang line."
            fi
            chmod +x "$SOURCE_FILE"
            if command_exists realpath; then
                SRC_PATH=$(realpath "$SOURCE_FILE")
            elif command_exists readlink; then
                SRC_PATH=$(readlink -f "$SOURCE_FILE" 2>/dev/null || echo "$SOURCE_FILE")
            else
                SRC_PATH="$SOURCE_FILE"
            fi
            ln -sf "$SRC_PATH" "$TARGET"
            ;;
        *)
            echo "Unsupported file type: '$EXT'"
            echo "Only .c, .cpp, .py are supported"
            exit 1
            ;;
    esac

    chmod +x "$TARGET"
    echo "Installed '$COMMAND_NAME' to $TARGET"
    add_path
    exit 0
fi

# ----------------------------
# UNINSTALL
# ----------------------------
if [[ "$1" == "uninstall" ]]; then
    if [ -z "$2" ]; then
        echo "Error: Missing command name."
        echo "Usage: ./cmd.sh uninstall <command_name>"
        exit 1
    fi

    # Parse arguments
    COMMAND_NAME="$2"
    TARGET="$INSTALL_DIR/$COMMAND_NAME"

    if [ -f "$TARGET" ]; then
        rm "$TARGET"
        echo "Removed $TARGET"
    else
        echo "Warning: $TARGET not found"
    fi

    remove_path
    exit 0
fi

# ----------------------------
# DEFAULT HELP
# ----------------------------
echo "Usage:"
echo "  ./cmd.sh install <command_name> <source_file.{c,cpp,py}>"
echo "  ./cmd.sh uninstall <command_name>"
exit 1