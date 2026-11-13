"""Uploads the App Store texts and screenshots in docs/appstore/ to the editable app version.

Env: ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH. Safe to run again: texts are overwritten and
screenshot sets are emptied before uploading.
"""
import hashlib
import os
import pathlib
import sys
import time

import jwt
import requests

API = "https://api.appstoreconnect.apple.com/v1"
ROOT = pathlib.Path(__file__).resolve().parents[2] / "docs" / "appstore"
BUNDLE_ID = "com.bzrmed.inly"
LOCALES = {"en-GB": "en", "en-US": "en", "fr-FR": "fr", "es-ES": "es", "ar-SA": "ar"}
# 6.9" iPhone screenshots are 1320x2868; Apple Watch Ultra 3 captures are 422x514.
IPHONE_TYPES = ["APP_IPHONE_67"]
WATCH_TYPES = ["APP_WATCH_ULTRA"]
problems: list[str] = []


def token() -> str:
    key = pathlib.Path(os.environ["ASC_KEY_PATH"]).read_text()
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


def call(method, path, ok=(200, 201, 204), **kw):
    url = path if path.startswith("http") else API + path
    r = requests.request(method, url, headers={"Authorization": f"Bearer {token()}"}, timeout=120, **kw)
    if r.status_code not in ok:
        raise RuntimeError(f"{method} {path} -> {r.status_code}: {r.text[:800]}")
    return r.json() if r.text else {}


def read(loc, name):
    p = ROOT / loc / name
    return p.read_text().strip() if p.exists() else None


def main():
    app = call("GET", f"/apps?filter[bundleId]={BUNDLE_ID}")["data"][0]
    app_id = app["id"]
    print("App", app_id, app["attributes"].get("name"))

    # Editable version (create 1.0 if none).
    versions = call("GET", f"/apps/{app_id}/appStoreVersions?filter[platform]=IOS&limit=10")["data"]
    editable = [v for v in versions if v["attributes"]["appStoreState"] in
                ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY")]
    if editable:
        version = editable[0]
    else:
        version = call("POST", "/appStoreVersions", json={"data": {"type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": "1.0"},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}})["data"]
    vid = version["id"]
    print("Version", version["attributes"]["versionString"], version["attributes"]["appStoreState"])

    # App info (name, subtitle, privacy URL) on the editable app info.
    infos = call("GET", f"/apps/{app_id}/appInfos")["data"]
    info = next((i for i in infos if i["attributes"].get("appStoreState") in (None, "PREPARE_FOR_SUBMISSION")
                 or i["attributes"].get("state") in ("PREPARE_FOR_SUBMISSION", None)), infos[0])
    info_locs = {l["attributes"]["locale"]: l for l in call("GET", f"/appInfos/{info['id']}/appInfoLocalizations?limit=50")["data"]}
    for loc in LOCALES:
        attrs = {"name": read(loc, "name.txt"), "subtitle": read(loc, "subtitle.txt"), "privacyPolicyUrl": read(loc, "privacy_url.txt")}
        try:
            if loc in info_locs:
                call("PATCH", f"/appInfoLocalizations/{info_locs[loc]['id']}",
                     json={"data": {"type": "appInfoLocalizations", "id": info_locs[loc]["id"], "attributes": attrs}})
            else:
                call("POST", "/appInfoLocalizations", json={"data": {"type": "appInfoLocalizations",
                     "attributes": {"locale": loc, **attrs},
                     "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info["id"]}}}}})
            print("App info", loc, "ok")
        except RuntimeError as e:
            problems.append(f"App info {loc}: {e}")

    # Version texts.
    v_locs = {l["attributes"]["locale"]: l for l in call("GET", f"/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")["data"]}
    for loc in LOCALES:
        attrs = {"description": read(loc, "description.txt"), "keywords": read(loc, "keywords.txt"),
                 "promotionalText": read(loc, "promotional_text.txt"), "supportUrl": read(loc, "support_url.txt"),
                 "marketingUrl": read(loc, "marketing_url.txt")}
        try:
            if loc in v_locs:
                call("PATCH", f"/appStoreVersionLocalizations/{v_locs[loc]['id']}",
                     json={"data": {"type": "appStoreVersionLocalizations", "id": v_locs[loc]["id"], "attributes": attrs}})
            else:
                v_locs[loc] = call("POST", "/appStoreVersionLocalizations", json={"data": {"type": "appStoreVersionLocalizations",
                     "attributes": {"locale": loc, **attrs},
                     "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})["data"]
            print("Texts", loc, "ok")
        except RuntimeError as e:
            problems.append(f"Texts {loc}: {e}")

    # Screenshots.
    for loc, short in LOCALES.items():
        if loc not in v_locs:
            continue
        lid = v_locs[loc]["id"]
        folder = ROOT / "screenshots" / short
        upload_set(lid, IPHONE_TYPES, sorted(folder.glob("iphone-*.png")), loc, "iPhone")
        upload_set(lid, WATCH_TYPES, sorted(folder.glob("watch-*.png")), loc, "Watch")

    print()
    if problems:
        print("Finished with problems:")
        for p in problems:
            print(" -", p)
        sys.exit(1)
    print("All uploaded.")


def upload_set(lid, types, files, loc, label):
    if not files:
        return
    sets = {s["attributes"]["screenshotDisplayType"]: s for s in
            call("GET", f"/appStoreVersionLocalizations/{lid}/appScreenshotSets?limit=50")["data"]}
    last_error = None
    for display_type in types:
        try:
            if display_type in sets:
                sid = sets[display_type]["id"]
                for shot in call("GET", f"/appScreenshotSets/{sid}/appScreenshots?limit=50")["data"]:
                    call("DELETE", f"/appScreenshots/{shot['id']}")
            else:
                sid = call("POST", "/appScreenshotSets", json={"data": {"type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": display_type},
                    "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": lid}}}}})["data"]["id"]
            for f in files:
                upload_one(sid, f)
            print(label, loc, display_type, len(files), "uploaded")
            return
        except RuntimeError as e:
            last_error = e
    problems.append(f"{label} screenshots {loc}: {last_error}")


def upload_one(set_id, path: pathlib.Path):
    data = path.read_bytes()
    shot = call("POST", "/appScreenshots", json={"data": {"type": "appScreenshots",
        "attributes": {"fileName": path.name, "fileSize": len(data)},
        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in shot["attributes"]["uploadOperations"]:
        chunk = data[op["offset"]: op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        r = requests.request(op["method"], op["url"], headers=headers, data=chunk, timeout=120)
        if r.status_code >= 300:
            raise RuntimeError(f"upload {path.name}: {r.status_code} {r.text[:300]}")
    call("PATCH", f"/appScreenshots/{shot['id']}", json={"data": {"type": "appScreenshots", "id": shot["id"],
        "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    # Wait until Apple has processed the image.
    for _ in range(30):
        state = call("GET", f"/appScreenshots/{shot['id']}")["data"]["attributes"].get("assetDeliveryState", {}).get("state")
        if state in ("COMPLETE", "FAILED"):
            if state == "FAILED":
                raise RuntimeError(f"{path.name} rejected by App Store Connect")
            return
        time.sleep(2)


if __name__ == "__main__":
    main()
