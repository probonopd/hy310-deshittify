#!/usr/bin/env python3
"""Sign an APK with a v1 (JAR) signature: python3 -I sign.py in.apk out.apk key.pem
Android 11 accepts v1-only for apps that target SDK 28, so no apksigner is needed.
The key (RSA 2048, self-signed) is created if key.pem does not exist; keep it to be able to update the app."""
import base64, datetime, hashlib, os, sys, zipfile
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs7
from cryptography.x509.oid import NameOID

src, dst, keyfile = sys.argv[1:4]
if os.path.exists(keyfile):
    key = serialization.load_pem_private_key(open(keyfile, "rb").read(), None)
else:
    key = rsa.generate_private_key(65537, 2048)
    with open(os.open(keyfile, os.O_WRONLY | os.O_CREAT, 0o600), "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))
name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "hy310-deshittify")])
now = datetime.datetime(2026, 1, 1)
cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
        .serial_number(1).not_valid_before(now).not_valid_after(now + datetime.timedelta(days=36500))
        .sign(key, hashes.SHA256()))

b64 = lambda b: base64.b64encode(b).decode()
zin = zipfile.ZipFile(src)
entries = [(i, zin.read(i.filename)) for i in zin.infolist() if not i.filename.startswith("META-INF/")]
mf = "Manifest-Version: 1.0\r\nCreated-By: hy310-deshittify\r\n\r\n"
sections = {}
for i, data in entries:
    assert len(i.filename) < 55, "manifest line wrapping not implemented"
    sections[i.filename] = f"Name: {i.filename}\r\nSHA-256-Digest: {b64(hashlib.sha256(data).digest())}\r\n\r\n"
    mf += sections[i.filename]
mfb = mf.encode()
sf = f"Signature-Version: 1.0\r\nCreated-By: hy310-deshittify\r\nSHA-256-Digest-Manifest: {b64(hashlib.sha256(mfb).digest())}\r\n\r\n"
for n, sec in sections.items():
    sf += f"Name: {n}\r\nSHA-256-Digest: {b64(hashlib.sha256(sec.encode()).digest())}\r\n\r\n"
sfb = sf.encode()
rsa_blob = (pkcs7.PKCS7SignatureBuilder().set_data(sfb).add_signer(cert, key, hashes.SHA256())
            .sign(serialization.Encoding.DER, [pkcs7.PKCS7Options.DetachedSignature,
                                               pkcs7.PKCS7Options.Binary,
                                               pkcs7.PKCS7Options.NoCapabilities]))
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("META-INF/MANIFEST.MF", mfb)
    z.writestr("META-INF/CERT.SF", sfb)
    z.writestr("META-INF/CERT.RSA", rsa_blob)
    for i, data in entries:
        # resources.arsc must stay uncompressed for apps that target R; harmless for SDK 28
        z.writestr(i, data, zipfile.ZIP_STORED if i.filename == "resources.arsc" else zipfile.ZIP_DEFLATED)
