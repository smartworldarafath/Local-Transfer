#!/usr/bin/env python3
import os
import sys

# Locate app directory relative to script
script_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(script_dir, "..", ".."))
app_dir = os.path.join(repo_root, "app")

print(f"Repo root: {repo_root}")
print(f"App dir: {app_dir}")

# 1. Remove FOSS lines from pubspec.yaml
pubspec_path = os.path.join(app_dir, "pubspec.yaml")
if os.path.exists(pubspec_path):
    with open(pubspec_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    new_lines = [l for l in lines if "# [FOSS_REMOVE]" not in l]
    with open(pubspec_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print("Cleaned pubspec.yaml")

# 2. Comment out blocks in Dart files
def comment_out_foss(file_path):
    if not os.path.exists(file_path):
        return
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("// [FOSS_REMOVE_START]", "/*")
    content = content.replace("// [FOSS_REMOVE_END]", "*/")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Commented FOSS blocks in {os.path.basename(file_path)}")

comment_out_foss(os.path.join(app_dir, "lib", "config", "init.dart"))
comment_out_foss(os.path.join(app_dir, "lib", "pages", "donation", "donation_page.dart"))
comment_out_foss(os.path.join(app_dir, "lib", "pages", "donation", "donation_page_vm.dart"))

# 3. Swap donationPageVmProvider -> donationPageNoopVmProvider
donation_page_path = os.path.join(app_dir, "lib", "pages", "donation", "donation_page.dart")
if os.path.exists(donation_page_path):
    with open(donation_page_path, "r", encoding="utf-8") as f:
        content = f.read()
    content = content.replace("donationPageVmProvider", "donationPageNoopVmProvider")
    with open(donation_page_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Updated donationPageVmProvider reference")

# 4. Remove purchase_provider.dart
purchase_provider = os.path.join(app_dir, "lib", "provider", "purchase_provider.dart")
if os.path.exists(purchase_provider):
    os.remove(purchase_provider)
    print("Removed purchase_provider.dart")

print("All proprietary dependencies stripped successfully.")
