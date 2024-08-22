$logFile = "C:\backup\backup-log.txt"

# Kayıt tutma başlatılıyor
Start-Transcript -Path $logFile -Append

# Yedekleme klasörünü belirleyin
$backupPath = "C:\backup"

# Tüm çalışan VM'leri alın
$vms = Get-VM | Where-Object {$_.State -eq 'Running'}

foreach ($vm in $vms) {
    $vmName = $vm.Name
    $date = Get-Date -Format "yyyy-MM-dd-HH-mm"
    $exportPath = Join-Path $backupPath "$vmName-$date"
    
    # VM'i dışa aktarın (yedekleyin)
    Export-VM -Name $vmName -Path $exportPath

    # Bu VM için mevcut yedekleri alın ve tarihe göre sıralayın
    $existingBackups = Get-ChildItem -Path $backupPath -Directory | Where-Object {$_.Name -like "$vmName-*"} | Sort-Object CreationTime -Descending

    # Eğer 5'ten fazla yedek varsa, en eski olanları silin
    if ($existingBackups.Count -gt 5) {
        $existingBackups | Select-Object -Skip 5 | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force
            Write-Host "Eski yedek silindi: $($_.FullName)"
        }
    }
}

# Tüm VM'ler için yedekleme işlemi tamamlandıktan sonra, boş kalmış klasörleri temizle
Get-ChildItem -Path $backupPath -Directory | Where-Object {(Get-ChildItem $_.FullName).Count -eq 0} | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Boş klasör silindi: $($_.FullName)"
}

# Kayıt tutma bitiriliyor
Stop-Transcript