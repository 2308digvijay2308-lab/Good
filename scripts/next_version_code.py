#!/usr/bin/env python3
"""PROJECT JARVIS — fetch the highest versionCode already on Google Play.

Queries the Play Developer API and prints the largest versionCode currently
uploaded across all release tracks. Used to auto-increment the next build so
Play never rejects it with "versionCode already used".

Usage:
    export SERVICE_ACCOUNT_JSON="$(cat service-account.json)"
    python3 scripts/next_version_code.py com.example.project_jarvis
    # prints e.g. 47

Requires the google-api-python-client + google-auth packages.
"""
import json
import os
import sys

from google.auth.transport.requests import Request
from google.oauth2 import service_account
from googleapiclient.discovery import build

PACKAGE = sys.argv[1] if len(sys.argv) > 1 else "com.example.project_jarvis"


def get_max_version_code(package):
    creds_raw = os.environ.get("SERVICE_ACCOUNT_JSON")
    if not creds_raw:
        return None
    info = json.loads(creds_raw)
    creds = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/androidpublisher"]
    )
    creds.refresh(Request())
    service = build("androidpublisher", "v3", credentials=creds, cache_discovery=False)

    # Create an edit (tracks are read from it).
    edit = service.edits().insert(body={}, packageName=package).execute()
    edit_id = edit["id"]

    max_code = 0
    tracks = service.edits().tracks().list(
        packageName=package, editId=edit_id
    ).execute()
    for track in tracks.get("tracks", []):
        for release in track.get("releases", []):
            for code in release.get("versionCodes", []):
                max_code = max(max_code, int(code))
    return max_code


if __name__ == "__main__":
    result = get_max_version_code(PACKAGE)
    if result is None:
        print("NO_PLAY_ACCESS", file=sys.stderr)
        sys.exit(1)
    print(result)
