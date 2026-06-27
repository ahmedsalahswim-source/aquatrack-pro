import fitz

def extract_pdf(pdf_path, output_path):
    print(f"Extracting {pdf_path}...")
    doc = fitz.open(pdf_path)
    text = ""
    for i, page in enumerate(doc):
        text += f"--- Page {i+1} ---\n"
        text += page.get_text() + "\n"
    
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(text)
    
    print(f"Extracted {len(text)} characters to {output_path}")

if __name__ == "__main__":
    pdf_path = "biobio/Bio-mechanisms_of_Swimming_and_Flying_OCR_searchable.pdf"
    output_path = "assets/knowledge_base/books/Bio-mechanisms_of_Swimming_and_Flying.txt"
    extract_pdf(pdf_path, output_path)
