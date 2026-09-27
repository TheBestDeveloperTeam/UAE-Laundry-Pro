import os
from PIL import Image

def generate_assets():
    # Source image generated previously
    source_img_path = r"C:\Users\Admin\.gemini\antigravity-ide\brain\cfad22f2-2fdb-4707-920d-21f502b93ca7\laundry_pro_app_icon_1790507595115.jpg"
    
    # Project paths
    project_root = r"e:\Projects\Flutter\UAE-Laundry-Pro"
    windows_icon_path = os.path.join(project_root, "windows", "runner", "resources", "app_icon.ico")
    branding_dir = os.path.join(project_root, "assets", "images", "branding")
    
    if not os.path.exists(branding_dir):
        os.makedirs(branding_dir)

    try:
        with Image.open(source_img_path) as img:
            # Generate ICO with multiple sizes for Windows
            icon_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
            img.save(windows_icon_path, format='ICO', sizes=icon_sizes)
            print(f"Successfully generated: {windows_icon_path}")

            # Generate PNG variants for other uses (web, android, ios icons)
            png_sizes = [32, 64, 128, 256, 512]
            for size in png_sizes:
                resized_img = img.resize((size, size), Image.Resampling.LANCZOS)
                png_path = os.path.join(branding_dir, f"logo_{size}x{size}.png")
                resized_img.save(png_path, format='PNG')
                print(f"Successfully generated: {png_path}")
                
    except Exception as e:
        print(f"Error processing image: {e}")

if __name__ == "__main__":
    generate_assets()
