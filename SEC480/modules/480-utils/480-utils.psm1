function 480Banner(){
    Write-Host "Hello SEC-480"
}

function 480Connect([String] $server){
    $conn = $global:DefaultVIServer
    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn
        Write-Host -ForegroundColor Green $msg
    }else {
        $conn = Connect-VIServer -Server $server
    }
}

function 480Disconnect([String] $server){
    $conn = $global:DefaultVIServer
    if ($conn){
        $conn = Disconnect-VIServer -Server $server
        
    }else {
        $msg = "Already Disconnected to: {0}" -f $conn
        Write-Host -ForegroundColor Red $msg
    }
}

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
Function Add-LinkedVM([String] $name, [string] $vm, [string] $snap, [string] $vmhost, [string] $ds){
    $linked_name = "{0}.linked" -f $name
    $linked_vm = New-VM -LinkedClone -Name $linked_name -VM $vm -ReferenceSnapshot $snap -VMHost $vmhost -Datastore $ds
    Write-Host "Linked Virtual Machine Created!"
    return $linked_vm
}
Function Add-FullVM([String] $name, [string] $vm, [string] $snapshot, [string] $vmhost, [string] $ds){
    $data_store = (Get-Datastore).Name
    $linked = Add-LinkedVM $name $vm $snapshot $vmhost $ds
    $full_vm = New-VM -Name $name -VM $linked -VMHost $vmhost -Datastore $ds
    $full_vm | New-Snapshot -Name "Base"
    $linked | Remove-VM
    Write-Host "Full Virtual Machine Created!"
    return $full_vm
}