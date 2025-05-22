########################################################################################################################

#SQL Auto backup script

#Created by CelyMe (GitHub) https://github.com/CelyMe

########################################################################################################################

#The purpose of this project to save Microsoft SQL Databases to a NAS that is not part of the domain; overcoming a permission restriction issue. The goal is to first save the backups locally, where the computer/server have "LOCAL SERVICE" permissions to a folder (eg. C:\), then copies or moves the backup file (.BAK) to a NAS. It does this by first finding out all the databases stored on the server (you can choose which databases you would like to skip) and then exporting a backup file, one database at a time. After each database export, the script will move (or copy) the backup file from the local computer/server to the NAS location in a date-based directory structure to make it easier to locate a specific backup. 


#STEP 1:  Determine if you want to save the .BAK files locally in addition to a NAS directory; if this is the case, a date-based directory structure will apply to the local directory and the NAS directory. Otherwise, you can save the backups to a temp folder on your server/PC and have the .BAK files MOVE to the NAS.

#STEP 2:  Ensure the variable `$SaveBackupsLocally` reflect the action you would like the script to make, as determined in STEP 1.

#STEP 3:  Setup the correct file permissions for the local backup location; create a folder(s) on your local device (eg. C:\DB_Backups\Backups) and give "LOCAL SERVICE" Full Control over the folder. This will allow the script (Backup-SqlDatabase) commands to save the database backup file to the location without access issues. 

#STEP 4:  Ensure the variable `$Local_basePath` reflects the folder location you have set permissions for in STEP 3. 

#STEP 5:  Ensure your server/computer have access (saved credentials) and permissions to the NAS and the backup desination folder. 

#STEP 6:  Ensure the variable `$NAS_basePath` reflects the folder location you have set permissions for, in STEP 5. 

#STEP 7:  Insert the database server name (`$serverName`) and the database credentials (`$username` and `$password`)  


########################################################################################################################
#  Variables that requires editing. 
########################################################################################################################

$SaveBackupsLocally = $false 
#True (Save locally and to NAS) = Backups the databases in a nested folder structure (2025\May\12) to local C:\ drive and COPIES DB to NAS
#False (Save to temp location then move to NAS) = Backups the database into a temp folder on the C:\ drive and MOVES the DB to NAS. 



#DB Server Name
$serverName = "NAME_OF_SERVER_HOSTING_MSQL"

#DB Credentials
$username = "MSQL_USERNAME"
$password = "MSQL_PASSWORD"

#Local folder path for both Locally saved backups and temp backups. 
$localDirectoryPath = "C:\DB_Backups\Backups" 

#NAS Storage backup location
$NAS_basePath = "\\slide-storage\Backups\Database\Backups ($servername)"


########################################################################################################################
#  Folder(s) creation
########################################################################################################################

#Time/Date for folder and file name structure
$getCurrentDate = Get-Date
$currentYear = $getCurrentDate.Year
$currentMonth = $getCurrentDate.ToString("MMMM")
$currentDate = $getCurrentDate.ToString("dd-MM-yyyy")
$timestamp = Get-Date -Format "dd-MM-yyyy_HHmmss"



if($SaveBackupsLocally)
{
$DB_ExportLocation = Join-Path -Path $localDirectoryPath -ChildPath "$currentYear\$currentMonth\$currentDate\\" #true = Create an organised folder structure by date.
}
else
{
$DB_ExportLocation = "$localDirectoryPath\Temp_Backups"  #false = Backup to a simple temp folder  
}
Write-Host $DB_ExportLocation

$NASBackupSaveLocation = Join-Path -Path "$NAS_basePath" -ChildPath "$currentYear\$currentMonth\$currentDate\\"

Write-Host $NASBackupSaveLocation
 cd "C:/" #Just to ensure we are not in a SQL command console. 


#Create date directories 
if (!(Test-Path -Path $DB_ExportLocation)) {
    New-Item -ItemType Directory -Path $DB_ExportLocation
}

if (!(Test-Path -Path $NASBackupSaveLocation)) {
    New-Item -ItemType Directory -Path $NASBackupSaveLocation
}


########################################################################################################################
#  Database name retrieval 
########################################################################################################################


try {
    $passwordConvert = ConvertTo-SecureString $password -AsPlainText -Force
    $databases = Invoke-Sqlcmd -ServerInstance $serverName -Username $username -Password $password -Query "SELECT name FROM sys.databases WHERE name NOT IN ('master','model', 'msdb', 'tempdb', 'rdsadmin', 'Practice')" #Add the databases you do not want to backup; currently skipping over System databases. 
    foreach ($db in $databases) {
        Write-Output "Database Name: $($db.name)" #Prints a list of all the Databases found.
    }
}
catch {
    Write-Error "Failed to retrieve databases: $_"
    exit 1
}

########################################################################################################################
#  Exporting each database backup from MSQL server and copying/moving to NAS location
########################################################################################################################


try {
$credential = New-Object System.Management.Automation.PSCredential ($username, $passwordConvert)
foreach ($db in $databases){
        $exportFileName = "$($db.name)'_$serverName'_($timestamp).bak" 
        Backup-SqlDatabase -ServerInstance $serverName -Database $($db.name) -Credential $credential -BackupFile "$DB_ExportLocation\$exportFileName" -Verbose
         cd "C:/" #This is to break out of the SQLSERVER console after using the "Backup-SqlDatabase" command. 

        if ($SaveBackupsLocally){
                #$DBfileSize = "{0:N2} GB" -f ((Get-Item $directoryLocation).Length / 1GB)       
                #Copy-Item -Path $directoryLocation -Destination $NASBackupSaveLocation
                robocopy $DB_ExportLocation $NASBackupSaveLocation "$exportFileName" /Z /R:3 /W:5 
        }
        else{
                #$DBfileSize = "{0:N2} GB" -f ((Get-Item $directoryLocation).Length / 1GB)       
                #Move-Item -Path $directoryLocation -Destination $NASBackupSaveLocation 
                robocopy $DB_ExportLocation $NASBackupSaveLocation $exportFileName /MOV /R:3 /W:5              
        }       
    }
    Write-Output "Backup completed."
    exit 0
}
catch {
    Write-Output "An error occurred: $_"
    exit 1
}
