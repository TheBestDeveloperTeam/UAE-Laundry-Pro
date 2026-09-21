import os
import re
import json

def audit_l10n():
    print("--- Auditing Localization Keys ---")
    try:
        with open('assets/lang/en.json', 'r', encoding='utf-8') as f:
            en_keys = set(json.load(f).keys())
    except Exception as e:
        print(f"Error reading en.json: {e}")
        return

    used_keys = set()
    views_dir = 'lib/views'
    for root, dirs, files in os.walk(views_dir):
        for file in files:
            if file.endswith('.dart'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    content = f.read()
                    keys = re.findall(r"(?:l10n|context\.l10n)\.t\(['\"]([^'\"]+)['\"]\)", content)
                    used_keys.update(keys)

    missing = used_keys - en_keys
    if missing:
        print(f"Found {len(missing)} missing localization keys in UI:")
        for k in missing:
            print(f"  - {k}")
    else:
        print("All localization keys are valid.")

def audit_json_parsing():
    print("\n--- Auditing JSON Parsing Risks ---")
    models_dir = 'lib/models'
    risks = []
    for root, dirs, files in os.walk(models_dir):
        for file in files:
            if file.endswith('.dart'):
                with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    for i, line in enumerate(lines):
                        if 'as double' in line and 'num?' not in line:
                            risks.append(f"{file}:{i+1}: Direct 'as double' cast (use num? instead for safety): {line.strip()}")
                        if 'as int' in line and 'num?' not in line:
                            risks.append(f"{file}:{i+1}: Direct 'as int' cast (use num? or check for String first): {line.strip()}")
                        if 'parse' in line and 'tryParse' not in line:
                            risks.append(f"{file}:{i+1}: Using parse instead of tryParse: {line.strip()}")
    if risks:
        for r in risks:
            print(r)
    else:
        print("No immediate parsing risks found.")

if __name__ == '__main__':
    audit_l10n()
    audit_json_parsing()
