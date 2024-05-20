
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
