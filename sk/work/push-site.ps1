$ErrorActionPreference = 'Stop'
$secureInput = Read-Host 'Site publishing credential (hidden)' -AsSecureString
$credentialJson = [System.Net.NetworkCredential]::new('', $secureInput).Password
$siteCredential = $credentialJson | ConvertFrom-Json
$env:SITES_GIT_AUTHORIZATION = 'Authorization: Bearer ' + $siteCredential.token
try {
  $siteRemote = $siteCredential.remote_url
  $existing = & git -c http.sslBackend=openssl -c credential.helper= -c http.extraHeader= -c http.followRedirects=false "--config-env=http.$siteRemote.extraHeader=SITES_GIT_AUTHORIZATION" ls-remote --heads $siteRemote refs/heads/main
  if ($LASTEXITCODE -ne 0) { throw 'Remote source check failed.' }
  if ($existing) { throw 'Remote is not empty; reconcile before pushing.' }
  & git -c http.sslBackend=openssl -c credential.helper= -c http.extraHeader= -c http.followRedirects=false "--config-env=http.$siteRemote.extraHeader=SITES_GIT_AUTHORIZATION" push $siteRemote HEAD:refs/heads/main
  if ($LASTEXITCODE -ne 0) { throw 'Site source upload failed.' }
  & git rev-parse HEAD
} finally { Remove-Item Env:SITES_GIT_AUTHORIZATION; $credentialJson = $null; $siteCredential = $null }

