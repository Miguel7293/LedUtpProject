#!/bin/sh
set -eu
cloud-init status --wait >/dev/null
python3 - <<'PY'
import json
import socket
import urllib.request

with urllib.request.urlopen('http://10.30.2.4', timeout=15) as response:
    data = json.load(response)
assert data['host'] == 'vm02', data
print('HTTP VM01 -> VM02: OK')
for port in (22, 3389):
    try:
        connection = socket.create_connection(('10.30.2.4', port), timeout=4)
    except TimeoutError:
        print(f'TCP {port} VM01 -> VM02: timeout esperado')
    except ConnectionRefusedError:
        raise AssertionError(f'Puerto {port}: rechazo del host; no demuestra filtrado NSG')
    else:
        connection.close()
        raise AssertionError(f'Puerto {port} accesible inesperadamente')
print('LEADUTP_NETWORK_TEST_PASS')
PY
