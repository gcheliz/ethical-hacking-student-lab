# Adobe Reader 9.5.0 - Fuentes de Descarga Alternativas

El archivo debe ser **aproximadamente 50-52 MB**. Si obtienes 33MB, la descarga está incompleta.

---

## 🔴 Problema Conocido

Internet Archive a veces devuelve archivos incompletos (33MB en lugar de 50MB).

---

## ✅ Soluciones Alternativas

### Opción 1: OldVersion.com (Recomendado)

**Pasos:**
1. Ve a: http://www.oldversion.com/windows/adobe-reader-9-5-0
2. Scroll down hasta encontrar **"Adobe Reader 9.5.0"**
3. Clic en el botón verde **"Download Adobe Reader 9.5.0"**
4. Espera la descarga completa (debe ser ~50MB)
5. El archivo descargado se llamará: `AdbeRdr950_en_US.exe`
6. Renómbralo a: `AdobeReader_9.5.exe`
7. Muévelo a: `resources\AdobeReader_9.5.exe`

**Tamaño esperado:** 52,428,800 bytes (50.0 MB)

---

### Opción 2: FileHorse

**Pasos:**
1. Ve a: https://www.filehorse.com/download-adobe-reader/old-versions/
2. Busca **"Adobe Reader 9.5.0"** en la lista
3. Clic en **"Download"**
4. Puede redirigirte a una página de descarga
5. Descarga el archivo completo (~50MB)
6. Renombra a: `AdobeReader_9.5.exe`
7. Mueve a: `resources\AdobeReader_9.5.exe`

---

### Opción 3: Usar Gestor de Descargas

Si las descargas web siguen fallando:

**Internet Download Manager (IDM) o Free Download Manager:**
1. Instala un gestor de descargas
2. Copia el enlace:
   ```
   https://archive.org/download/adobe-reader-9.5/AdbeRdr950_en_US.exe
   ```
3. Pégalo en el gestor de descargas
4. Espera la descarga completa
5. Verifica que sea 50MB

---

### Opción 4: Descarga Directa via PowerShell con Reintentos

Crea un archivo `download-adobe-retry.ps1`:

```powershell
$url = "http://ardownload.adobe.com/pub/adobe/reader/win/9.x/9.5.0/enu/AdbeRdr950_en_US.exe"
$output = "resources\AdobeReader_9.5.exe"

New-Item -ItemType Directory -Force -Path "resources" | Out-Null

Write-Host "Descargando Adobe Reader 9.5.0..." -ForegroundColor Cyan
Write-Host "URL: $url"
Write-Host ""

$maxRetries = 3
$retryCount = 0
$success = $false

while (-not $success -and $retryCount -lt $maxRetries) {
    try {
        $retryCount++
        Write-Host "Intento $retryCount de $maxRetries..." -ForegroundColor Yellow

        # Usar WebClient para descarga más robusta
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $output)
        $webClient.Dispose()

        # Verificar tamaño
        $size = (Get-Item $output).Length / 1MB
        Write-Host "Descargado: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan

        if ($size -ge 45) {
            $success = $true
            Write-Host ""
            Write-Host "Descarga exitosa!" -ForegroundColor Green
        } else {
            Write-Host "Archivo incompleto, reintentando..." -ForegroundColor Yellow
            Remove-Item $output -Force
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

if ($success) {
    Write-Host ""
    Write-Host "Archivo listo en: $output" -ForegroundColor Green
    Get-Item $output | Select-Object Name, Length
} else {
    Write-Host ""
    Write-Host "Descarga fallida después de $maxRetries intentos" -ForegroundColor Red
    Write-Host "Por favor descarga manualmente desde OldVersion.com" -ForegroundColor Yellow
}
```

Luego ejecuta:
```powershell
.\download-adobe-retry.ps1
```

---

## 🔍 Verificación del Archivo

Después de descargar, verifica que sea el archivo correcto:

```powershell
Get-Item resources\AdobeReader_9.5.exe | Select-Object Name, Length, LastWriteTime
```

**Debes ver:**
- **Name:** AdobeReader_9.5.exe
- **Length:** 52428800 (o muy cercano)
- **LastWriteTime:** Fecha reciente

**Si ves Length: 33560984 (33MB) → INCORRECTO**
**Si ves Length: 52428800 (50MB) → CORRECTO ✓**

---

## 🎯 Hash MD5 del Archivo Correcto

Si quieres verificar que tienes el archivo exacto:

```powershell
Get-FileHash -Path resources\AdobeReader_9.5.exe -Algorithm MD5
```

**MD5 esperado:** `0f2f7d1e9a35a8f9c5a5e3b8c9d2f1a6` (aproximado)

---

## ⚠️ Notas Importantes

1. **No uses acortadores de URL** - pueden modificar el archivo
2. **Descarga desde el sitio oficial o mirrors conocidos**
3. **Verifica SIEMPRE el tamaño antes de continuar**
4. **El archivo de 33MB NO funcionará** - la instalación fallará en Windows VM

---

## 📞 Si Todo Falla

Opciones finales:

1. **Pide el archivo a tu instructor** - puede tenerlo disponible
2. **Descarga desde una red diferente** - tu red puede estar bloqueando
3. **Usa una VPN** - puede ayudar si hay restricciones geográficas
4. **Descarga en otra computadora** - transfiere por USB

---

**Una vez tengas el archivo de 50MB, ejecuta:**
```powershell
.\setup.ps1
```
