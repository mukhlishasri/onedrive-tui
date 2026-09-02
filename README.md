# OneDrive TUI

A terminal user interface (TUI) wrapper for the [abraunegg/onedrive](https://github.com/abraunegg/onedrive) client, built using `whiptail`. This script provides a simple, menu-driven way to manage your OneDrive synchronization, edit configurations, and control the background monitor service without needing to memorize CLI flags.

## Prerequisites

Before using this script, ensure you have the following installed on your system:

1. **`whiptail`**: Used for rendering the TUI.
   ```bash
   sudo apt install whiptail
   ```
2. **`abraunegg/onedrive` client**: The actual backend client that handles synchronization. Follow the instructions on their [GitHub page](https://github.com/abraunegg/onedrive) to install it for your specific distribution.

## Usage

1. Make the script executable:
   ```bash
   chmod +x onedrive-tui.sh
   ```
2. Run the script:
   ```bash
   ./onedrive-tui.sh
   ```

## Features

When you launch the script, you will be presented with a main menu containing the following options:

### 1. Synchronize Now
Triggers a standard synchronization (`onedrive --sync`). This will upload and download changes between your local machine and OneDrive based on your configuration.

### 2. Full Resync (Rebuild Database)
Performs a full resync (`onedrive --resync --sync`). This deletes the local state database and rebuilds it from the current online state. **Use this only when necessary**, such as after changing your `sync_dir` or modifying your `sync_list`.

### 3. View Sync Status
Displays the current synchronization status (`onedrive --display-sync-status`) in a scrollable text box, helping you identify any pending changes or errors.

### 4. View Configuration
Shows your current active OneDrive client configuration (`onedrive --display-config`).

### 5. Edit Configuration
Provides an interactive menu to safely modify your `~/.config/onedrive/config` file. You can easily set or remove options such as:
- `sync_dir`: Your local synchronization directory.
- `skip_file` / `skip_dir`: Patterns for files or directories to ignore.
- Monitor intervals and logging frequencies.
- Sync behaviors like `download_only`, `upload_only`, and `local_first`.

### 6. Manage Sync List
Opens your `~/.config/onedrive/sync_list` file in your default editor (or `nano`). This file allows you to specify exactly which directories or files to include or exclude from syncing.

### 7-10. Background Monitor Management
These options allow you to manage the `onedrive` systemd user service (`systemctl --user ... onedrive`):
- **Start Background Monitor**: Starts continuous background syncing.
- **Stop Background Monitor**: Stops the background service.
- **Check Background Monitor Status**: Displays whether the service is currently running or stopped.
- **View Monitor Logs**: Follows the live logs (`journalctl`) of the background service. Press `q` to exit.

### 11. Authenticate / Re-Authenticate
Starts the interactive authentication process (`onedrive --reauth`). Use this if you are logging in for the first time or if your authentication token has expired.

## Troubleshooting

- **"whiptail is not installed"**: Install `whiptail` using your package manager (e.g., `apt install whiptail`).
- **"OneDrive client not found"**: Ensure the `abraunegg/onedrive` client is installed and accessible in your `$PATH`.
- **Background Monitor fails to start**: Make sure you have enabled user lingering or that your system supports systemd user services. You can check the logs using Option 10 to debug further.
