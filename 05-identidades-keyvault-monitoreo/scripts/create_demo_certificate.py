from datetime import datetime, timedelta, timezone
from pathlib import Path
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12

root = Path(__file__).resolve().parents[1] / '.local'
root.mkdir(exist_ok=True)
key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
subject = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,'demo.leadutp.invalid')])
now = datetime.now(timezone.utc)
certificate = (x509.CertificateBuilder().subject_name(subject).issuer_name(subject).public_key(key.public_key()).serial_number(x509.random_serial_number()).not_valid_before(now-timedelta(minutes=5)).not_valid_after(now+timedelta(days=12)).add_extension(x509.BasicConstraints(ca=False,path_length=None),critical=True).sign(key,hashes.SHA256()))
payload = pkcs12.serialize_key_and_certificates(b'leadutp-demo',key,certificate,None,serialization.NoEncryption())
destination = root / 'demo-certificate.pfx'
destination.write_bytes(payload)
print('Certificado autofirmado de demostración generado; vencimiento en 12 días. No apto para producción.')
