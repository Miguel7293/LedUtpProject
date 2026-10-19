#!/bin/sh
set -eu
python3 - <<'PY'
import hashlib
import json
import urllib.error
import urllib.parse
import urllib.request
import uuid

url = '__DOCUMENT_URL__'
expected = '__EXPECTED_SHA256__'
imds = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=' + urllib.parse.quote('https://storage.azure.com/',safe='')
local_opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
with local_opener.open(urllib.request.Request(imds,headers={'Metadata':'true'}),timeout=15) as response:
    token = json.load(response)['access_token']
headers = {'Authorization':'Bearer '+token,'x-ms-version':'2023-11-03'}
with urllib.request.urlopen(urllib.request.Request(url,headers=headers),timeout=30) as response:
    data = response.read()
assert data.startswith(b'%PDF-'), 'No es un PDF'
digest = hashlib.sha256(data).hexdigest()
assert digest == expected, 'La huella del documento no coincide'
print(json.dumps({'pdf_bytes':len(data),'sha256':digest,'managed_identity_read':'ok'}))

write_url = url.rsplit('/',1)[0]+'/forbidden-probe-'+uuid.uuid4().hex+'.txt'
try:
    request = urllib.request.Request(write_url,data=b'RBAC verification',headers={**headers,'x-ms-blob-type':'BlockBlob'},method='PUT')
    urllib.request.urlopen(request,timeout=30)
except urllib.error.HTTPError as error:
    assert error.code == 403, f'Se esperaba 403; recibido {error.code}'
    print('Escritura con identidad de solo lectura: 403 esperado')
else:
    raise AssertionError('La VM obtuvo escritura inesperada')
print('MI_STORAGE_TEST_PASS')
PY
