### How to Use Your ~/.bashrc Prompt in Warp
Follow these steps to ensure Warp loads your bash configurations and uses your custom prompt:
 - Set Bash as your startup shell:
 - Open Warp Settings via CMD + , (macOS) or Ctrl + , (Windows/Linux).
 - Navigate to Features > Session > "Startup shell for new sessions".
 - Select bash from the dropdown list. (You may need to update your bash installation and use the custom path if you encounter issues).
---

### Enable the Shell Prompt (PS1) in Appearance Settings:
 - Navigate to Settings > Appearance > Input > Classic > Current prompt.
 - Select the Shell Prompt (PS1) option.
 - Restart Warp or open a new session:
 - The changes will only take effect in new sessions (new windows, tabs, or panes). 
---

## By following these steps, Warp will stop using its native customizable prompt chips and instead render the prompt exactly as defined in your ~/.bashrc file's PS1 variable. 
