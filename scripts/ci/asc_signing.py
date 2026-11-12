#!/usr/bin/env python3
"""Ephemeral App Store signing for CI.

`setup`   creates a temporary Apple Distribution certificate and App Store
          provisioning profiles through the App Store Connect API, and installs
          them on the runner (certificate in a temporary keychain).
`cleanup` deletes the profiles and the certificate again and removes the keychain.

No device and no stored certificate is needed. Requires an API key with the
Admin role. Environment: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH, RUNNER_TEMP.
"""
import base64
import json
import os
import pathlib
import secrets
import subprocess
import sys
import time

import jwt
import requests

API = "https://api.appstoreconnect.apple.com/v1"
PROFILES = {
    "com.bzrmed.inly": "Inly CI AppStore",
    "com.bzrmed.inly.widgets": "Inly CI Widgets AppStore",
    "com.bzrmed.inly.watchkitapp": "Inly CI Watch AppStore",
    "com.bzrmed.inly.watchkitapp.widgets": "Inly CI Watch Widgets AppStore",
}
WORK = pathlib.Path(os.environ.get("RUNNER_TEMP", "/tmp")) / "signing"
STATE = WORK / "state.json"


def token() -> str:
    key = pathlib.Path(os.environ["ASC_KEY_PATH"]).read_text()
    now = int(time.time())
    return jwt.encode(
        {"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        key,
        algorithm="ES256",
        headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"},
    )


def call(method: str, path: str, ok=(200, 201, 204), **kwargs):
    resp = requests.request(
        method, API + path, headers={"Authorization": "Bearer " + token()}, timeout=60, **kwargs
    )
    if resp.status_code not in ok:
        raise RuntimeError(f"{method} {path} -> {resp.status_code}: {resp.text[:800]}")
    return resp.json() if resp.content else {}


def run(*args: str, **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(args, check=True, text=True, **kwargs)


def purge_leftover_certificates() -> None:
    """Revoke earlier distribution certificates (left over from previous runs).

    Apple allows only one current Distribution certificate for this kind of request, and the
    previous run intentionally leaves its certificate in place so Apple can finish processing.
    Builds that are already uploaded keep working after the certificate is revoked.
    """
    listing = call("GET", "/certificates?filter[certificateType]=DISTRIBUTION&limit=200")
    for cert in listing.get("data", []):
        attrs = cert["attributes"]
        print("Revoking earlier distribution certificate", cert["id"], attrs.get("name"), attrs.get("serialNumber"))
        call("DELETE", f"/certificates/{cert['id']}")


def create_certificate(csr_pem: str) -> dict:
    body = {
        "data": {
            "type": "certificates",
            "attributes": {"certificateType": "DISTRIBUTION", "csrContent": csr_pem},
        }
    }
    return call("POST", "/certificates", json=body)["data"]


def bundle_id_resource(identifier: str) -> str:
    listing = call("GET", f"/bundleIds?filter[identifier]={identifier}&limit=200")
    for item in listing.get("data", []):
        if item["attributes"]["identifier"] == identifier:
            return item["id"]
    # Not registered yet (e.g. the watch app's ID): register it.
    body = {"data": {"type": "bundleIds", "attributes": {
        "identifier": identifier, "name": "Inly " + identifier.rsplit(".", 1)[-1], "platform": "IOS"}}}
    created = call("POST", "/bundleIds", json=body)["data"]
    print("Registered bundle ID", identifier)
    return created["id"]


def delete_profiles_named(name: str) -> None:
    listing = call("GET", f"/profiles?filter[name]={requests.utils.quote(name)}&limit=200")
    for prof in listing.get("data", []):
        print("Deleting old profile", prof["id"], name)
        call("DELETE", f"/profiles/{prof['id']}")


def setup() -> None:
    WORK.mkdir(parents=True, exist_ok=True)
    key_pem, csr_pem, p12 = WORK / "key.pem", WORK / "req.csr", WORK / "cert.p12"

    purge_leftover_certificates()
    run("openssl", "req", "-new", "-newkey", "rsa:2048", "-nodes",
        "-keyout", str(key_pem), "-out", str(csr_pem), "-subj", "/CN=Inly CI/O=Inly/C=US")
    cert = create_certificate(csr_pem.read_text())
    print("Created distribution certificate", cert["id"])
    STATE.write_text(json.dumps({"cert": cert["id"], "profiles": [], "keychain": str(WORK / "ci.keychain-db")}))

    der = WORK / "cert.der"
    der.write_bytes(base64.b64decode(cert["attributes"]["certificateContent"]))
    cert_pem = WORK / "cert.pem"
    run("openssl", "x509", "-inform", "der", "-in", str(der), "-out", str(cert_pem))
    password = secrets.token_hex(16)
    export_cmd = ["openssl", "pkcs12", "-export", "-inkey", str(key_pem), "-in", str(cert_pem),
                  "-out", str(p12), "-passout", f"pass:{password}"]
    try:
        # OpenSSL 3 needs -legacy so macOS `security` can read the file.
        run(*export_cmd, "-legacy")
    except subprocess.CalledProcessError:
        run(*export_cmd)

    keychain = str(WORK / "ci.keychain-db")
    run("security", "create-keychain", "-p", password, keychain)
    run("security", "set-keychain-settings", "-lut", "21600", keychain)
    run("security", "unlock-keychain", "-p", password, keychain)
    run("security", "import", str(p12), "-k", keychain, "-P", password,
        "-T", "/usr/bin/codesign", "-T", "/usr/bin/security")
    run("security", "set-key-partition-list", "-S", "apple-tool:,apple:", "-s", "-k", password, keychain)
    existing = subprocess.run(["security", "list-keychains", "-d", "user"], capture_output=True, text=True).stdout
    current = [line.strip().strip('"') for line in existing.splitlines() if line.strip()]
    run("security", "list-keychains", "-d", "user", "-s", keychain, *current)

    profile_ids = []
    install_dirs = [
        pathlib.Path.home() / "Library/MobileDevice/Provisioning Profiles",
        pathlib.Path.home() / "Library/Developer/Xcode/UserData/Provisioning Profiles",
    ]
    for d in install_dirs:
        d.mkdir(parents=True, exist_ok=True)
    for identifier, name in PROFILES.items():
        delete_profiles_named(name)
        body = {
            "data": {
                "type": "profiles",
                "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
                "relationships": {
                    "bundleId": {"data": {"type": "bundleIds", "id": bundle_id_resource(identifier)}},
                    "certificates": {"data": [{"type": "certificates", "id": cert["id"]}]},
                },
            }
        }
        prof = call("POST", "/profiles", json=body)["data"]
        profile_ids.append(prof["id"])
        content = base64.b64decode(prof["attributes"]["profileContent"])
        for d in install_dirs:
            (d / f"{prof['attributes']['uuid']}.mobileprovision").write_bytes(content)
        print("Installed profile", name, prof["attributes"]["uuid"])

    STATE.write_text(json.dumps({"cert": cert["id"], "profiles": profile_ids, "keychain": keychain}))
    
    run("security", "find-identity", "-v", "-p", "codesigning", keychain)


def cleanup() -> None:
    """Remove the temporary keychain only.

    The certificate and profiles are deliberately NOT revoked here: Apple re-checks the signing
    certificate while it processes the upload (error 90721 "Certificate Revoked" otherwise).
    The next run revokes the leftover certificate in purge_leftover_certificates() and replaces
    same-named profiles.
    """
    if not STATE.exists():
        print("Nothing to clean up.")
        return
    state = json.loads(STATE.read_text())
    subprocess.run(["security", "delete-keychain", state["keychain"]], check=False)
    print("Removed temporary keychain; certificate kept until the next run so Apple can finish processing.")


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in ("setup", "cleanup"):
        sys.exit("usage: asc_signing.py setup|cleanup")
    setup() if sys.argv[1] == "setup" else cleanup()
