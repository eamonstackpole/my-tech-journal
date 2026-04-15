& "/home/champuser/my-tech-journal/SEC480/480driver.ps1"
Set-Network -Name 'DC-Blue25'
PowerOn-VM -Name 'DC-Blue25'
Set-WindowsStatic -name 'DC-Blue25' -ip 10.0.5.5 -netmask 255.255.255.0 -gateway 10.0.5.2 -dns 10.0.5.2