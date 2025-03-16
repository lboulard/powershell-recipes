## Requirements to verify python binary signed with Sigstore CoSign

- `CoSign` (Container Signing): <tps://github.com/sigstore/cosign>

On Windows, using PowerShell from CMD.EXE, to download last known version (as
writing this document):

```
PowerShell.exe -NoProfile -Command "iwr https://github.com/sigstore/cosign/releases/download/v2.4.3/cosign-windows-amd64.exe -OutFile cosign.exe -UseBasicParsing"
PowerShell.exe -NoProfile -Command "iwr https://github.com/sigstore/cosign/releases/download/v2.4.3/cosign-windows-amd64.exe-keyless.pem -OutFile cosign.exe-keyless.pem -UseBasicParsing"
PowerShell.exe -NoProfile -Command "iwr https://github.com/sigstore/cosign/releases/download/v2.4.3/cosign-windows-amd64.exe-keyless.sig -OutFile cosign.exe-keyless.sig -UseBasicParsing"
```

Replace `PowerShell.exe` with  `pwsh.exe` if you have PowerShell 7 installed
for faster downloads.

Self verify download in CMD.EXE with:

```dosbatch
.\cosign.exe verify-blob cosign.exe^
 --certificate cosign.exe-keyless.pem^
 --signature cosign.exe-keyless.sig^
 --cert-identity "keyless@projectsigstore.iam.gserviceaccount.com"^
 --cert-oidc-issuer "https://accounts.google.com"
```

Output should be like this:

```
Verified OK
```

See [document](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/)
for more information.

Move, or copy `cosign.exe` to a place accessible from `PATH` environment
variable as user. So scripts for Python sigstore verification can work.
