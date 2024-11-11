function Get-ValidSerial {
    while ($true) {
        # User input Serial number
        $serial = Read-Host "Enter the serial number"

        # get current year and month
        $yearmonth = Get-Date -Format "yyMM"

        # Validate serial using regex CB{yearmonth}\d{4}[A-Z]
        $match = $serial -match "CB(?<yymm>\d{4})(?<application>[A-Z])(?<serial>\d{4})(?<model>[A-Z])"

        if (!$match) {
            Write-Host "The serial number format is incorrect."
            continue
        }

        Write-Host "The serial number format is correct."
        $serialdate = $matches.yymm
        $application = $matches.application
        $serial = $matches.serial
        $model = $matches.model

        # print the serial number parts
        Write-Host "Date: $serialdate"
        Write-Host "Type: $application"
        Write-Host "Number: $serial"
        Write-Host "Model: $model"

        if ($serialdate -ne $yearmonth) {
            Write-Host -NoNewline "The serial number date ($serialdate) does not match the current date ($yearmonth). Do you want to continue? (Y/N) "
            $continue = Read-Host
            if ($continue.ToUpper() -ne "Y") {
                continue
            }
        } 

        return $matches.0
    }
}

# Call the function to get a valid serial number
$serial = Get-ValidSerial

# Print the serial number
Write-Host "Serial number: $serial"

# check if the user already exists
$user = Get-LocalUser -Name $serial -ErrorAction SilentlyContinue

if ($user) {
    Write-Host "The user $serial already exists."
}
else {
    # Create new local user with the serial number and no password
    cmd /c net user $serial /add

    $newUser = Get-LocalUser -Name $serial -ErrorAction SilentlyContinue
    if ($newUser) {
        Write-Host "The user $serial was created successfully."
    }
    else {
        Write-Host "The user $serial could not be created."
    }
}
