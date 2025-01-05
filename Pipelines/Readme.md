# mdr-cicd-templates

This repository contains CI/CD pipeline templates for the MDR WebApp. These templates are designed to streamline the deployment process and ensure consistent environments across different stages.

## Contents

- `pipelines/`: Contains YAML files for various CI/CD pipelines.
- `templates/`: Includes reusable YAML templates for different pipeline stages.
- `variables/`: Stores variable files used in the pipelines.
- `scripts/`: Contains PowerShell scripts used in the pipeline tasks.

## Pipelines

### MDR-WebApp-MultiRelease-Pipeline-UAT.yaml

This pipeline handles the deployment of the MDR WebApp in the UAT environment. It includes stages for stopping IIS, downloading new artifacts, updating all or specific websites, and restarting IIS.

### Key Parameters

- `environment`: The target environment for deployment.
- `envTags`: Tags to filter the resources in the environment.
- `allWebsites`: Boolean to decide whether to update all websites.
- `websiteList`: List of specific websites to update if `allWebsites` is false.
- `definitionId`: CI pipeline artifact definition ID.
### Description for the MDR-WebApp-MultiRelease-Pipeline-UAT.yaml

## parameters##
it has various parameters which we can pass tthem at the time of triggering the pipeline some of the parameters has default values
if we won't pass any parameters it takes those default values.

## The pipeline has different stages

 ## stage1 --Stop IIS
 
stage: StopIIS 
This stage is used to stop the IIS server if it is in running stage. 
we are using  a template (MDR-WebApp-IISStatus.yaml) to stop the Internet Information Services (IIS) on the target virtual machine or availability set.

This is necessary to safely update the web applications without causing service disruptions or file access conflicts.
"MDR-WebApp-IISStatus.yaml" file contain a job  that is designed to control the IIS service on a virtual machine within
 a specified environment by running a PowerShell script with the appropriate action as an argument. The actual script (IISservicestatus.ps1) is  shown here in the scripts ,  it would contain the logic to start or stop the IIS service based on the argument provided.

## Stage 2 -- Download New Artifact
stage: downloadNewArtifact jobs:
The downloadNewArtifact stage follows, which uses another template (MDR-WebApp-DownloadArtifact.yaml) to download the new artifact specified by the definitionId parameter. 
This artifact contains the updated web application files that need to be deployed.
(MDR-WebApp-DownloadArtifact.yaml) file contains a jobs which includes 3 tasks
      
      1.
      Clean Artifact Folder:
      Task: PowerShell@2
      Runs a PowerShell script (CleanFolder.ps1) to clean the F:\Artifact folder.
      The script is designed to clean out all contents of a given folder path, ensuring the folder is empty.

      
      2.
      Download New Artifact:
      Task: DownloadPipelineArtifact@2
      Downloads the new artifact from a specific build definition (parameters.definitionId) to the pipeline workspace.

      
      3.
      Unzip Artifact:
      Task: ExtractFiles@1
      Unzips the downloaded artifact to the F:\Artifact folder and cleans the destination folder before extraction.
      
 Overall, this job is responsible for preparing the new version of the application for deployment by cleaning the target 
 folder,downloading the latest artifact, and extracting its contents to a specified location on the virtual machine.


## stage 3 -- Relese only 

Update All Websites

Update All Websites Condition: If the allWebsites parameter is set to true, the pipeline proceeds to the ReleaseOnly stage that updates all websites.
It may include a job to retrieve the full list of website names from the apps folder (commented out in the script) and then uses the MDR-WebApp-Release-Template3.yaml template to perform the update.

#Update Specific Websites
Update Specific Websites Condition: If the allWebsites parameter is set to false, the pipeline instead uses the list of specific websites provided in
the websiteList parameter to update only those sites. It uses the same release template as the previous step.

The release only stage uses the  MDR-WebApp-Release-Template3.yaml template which contains the following steps/tasks
1. it involves backing up the existing application inorder to restore the application if the upgradation of application 
   fails.
   
     Backup Old Versions Folder:
     Task: PowerShell@2
     Runs a PowerShell script (backupOldVersionsFolder.ps1) to back up the old version of the folder for the website ${{ 
     websiteName }}.mdr-web-uat.ey.com.


     The provided PowerShell script defines a function copyOldVersionsFolder which backs up the contents of a specified 
     website folder to a backup directory. Here's a detailed description:

        Parameters:
        
        $websiteName: A mandatory string parameter specifying the name of the website folder to back up.
        Function copyOldVersionsFolder:
        
        Accepts the $websiteName parameter.
        Defines the path of the apps directory (F:\Apps).
        Constructs the path for the backup folder as F:\Apps\backUps\<websiteName>_backup.
        Checks if the backup folder exists; if not, it creates the folder.
        Cleans the backup folder by removing all its contents.
        Copies all files from the specified website folder to the backup folder.
        Execution:
        
        Calls the copyOldVersionsFolder function with the $websiteName parameter.
        The script ensures that the backup folder is created and cleaned before copying the website's contents to it, 
        providing a fresh backup each time it's run.

   
  2.Update Version: it updates the application to the latest version

     Steps:
        Checkout: Checks out the repository.
        Save Files and Clean Folder:
        Task: PowerShell@2
        Runs a PowerShell script (saveFilesAndCleanFolder.ps1) to save the config and license files and clean the user's 
        folder for the website ${{ websiteName }}.mdr-web-uat.ey.com.
        
        Move Artifact to User's Folder:
        Task: PowerShell@2
        Runs a PowerShell script (moveArtifactToWebsiteFolder.ps1) to move the downloaded artifact to the user's folder 
        for the website ${{ websiteName }}.mdr-web-uat.ey.com.
  
  ## saveFilesAndCleanFolder.ps1
        The provided PowerShell script defines two functions: SaveFilesInTempFolder and cleanUsersFolder. Here's a 
        detailed description:

          Parameters:
          
          $websiteName: A mandatory string parameter specifying the name of the website folder to process.
          Function SaveFilesInTempFolder:
          
          Accepts the $websiteName parameter.
          Defines the path of the apps directory (F:\Apps).
          Constructs the paths for web.config and license.bin files within the specified website folder.
          Checks if these files exist and logs messages accordingly.
          Defines a temporary folder path within the website folder.
          Creates the temporary folder if it doesn't exist.
          Copies the web.config and license.bin files to the temporary folder, logging success or error messages.
          Function cleanUsersFolder:

          Accepts the $websiteName parameter.
          Defines the path of the website folder and the temporary folder within it.
          Checks if the website folder exists.
          Removes all items in the website folder except for the temporary folder, logging success or error messages.
          Execution:
          
          Calls the SaveFilesInTempFolder function with the $websiteName parameter.
          Calls the cleanUsersFolder function with the $websiteName parameter.
          This script ensures that the web.config and license.bin files are saved in a temporary folder before cleaning 
          out the contents of the website folder, except for the temporary folder.

   ## moveArtifactToWebsiteFolder.ps1

        The provided PowerShell script defines two functions: moveArtifactToUsersFolder and restoreFilesInTempFolder. 
         Here's a detailed description:
        
        Parameters:
        
        $websiteName: A mandatory string parameter specifying the name of the website folder to process.
        Function moveArtifactToUsersFolder:
        
        Accepts the $websiteName parameter.
        Defines the source path (F:\Artifact) and the destination path (F:\Apps\$websiteName).
        Checks if the source path exists.
        If the source path exists, it copies all items from the source path to the destination path, logging a success 
        message.
        If the source path does not exist, it logs an error message.
        Function restoreFilesInTempFolder:
        
        Accepts the $websiteName parameter.
        Defines the path of the temporary folder within the website folder (F:\Apps\$websiteName\tempFolder).
        Checks if the temporary folder exists.
        If the temporary folder exists:
        Moves license.bin from the temporary folder to the original license path (F:\Apps\$websiteName\bin), logging 
        success or error messages.
        Moves web.config from the temporary folder to the original config path (F:\Apps\$websiteName), logging success or 
        error messages.
        
        If the temporary folder does not exist, it logs a warning message.
        Checks if the temporary folder is empty.
        If the temporary folder is empty, it removes the folder and logs a message.
        If the temporary folder is not empty, it logs a message.
        Execution:
        
        Calls the moveArtifactToUsersFolder function with the $websiteName parameter.
        Calls the restoreFilesInTempFolder function with the $websiteName parameter.
        The script is designed to move artifacts to a user's folder and restore specific files from a temporary folder, 
        ensuring the temporary folder is empty and removed if necessary.
  
  3.
      Restore Old Version from Backup:
      Task: PowerShell@2
      Runs a PowerShell script (restoreOldVersion.ps1) to restore the old version from backup if there was an error in the 
      update for the website ${{ websiteName }}.mdr-web-uat.ey.com.      

    ## restoreOldVersion.ps1
    
    The provided PowerShell script defines a function restoreOldVersion which restores the old version of a website from a 
    backup. Here's a detailed description:

      Parameters:
      
      $websiteName: A mandatory string parameter specifying the name of the website folder to restore.
      Function restoreOldVersion:
      
      Accepts the $websiteName parameter.
      Defines the path of the apps directory (F:\Apps).
      Constructs the source path for the backup folder and the destination path for the website folder.
      Checks if the destination folder exists:
      If it exists, it removes all items in the destination folder to prepare for the restoration.
      Logs a success or error message based on the existence of the destination folder.
      Checks if the source path (backup folder) exists:
      If it exists, it copies all items from the source path to the destination path, logging a success message.
      If the source path does not exist, it logs an error message.
      Execution:
      
      Calls the restoreOldVersion function with the $websiteName parameter.
      The script ensures that the current website folder is cleaned before restoring the old version from the backup 
      folder.

      Overall, this job sequence ensures that each website in the list is backed up before updating, updated with the new        version, and, if necessary, restored to the old version in case of an update failure. The PowerShell scripts         
      referenced in the tasks are responsible for the actual file operations on the virtual machine.     


## stage4 -- Start IIS

 Start IIS Stage: The final stage, StartIIS, is set to always run regardless of the success or failure of previous stages. 
 It uses the MDR-WebApp-IISStatus.yaml template again,
 but this time to start IIS services back up after the updates are complete.
