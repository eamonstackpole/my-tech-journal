# Simple Banner
function 480Banner(){
    Write-Host "Hello SEC-480"
}
# Connects to $server if not already connected, otherwise throws error
function 480Connect([String] $server){
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn
        Write-Host -ForegroundColor Green $msg
    }else {
        $conn = Connect-VIServer -Server $server
    }
}

# Disconnects from $server if already connected, otherwise throws error
function 480Disconnect([String] $server){
    $conn = $global:DefaultVIServer
    if ($conn){
        $conn = Disconnect-VIServer -Server $server
        
    }else {
        $msg = "Already Disconnected to: {0}" -f $conn
        Write-Host -ForegroundColor Red $msg
    }
}

# Gets and Reads a JSON file at $config_path, throws error for no configuration in file
function Get-480Config([String] $config_path){
    $conf=$null
    if(Test-Path $config_path){
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor Green $msg
    } else {
        Write-Host -ForegroundColor Yellow "No Configuration"
    }
    return $conf
}
# Given a folder it lists all the VMs in the folder and prompts user to select one
Function Select-VM([String] $folder){
    $selected_vm=$null
    try {
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms){
            Write-Host [$index] $vm.Name
            $index+=1
        }
        $pick_index = Read-Host "Which index number [x] would you like to pick?"
        if ($pick_index -ge $index -or $pick_index -le 0){
            Write-Host "Invalid index!"
            exit
        }
        else {
            $selected_vm = $vms[$pick_index-1]
            Write-Host "You picked " $selected_vm.Name
            return $selected_vm
        }
        
    }
    catch {
        Write-Host "Invalid Folder: $folder" -ForegroundColor Red
    }
}

# Creates a linked VM
Function Add-LinkedVM([String] $name, [string] $vm, [string] $snap, [string] $vmhost, [string] $ds){
    # $linked_name = "{0}.linked" -f $name # No longer will add ".linked" suffix to linked vm names, only for full vm process
    $linked_vm = New-VM -LinkedClone -Name $name -VM $vm -ReferenceSnapshot $snap -VMHost $vmhost -Datastore $ds
    Write-Host "Linked Virtual Machine Created!"
    return $linked_vm
}

# Creates a Full VM using a temporary linked VM as a base
Function Add-FullVM([String] $name, [string] $vm, [string] $snapshot, [string] $vmhost, [string] $ds){
    $linked_name = "{0}.linked" -f $name
    $linked = Add-LinkedVM $linked_name $vm $snapshot $vmhost $ds
    $full_vm = New-VM -Name $name -VM $linked -VMHost $vmhost -Datastore $ds
    $full_vm | New-Snapshot -Name "Base"
    $linked | Remove-VM
    Write-Host "Full Virtual Machine Created!"
    return $full_vm
}

# Creates a new virtual network and portgroup
Function New-Network($name, $vmhost){
    Write-Host "Creating new Virtual Network..."
    $switch = New-VirtualSwitch -VMHost $vmhost -Name $name
    Write-Host "Creating new Virtual Port Group..."
    New-VirtualPortGroup -VirtualSwitch $switch -Name $name
}
# Gets the first IP & Mac address of a VM by name
Function Get-IP ([String]$name){
    try {
        $vm = Get-VM -Name $name -ErrorAction Ignore
        $mac = ($vm | Get-NetworkAdapter | Select-Object -First 1).MacAddress
        $ip = $vm.Guest.IPAddress[0]
        Write-Host "Addresses for $($vm.Name)"
        Write-Host "===================================="
        Write-Host "MAC Address: $mac" 
        Write-Host "IP Address: $ip"
        } catch {
         Write-Host "ERROR: VM Name does not exist!"
    }
}
# Starts a VM by name
Function PowerOn-VM([String]$name){
    $status = (Get-VM -Name $name).PowerState
    if ($status -eq "PoweredOn"){
        $msg = "{0} is already powered on" -f $name
        Write-Host -ForegroundColor Green $msg
    }
    else{
        Start-VM -VM $name 
    }
}

# Stops a VM by name
Function PowerOff-VM([String]$name){
    $status = (Get-VM -Name $name).PowerState
    if ($status -eq "PoweredOff"){
        $msg = "{0} is already powered off" -f $name
        Write-Host -ForegroundColor Red $msg
    }
    else{
        Stop-VM -VM $name
    }
}
# Sets the network adapter of a given virtual machine to the network of choice
Function Set-Network($name){
    $adapters = Get-VM -Name $name | Get-NetworkAdapter
    $networks = Get-VirtualNetwork
    $index = 1
    Write-Host "Please Select the Network Adapter you wish to edit: "
    foreach($adapter in $adapters){
        Write-Host [$index] $adapter.Name
        $index+=1
        }
        $pick_index = Read-Host "Which index number [x] would you like to pick?"
        if ($pick_index -ge $index -or $pick_index -le 0){
            Write-Host "Invalid index!"
            return
        }
        else {
            $selected_adapter = $adapters[$pick_index-1]
            Write-Host "You picked " $selected_adapter.Name
        }
    Write-Host "Please Select the Virtual Network to assign to the Network Adapter: "
    $index = 1
    foreach($network in $networks){
        Write-Host [$index] $network.Name
        $index+=1
    }
    $pick_index = Read-Host "Which index number [x] would you like to pick?"
        if ($pick_index -ge $index -or $pick_index -le 0){
            Write-Host "Invalid index!"
            return
        }
        else {
            $selected_network = $networks[$pick_index-1]
            Write-Host "You picked " $selected_network.Name
        }
    $selected_adapter | Set-NetworkAdapter -NetworkName $selected_network.Name -Confirm:$false
    $again = Read-Host -Prompt "Would you like to modify another network adapter? (Y/N): "
    if ($again -eq "Y"){
        Set-Network($name)
    }
    else {
        return
    }
}
# Sets a static IP address to the given virtual machine
Function Set-WindowsStatic($name, $ip, $netmask, $gateway, $dns, $guest_user){
$guest_creds = Get-Credential #New-Object System.Net.NetworkCredential($guest_user, $guest_password)
Invoke-VMScript -VM $name -ScriptText "netsh interface ip set address name='Ethernet0' static $ip $netmask $gateway" -GuestCredential $guest_creds -ScriptType Powershell
Invoke-VMScript -VM $name -ScriptText "netsh interface ip set dns name='Ethernet0' static $dns" -GuestCredential $guest_creds -ScriptType Powershell

}