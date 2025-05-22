# Powershell-Script-MSQL-Autobackup-to-NAS


MSQL Auto backup script - Created by CelyMe (GitHub) https://github.com/CelyMe

Paired with "Task Scheduler", you can have this powershell script backup the Microsoft SQL server's databases automatically to a NAS. 
<hr>


The purpose of this project to save Microsoft SQL Databases to a NAS that is not part of the domain; overcoming a permission restriction issue. The goal is to first save the backups locally, where the computer/server have "LOCAL SERVICE" permissions to a folder (eg. C:\), then copies or moves the backup file (.BAK) to a NAS. It does this by first finding out all the databases stored on the server (you can choose which databases you would like to skip) and then exporting a backup file, one database at a time. After each database export, the script will move (or copy) the backup file from the local computer/server to the NAS location in a date-based directory structure to make it easier to locate a specific backup. 
<hr>

<b>STEP 1:</b>  Determine if you want to save the .BAK files locally in addition to a NAS directory; if this is the case, a date-based directory structure will apply to the local directory and the NAS directory. Otherwise, you can save the backups to a temp folder on your server/PC and have the .BAK files MOVE to the NAS.

<b>STEP 2:</b>Ensure the variable `$SaveBackupsLocally` reflect the action you would like the script to make, as determined in STEP 1.

<b>STEP 3:</b>  Setup the correct file permissions for the local backup location; create a folder(s) on your local device (eg. C:\DB_Backups\Backups) and give "LOCAL SERVICE" Full Control over the folder. This will allow the script (Backup-SqlDatabase) commands to save the database backup file to the location without access issues. 

<b>STEP 4:</b> Ensure the variable `$Local_basePath` reflects the folder location you have set permissions for in STEP 3. 

<b>STEP 5:</b> Ensure your server/computer have access (saved credentials) and permissions to the NAS and the backup desination folder. 

<b>STEP 6:</b>  Ensure the variable `$NAS_basePath` reflects the folder location you have set permissions for, in STEP 5. 

<b>STEP 7:</b>  Insert the database server name (`$serverName`) and the database credentials (`$username` and `$password`)  
