Powershell script to Demo/Test an Azure VM Availability Set during VM creation
==============================================================================

            

Powershell script to Demo/Test an Azure VM Availability Set during VM creation.


The attached PS script creates Azure Storage Account, Cloud Service, 2 VMs under the same Cloud Service, assigning each of them to the same Availability Set at VM creating time. Availability Set is an Azure feature that ensures that Workloads withing the
 availability Set are placed on different Fault and Upgrade domains.


 

 For more information see [https://superwidgets.wordpress.com/2015/12/14/using-powershell-to-create-azure-vms-in-an-availability-set/](https://superwidgets.wordpress.com/2015/12/14/using-powershell-to-create-azure-vms-in-an-availability-set/)

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
