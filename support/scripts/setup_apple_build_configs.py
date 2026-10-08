#!/usr/bin/env python3
import os
import re
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
app_dir = os.path.join(repo_root, "app")

platform = sys.argv[1] if len(sys.argv) > 1 else "all"

if platform in ("macos", "all"):
    pbx_macos = os.path.join(app_dir, "macos", "Runner.xcodeproj", "project.pbxproj")
    if os.path.exists(pbx_macos):
        with open(pbx_macos, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r'DEVELOPMENT_TEAM = [^;]+;', 'DEVELOPMENT_TEAM = "";', content)
        content = re.sub(r'CODE_SIGN_STYLE = Automatic;', 'CODE_SIGN_STYLE = Manual;', content)
        content = re.sub(r'CODE_SIGN_IDENTITY = [^;]+;', 'CODE_SIGN_IDENTITY = "";', content)
        content = re.sub(r'"CODE_SIGN_IDENTITY\[sdk=macosx\*\]" = [^;]+;', '"CODE_SIGN_IDENTITY[sdk=macosx*]" = "";', content)
        with open(pbx_macos, "w", encoding="utf-8") as f:
            f.write(content)
        print("Updated macOS project.pbxproj")

    xcconfig_macos = os.path.join(app_dir, "macos", "Runner", "Configs", "Release.xcconfig")
    if os.path.exists(xcconfig_macos):
        with open(xcconfig_macos, "a", encoding="utf-8") as f:
            f.write("\nCODE_SIGNING_REQUIRED = NO\nCODE_SIGNING_ALLOWED = NO\nCODE_SIGN_IDENTITY =\nDEVELOPMENT_TEAM =\n")
        print("Updated macOS Release.xcconfig")

if platform in ("ios", "all"):
    pbx_ios = os.path.join(app_dir, "ios", "Runner.xcodeproj", "project.pbxproj")
    if os.path.exists(pbx_ios):
        with open(pbx_ios, "r", encoding="utf-8") as f:
            content = f.read()
        content = re.sub(r'DEVELOPMENT_TEAM = [^;]+;', 'DEVELOPMENT_TEAM = "";', content)
        content = re.sub(r'CODE_SIGN_STYLE = Automatic;', 'CODE_SIGN_STYLE = Manual;', content)
        content = re.sub(r'CODE_SIGN_IDENTITY = [^;]+;', 'CODE_SIGN_IDENTITY = "";', content)
        content = re.sub(r'"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]" = [^;]+;', '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "";', content)
        with open(pbx_ios, "w", encoding="utf-8") as f:
            f.write(content)
        print("Updated iOS project.pbxproj")

    xcconfig_ios = os.path.join(app_dir, "ios", "Flutter", "Release.xcconfig")
    if os.path.exists(xcconfig_ios):
        with open(xcconfig_ios, "a", encoding="utf-8") as f:
            f.write("\nCODE_SIGNING_REQUIRED = NO\nCODE_SIGNING_ALLOWED = NO\nCODE_SIGN_IDENTITY =\nDEVELOPMENT_TEAM =\n")
        print("Updated iOS Release.xcconfig")
