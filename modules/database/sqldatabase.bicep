param tags object

param location string
param CAFPrefix string
param nameSeparator string
param administratorLoginPassword string
param administratorLogin string

var sqlServerName = '${CAFPrefix}${nameSeparator}db-servername'
var databaseName = '${CAFPrefix}${nameSeparator}db'
var edition = 'Basic'
var computeSize = 'Basic'

param maxSizeBytes string = '2147483648' // 2 GB

// SQL Server
resource sqlServer 'Microsoft.Sql/servers@2022-11-01' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

// SQL Server Firewall Rule (Allow Azure services to access)
resource allowAzureServices 'Microsoft.Sql/servers/firewallRules@2022-11-01' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// SQL Database
resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-11-01' = {
  name: databaseName
  location: location
  sku: {
    name: computeSize
    tier: edition
  }
  properties: {
    maxSizeBytes: maxSizeBytes
  }
}
