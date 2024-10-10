# This is a PowerShell script that scans all the scopes from a Windows DHCP Server
# then outputs the scanned information to a .csv file for documentation.


# Load the DHCP Server module (if not already loaded)
Import-Module DhcpServer

# Get all DHCP Scopes
$dhcpScopes = Get-DhcpServerv4Scope

# Function to convert subnet mask to CIDR notation
function Get-CIDRNotation {
    param ($SubnetMask)

    # Convert the Subnet Mask (IPAddress object) to a string and split it into octets
    $binaryMask = $SubnetMask.ToString().Split('.') | ForEach-Object { [Convert]::ToString($_,2).PadLeft(8,'0') }

    # Count the number of 1s in the binary representation of the mask
    $CIDR = ($binaryMask -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object

    return $CIDR.Count
}

# Create an empty array to store the results
$dhcpScopeData = @()

# Loop through each scope and output the scope information with CIDR notation
foreach ($scope in $dhcpScopes) {
    $CIDR = Get-CIDRNotation $scope.SubnetMask
    
    # Create a custom object for each scope
    $scopeInfo = [pscustomobject]@{
        ScopeID   = $scope.ScopeId
        Name      = $scope.Name
        Subnet    = $scope.SubnetMask.ToString()
        CIDR      = "/$CIDR"
    }
    
    # Add the scope info to the array
    $dhcpScopeData += $scopeInfo
}

# Define the output CSV file path
$outputCsv = "C:\Path\To\Output\DHCP_Scopes.csv"

# Export the data to a CSV file
$dhcpScopeData | Export-Csv -Path $outputCsv -NoTypeInformation

# Confirm the file was saved
Write-Output "DHCP scope information saved to $outputCsv"
