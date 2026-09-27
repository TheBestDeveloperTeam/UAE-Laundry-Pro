import os
import re

# Mapping of common Material Icons to Phosphor Icons
ICON_MAP = {
    r"Icons\.add": "PhosphorIcons.plus()",
    r"Icons\.refresh": "PhosphorIcons.arrowsClockwise()",
    r"Icons\.sync": "PhosphorIcons.arrowsClockwise()",
    r"Icons\.search": "PhosphorIcons.magnifyingGlass()",
    r"Icons\.settings": "PhosphorIcons.gear()",
    r"Icons\.print": "PhosphorIcons.printer()",
    r"Icons\.delete_outline": "PhosphorIcons.trash()",
    r"Icons\.delete": "PhosphorIcons.trash()",
    r"Icons\.edit": "PhosphorIcons.pencil()",
    r"Icons\.close": "PhosphorIcons.x()",
    r"Icons\.person": "PhosphorIcons.user()",
    r"Icons\.check": "PhosphorIcons.check()",
    r"Icons\.download": "PhosphorIcons.download()",
    r"Icons\.computer": "PhosphorIcons.desktop()",
    r"Icons\.folder_outlined": "PhosphorIcons.folder()",
    r"Icons\.security_outlined": "PhosphorIcons.shieldCheck()",
    r"Icons\.chevron_right": "PhosphorIcons.caretRight()",
    r"Icons\.inventory_2": "PhosphorIcons.package()",
    r"Icons\.receipt_long": "PhosphorIcons.receipt()",
    r"Icons\.error_outline": "PhosphorIcons.warningCircle()",
    r"Icons\.warning_amber_rounded": "PhosphorIcons.warning()",
    r"Icons\.add_circle_outline": "PhosphorIcons.plusCircle()",
    r"Icons\.remove_circle_outline": "PhosphorIcons.minusCircle()",
    r"Icons\.local_laundry_service": "PhosphorIcons.washingMachine()",
    r"Icons\.shopping_bag_outlined": "PhosphorIcons.tote()",
    r"Icons\.dashboard": "PhosphorIcons.squaresFour()",
    r"Icons\.qr_code_scanner": "PhosphorIcons.qrCode()",
    r"Icons\.sensors": "PhosphorIcons.wifiHigh()",
    r"Icons\.more_horiz": "PhosphorIcons.dotsThree()",
    r"Icons\.arrow_forward": "PhosphorIcons.arrowRight()",
    r"Icons\.tune": "PhosphorIcons.slidersHorizontal()",
    r"Icons\.clear": "PhosphorIcons.x()",
    r"Icons\.search_off_rounded": "PhosphorIcons.magnifyingGlassMinus()",
    r"Icons\.inbox_outlined": "PhosphorIcons.tray()",
    r"Icons\.picture_as_pdf": "PhosphorIcons.filePdf()",
    r"Icons\.table_chart_outlined": "PhosphorIcons.table()",
    r"Icons\.cloud_upload_outlined": "PhosphorIcons.cloudArrowUp()",
    r"Icons\.devices": "PhosphorIcons.devices()",
    r"Icons\.view_list": "PhosphorIcons.list()",
    r"Icons\.view_kanban": "PhosphorIcons.kanban()",
}

def migrate_icons(lib_path):
    updated_files = 0
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                original_content = content
                
                # Check if we need to replace any icons
                replaced_any = False
                for mat_icon, phos_icon in ICON_MAP.items():
                    if re.search(mat_icon, content):
                        # PhosphorIcons uses Icon(PhosphorIcons.plus()) not Icon(Icons.add)
                        # Remove 'const' if it precedes Icon(Icons...) because PhosphorIcons calls are not const
                        # regex to catch 'const Icon(Icons.add)'
                        pattern = r"const\s+Icon\(" + mat_icon
                        content = re.sub(pattern, f"Icon({phos_icon}", content)
                        
                        # Catch normal Icon(Icons.add)
                        pattern2 = r"Icon\(" + mat_icon
                        content = re.sub(pattern2, f"Icon({phos_icon}", content)
                        
                        # Catch standalone Icons.add without Icon() wrapper
                        content = re.sub(mat_icon, phos_icon, content)
                        
                        replaced_any = True

                if replaced_any:
                    # Ensure phosphor_flutter is imported
                    if "import 'package:phosphor_flutter/phosphor_flutter.dart';" not in content:
                        import_stmt = "import 'package:phosphor_flutter/phosphor_flutter.dart';\n"
                        # Insert after material.dart import
                        content = re.sub(r"(import 'package:flutter/material\.dart';\n)", r"\1" + import_stmt, content)
                    
                    if content != original_content:
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(content)
                        updated_files += 1
                        print(f"Migrated: {filepath}")

    print(f"Migration complete. Updated {updated_files} files.")

if __name__ == "__main__":
    migrate_icons(r"e:\Projects\Flutter\UAE-Laundry-Pro\lib")
