import os
import json
import PyPDF2
from pathlib import Path

# Paths
INPUT_DIR = Path(r"E:\fitness")
OUTPUT_DIR = Path(r"C:\Users\ِAhmed\Desktop\AquaTrack Pro\assets\knowledge_base\books")
MANIFEST_PATH = Path(r"C:\Users\ِAhmed\Desktop\AquaTrack Pro\assets\knowledge_base\manifest.json")

def extract_text_from_pdf(pdf_path):
    text = ""
    try:
        with open(pdf_path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            for page in reader.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
    except Exception as e:
        print(f"Failed to read {pdf_path}: {e}")
    return text

def process_pdfs():
    if not OUTPUT_DIR.exists():
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    new_books = []
    
    # Process PDF files in E:\fitness
    if not INPUT_DIR.exists():
        print(f"Directory not found: {INPUT_DIR}")
        return

    for filename in os.listdir(INPUT_DIR):
        if filename.lower().endswith(".pdf"):
            pdf_path = INPUT_DIR / filename
            output_filename = filename.replace('.pdf', '.txt')
            output_path = OUTPUT_DIR / output_filename
            
            print(f"Processing: {filename}...")
            extracted_text = extract_text_from_pdf(pdf_path)
            
            if extracted_text.strip():
                with open(output_path, "w", encoding="utf-8") as text_file:
                    text_file.write(extracted_text)
                print(f"Saved to {output_filename}")
                
                # Prepare manifest entry
                new_books.append({
                    "id": filename.replace('.pdf', '').replace(' ', '_').lower(),
                    "title": filename.replace('.pdf', ''),
                    "author": "Unknown",
                    "category": "fitness_and_anatomy",
                    "type": "book",
                    "path": f"assets/knowledge_base/books/{output_filename}"
                })
            else:
                print(f"Warning: No text extracted from {filename}")
                
    # Update Manifest
    if new_books:
        manifest_data = {"books": []}
        if MANIFEST_PATH.exists():
            with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
                manifest_data = json.load(f)
        
        # Avoid duplicates
        existing_paths = [b.get("path") for b in manifest_data.get("books", [])]
        for book in new_books:
            if book["path"] not in existing_paths:
                manifest_data["books"].append(book)
                
        with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
            json.dump(manifest_data, f, ensure_ascii=False, indent=2)
            
        print(f"Updated manifest with {len(new_books)} new books.")

if __name__ == "__main__":
    process_pdfs()
