Import-Module '480-utils' -Force

# Gets Config
$conf = Get-480Config -config_path "/home/champuser/my-tech-journal/SEC480/480.json"
# Connnnects to VIServer
480Connect -server $conf.vcenter_server
# Selects VM to clone
Write-Host "Selecting your VM to clone"
$vm = Select-VM -folder $conf.vm_folder
# Determine type of VM to be created
$type = Read-Host -Prompt "Would you like to make a full clone (F) or a linked clone (L)? "
# Input Checking
if ($type -ne "F" -and $type -ne "L"){
    Write-Host "Incorrect Option!"
    exit
}
# Gets VMHost either from user input or default config file
$vmhost = Read-Host -Prompt "What ESXI Host would you like to run the clone on? [$($conf.esxi_host)] "
if (-not $vmhost) {
	$vmhost = $conf.esxi_host
}
# Gets datastore either from user input or default config file
$ds = Read-Host -Prompt "Where would you like the new VM to be stored? [$($conf.default_ds)] "
if (-not $ds) {
	$ds = $conf.default_ds
}
# Gets Snapshot either from user input or default config file
Get-Snapshot -VM $vm
$snap = Read-Host -Prompt "Please select the snapshot you wish to base the clone on: [$($conf.default_snap)] "

if (-not $snap){
	$snap = $conf.default_snap
}
# Gets New VM Name from User Input
$name = Read-Host -Prompt "Please enter the name for the new virtual machine: "
# Creates a Full or Linked VM based on $type value
if ($type -eq "F"){
    Add-FullVM $name $vm $snap $vmhost $ds
} else{
    Add-LinkedVM $name $vm $snap $vmhost $ds
}