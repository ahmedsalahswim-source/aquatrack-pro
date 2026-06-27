import os
import json
import time

try:
    import PyPDF2
except ImportError:
    print("PyPDF2 is not installed. Please install it.")
    exit(1)

has_ocr = False
try:
    from pdf2image import convert_from_path
    import pytesseract
    has_ocr = True
except ImportError:
    print("pdf2image or pytesseract not available. OCR will be skipped.")

def extract_text_pypdf2(pdf_path):
    text = ""
    try:
        reader = PyPDF2.PdfReader(pdf_path)
        for page in reader.pages:
            t = page.extract_text()
            if t:
                text += t + "\n\n"
    except Exception as e:
        print(f"  [Error] PyPDF2 failed: {e}")
    return text.strip()

def extract_text_ocr(pdf_path):
    if not has_ocr:
        print("  [OCR] Skipped (dependencies not installed)")
        return ""
        
    print("  [OCR] Falling back to OCR...")
    text = ""
    try:
        images = convert_from_path(pdf_path)
        for i, img in enumerate(images):
            text += pytesseract.image_to_string(img) + "\n\n"
            if (i + 1) % 50 == 0:
                print(f"  [OCR] Processed {i+1}/{len(images)} pages...")
    except Exception as e:
        print(f"  [Error] OCR failed: {e}")
    return text.strip()

def process_books():
    manifest_path = "assets/knowledge_base/manifest.json"
    books_dir = "assets/knowledge_base/books"
    
    with open(manifest_path, 'r', encoding='utf-8') as f:
        manifest = json.load(f)
        
    books = manifest.get("books", [])
    total = len(books)
    
    print(f"Found {total} books in manifest.")
    
    new_books = []
    
    for i, book in enumerate(books):
        file_name = book.get("file", "")
        title = book.get("title", "")
        
        if file_name.endswith(".txt"):
            print(f"[{i+1}/{total}] Skipping {file_name} (already TXT)")
            new_books.append(book)
            continue
            
        pdf_path = os.path.join(books_dir, file_name)
        txt_filename = file_name.replace(".pdf", ".txt")
        txt_path = os.path.join(books_dir, txt_filename)
        
        if not os.path.exists(pdf_path):
            print(f"[{i+1}/{total}] Skipping {file_name} (Not found)")
            new_books.append(book)
            continue
            
        if os.path.exists(txt_path):
            print(f"[{i+1}/{total}] Skipping {file_name} (TXT already exists)")
            new_book = book.copy()
            new_book["file"] = txt_filename
            new_books.append(new_book)
            continue
            
        print(f"\n[{i+1}/{total}] Processing {file_name} ({title})...")
        
        # Try fast extraction
        text = extract_text_pypdf2(pdf_path)
        
        # If text is too short or looks like gibberish, use OCR
        if len(text) < 1000:  
            text = extract_text_ocr(pdf_path)
            
        if len(text) > 500:
            with open(txt_path, 'w', encoding='utf-8') as f:
                f.write(text)
            print(f"  [Success] Saved {txt_filename} ({len(text)} chars)")
            
            new_book = book.copy()
            new_book["file"] = txt_filename
            new_books.append(new_book)
        else:
            print(f"  [Failed] Could not extract sufficient text from {file_name}")
            new_books.append(book)
            
    # Update manifest
    manifest["books"] = new_books
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=4, ensure_ascii=False)
        
    print("\nManifest updated to point to .txt files!")

if __name__ == "__main__":
    process_books()
