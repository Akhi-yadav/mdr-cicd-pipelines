This Document includes 
## User Guide to run the pipeline
## Explanation of the pipeline

# User Guide to run the pipeline
 Name of the pipenine-- MDR-WebApp-NewClients-UAT
 
 link to acess the pipeline https://dev.azure.com/TransferPricingGlobal/MDR%20Web%20App%20Development/_build? 
 definitionId=181&_a=summary
This pipeline is designed to create the SSL Certificate, DNS Mapping, SQL Database and to configure the application gateway,
these four things are the prerequisites to install the new clients for the MDR Application.

  To run this pipeline we need to pass these parameters while running it.
  1.  Name of the Website: 
   -- Here we can pass the multiple names at a time as a list (These are the actual client names)
  2.  Target VM or Availability set:
   -- We can pass either availability set or The virtual machine name , so that the Client will be installed  in these 
      availabilty set or VM.
  3. CI pipeline (Artifact):
     -- Here we need to pass the Build pipeline name , to download the artifact from this pipeline
  4. AppGw Backend Pool: Pass the Backendpool of the application gateway

 As it is multi stage pipeline we can select the required stage to run for example:
 if we need to create only the ssl certificate we can select only this stage to run and create ssl certificate from the 
 ansible tower


## Explanation of the pipeline
   ## Contents
    pipelines/: Contains YAML files for various CI/CD pipelines.
    templates/: Includes reusable YAML templates for different pipeline stages.
    variables/: Stores variable files used in the pipelines.
    scripts/: Contains PowerShell scripts used in the pipeline tasks.

The pipeline is designed to handle multiple stages, including SSL certificate provisioning, SQL database setup, DNS configuration, and Application Gateway setup.

The pipeline is divided into the following stages:

    1. **SSL**: Provisions SSL certificates for the specified web applications.
    2. **SQLDATABASE**: Sets up SQL databases for the web applications.
    3. **DNS**: Configures DNS settings for the web applications.
    4. **AAG (Application Gateway)**: Configures the Application Gateway with the necessary backend pool for the web applications.
  In each stage the the pipeline is referring to the templates and powershell scripts to execute the required jobs
1. ## SSL CERTIFICATE Creation- Template
    In this stage  we are using 3 Tasks 
    1. Check If SSL certificate exists:  This task check for the ssl certificate in the keyvault, if certificate exists it won't procced 
      for the next steps. it stops the excution of job and complete the execution. else it moves to next step for the creation of the
      certificate.
    2. Get Ansible Tower credentials: This task depends on the previous task , if the previous task condition is false then this task
        retrives the Ansible tower credientials from the key vault and passes these credientials as a parameters to login to the
        Ansible tower.
    3. Create SSL certificate using Building Block: This task depends on the Check If SSL certificate exists task , if Check If SSL certificate exists
        condition is false then only  it starts creation of the SSL certificate using the Ansible tower using the building block templates

 2. ## DNS Creation Template
    In this stage we are using 3 tasks 
    1. Check If DNS Exists: This task helps in determining whether a DNS record for the specified website already exists or needs to be created.
       if the Dns record doesn't exists it moves to the next steps i.e for the creation of DNS record using Ansible tower.
    2. Get Ansible Tower credentials: This task depends on the previous task , if the previous task condition is false then this task
        retrives the Ansible tower credientials from the key vault and passes these credientials as a parameters to login to the
        Ansible tower.
    3.Creation of DNS Record: This task depends on the Check If DNS Exists task , if Check If DNS Exists exists condition 
     is false then only  it starts creation of DNS Record  using the Ansible tower using the building block templates

 3. ## SQL DATABASE Template
    In this stage we are using 3 tasks 
    1. Check If SQL DATABASE Exists: This task helps in determining whether a SQL DATABSE for the specified website already 
       exists or needs to be created.if the SQL DATABASE doesn't exists it moves to the next steps i.e for the creation of 
       SQL DATABASE using Ansible tower.
    2. Get Ansible Tower credentials: This task depends on the previous task , if the previous task condition is false then 
      this taskretrives the Ansible tower credientials from the key vault and passes these credientials as a parameters to 
      login to theAnsible tower.
    3.Creation of SQL DATABASE: This task depends on the Check If SQL DATABASE Exists task , if Check If SQL DATABASE 
       Exists exists condition is false then only  it starts creation of SQL DATABASE using the Ansible tower using the 
       building block templates

 4. ## APP GATEWAY Configuration
   In this stage it configures  the following configuration
      1. listener
      2. Backenedsetting
      3. Rules
      4. Health Probes
  If these configurations doesn't exists in the Gateway. If exists it throws a message saying  all these configurations already exists

    
## Important Notes

- The `SSL` stage must complete successfully before the `AAG` stage begins.
- The `SQLDATABASE` and `DNS` stages do not have dependencies and can run independently.
- Ensure that the templates referenced in the pipeline exist in the specified relative paths.
- Customize the `websiteList` and other parameters according to your deployment needs.

## Security

Do not commit sensitive information to your repository. Always use Azure Key Vault or Azure DevOps secure files to manage secrets and credentials.
