[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls13
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$SupabaseUrl = "https://frtbijfiigifncnlkqqy.supabase.co/rest/v1/licencias"
$SupabaseKey = "sb_publishable_9MfTGldlzk9yBzgA4rTe-A_J6uFENTy"

function Verificar-LicenciaNube([string]$licenciaIngresada) {$urlApi = "$SupabaseUrl?clave_licencia=eq.$licenciaIngresada&select=*"
    $headers = @{
        "apikey" = $SupabaseKey
        "Authorization" = "Bearer $SupabaseKey"
    }

    try {
        $respuesta = Invoke-RestMethod -Uri $urlApi -Headers$headers -Method Get
        if ($respuesta) {$reg = if ($respuesta -is [array]) {$respuesta[0] } else { $respuesta }$fechaExpiracion = [DateTime]$reg.fecha_expiracion$fechaActual = Get-Date

            if ($reg.activa -eq$true -and $fechaActual -lt$fechaExpiracion) {
                return $true
            } else {
                [System.Windows.Forms.MessageBox]::Show("Tu licencia ha expirado o fue desactivada.", "Expirado", 0, 48)
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("La licencia ingresada no existe.", "Error", 0, 16)
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Error de conexión al verificar la licencia en la nube.", "Red", 0, 16)
    }
    return $false
}

# ================= VENTANA DE LOGIN =================
$formLogin = New-Object System.Windows.Forms.Form
$formLogin.Text = "Licencia - TotalPlay"
$formLogin.Size = New-Object System.Drawing.Size(320, 180)$formLogin.StartPosition = "CenterScreen"
$formLogin.BackColor = "#121212"
$formLogin.ForeColor = "#ffffff"
$formLogin.FormBorderStyle = "FixedDialog"
$formLogin.MaximizeBox =$false

$lblLic = New-Object System.Windows.Forms.Label
$lblLic.Text = "Ingresa tu Clave de Licencia:"
$lblLic.Location = New-Object System.Drawing.Point(20, 20)
$lblLic.AutoSize =$true

$txtLic = New-Object System.Windows.Forms.TextBox
$txtLic.Location = New-Object System.Drawing.Point(20, 45)$txtLic.Size = New-Object System.Drawing.Size(260, 25)

$btnEntrar = New-Object System.Windows.Forms.Button
$btnEntrar.Text = "Verificar Licencia"
$btnEntrar.Location = New-Object System.Drawing.Point(20, 80)
$btnEntrar.Size = New-Object System.Drawing.Size(260, 35)$btnEntrar.BackColor = "#00b3b3"
$btnEntrar.FlatStyle = "Flat"

$accesoConcedido = $false$btnEntrar.Add_Click({
    $intento =$txtLic.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($intento)) {
        if (Verificar-LicenciaNube $intento) {$script:accesoConcedido = $true$formLogin.Close()
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Escribe una licencia.", "Aviso", 0, 48)
    }
})

$formLogin.Controls.AddRange(@($lblLic,$txtLic, $btnEntrar))$formLogin.ShowDialog() | Out-Null

if (-not $accesoConcedido) { exit }

# ================= PANEL PRINCIPAL DE AUTO PING =================
$ArchivoEnc = "$env:APPDATA\portal_tp_url.enc"
$global:JobPing =$null

function Mostrar-Banner {
    Clear-Host
    Write-Host @"
    ____  ____  _____ ______   ___ ___     ___ ___   ___  ____   __ __ 
  /    |/    ||     |      | / _]   \   |   |   | /  _]|    \ |  |  |
 |  o  |  o  ||  __|      |/ [_|   /   | _   _ | /  [_ |  _  ||  |  |
 |     |     ||  |_ |_|  |_||   _]  D  | |   \_/ ||   _]|  |  ||  |  |
 |  _  |  _  ||  _]  |  |  |   [_|   _| |   |   ||   [_ |  |  ||  :  |
 |  |  |  |  ||  |    |  |  |     |   _| |   |   ||      ||  |  ||     |
 |__|__|__|__||__|    |__|  |_____|_____| |___|___||_____||__|__|\__,_|
               /\____/\   [ TOTALPLAY AUTO PING ]
              /  o   o  \  -----------------------
             ( ==  ^  == )  1. Iniciar / Configurar Auto Ping
              )       (     2. Exit (Salir)
             (         )
            ( (  )   (  ) )
           (__(__)___(__)__)
"@ -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor DarkGray
}

function Guardar-UrlCifrada {
    param([string]$urlTexto)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($urlTexto.Trim())
    $encoded = [Convert]::ToBase64String($bytes)
    Set-Content -Path $ArchivoEnc -Value$encoded -Force
}

function Leer-UrlCifrada {
    if (Test-Path $ArchivoEnc) {
        try {
            $encoded = Get-Content -Path$ArchivoEnc -ErrorAction Stop
            $bytes = [Convert]::FromBase64String($encoded)
            return [System.Text.Encoding]::UTF8.GetString($bytes)
        } catch {
            return $null
        }
    }
    return $null
}

function Menu-TotalPlay {
    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "         AUTO PING TOTALPLAY (LICENCIADO)                 " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    $urlPrevia = Leer-UrlCifrada$urlFinal = ""

    if ($urlPrevia) {
        Write-Host "`n[+] Se detectó una URL guardada previamente." -ForegroundColor Green
        $resp = Read-Host "¿Deseas usar la URL guardada? (Enter = Sí / N = Pegar nueva URL)"
        if ($resp -match "^[nN]") {
            $urlFinal = Read-Host "Pega aquí la URL completa del portal"
            if (-not [string]::IsNullOrWhiteSpace($urlFinal)) {
                Guardar-UrlCifrada -urlTexto $urlFinal
            }
        } else {
            $urlFinal = $urlPrevia
        }
    } else {
        $urlFinal = Read-Host "`nPega aquí la URL completa del portal"
        if (-not [string]::IsNullOrWhiteSpace($urlFinal)) {
            Guardar-UrlCifrada -urlTexto $urlFinal
        }
    }

    if ([string]::IsNullOrWhiteSpace($urlFinal)) {
        Write-Host "[!] No se ingresó ninguna URL válida. Regresando al menú..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }

    Write-Host "`nSelecciona cómo quieres ejecutar el Auto Ping:" -ForegroundColor Yellow
    Write-Host "  [1] En pantalla (Ver consola diciendo 'Activo' cada segundo; presiona 'Q' para volver al menú)"
    Write-Host "  [2] En segundo plano (Sigue corriendo mientras usas el menú)"
    $modo = Read-Host "Elige (1 o 2)"

    if ($modo -eq "2") {
        if ($global:JobPing) { Stop-Job $global:JobPing -ErrorAction SilentlyContinue; Remove-Job $global:JobPing -Force -ErrorAction SilentlyContinue }
        $global:JobPing = Start-Job -ScriptBlock {
            param($u)
            while ($true) {
                try { Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 3 | Out-Null } catch {}
                Start-Sleep -Seconds 1
            }
        } -ArgumentList $urlFinal
        Write-Host "`n[+] Auto Ping corriendo en segundo plano." -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host "`n--- Consola Limpia (Presiona la tecla 'Q' para detener y volver al menú) ---" -ForegroundColor Cyan
        while ($true) {
            if ([Console]::KeyAvailable) {
                $tecla = [Console]::ReadKey($true)
                if ($tecla.Key -eq "Q" -or $tecla.KeyChar -eq 'q') {
                    Write-Host "`n[!] Auto Ping detenido. Regresando al menú..." -ForegroundColor Yellow
                    break
                }
            }
            try {
                Invoke-WebRequest -Uri $urlFinal -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop | Out-Null
                Write-Host "Activo" -ForegroundColor Green
            } catch {}
            Start-Sleep -Seconds 1
        }
        Start-Sleep -Seconds 1
    }
}

do {
    Mostrar-Banner
    if ($global:JobPing -and$global:JobPing.State -eq "Running") {
        Write-Host " [Estado TotalPlay: ACTIVO EN SEGUNDO PLANO]" -ForegroundColor Green
    }
    $opcion = Read-Host "`nSelecciona una opción (1-2)"

    switch ($opcion) {
        "1" { Menu-TotalPlay }
        "2" {
            if ($global:JobPing) {
                Stop-Job $global:JobPing -ErrorAction SilentlyContinue
                Remove-Job $global:JobPing -Force -ErrorAction SilentlyContinue
            }
            Write-Host "`nSaliendo del panel... ¡Hasta luego!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            break
        }
        default {
            Write-Host "Opción no válida, elige 1 o 2." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($opcion -ne "2")
