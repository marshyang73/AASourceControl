param(    
    [Parameter(Mandatory = $false)] 
    [String] $ResourceGroupName
)

#====================START OF CONNECTION SETUP=======================
$connectionName = "AzureRunAsConnection"
$SubId = Get-AutomationVariable -Name 'AzureSubscriptionId'
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
    "Setting context to a specific subscription"  
    Set-AzureRmContext -SubscriptionId $SubId             
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
#====================END OF CONNECTION SETUP=======================

# If there is a specific resource group, then get all VMs in the resource group,
# otherwise get all VMs in the subscription.
if ($ResourceGroupName) { 
    Write-Output "Resource Group specified: $($ResourceGroupName)"
    $VMs = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
}
else { 
    Write-Output "No Resource Group specified"
    $VMs = Get-AzureRmVM
}

foreach ($VM in $VMs) {
    try {
        Write-Output "Starting VM: $($VM.Name)"
        $VM | Start-AzureRmVM -ErrorAction Stop
        Write-Output ($VM.Name + " has been started")
    }
    catch {
        Write-Output ($VM.Name + " failed to start")
    }
} 
