# Populate-HPE-OneView
Quickly and reliably configure an HPE OneView virtual demonstration appliance with all included hardware.

**WARNING**: this version of the script in branch 7.0 applies to HPE OneView 7.0 and later. Version 7.0 has dropped support for some hardware like c7000 enclosures and therefore this script no longer configures deprecated hardware. If you want to use an earlier version of HPE OneView with DCS, you should switch to the master branch and get the script from that branch.

Here are the steps you need to take prior to running the script:

1)	Deploy a new OneView DCS Appliance and make sure it is assigned a valid IP address from a DHCP server on your network
2)	Take note of the DHCP-assigned IP address and the DNS hostname associated with the DHCP-assigned IP address
3)	Select a new password for the Administrator user for your appliance 

Once you have these three pieces of information, you will need to modify lines 89-91 in the script to reflect your IP/password/hostname:

```
$ip_addr  = "<DHCP IP Address assigned to DCS appliance>"
$password = "<New Administrator Password>"
$hostname = "<Hostname associated with DHCP IP Address of the DCS appliance>"
```