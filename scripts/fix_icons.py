import os
import re

def fix_icons(lib_path):
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                original_content = content
                
                # Fix malformed PhosphorIcons
                content = content.replace(r"()_outlined", r"()")
                content = content.replace(r"()_outline", r"()")
                content = content.replace(r"()_circle", r"Circle()")
                content = content.replace(r"PhosphorPhosphorIcons.printer()er()", r"PhosphorIcons.printer()")
                
                # Catch remaining common outlined icons from material
                content = re.sub(r"Icons\.([a-zA-Z0-9_]+)_outlined?", r"PhosphorIcons.circle()", content)
                content = re.sub(r"Icons\.([a-zA-Z0-9_]+)", r"PhosphorIcons.circle()", content)

                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Fixed: {filepath}")

if __name__ == "__main__":
    fix_icons(r"e:\Projects\Flutter\UAE-Laundry-Pro\lib")
