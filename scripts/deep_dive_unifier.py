import os

def clean_code_files(root_dir, extensions):
    cleaned_count = 0
    for root, dirs, files in os.walk(root_dir):
        if '.git' in root or '.dart_tool' in root:
            continue
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                    
                    cleaned_lines = [line.rstrip() + '\n' for line in lines]
                    # Ensure single trailing newline
                    while len(cleaned_lines) > 0 and cleaned_lines[-1].strip() == "":
                        cleaned_lines.pop()
                    if len(cleaned_lines) > 0:
                        cleaned_lines[-1] = cleaned_lines[-1].rstrip() + '\n'

                    if lines != cleaned_lines:
                        with open(path, 'w', encoding='utf-8') as f:
                            f.writelines(cleaned_lines)
                        cleaned_count += 1
                except Exception as e:
                    print(f"Failed to clean {path}: {e}")
    return cleaned_count

def unify_swagger(docs_dir):
    local_path = os.path.join(docs_dir, 'swagger', 'SWAGGER_LOCAL.yaml')
    cloud_path = os.path.join(docs_dir, 'swagger', 'SWAGGER_CLOUD.yaml')
    unified_path = os.path.join(docs_dir, 'swagger', 'UNIFIED_SWAGGER.yaml')
    
    unified_content = "openapi: 3.0.0\ninfo:\n  title: Unified Laundry Pro API (Local & Cloud)\n  version: 1.0.0\npaths:\n"
    
    for path in [local_path, cloud_path]:
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
                # Extremely basic merging by appending content under paths
                # Real swagger merging is complex, but we append raw data as comments for unification record
                unified_content += f"\n# --- FROM {os.path.basename(path)} ---\n"
                unified_content += content
            os.remove(path)
            
    with open(unified_path, 'w', encoding='utf-8') as f:
        f.write(unified_content)
    print("Swagger unified into UNIFIED_SWAGGER.yaml")

def unify_docs(source_dir, output_file):
    if not os.path.exists(source_dir):
        return
    unified = f"# Unified Documentation: {os.path.basename(source_dir)}\n\n"
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            if file.endswith('.md') and file != os.path.basename(output_file):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        unified += f"\n\n## --- FILE: {file} ---\n\n"
                        unified += f.read()
                    os.remove(path)
                except Exception as e:
                    pass
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(unified)
    print(f"Unified documents into {output_file}")

if __name__ == '__main__':
    base_dir = r"e:\Projects\Flutter\UAE-Laundry-Pro"
    
    # 1. Clean Dart and PHP code
    dart_cleaned = clean_code_files(os.path.join(base_dir, 'lib'), ['.dart'])
    php_cleaned = clean_code_files(base_dir, ['.php'])
    print(f"Cleaned {dart_cleaned} Dart files and {php_cleaned} PHP files (trailing whitespaces, newlines).")
    
    # 2. Unify Swagger
    unify_swagger(os.path.join(base_dir, 'docs'))
    
    # 3. Unify MD and AI logic
    unify_docs(os.path.join(base_dir, '.ai'), os.path.join(base_dir, '.ai', 'UNIFIED_AI_LOGICS.md'))
    unify_docs(os.path.join(base_dir, 'docs'), os.path.join(base_dir, 'docs', 'UNIFIED_DOCUMENTATION.md'))
    
    print("Deep dive unification complete.")
