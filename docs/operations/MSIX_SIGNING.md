# MSIX code signing

Production desktop delivery uses a **signed** MSIX for SmartScreen trust on Windows 10/11.

## Certificate

- Use an **OV or EV** code signing certificate from your CA.
- Store the `.pfx` outside the repository.

## Build

```powershell
$env:LAUNDRYPRO_MSIX_CERT_PATH = "D:\certs\laundrypro_codesign.pfx"
$env:LAUNDRYPRO_MSIX_CERT_PASSWORD = "<from secure vault>"

.\scripts\build_prod.ps1 `
  -BuildMsix `
  -ApiBaseUrl "https://laundrypro-api/api/v1" `
  -CloudApiBaseUrl "https://CLOUD_DOMAIN/api/v1" `
  -CertificatePath $env:LAUNDRYPRO_MSIX_CERT_PATH `
  -CertificatePassword $env:LAUNDRYPRO_MSIX_CERT_PASSWORD
```

Or sign only:

```powershell
.\scripts\build_msix.ps1 -CertificatePath ... -CertificatePassword ...
```

## VM smoke test (required before pilot)

1. Fresh Windows VM, no developer mode.
2. Install MSIX from `build/prod_release/<version>/`.
3. Launch app → setup → license → test sale → sync.

## pubspec.yaml

`msix_config` in [`pubspec.yaml`](../../pubspec.yaml) holds display metadata. Certificate paths are passed at build time via script/env — **not** committed to git.
