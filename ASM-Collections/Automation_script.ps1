##############################################################
# F5_Automation_script.ps1
#
#	This script deploys a Service to the F5
#	
#   It will create the LTM configuration as well as
#   the initial ASM Security Policy
#
#	It will read the values of a JSON file, passed
#   as a parameter, and run a Postman through Newman
#   to configure the BIG-IP devices
#
#   Postman Collection: GWL.postman_collection.json
#   Base Environemnt Variables: GWL_BaseLine.postman_environment
#
##############################################################

param(

    [Parameter(Mandatory=$true)]
    [string]
	$username,

[Parameter(Mandatory=$true)]
    [string]
	$password,
    
    [Parameter(Mandatory=$true)]
    [string]
	$ConfigFileName
)

#Script to read from a json file and populate all environment variables for Postman

$AppJSONFile = Get-Content -Raw -Path "D:\OneDrive - Scalar Decisions\Documents\GWL\Automation\$ConfigFileName" | ConvertFrom-Json

#Set VLAN to be Enabled on for the deployment. VLAN will depend on Environment and Business
#LIFECO and PROD = VLAN 920
#LIFECO and UAT = VLAN 926
#FUNDCO and PROD = VLAN 
#FUNDCO and UAT = VLAN 928

$business = $AppJSONFile.F5DeploymentAppInfo.business
$environemnt = $AppJSONFile.F5DeploymentAppInfo.environment

if ($business -eq "LIFECO") {
    
    if ($environemnt -eq "PROD") {
    
        $VLAN = "920"
    
    } elseif ($environemnt -eq "UAT") {
    
        $VLAN = "926"
    
    }

} elseif ($business -eq "FUNDCO") {

    if ($environemnt -eq "PROD") {
        
        $VLAN = "922"
    
    } elseif ($environemnt -eq "UAT") {
    
        $VLAN = "928"

    }
}


#Print information of Service to be Deployed
Write-Host "-----------------------"
Write-Host "SERVICE TO BE DEPLOYED"
Write-Host "-----------------------"
Write-Host "ENVIRONMENT:  " $AppJSONFile.F5DeploymentAppInfo.environment
Write-Host "APP SUITE:    " $AppJSONFile.F5DeploymentAppInfo.app
Write-Host "BUSINESS:     " $AppJSONFile.F5DeploymentAppInfo.business
Write-Host "Description:  " $AppJSONFile.F5DeploymentAppInfo.description
Write-Host "WAF VIP:      " $AppJSONFile.F5DeploymentAppInfo.vs_ip_destination
Write-Host "LB VIP:       " $AppJSONFile.F5DeploymentAppInfo.node_ip
Write-Host "ASM Template: " $AppJSONFile.F5DeploymentAppInfo.asm_template_name
Write-Host "Deploy to:    " $AppJSONFile.F5DeploymentAppInfo.bigip_mgmt
Write-Host "Enabled On:   " "VLAN" $VLAN
Write-Host "-----------------------"

#BaseLine file will be a environment variable file with unique tags as variables name/value to do an easy search/replace
$AppEnvironmentVariables = Get-Content -Raw -Path 'D:\OneDrive - Scalar Decisions\Documents\GWL\Automation\BaseLineFiles\GWL_BaseLine.postman_environment.json'


$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{username}}", $username
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{password}}", $password
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{environment}}", $AppJSONFile.F5DeploymentAppInfo.environment
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{app}}", $AppJSONFile.F5DeploymentAppInfo.app
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{description}}", $AppJSONFile.F5DeploymentAppInfo.description
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{year}}", $AppJSONFile.F5DeploymentAppInfo.year
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{bigip_mgmt}}", $AppJSONFile.F5DeploymentAppInfo.bigip_mgmt
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{certificate_passphrase}}", $AppJSONFile.F5DeploymentAppInfo.certificate_passphrase
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{node_ip}}", $AppJSONFile.F5DeploymentAppInfo.node_ip
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{vs_ip_destination}}", $AppJSONFile.F5DeploymentAppInfo.vs_ip_destination
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{vlanEnabledOn}}", $VLAN
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{asm_template_name}}", $AppJSONFile.F5DeploymentAppInfo.asm_template_name
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{log_local}}", $AppJSONFile.F5DeploymentAppInfo.log_local
$AppEnvironmentVariables = $AppEnvironmentVariables -replace "{{log_remote}}", $AppJSONFile.F5DeploymentAppInfo.log_remote

#Save the AppEnvironmentVariables into a file
$AppEnvironmentVariables |  Set-Content 'D:\OneDrive - Scalar Decisions\Documents\GWL\Automation\BaseLineFiles\GWL_Postman_Variable.json'

#run Newman using the new environment variables
newman.cmd run 'D:\OneDrive - Scalar Decisions\Documents\GWL\Automation\BaseLineFiles\GWL.postman_collection.json' -e 'D:\OneDrive - Scalar Decisions\Documents\GWL\Automation\BaseLineFiles\GWL_Postman_Variable.json' -k