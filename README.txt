 ____     __  __  _____   ____     _____      
/\  _`\  /\ \/\ \/\  __`\/\  _`\  /\  __`\    
\ \ \/\_\\ \ \_\ \ \ \/\ \ \ \/\_\\ \ \/\ \   
 \ \ \/_/_\ \  _  \ \ \ \ \ \ \/_/_\ \ \ \ \  
  \ \ \L\ \\ \ \ \ \ \ \_\ \ \ \L\ \\ \ \_\ \ 
   \ \____/ \ \_\ \_\ \_____\ \____/ \ \_____\
    \/___/   \/_/\/_/\/_____/\/___/   \/_____/


This repository contains a PowerShell script and a batch launcher to install or upgrade Chocolatey (https://chocolatey.org/), a popular Windows package manager. Optionally, it can install the Chocolatey GUI.

---

Contents

- choco_install_internal.ps1 — Main PowerShell script for installation and upgrade.  
- install.bat — Batch file to easily launch the PowerShell script with the correct execution policy.  
- README.md — This documentation.

---

Requirements

- Windows operating system  
- PowerShell (Windows PowerShell or PowerShell Core)  
- Internet connection to download Chocolatey  
- Administrator privileges (script auto-elevates if needed)

---

How to use

1. Run install.bat by double-clicking it.  
2. The script checks if Chocolatey is installed and shows the version if found.  
3. You’ll be asked to confirm installation or upgrade (enter ‘Y’ for yes).  
4. Internet connection is tested; without it, the script exits.  
5. Optionally, you can choose to install the Chocolatey GUI as well (enter ‘Y’ for yes).  
6. After installation:  
   - If GUI is installed, it launches automatically and the script window closes shortly after.  
   - If CLI only, the PowerShell window stays open so you can use Chocolatey commands directly.

---

Important notes

- Administrator rights are required; the script requests elevation automatically.  
- No internet means installation won’t proceed.  
- After GUI install, the script exits to avoid blocking the GUI window.  
- CLI-only install leaves the window open for immediate use.

---

Troubleshooting

- Check your network and firewall if no internet connection is detected.  
- If errors occur, rerun the script and note any error messages.  
- For official manual installation instructions, see the official Chocolatey Installation Guide: https://chocolatey.org/install

---

Error Reference

Error message:                                        Meaning:                                      Suggested action:

"This script requires Administrator rights.         Script is not running with admin privileges. Wait for elevation prompt or restart
Restarting as Administrator..."                     Script restarts elevated automatically.         script as administrator.

"Error: No internet connection or unable to         No internet or URL unreachable.               Check network and firewall, then retry.
reach Chocolatey URL."

"Installation failed due to unexpected error."      Unknown error during installation.            Retry, check error details and prerequisites.

"Chocolatey is already up-to-date or installation   No new version installed, install may have    Verify installed version or retry if unsure.
failed."                                             failed or already latest.

"Error installing or starting Chocolatey GUI:       GUI installation or launch failed.             Check error message and GUI dependencies.
[message]"

"Installation cancelled."                            User aborted installation.                     Restart script if you want to install later.

---

License

This project is licensed under the MIT License. See LICENSE file for details.

---

Legal Disclaimer

- Chocolatey and Chocolatey GUI are trademarks and products of their respective owners. 
This repository contains only a third-party installer script created independently to automate the installation or upgrade of Chocolatey and optionally its GUI.
- This script is not affiliated with or endorsed by Chocolatey Software, Inc. or any of its partners.
- This script is intended mainly for private use only. The author does not take any responsibility for security, data loss, or any damages caused by using this script.
- Use this script at your own risk. The author takes no responsibility for any damage or issues caused by running this script.
- For official Chocolatey licensing and installation information, please refer to the Chocolatey License: https://github.com/chocolatey/choco/blob/master/LICENSE.txt  
  and the official Chocolatey Installation Guide: https://chocolatey.org/install

---

Contributing

Issues and pull requests to improve this installer are welcome.

---

Note: This is one of my first scripts and it’s probably not great, but it’s good enough for my personal use case. Sorry for that.


---

Created by DozyLynx


