# Prompt user to enter the DHCP server name (must be in ALL CAPS)
$dhcpServer = Read-Host "Enter the DHCP server name in ALL CAPS (e.g., HOSTNAME.DOMAIN.COM)"
$dhcpServer = $dhcpServer.ToUpper()  # Ensure server name is in all caps

# Prompt user for search type: MAC Address, Name, or IP Address
$searchType = Read-Host "Start search. Type 'MAC', 'Name', or 'IP' and then press ENTER"

# Convert search type to lowercase for easier comparison
$searchType = $searchType.ToLower()

# Get search value based on chosen search type
if ($searchType -eq "mac") {
    $searchValue = Read-Host "Enter MAC address (format: CC-90-70-65-F7-F8)"
    $searchValue = $searchValue.ToUpper() # Ensure MAC is uppercase
} elseif ($searchType -eq "name") {
    $searchValue = Read-Host "Enter client name"
} elseif ($searchType -eq "ip") {
    $searchValue = Read-Host "Enter IP address"
} else {
    Write-Host "Invalid search type entered. Please enter 'MAC', 'Name', or 'IP'."
    exit
}

# Get all DHCP scopes
$scopes = Get-DhcpServerv4Scope -ComputerName $dhcpServer
Write-Host "Retrieved all scopes from DHCP server: $dhcpServer"

# Loop through each scope and search for the MAC address, Name, or IP address
foreach ($scope in $scopes) {
    Write-Host "Searching in scope: $($scope.ScopeId)"
    
    try {
        # Get all leases for the current scope
        $leases = Get-DhcpServerv4Lease -ComputerName $dhcpServer -ScopeId $scope.ScopeId
        Write-Host "Retrieved $($leases.Count) leases in scope: $($scope.ScopeId)"
    } catch {
        Write-Host "Error retrieving leases for scope $($scope.ScopeId): $_"
        continue
    }
    
    # Search by MAC Address, Client Name, or IP Address
    if ($searchType -eq "mac") {
        # Search in ClientId (Unique ID column) for MAC Address
        $matchingLease = $leases | Where-Object { $_.ClientId -eq $searchValue }
    } elseif ($searchType -eq "name") {
        # Search in HostName for Client Name
        $matchingLease = $leases | Where-Object { $_.HostName -eq $searchValue }
    } elseif ($searchType -eq "ip") {
        # Search in IPAddress for IP Address
        $matchingLease = $leases | Where-Object { $_.IPAddress -eq $searchValue }
    }

    # Debugging: output number of leases checked
    Write-Host "Checked $($leases.Count) leases in scope $($scope.ScopeId)"
    
    # Output results
    if ($matchingLease) {
        Write-Host "Found matching $($searchType) in scope: $($scope.ScopeId)"
        $matchingLease | Format-Table -Property IPAddress, ClientId, HostName, LeaseExpiryTime
    } else {
        Write-Host "No matching $($searchType) found in scope $($scope.ScopeId)"
    }
}