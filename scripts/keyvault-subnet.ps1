# PowerShell Script to Add Service Point Enabled AzureAppGatewaySubnet to Core Key Vault

param (
    [string]$applicationGatewaySubnetName,
    [string]$keyVaultResourceGroupName,
    [string]$virtualNetworkName,
    [string]$coreSubscriptionId,
    [string]$resourceGroupName,
    [string]$subscriptionId,
    [string]$keyVaultName
)

Set-AzContext -Subscription $subscriptionId

$virtualNetwork = (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroup $resourceGroupName)
$subnets = (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroup $resourceGroupName).Subnets
$subnets = $virtualNetwork.Subnets.Name
$subnetName = $applicationGatewaySubnetName
$subnetIndex = $subnets.IndexOf($subnetName)
$subnetResourceId = (Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroup $resourceGroupName).Subnets[$subnetIndex].id

Set-AzContext -Subscription $coreSubscriptionId

Add-AzKeyVaultNetworkRule -VaultName $keyVaultName -ResourceGroupName $keyVaultResourceGroupName -VirtualNetworkResourceId $subnetResourceId -PassThru