<#
.Synopsis
   Name: Copy-ADComputerGroupMembership.ps1
   A function to copy all Active Directory Group Memberships from one computer to another.
.DESCRIPTION
   A function to copy all group memberships from one computer to another in Active Directory.   
   The ActiveDirectory module is required for this function to work.
.EXAMPLE
   Copy-ADComputerGroupMembership -SourceComputer Computer-A -DestinationComputer Computer-B
.NOTES
   Original release Date: 31.07.2018
   Author: Flemming Sørvollen Skaret (https://github.com/flemmingss/)
.LINK
   https://github.com/flemmingss/
#>

Function Copy-ADComputerGroupMembership
{
param (
	[Parameter(Mandatory=$true,Position=0)]
	[string]$SourceComputer,
	[Parameter(Mandatory=$true,Position=1)]
	[string]$DestinationComputer
	)

    $script:ErrorDetected = $false

    try
    {
    $MemberOfSource = $null
    $MemberOfSource = (Get-ADComputer -Identity "$SourceComputer" -Properties MemberOf).MemberOf | ForEach {$_.Split(",")[0].Split("=")[1]} #Get members and convert from LDAP string
    }

    catch 
    {
    $script:ErrorDetected = $true
    Write-Host "Cannot find source computer $SourceComputer in Active Directory" -ForegroundColor Red
    }

    try
    {
    $MemberOfDestination = $null
    $MemberOfDestination = (Get-ADComputer -Identity "$DestinationComputer" -Properties MemberOf).MemberOf | ForEach {$_.Split(",")[0].Split("=")[1]} #Get members and convert from LDAP string
    }

    catch 
    {
    Write-Host "Cannot find destination computer $DestinationComputer in Active Directory" -ForegroundColor Red
    $script:ErrorDetected = $true
    }


    if ($ErrorDetected -eq $false)
    {

    	# Comparing groups from computers

    	if ($MemberOfSource -ne $null -and $MemberOfDestination -ne $null) #if bouth source and destination is not null
    	{

    	$MemberOf_OnlyEqual = (Compare-Object -ReferenceObject $MemberOfSource -DifferenceObject $MemberOfDestination -IncludeEqual -ExcludeDifferent).InputObject
    	$MemberOf_OnlyInSource = (Compare-Object -ReferenceObject $MemberOfSource -DifferenceObject $MemberOfDestination | Where-Object {$_.SideIndicator -eq "<="}).InputObject
    	$MemberOf_OnlyInDestination = (Compare-Object -ReferenceObject $MemberOfSource -DifferenceObject $MemberOfDestination | Where-Object {$_.SideIndicator -eq "=>"}).InputObject

    	}

    	elseif ($MemberOfSource -eq $null -and $MemberOfDestination -ne $null) #else if only source is null
    	{
    	$MemberOf_OnlyEqual = $null
    	$MemberOf_OnlyInSource = $null
    	$MemberOf_OnlyInDestination = $MemberOfDestination
    	Write-Host "The source computers are not member of any groups"
    	}

    	elseif ($MemberOfSource -ne $null -and $MemberOfDestination -eq $null) #else if only destination is null
    	{
    	$MemberOf_OnlyEqual = $null
    	$MemberOf_OnlyInSource = $MemberOfSource
    	$MemberOf_OnlyInDestination = $null
    	}

    	else
    	{
    	$MemberOf_OnlyEqual = $null
    	$MemberOf_OnlyInSource = $null
    	$MemberOf_OnlyInDestination = $null
    	Write-Host "None of the computers are member of any groups"
    	}

        # End of comparing groups from computers
		# Copying Groups

        $EqualCounter = 0
        $CopyCounter = 0
        $CopyErrorCounter = 0


    	foreach ($Group in $MemberOf_OnlyEqual)
    	{
        Write-Host "$Group" -nonewline; Write-Host " not copied (Already exists)" -ForegroundColor Yellow
        $EqualCounter = $EqualCounter+1
    	}

    	foreach ($Group in $MemberOf_OnlyInSource)
    	{

        	try
        	{
        	Add-ADGroupMember -Identity "$Group" -Members "$DestinationComputer$" 
        	Write-Host "$Group" -nonewline; Write-Host " copied (Ok)" -ForegroundColor Green
            $CopyCounter = $CopyCounter+1
        	}

        	catch
        	{
            Write-Host "$Group" -nonewline; Write-Host " not copied (Error)" -ForegroundColor Red
            $CopyErrorCounter = $CopyErrorCounter+1
    	    }

	    }

		#End of Copying Groups

    If ($CopyErrorCounter -eq 0)
    {
    Write-Host Copying of group membership from $SourceComputer to $DestinationComputer done without errors -ForegroundColor Green
    }

    else
    {
    Write-Host Copying of group membership from $SourceComputer to $DestinationComputer done with errors -ForegroundColor Red
    }

    Write-Host "Summary: $CopyCounter copied / $EqualCounter already exists / $CopyErrorCounter error(s)."

    }

} #End
