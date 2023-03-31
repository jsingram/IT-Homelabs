# =============================================================
# Script for provisioning Virtual Machines in Hyper-V via
# template VMs.
# =============================================================

# =============================================================
# Lab Information
# =============================================================

$LabRootFolder = "H:\IT-Homelabs\Hyper-V"
$LabName = "Work-Lab"
$LabFolder = "$($LabRootFolder)\$($LabName)"

# =============================================================
# Lab Network Information (Created ahead of time.)
# =============================================================
$ExternalSwitch = "Default Switch"
$InternalSwitch = "Internal Switch"

# =============================================================
# Template Information
# =============================================================
$DesktopTemplate = "H:\IT-Homelabs\Hyper-V\Templates\Windows-10-Client\Template - Windows 10.vhdx"
$ServerTemplate = "H:\IT-Homelabs\Hyper-V\Templates\Windows-Server-2022\Template - Windows Server 2022\Virtual Hard Disks\Template - Windows Server 2022.vhdx"

# =============================================================
# VM Information
# =============================================================

$VMNames = "DC-001", "Desktop-1", "Desktop-2"

# =============================================================
# Provision VMs
# =============================================================

# Check for lab folder
if (Test-Path $LabFolder) {
    Write-Host "Folder exists, adding VM's..."
}
else {
    #Create directory if it does not exist
    New-Item $LabFolder -ItemType Directory
    Write-Host "Lab folder created successfully, creating VM's..."
}
 
# Loop through $VMNames and provision a VM for each
foreach ($VMName in $VMNames) {
    # Create a directory for the VM
    $VMDirectory = "$($LabRootFolder)\$($LabName)\$($VMName)"

    # Check if directory exists
    if (Test-Path $VMDirectory) {
        Write-Host "VM folder already exists! Skipping to avoid losing data."
    }
    else {
        # Create a directory for the VM
        New-Item $VMDirectory -ItemType Directory
        Write-Host "VM folder created successfully, provistion VM: $VMName"

        $MachinePath = $VMDirectory
        $DiskPath = $VMDirectory
        $SmartPagingFilePath = $VMDirectory
        
        # If the machine is named DC-001, provistion a server with the server template $ServerTemplate
        if ($VMName -eq "DC-001") {
            write-host "Preparing domain controller: $($VMName)"     
            Copy-Item $ServerTemplate -Destination "$($DiskPath)\$($VMName).vhdx"     
            New-VM -Name $VMName -Path $MachinePath -Switch $InternalSwitch -Generation 2 -VHDPath "$($DiskPath)\$($VMName).vhdx" -MemoryStartupBytes 4GB | Out-Null    
            Add-VMNetworkAdapter -VMName $VMName -Switch $ExternalSwitch 
            Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector | Out-Null    
            Enable-VMTPM -VMName $VMName | Out-Null    
            Set-VM -Name $VMName -AutomaticCheckpointsEnabled $false -ProcessorCount 2 -SmartPagingFilePath $SmartPagingFilePath | Out-Null    
            Checkpoint-VM -Name $VMName -SnapshotName "OOBE" | Out-Null  
            #write-host "Starting  "$VMName   
            #Start-VM -Name $vmname | Out-Null    
        }
        else {
            # Otherwise, provision a desktop with the desktop client template $DesktopTemplate
            write-host "Preparing "$VMName     
            Copy-Item $DesktopTemplate -Destination "$($DiskPath)\$($VMName).vhdx"    
            New-VM -Name $VMName -Path $MachinePath -Switch $InternalSwitch -Generation 2 -VHDPath "$($DiskPath)\$($VMName).vhdx" -MemoryStartupBytes 4GB | Out-Null   
            Set-VMKeyProtector -VMName $VMName -NewLocalKeyProtector | Out-Null    
            Enable-VMTPM -VMName $VMName | Out-Null    
            Set-VM -Name $VMName -AutomaticCheckpointsEnabled $false -ProcessorCount 2 -SmartPagingFilePath $SmartPagingFilePath | Out-Null    
            Checkpoint-VM -Name $VMName -SnapshotName "OOBE" | Out-Null    
            #write-host "Starting  "$VMName 
            #Start-VM -Name $vmname | Out-Null    
        }
    }  

}  

# Show a list of VMs
Get-VM | Format-Table