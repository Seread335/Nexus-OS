<# Generate a secure token for Cerberus (PowerShell) #>
$rand = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 32
$rand.GetBytes($bytes)
$hex = ([System.BitConverter]::ToString($bytes)).Replace('-','').ToLower()
Write-Output "# Cerberus auth token (keep secret)"
Write-Output "CERBERUS_AUTH_TOKEN=$hex"
Write-Output "# Example: setx CERBERUS_AUTH_TOKEN $hex -m   # persistent for machine"
