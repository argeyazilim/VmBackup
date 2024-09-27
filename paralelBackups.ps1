$logFile = "F:\backup\backup-log.txt"
# Kayıt tutma başlatılıyor
Start-Transcript -Path $logFile -Append

# Yedekleme klasörünü belirleyin
$backupPath = "F:\backup"

# Tüm çalışan VM'leri alın
$vms = Get-VM | Where-Object {$_.State -eq 'Running'}

# Her VM için bir yedekleme işi başlatın
$jobs = foreach ($vm in $vms) {
    $vmName = $vm.Name
    Start-Job -ScriptBlock {
        param($vmName, $backupPath)
        
        $date = Get-Date -Format "yyyy-MM-dd-HH-mm"
        $exportPath = Join-Path $backupPath "$vmName-$date"
        
        # VM'i dışa aktarın (yedekleyin)
        Export-VM -Name $vmName -Path $exportPath
        
        # Bu VM için mevcut yedekleri alın ve tarihe göre sıralayın
        $existingBackups = Get-ChildItem -Path $backupPath -Directory | Where-Object {$_.Name -like "$vmName-*"} | Sort-Object CreationTime -Descending
        
        # Eğer 3'ten fazla yedek varsa, en eski olanları silin
        if ($existingBackups.Count -gt 3) {
            $existingBackups | Select-Object -Skip 3 | ForEach-Object {
                Remove-Item $_.FullName -Recurse -Force
                Write-Output "Eski yedek silindi: $($_.FullName)"
            }
        }
    } -ArgumentList $vmName, $backupPath
}

# Tüm işlerin tamamlanmasını bekleyin
$jobs | Wait-Job

# İşlerin sonuçlarını alın ve yazdırın
$jobs | Receive-Job

# İşleri temizleyin
$jobs | Remove-Job

# Tüm VM'ler için yedekleme işlemi tamamlandıktan sonra, boş kalmış klasörleri temizle
Get-ChildItem -Path $backupPath -Directory | Where-Object {(Get-ChildItem $_.FullName).Count -eq 0} | ForEach-Object {
    Remove-Item $_.FullName -Force
    Write-Host "Boş klasör silindi: $($_.FullName)"
}

# Kayıt tutma bitiriliyor
Stop-Transcript
