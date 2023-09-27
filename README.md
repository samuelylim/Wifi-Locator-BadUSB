# Wifi-Locator-BadUSB
Tracks laptops using nearby wifi signals. Also allows for remote code execution. Injected via BadUSB

# How to use
1. Edit the variables in primary.ps1 to reflect your output url (where requests get sent to) and your input url (where your remote code is read from)

2. Edit get_loc.txt to include links to your autostart.bat file and your primary.ps1 file

3. Update remotecode.txt whenever you want to execute new remote code
* The first line is a timestamp. The code will execute if the timestamp is greater than the current time.
* The second line is the code that gets executed.

4. Load get_loc.txt onto your Bad USB
