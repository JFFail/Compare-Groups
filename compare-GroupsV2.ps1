#Updated 10/13/2014
#    Added check to see if group member in on-prem AD has an email address and exits if someone doesn't.
#Initial Release 10/3/2014
#Define an optional parameter so you can use it from the command line rather than interactively if you so choose.
Param
(
    [Parameter(Mandatory=$false,Position=1)]
        [string]$groupSMTP
)

#Get the SMTP address to check if it wasn't passed already.
if($groupSMTP -eq "")
{
    #Script to compare AD group information with O365 group information.
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "Welcome to the Super-Awesome Group Comparison Script™!" -ForegroundColor Green
    Write-Host "======================================================" -ForegroundColor Green
    Write-Host "You need to already be connected to Exchange Online!!!" -ForegroundColor Yellow
    Write-Host "`tCtrl + C with the quickness if you aren't..." -ForegroundColor Yellow
    Write-Host " "

    $groupSMTP = Read-Host "Enter the email address of the group"
}

#Parse out the SMTP for the group so we know which DC to query.
$domainInfo = $groupSMTP.Split("@")[1]
$domainController = "dc1." + $domainInfo

#Query on-prem AD first for the group object since you can't filter Get-ADGroupMember.
$groupObject = Get-ADGroup -Filter {mail -eq $groupSMTP} -Server $domainController

#Check if the group is null and kill the script.
if($groupObject -eq $null)
{
    Write-Host "`nDERP! There is no group in AD for this... Quitting now!" -ForegroundColor Red
    exit
}

#Show users what's going on for great justice.
Write-Host "`nPopulating the members from AD..."

#Now get the members.
$groupMembersAD = Get-ADGroupMember -Identity $groupObject -Server $domainController
$ADEmailAddresses = @()

$allHaveEmailValues = $true

#Put the members in an array with the addresses only.
foreach($singleAddress in $groupMembersAD)
{
    $tempAddressValue = (Get-ADObject -Identity $singleAddress -Properties mail).mail
    
    #Check to see if the address is null and exit if it is since it'll bork the comparison!
    if($tempAddressValue -eq $null)
    {
        $userDN = (Get-ADObject -Identity $singleAddress).distinguishedName
        Write-Host "`nThe following user has NO EMAIL ADDRESS!  $userDN" -ForegroundColor Red
        $allHaveEmailValues = $false
    }
    $ADEmailAddresses += $tempAddressValue
}

if(-not($allHaveEmailValues))
{
    Write-Host "The script will exit since this'll break the comparison!" -ForegroundColor Red
    exit
}

#Take off every zig!
Write-Host "`nPopulating the members from O365...`n"

#Get the group in Office 365.
$groupMembersCloud = Get-DistributionGroupMember -Identity $groupSMTP

#Make an array of just SMTP addresses from this.
$cloudEmailAddresses = @()
foreach($singleMember in $groupMembersCloud)
{
    $tempAddressValue = $singleMember.PrimarySmtpAddress
    $cloudEmailAddresses += $tempAddressValue
}

#Compare the two arrays of email addresses.
$comparisonResults = Compare-Object -ReferenceObject $ADEmailAddresses -DifferenceObject $cloudEmailAddresses

#Make the output a bit more user-friendly with a better side indicator.
foreach($singleResult in $comparisonResults)
{
    if($singleResult.SideIndicator -eq "<=")
    {
        $singleResult.SideIndicator = "AD Only!"
    }

    if($singleResult.SideIndicator -eq "=>")
    {
        $singleResult.SideIndicator = "O365 Only!"
    }
}

#Output the results.
$comparisonResults