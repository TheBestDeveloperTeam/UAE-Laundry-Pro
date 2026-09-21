import os
import re

def refactor_models():
    models_dir = 'lib/models'
    
    replacements = [
        # DateTime.parse(json['field'] as String) or DateTime.parse(json["field"] as String)
        (r"DateTime\.parse\(\s*json\['(.*?)'\]\s*as\s*String\s*\)", r"SafeParser.parseDateTime(json['\1'])"),
        (r'DateTime\.parse\(\s*json\["(.*?)"\]\s*as\s*String\s*\)', r'SafeParser.parseDateTime(json["\1"])'),
        
        # as int? ?? 0
        (r"json\['(.*?)'\]\s*as\s*int\?\s*\?\?\s*(\d+)", r"SafeParser.parseInt(json['\1'], \2)"),
        (r'json\["(.*?)"\]\s*as\s*int\?\s*\?\?\s*(\d+)', r'SafeParser.parseInt(json["\1"], \2)'),
        
        # as int?
        (r"json\['(.*?)'\]\s*as\s*int\?", r"SafeParser.parseInt(json['\1']) == 0 ? null : SafeParser.parseInt(json['\1'])"),
        
        # as int
        (r"json\['(.*?)'\]\s*as\s*int", r"SafeParser.parseInt(json['\1'])"),
        (r'json\["(.*?)"\]\s*as\s*int', r'SafeParser.parseInt(json["\1"])'),
        
        # as double? ?? 0.0
        (r"json\['(.*?)'\]\s*as\s*double\?\s*\?\?\s*([\d.]+)", r"SafeParser.parseDouble(json['\1'], \2)"),
        (r'json\["(.*?)"\]\s*as\s*double\?\s*\?\?\s*([\d.]+)', r'SafeParser.parseDouble(json["\1"], \2)'),
        
        # as double?
        (r"json\['(.*?)'\]\s*as\s*double\?", r"SafeParser.parseDouble(json['\1']) == 0.0 ? null : SafeParser.parseDouble(json['\1'])"),
        
        # as double
        (r"json\['(.*?)'\]\s*as\s*double", r"SafeParser.parseDouble(json['\1'])"),
        (r'json\["(.*?)"\]\s*as\s*double', r'SafeParser.parseDouble(json["\1"])'),
    ]

    for root, dirs, files in os.walk(models_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()

                original_content = content
                
                for pattern, repl in replacements:
                    content = re.sub(pattern, repl, content)
                
                # If changed, ensure import is present
                if content != original_content:
                    if 'SafeParser' in content and 'safe_parser.dart' not in content:
                        # Find the last import and insert after it
                        import_pattern = r"(import\s+['\"].*?['\"];\n)"
                        imports = list(re.finditer(import_pattern, content))
                        if imports:
                            last_import = imports[-1]
                            insert_pos = last_import.end()
                            content = content[:insert_pos] + "import 'package:laundrypro_uae/core/safe_parser.dart';\n" + content[insert_pos:]
                        else:
                            content = "import 'package:laundrypro_uae/core/safe_parser.dart';\n\n" + content

                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Refactored {file}")

if __name__ == '__main__':
    refactor_models()
