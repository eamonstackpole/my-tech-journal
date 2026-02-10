Write-Host "Please select the folder with the virtual machine you wish to clone: "
$folders = Get-Folder
for ($i = 0; $i -lt $folders.Count; $i++) {
	"{0}. {1}" -f ($i +1), $folders[$i]
}
$num = Read-Host -Prompt "Please enter the index number of the folder: "
$folder = $folders[$num-1]
Write-Host "Please select which virtual machine you would like to clone: "
$vms = (Get-Folder -Name $folder | Get-VM).Name
for ($i = 0; $i -lt $vms.Count; $i++) {
	"{0}. {1}" -f ($i +1), $vms[$i]
}
$num = Read-Host -Prompt "Please enter the index number of the virtual machine: "
$vm = $vms[$num-1]
$type = Read-Host -Prompt "Would you like to make a full clone (F) or a linked clone (L)? "
$vmhost = Read-Host -Prompt "What ESXI Host would you like to run the clone on? [192.168.3.225] "
if (-not $vmhost) {
	$vmhost = (Get-VMHost).Name
}
$ds = Read-Host -Prompt "Where would you like the new VM to be stored? [datastore1.super25] "
if (-not $ds) {
	$ds = (Get-Datastore).Name
}
$name = Read-Host -Prompt "Please select the snapshot you wish to base the clone on: [Base] "
Get-Snapshot -VM $vm
if (-not $name){
	$name = "Base"
}
$snapshot = Get-Snapshot -VM $vm -Name $name
$newname = Read-Host -Prompt "Please enter the name for the new virtual machine "
$linkedname = "{0}.linked" -f $newname
$linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
$netad = Read-Host -Prompt "Which network would you like to add the virtual machine to? [480-Internal]"
if (-not $netad) {
	$netad = "480-Internal"
}
$linkedvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $netad 		
if ($type -eq "F") {
	$newvm = New-VM -Name $newname -VM $linkedvm -VMHost $vmhost -Datastore $ds
	$newvm | new-snapshot -Name "Base"
	$linkedvm | Remove-VM
}
