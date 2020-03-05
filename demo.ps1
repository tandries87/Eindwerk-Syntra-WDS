$secpasswd = ConvertTo-SecureString 'Tweakers4725' -AsPlainText -Force
$Safepass = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
$secpasswd = ConvertTo-SecureString 'Tweakers4725' -AsPlainText -Force
$localuser = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
 
configuration dscconfig
{ 
     param
    ( 
        [string[]]$NodeName ='localhost', 
        [Parameter(Mandatory)][string]$MachineName, 
        [Parameter(Mandatory)][string]$DomainName,
        [Parameter()]$firstDomainAdmin,
        [Parameter()][string]$UserName,
        [Parameter()]$Safepass,
        [Parameter()]$Password,
        [Parameter(Mandatory)]   
        [ValidateNotNullOrEmpty()]   
        [String]$StartPageURL  
    ) 
        

   Import-DscResource –ModuleName PSDesiredStateConfiguration
   Import-DscResource –ModuleName xDhcpServer
   Import-DscResource -ModuleName xActiveDirectory
   Import-DscResource -Module xNetworking 
   Import-DscResource -ModuleName xsmbshare
   Import-DscResource -Module xComputerManagement
   Import-DscResource -ModuleName xPendingReboot, xDnsServer, xComputerManagement, NetworkingDsc
   Import-DSCResource -ModuleName xInternetExplorerHomePage 

   
    Node $NodeName
    { 
          xComputer NewNameAndWorkgroup 
        { 
            Name          = $MachineName
            
        
  
        }
        LocalConfigurationManager
        {

            RefreshMode = 'Push'
            RebootNodeIfNeeded = $True
            RefreshFrequencyMins = 30
            ConfigurationMode = 'ApplyAndAutoCorrect'

        }
        xIPAddress newipaddress 
        {
         InterfaceAlias = 'Ethernet1'
         IPAddress = '192.168.123.170/24'
         AddressFamily = 'IPV4'
        }
        xDefaultGatewayAddress DefaultGateway
        {
         Address = '192.168.123.2'
         InterfaceAlias = 'Ethernet1'
         AddressFamily = 'IPV4'
        }
        xDnsServerAddress DnsServerAddress
        {
         Address = '127.0.0.1'
         InterfaceAlias = 'Ethernet1'
         AddressFamily = 'IPV4'
         Validate = $true
        }         
       

        WindowsFeature ADDSInstall 
        { 
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
            
        }
         
        WindowsFeature RSATTools 
        { 
            DependsOn= '[WindowsFeature]ADDSInstall'
            Ensure = 'Present'
            Name = 'RSAT-AD-Tools'
            IncludeAllSubFeature = $true
            
        }  
 
        xADDomain SetupDomain 
        {
            DomainAdministratorCredential= $firstDomainAdmin
            DomainName= $DomainName
            SafemodeAdministratorPassword= $Safepass
            DependsOn='[WindowsFeature]RSATTools'
            DomainNetbiosName = $DomainName.Split('.')[0]
            
        }
        WindowsFeature dhcp-server {

            Name = 'DHCP'

            Ensure = 'Present'
            DependsOn= '[xADDomain]SetupDomain'

        }

        WindowsFeature dhcp-server-tools {

            DependsON = '[WindowsFeature]dhcp-server'

            Name = 'RSAT-DHCP'

            Ensure = 'present'
            

         }
        xDhcpServerScope Scope {

            Ensure = 'present'

            Name = 'PowerShellScope'

            ScopeID = '192.168.123.0'

            IPStartRange = '192.168.123.80'

            IPEndRange = '192.168.123.100'

            SubnetMask = '255.255.255.0'

            LeaseDuration = '00:08:00'

            State = 'Active'

            AddressFamily = 'IPv4'
            DependsOn= '[xADDomain]SetupDomain'

          }

        xDhcpServerOption option {
            Ensure = 'Present'
            DnsDomain = 'maeyerdc10.maeyer.int'
            router = '192.168.123.2'
            ScopeID = '192.168.123.0'
            DnsServerIPAddress = '192.168.123.170','8.8.8.8'
            AddressFamily = 'IPv4'
            DependsOn= '[xADDomain]SetupDomain' 
          }

        xDhcpServerAuthorization authorization
          {
            Ensure = 'present'
            DnsName = 'maeyerdc10.maeyer.int'
            IPAddress = '192.168.123.170'
            DependsOn= '[xADDomain]SetupDomain'
          }
        WindowsFeature dnsserver
	      {
  	        Ensure = "Present"
  	 
   	        Name = "dns" 
            DependsOn= '[xDhcpServerOption]option'
	      }
        xDnsServerForwarder SetForwarders
          {
            IsSingleInstance = 'Yes'
            IPAddresses = '8.8.8.8','1.1.1.1'
            UseRootHint = $false
            DependsOn= '[xDhcpServerOption]option'
          }
        File HR
        {
            DestinationPath = 'C:\shares\HR'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        File Marketing
        {
            DestinationPath = 'C:\shares\Marketing'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        File Productie
        {
            DestinationPath = 'C:\shares\Productie'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        File Onderzoek
        {
            DestinationPath = 'C:\shares\Onderzoek'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        File Logistiek
        {
            DestinationPath = 'C:\shares\Logistiek'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        File web
        {
            DestinationPath = 'c:\inetpub\wwwroot\web'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]dnsserver'
        }
        xSMBShare HR
        {
            Name = 'HR'
            Path = 'C:\shares\HR'
            FullAccess = 'administrator'
            ReadAccess = 'maeyer.int\maeyerdc10$'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]HR'
        }
        xSMBShare Marketing
        {
            Name = 'Marketing'
            Path = 'C:\shares\Marketing'
            FullAccess = 'administrator'
            ReadAccess = 'maeyer.int\maeyerdc10$'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Marketing'
        }
        xSMBShare Productie
        {
            Name = 'Productie'
            Path = 'C:\shares\productie'
            FullAccess = 'administrator'
            ReadAccess = 'maeyer.int\maeyerdc10$'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Productie'
        }
        xSMBShare Onderzoek
        {
            Name = 'Onderzoek'
            Path = 'C:\shares\Onderzoek'
            FullAccess = 'administrator'
            ReadAccess = 'maeyer.int\maeyerdc10$'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Onderzoek'
        }
        xSMBShare Logistiek
        {
            Name = 'Logistiek'
            Path = 'C:\shares\Logistiek'
            FullAccess = 'administrator'
            ReadAccess = 'maeyer.int\maeyerdc10$'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Logistiek'
         }
               
          WindowsFeature WebServer {
          Ensure = "Present"
          Name   = "Web-Server"
          dependson= '[xADDomain]SetupDomain'
          
        }

          File WebsiteContent {
          Ensure = 'Present'
          SourcePath = 'C:\Users\Roel2\index.htm'
          DestinationPath = 'C:\inetpub\wwwroot\'
          DependsOn='[WindowsFeature]WebServer'
        } 
          xInternetExplorerHomePage IEHomePage 
        { 
          StartPage = $StartPageURL 
          Ensure = 'present'
          DependsOn='[WindowsFeature]WebServer'
        } 
         Firewall EnableBuiltInFirewallRule
        {
          Name                  = 'IIS-WebServerRole-HTTP-In-TCP'
          Ensure                = 'Present'
          Enabled               = 'True'
          DependsOn             ='[file]websitecontent'
        } 
    } 
}

 

$configData = @{
                AllNodes = @(
                              @{
                                 NodeName = 'localhost';
                                 DebugMode            = "ForceModuleImport"
                                 CertificateId        = $node.thumbprint
                                 ActionAfterReboot    = 'ContinueConfiguration'
                                 AllowModuleOverwrite = $true
                                 RebootNodeIfNeeded   = $true
                                 PSDscAllowPlainTextPassword = $true
                                    }
                    )
               }
 
dscconfig -MachineName MAEYERDC10 -DomainName maeyer.int -StartPageURL "http://maeyerdc10" -Password $localuser -OutputPath:"C:\Users\dsc\dscconfig" `
    -UserName 'Roel2' -Safepass $Safepass `
    -firstDomainAdmin (Get-Credential -UserName 'Roel2' -Message 'geen wachtwoord voor de eerste domainadmin') -ConfigurationData $configData 


Set-DscLocalConfigurationManager 'C:\Users\dsc\dscconfig' -Verbose


Start-dscconfiguration –path 'C:\Users\dsc\dscconfig' –wait -verbose -Force
