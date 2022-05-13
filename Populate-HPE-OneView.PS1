#
# Function Declarations
#
function ConfigureAppliance {
    Param ( [Parameter(Mandatory=$True)] [string]$vm_ipaddr,
            [Parameter(Mandatory=$True)] [string]$vm_password,
            [Parameter(Mandatory=$True)] [string]$vm_hostname
    )

    # Accept the EULA
    if (Get-OVEulaStatus -appliance $vm_ipaddr) {
        Write-Output $vm_ipaddr "Accepting EULA..."
        $ret = Set-OVEulaStatus -supportAccess "yes" -appliance $vm_ipaddr
    }

    # For initial setup, connect first using "default" Administrator credentials
    try {
        $password = ConvertTo-SecureString "admin" -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential('Administrator',$password)
        $ret = Connect-OVMgmt -appliance $vm_ipaddr -Credential $credential
    } catch [ HPEOneView.Appliance.PasswordChangeRequired ] {
        $ret = Set-OVInitialPassword -oldPassword "admin" -newPassword "$vm_password" -Appliance $vm_ipaddr
    }
    $password = ConvertTo-SecureString $vm_password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('Administrator',$password)
    $ret = Connect-OVMgmt -appliance $vm_ipaddr -Credential $credential

    #
    # Update the networking configuration.
    # Key assumption here is that DHCP address we received initially will not change.
    $task = Set-OVApplianceNetworkConfig -hostname $vm_hostname -ipv4type "DHCP" -ipv6type "UNCONFIGURE"
    Disconnect-OVMgmt
}

function ImportSANManager {
    Add-OVSanManager -Type Cisco -Hostname 172.18.20.1 -SnmpAuthLevel AuthOnly -SnmpUserName dcs-MD5 -SnmpAuthPassword dcsdcsdcs -SnmpAuthProtocol md5 | Wait-OVTaskComplete
}

function CreateNetworks {
    # Create the FC networks
    New-OVNetwork -name "SAN FC A" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "VSAN11"
    New-OVNetwork -name "SAN FC B" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "VSAN11"
}

function ImportStorageArray {
    $password = ConvertTo-SecureString 'dcs' -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('dcs',$password)
    $myArrayDCSName = "ThreePAR-1"
    $myArrayDomain = "TestDomain"
    $myArrayPools = [System.Array]("FST_CPG1", "FST_CPG2")
    $myArray = "172.18.11.11"
    Write-Host "Importing storage array: $myArray"
    $task = New-OVStorageSystem -hostname $myArray -Credential $credential -Domain $myArrayDomain
    $task | Wait-OVTaskComplete -timeout (New-TimeSpan -Minutes 15)
    for ($i=0; $i -lt $myArrayPools.Length; $i++) {
        Get-OVStoragePool -Name $myArrayPools[$i] -ErrorAction Stop | Set-OVStoragePool -Managed $true | Wait-OVTaskComplete
    }
}

function AddServers {
    $password = ConvertTo-SecureString 'dcs' -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential('dcs',$password)
    Add-OVServer -hostname 172.18.31.11 -Credential $credential -LicensingIntent OneView
    Add-OVServer -hostname 172.18.31.12 -Credential $credential -LicensingIntent OneView
    Add-OVServer -hostname 172.18.31.13 -Credential $credential -LicensingIntent OneView
    Add-OVServer -hostname 172.18.31.4 -Credential $credential -LicensingIntent OneView
    Add-OVServer -hostname 172.18.31.7 -Credential $credential -LicensingIntent OneView
}

#
# Main Program
#
Remove-Module -ErrorAction SilentlyContinue HPOneView.400
Remove-Module -ErrorAction SilentlyContinue HPOneView.410
Remove-Module -ErrorAction SilentlyContinue HPOneView.420
Remove-Module -ErrorAction SilentlyContinue HPOneView.500
Remove-Module -ErrorAction SilentlyContinue HPOneView.520
Remove-Module -ErrorAction SilentlyContinue HPEOneView.530
Remove-Module -ErrorAction SilentlyContinue HPEOneView.540
Remove-Module -ErrorAction SilentlyContinue HPEOneView.550
Remove-Module -ErrorAction SilentlyContinue HPEOneView.600
Remove-Module -ErrorAction SilentlyContinue HPEOneView.610
Remove-Module -ErrorAction SilentlyContinue HPEOneView.620
if (-not (Get-Module HPEOneView.630))
{
    Import-Module -Name HPEOneView.630
}

$ip_addr  = "<DHCP IP Address assigned to DCS appliance>"
$password = "<New Administrator Password>"
$hostname = "<Hostname associated with DHCP IP Address of the DCS appliance>"

#
# Accept the EULA and configure the Administrator credentials
#
ConfigureAppliance $ip_addr "$password" "$hostname"
$credpassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('Administrator',$credpassword)
Connect-OVMgmt -Hostname $ip_addr -Credential $credential -ErrorAction Stop

#
# Configure virtual resources
#
ImportSanManager
CreateNetworks
ImportStorageArray
AddServers

#
# Clear any remaining alerts and disconnect from OneView
#
Get-OVAlert -AlertState Active | Set-OVAlert -Cleared
Disconnect-OVMgmt