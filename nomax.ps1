<#
MIT License
Copyright (c) 2025 asudouser

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
#>

Clear-Host
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "Gray"
Clear-Host

$adbPath = Join-Path $PSScriptRoot "adb.exe"
$maxPackage = "ru.oneme.app"

function Check-Adb {
	try {
		$output = & "$PSScriptRoot\adb.exe" version 2>$null
		if ($output) { return $true } else { return $false }
	} catch {
		return $false
	}
}

function Show-Banner {
	Clear-Host
	Write-Host "==================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Host "███████╗ ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██╗  ██╗" -ForegroundColor White
	Write-Host "██╔════╝███║██╔════╝██║ ██╔╝████╗ ████║██╔══██╗╚██╗██╔╝" -ForegroundColor White
	Write-Host "█████╗  ╚██║██║     █████╔╝ ██╔████╔██║███████║ ╚███╔╝ " -ForegroundColor White
	Write-Host "██╔══╝   ██║██║     ██╔═██╗ ██║╚██╔╝██║██╔══██║ ██╔██╗ " -ForegroundColor White
	Write-Host "██║      ██║╚██████╗██║  ██╗██║ ╚═╝ ██║██║  ██║██╔╝ ██╗" -ForegroundColor White
	Write-Host "╚═╝      ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor White
	Write-Host ""
	Write-Host "==================================================" -ForegroundColor DarkGray
	Write-Host "                 Max Remover v1.0                 " -ForegroundColor Yellow
	Write-Host "==================================================" -ForegroundColor DarkGray
	Write-Host ""
	Write-Host "Скрипт для удаления приложения Max." -ForegroundColor Gray

	if (-not (Check-Adb)) {
		Write-Host ""
		Write-Host "У вас не установлен ADB (Android Debug Bridge)" -ForegroundColor Red
		Write-Host "который необходим для корректной работы Max Remover!" -ForegroundColor Red
		$choice = Read-Host "Нажмите Y чтобы установить, любой другой символ чтобы выйти"

		if ($choice -eq "Y" -or $choice -eq "y") {
			$toolsZip = Join-Path $PSScriptRoot "platform-tools.zip"
			$toolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
			Write-Host "Скачивание platform-tools..." -ForegroundColor Yellow
			Invoke-WebRequest -Uri $toolsUrl -OutFile $toolsZip
			Write-Host "Распаковка..." -ForegroundColor Yellow
			$tempDir = Join-Path $PSScriptRoot "temp_platform_tools"
			Expand-Archive -Path $toolsZip -DestinationPath $tempDir -Force
			$sourceDir = Join-Path $tempDir "platform-tools"
			Get-ChildItem -Path $sourceDir -Recurse | ForEach-Object {
				$dest = Join-Path $PSScriptRoot $_.FullName.Substring($sourceDir.Length + 1)
				if ($_.PSIsContainer) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
				else { Copy-Item $_.FullName -Destination $dest -Force }
			}
			Remove-Item $tempDir -Recurse -Force
			Remove-Item $toolsZip -Force
			Write-Host "ADB установлен. Перезапустите скрипт." -ForegroundColor Green
			exit
		} else {
			Write-Host "Выход из программы..." -ForegroundColor Red
			exit
		}
	}
	Write-Host ""
}

function Show-Menu {
	Write-Host "1. Удалить Max" -ForegroundColor Yellow
	Write-Host "2. Проверить наличие Max" -ForegroundColor Yellow
	Write-Host "3. Выход" -ForegroundColor Yellow
	Write-Host ""
}

function Check-Device {
	$devices = & $adbPath devices | Select-String "device$"
	if ($devices.Count -eq 0) {
		Write-Host "Телефон не найден. Подключите устройство по USB и включите отладку." -ForegroundColor Red
		return $false
	}
	return $true
}

function Check-Max {
	param(
		[bool]$IsDebug = $true
	)
	if (-not (Check-Device)) { return $false }

	if ($IsDebug) { Write-Host "Ищу приложение Max..." -ForegroundColor Yellow }

	$packages = & $adbPath shell pm list packages | Select-String $maxPackage

	if ($packages) {
		if ($IsDebug) { Write-Host "Приложение Max найдено!" -ForegroundColor Green 
Start-Sleep -Seconds 2}
		return $true
	} else {
		if ($IsDebug) { Write-Host "Приложение Max не установлено." -ForegroundColor DarkGray
Start-Sleep -Seconds 2}
		return $false
	}
}


function Remove-Max {
	if (-not (Check-Device)) { return }
	Write-Host "Удаление Max..." -ForegroundColor Yellow
	& $adbPath uninstall $maxPackage
	if ($LASTEXITCODE -eq 0) {
		Write-Host "Max успешно удалён." -ForegroundColor Green
	} else {
		Write-Host "Не удалось удалить Max." -ForegroundColor Red
	}
	Start-Sleep -Seconds 2
}

do {
	Show-Banner
	Show-Menu
	$choice = Read-Host "Выберите"

	switch ($choice) {
		"1" {
			Clear-Host
			Show-Banner
			if (Check-Max -IsDebug $false) {
                Remove-Max
            } else {
                Write-Host "Приложение Max не установлено!" -ForegroundColor DarkYellow
                Start-Sleep -Seconds 2
            }

		}
		"2" {
			Clear-Host
			Show-Banner
			Check-Max -IsDebug $true
		}
		"3" {
			Clear-Host
			exit
		}
		Default {
			Write-Host "Неверный выбор." -ForegroundColor Red
			Start-Sleep -Seconds 1.5
		}
	}
} while ($true)
