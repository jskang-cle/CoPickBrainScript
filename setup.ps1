function Get-ValidSerial {
    while ($true) {
        # User input Serial number
        $serial = Read-Host "시리얼 넘버를 입력하세요"

        # get current year and month
        $yearmonth = Get-Date -Format "yyMM"

        # Validate serial using regex CB{yearmonth}\d{4}[A-Z]
        $match = $serial -match "CB(?<yymm>\d{4})(?<application>[A-Z])(?<serial>\d{4})(?<model>[A-Z])"

        if (!$match) {
            Write-Host "시리얼 넘버의 형식이 올바르지 않습니다."
            continue
        }

        Write-Host "올바른 형식의 시리얼 넘버입니다."
        $serialdate = $matches.yymm
        $application = $matches.application
        $serial = $matches.serial
        $model = $matches.model

        # print the serial number parts
        Write-Host "날짜: $serialdate"
        Write-Host "타입: $application"
        Write-Host "번호: $serial"
        Write-Host "모델: $model"

        if ($serialdate -ne $yearmonth) {
            Write-Host -NoNewline "시리얼 넘버의 일자($serialdate)가 현재 일자($yearmonth)와 일치하지 않습니다. 계속하시겠습니까? (Y/N) "
            $continue = Read-Host
            if ($continue.ToUpper() -ne "Y") {
                continue
            }
        } 

        return $matches.0
    }
}

function Disable-WindowsUpdate {
    # Disable Windows Update services (wuauserv, UsoSvc, uhssvc, WaaSMedicSvc)
    $services = @("wuauserv", "UsoSvc", "uhssvc", "WaaSMedicSvc")
    foreach ($service in $services) {
        $status = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($status.Status -eq "Running") {
            Stop-Service -Name $service
            Set-Service -Name $service -StartupType Disabled
            Set-Service -Name $service -ErrorAction Stop
            Write-Host "$service 서비스를 중지하고 시작 유형을 비활성화했습니다."
        } else {
            Write-Host "$service 서비스가 이미 중지되어 있습니다."
        }
    }

    # Update registry to disable Windows Update
    # HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"
    if (Test-Path $key) {
        Set-ItemProperty -Path $key -Name "Start" -Value 4
        # reg add "HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc" /v FailureActions /t REG_BINARY /d 000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000 /f
        Set-ItemProperty -Path $key -Name "FailureActions" -Value "000000000000000000000000030000001400000000000000c0d4010000000000e09304000000000000000000"
        Write-Host "WaaSMedicSvc 서비스 시작 유형을 비활성화했습니다."
    } else {
        Write-Host "WaaSMedicSvc 서비스가 없습니다."
    }
}

# Check if the script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "관리자 권한으로 실행해주세요."
    exit
}

# Call the function to get a valid serial number
$serial = Get-ValidSerial

# Print the serial number
Write-Host "시리얼 넘버: $serial"

# check if the user already exists
$user = Get-LocalUser -Name $serial

if ($user) {
    Write-Host "사용자 $serial이 이미 존재합니다."
} else {
    # Create new local user with the serial number and no password
    Import-Module microsoft.powershell.localaccounts -UseWindowsPowerShell 
    $newuser = New-LocalUser -Name $serial -NoPassword

    # check if the user was created
    if ($newuser) {
        Write-Host "새로운 사용자 $serial이 생성되었습니다."
    } else {
        Write-Host "사용자 $serial을 생성하는 중 오류가 발생했습니다."
        exit
    }
}
