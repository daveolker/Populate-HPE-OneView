#
# Function Declarations
#
function ConfigureAppliance {
    Param ( [Parameter(Mandatory=$True)] [string]$vm_ipaddr,
            [Parameter(Mandatory=$True)] [string]$vm_password,
            [Parameter(Mandatory=$True)] [string]$vm_hostname
    )

    # Accept the EULA
    if (Get-HPOVEulaStatus -appliance $vm_ipaddr) {
        Write-Output $vm_ipaddr "Accepting EULA..."
        $ret = Set-HPOVEulaStatus -supportAccess "yes" -appliance $vm_ipaddr
    }

    # For initial setup, connect first using "default" Administrator credentials
    try {
        $ret = Connect-HPOVMgmt -appliance $vm_ipaddr -user "Administrator" -password "admin"
    } catch [ HPOneView.Appliance.PasswordChangeRequired ] {
        $ret = Set-HPOVInitialPassword -oldPassword "admin" -newPassword "$vm_password" -Appliance $vm_ipaddr
    }
    $ret = Connect-HPOVMgmt -appliance $vm_ipaddr -user Administrator -password "$vm_password"

    #
    # Update the networking configuration.
    # Key assumption here is that DHCP address we received initially will not change.
    $task = Set-HPOVApplianceNetworkConfig -hostname $vm_hostname -ipv4type "DHCP" -ipv6type "UNCONFIGURE"
    Disconnect-HPOVMgmt
}

function ImportSANManager {
    Add-HPOVSanManager  -type BNA -hostname "172.18.15.1" -username dcs -password dcs -usessl
}

function CreateNetworks {
    # Create the Ethernet networks
    New-HPOVNetwork -name "corpnet A"       -type "Ethernet" -vlanId 10     -smartlink $true
    New-HPOVNetwork -name "corpnet B"       -type "Ethernet" -vlanId 10     -smartlink $true
    New-HPOVNetwork -name "ESXi mgmt A"     -type "Ethernet" -vlanId 1131   -smartlink $true
    New-HPOVNetwork -name "ESXi vmotion A"  -type "Ethernet" -vlanId 1132   -smartlink $true
    New-HPOVNetwork -name "ESXi mgmt B"     -type "Ethernet" -vlanId 1131   -smartlink $true
    New-HPOVNetwork -name "ESXi vmotion B"  -type "Ethernet" -vlanId 1132   -smartlink $true
    New-HPOVNetwork -name "prod vm1 A"      -type "Ethernet" -vlanId 1101   -smartlink $true
    New-HPOVNetwork -name "prod vm2 A"      -type "Ethernet" -vlanId 1102   -smartlink $true
    New-HPOVNetwork -name "prod vm3 A"      -type "Ethernet" -vlanId 1103   -smartlink $true
    New-HPOVNetwork -name "prod vm4 A"      -type "Ethernet" -vlanId 1104   -smartlink $true
    New-HPOVNetwork -name "prod vm1 B"      -type "Ethernet" -vlanId 1101   -smartlink $true
    New-HPOVNetwork -name "prod vm2 B"      -type "Ethernet" -vlanId 1102   -smartlink $true
    New-HPOVNetwork -name "prod vm3 B"      -type "Ethernet" -vlanId 1103   -smartlink $true
    New-HPOVNetwork -name "prod vm4 B"      -type "Ethernet" -vlanId 1104   -smartlink $true
    New-HPOVNetwork -name "test vm1 A"      -type "Ethernet" -vlanId 1111   -smartlink $true
    New-HPOVNetwork -name "test vm2 A"      -type "Ethernet" -vlanId 1112   -smartlink $true
    New-HPOVNetwork -name "test vm3 A"      -type "Ethernet" -vlanId 1113   -smartlink $true
    New-HPOVNetwork -name "test vm4 A"      -type "Ethernet" -vlanId 1114   -smartlink $true
    New-HPOVNetwork -name "test vm1 B"      -type "Ethernet" -vlanId 1111   -smartlink $true
    New-HPOVNetwork -name "test vm2 B"      -type "Ethernet" -vlanId 1112   -smartlink $true
    New-HPOVNetwork -name "test vm3 B"      -type "Ethernet" -vlanId 1113   -smartlink $true
    New-HPOVNetwork -name "test vm4 B"      -type "Ethernet" -vlanId 1114   -smartlink $true
    New-HPOVNetwork -name "dev vm1 A"       -type "Ethernet" -vlanId 1121   -smartlink $true
    New-HPOVNetwork -name "dev vm2 A"       -type "Ethernet" -vlanId 1122   -smartlink $true
    New-HPOVNetwork -name "dev vm3 A"       -type "Ethernet" -vlanId 1123   -smartlink $true
    New-HPOVNetwork -name "dev vm4 A"       -type "Ethernet" -vlanId 1124   -smartlink $true
    New-HPOVNetwork -name "dev vm1 B"       -type "Ethernet" -vlanId 1121   -smartlink $true
    New-HPOVNetwork -name "dev vm2 B"       -type "Ethernet" -vlanId 1122   -smartlink $true
    New-HPOVNetwork -name "dev vm3 B"       -type "Ethernet" -vlanId 1123   -smartlink $true
    New-HPOVNetwork -name "dev vm4 B"       -type "Ethernet" -vlanId 1124   -smartlink $true
    New-HPOVNetwork -name "iSCSI"           -type "Ethernet" -vlanId 22     -smartlink $true

    # Create the FC networks
    New-HPOVNetwork -name "3PAR SAN A fabric" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "SAN1_0"
    New-HPOVNetwork -name "3PAR SAN B fabric" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -managedSan "SAN1_1"
    New-HPOVNetwork -name "3PAR SAN A direct" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -fabricType DirectAttach
    New-HPOVNetwork -name "3PAR SAN B direct" -type "FibreChannel" -typicalBandwidth 4000 -autoLoginRedistribution $true -fabricType DirectAttach
}

function CreateNetworkSets {
    $res = New-HPOVNetworkSet -name "Production Networks A" -networks (Get-HPOVNetwork -name "prod*A") -typicalBandwidth 2500 -maximumBandwidth 10000
    $res = New-HPOVNetworkSet -name "Production Networks B" -networks (Get-HPOVNetwork -name "prod*B") -typicalBandwidth 2500 -maximumBandwidth 10000
    $res = New-HPOVNetworkSet -name "Test Networks A"       -networks (Get-HPOVNetwork -name "test*A") -typicalBandwidth 2500 -maximumBandwidth 10000
    $res = New-HPOVNetworkSet -name "Test Networks B"       -networks (Get-HPOVNetwork -name "test*B") -typicalBandwidth 2500 -maximumBandwidth 10000
    $res = New-HPOVNetworkSet -name "Dev Networks A"        -networks (Get-HPOVNetwork -name "dev*A")  -typicalBandwidth 2500 -maximumBandwidth 10000
    $res = New-HPOVNetworkSet -name "Dev Networks B"        -networks (Get-HPOVNetwork -name "dev*B")  -typicalBandwidth 2500 -maximumBandwidth 10000
}

function CreateLogicalInterconnectGroup {
    $lig = "FlexFabric Logical Interconnect Group"
    Write-Host "Create the LIG"
    $task = New-HPOVLogicalInterconnectGroup -ligName $lig -bays @{1 = "Flex2040f8";2 = "Flex2040f8"}
    $task | Wait-HPOVTaskComplete -timeout (New-TimeSpan -Minutes 5)

    Write-Host "Create the uplink set ESX A and B on " $global:connectedsessions.Name
    $networks = "ESXi mgmt A","ESXi vmotion A","iSCSI" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "esx A" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY1:X1" -usEthMode "Auto"
    $networks = "ESXi mgmt B","ESXi vmotion B" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "esx B" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY2:X1" -usEthMode "Auto"

    Write-Host "Create the uplink set Prod A and B on " $global:connectedsessions.Name
    $networks = "prod vm1 A","prod vm2 A","prod vm3 A","prod vm4 A" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Production A" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY1:X2" -usEthMode "Auto"
    $networks = "prod vm1 B","prod vm2 B","prod vm3 B","prod vm4 B" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Production B" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY2:X2" -usEthMode "Auto"

    Write-Host "Create the uplink set Test A and B on " $global:connectedsessions.Name
    $networks = "test vm1 A","test vm2 A","test vm3 A","test vm4 A" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Test A" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY1:X5" -usEthMode "Auto"
    $networks = "test vm1 B","test vm2 B","test vm3 B","test vm4 B" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Test B" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY2:X5" -usEthMode "Auto"

    Write-Host "Create the uplink set Dev A and B on " $global:connectedsessions.Name
    $networks = "dev vm1 A","dev vm2 A","dev vm3 A","dev vm4 A" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Dev A" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY1:X6" -usEthMode "Auto"
    $networks = "dev vm1 B","dev vm2 B","dev vm3 B","dev vm4 B" | Get-HPOVNetwork -type Ethernet
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "Dev B" -usType "Ethernet" -usNetworks $networks -usUplinkPorts "BAY2:X6" -usEthMode "Auto"

    Write-Host "Create the uplink set SAN A and B direct on " $global:connectedsessions.Name
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "3PAR SAN A direct" -usType "FibreChannel" -usNetworks (Get-HPOVNetwork -name "3PAR SAN A direct") -usUplinkPorts "BAY1:X3","BAY1:X4"
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "3PAR SAN B direct" -usType "FibreChannel" -usNetworks (Get-HPOVNetwork -name "3PAR SAN B direct") -usUplinkPorts "BAY2:X3","BAY2:X4"

    Write-Host "Create the uplink set SAN A and B fabric on " $global:connectedsessions.Name
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "3PAR SAN A fabric" -usType "FibreChannel" -usNetworks (Get-HPOVNetwork -name "3PAR SAN A fabric") -usUplinkPorts "BAY1:X7"
    $task = Get-HPOVLogicalInterconnectGroup -Name $lig | New-HPOVUplinkSet -usName "3PAR SAN B fabric" -usType "FibreChannel" -usNetworks (Get-HPOVNetwork -name "3PAR SAN B fabric") -usUplinkPorts "BAY2:X7"
}

function CreateEnclosureGroup {
    $lig = "FlexFabric Logical Interconnect Group"
    $EGName = "FlexFabric Enclosure Group"
    $mylig = Get-HPOVLogicalInterconnectGroup -name $lig
    $ret = New-HPOVEnclosureGroup -name "$EGName" -logicalInterConnectGroup $mylig
}

function ImportStorageArray {
    $myArrayUser = "dcs"
    $myArrayPass = "dcs"
    $myArrayDCSName = "ThreePAR-1"
    $myArrayDomain = "TestDomain"
    $myArrayPools = [System.Array]("FST_CPG1", "FST_CPG2")
    $myArray = "172.18.11.11"
    Write-Host "Importing storage array: $myArray"
    $task = New-HPOVStorageSystem -hostname $myArray -username $myArrayUser -password $myArrayPass -Domain $myArrayDomain
    $task | Wait-HPOVTaskComplete -timeout (New-TimeSpan -Minutes 15)
    $tasks = New-HPOVStoragePool -StorageSystem $myArrayDCSName -PoolName $myArrayPools
}

function ImportEnclosure {
    try {
        New-HPOVLicense -LicenseKey 'ACTG D9MA H9PQ 8HV3 V7B5 HWWB Y9JL KMPL WFSF 6DRE DXAU 2CSM GHTG L762 PA2Y W95U KJVT D5KM EFVW DT5J QYML NZ26 9K2P 3E22 JJQ4 LURR TZZX AB6X 82Z5 WHEF D9ED 3RUX BJS2 XFXC T84U R42A 58S5 XA2D WXAP GMTQ 4YLB MM2S CZU7 2E4X E8EW BGB5 BWPD CAAR YT9J 4NUG 2NJN J9UF "424919019 HPOV-NFR1 HP_OneView_16_Seat_NFR 35D9AEYGUYTJ"_3PZ55-B7K33-HX9D8-STKQ6-BLT8W'
        New-HPOVLicense -LicenseKey 'ACTE D9MA H9PA KHX2 U7B5 HWW5 Y9JL KMPL YFKD NEBE DXAU 2CSM GHTG L762 AAW7 FLNA KJVT D5KM EFVW DT5J YYEJ 4ZK6 9K2P 3E22 RJQ4 LURR TZZH MB5X 82Z5 WHEF D9ED 3RUX BJS2 XFXC T84U R42A 58S5 XA2D WXAP GMTQ 4YLB MM2S CZU7 2E4X E8EW BGB5 BWPD CAAR 2T9J MNEG 2NJN J9UF "424919023 HPOV-NFR2 HP_OneView_w/o_iLO_16_Seat_NFR HUCUAEYGUYHA"'
        New-HPOVLicense -LicenseKey 'QCDE D9MA H9PY KHW3 V7B5 HWWB Y9JL KMPL 2FKD PERE DXAU 2CSM GHTG L762 CEK4 WMNE KJVT D5KM EFVW DT5J 2YEJ 6Z26 9K2P 3E22 ZJQ4 LURR TZZX 9B5X 82Z5 WHEF D9ED 3RUX BJS2 XFXC T84U R42A 58S5 XA2D WXAP GMTQ 4YLB MM2S CZU7 2E4X E8EW BGB5 BWPD CAAR YT9J 4NUG 2NJN J9UF "424919031 HPOV-NFR1 HP_OneView_16_Seat_NFR CYY7AEYGU2E7"_3M9QC-ZV7MN-TGZPX-GCVST-XNY22'
    } catch {
        Write-Host "ERROR: Unable to load license keys"
    }
    
    $enclGroupName = "FlexFabric Enclosure Group"
    $licenseIntent = "OneView"
    $myOAUser = "dcs"
    $myOAPass = "dcs"
    $myOA = "172.18.1.11"
    $task = New-HPOVEnclosure -hostname $myOA -enclGroupName $enclGroupName -username $myOAUser -password $myOAPass -licensingIntent $licenseIntent -Async
    $task | Wait-HPOVTaskComplete -Timeout (New-TimeSpan -Minutes 30)
    if ( $task.taskState -ieq "Error" ) {
        Write-Host "Error importing the enclosure"
        Write-Host "Error array is: " $task.taskErrors
        Write-Host "Error output is: " $task.taskOutput
        return 1
    }
}

#
# Main Program
#
Import-Module HPOneView.410

$ip_addr  = "<DHCP IP Address assigned to DCS appliance>"
$password = "<New Administrator Password>"
$hostname = "<Hostname associated with DHCP IP Address of the DCS appliance>"

#
# Accept the EULA and configure the Administrator credentials
#
ConfigureAppliance $ip_addr "$password" "$hostname"
Connect-HPOVMgmt -Hostname $ip_addr -UserName Administrator -Password "$password" -ErrorAction Stop

#
# Configure virtual resources
#
ImportSanManager
CreateNetworks
CreateNetworkSets
CreateLogicalInterconnectGroup
CreateEnclosureGroup
ImportStorageArray
ImportEnclosure

#
# Clear any remaining alerts and disconnect from OneView
#
Get-HPOVAlert -AlertState Active | Set-HPOVAlert -Cleared
Disconnect-HPOVMgmt