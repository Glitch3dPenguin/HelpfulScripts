# This is a PowerShell script that scans all the scopes from a Windows DHCP Server
# then outputs it in the PowerShell terminal for whatever you may need this
# information for. 


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

# Loop through each scope and output the scope information with CIDR notation
foreach ($scope in $dhcpScopes) {
    $CIDR = Get-CIDRNotation $scope.SubnetMask
    Write-Output "Scope: $($scope.ScopeId) - $($scope.Name) - CIDR: /$CIDR"
}