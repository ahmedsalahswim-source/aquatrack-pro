import sys
import PyPDF2

def extract_pdf_to_text(pdf_path, text_path):
    print(f"Extracting text from {pdf_path}...")
    try:
        reader = PyPDF2.PdfReader(pdf_path)
        with open(text_path, 'w', encoding='utf-8') as f:
            for i, page in enumerate(reader.pages):
                text = page.extract_text()
                if text:
                    f.write(text + "\n\n")
                if (i + 1) % 50 == 0:
                    print(f"Processed {i + 1}/{len(reader.pages)} pages...")
        print(f"Extraction completed. Saved to {text_path}")
    except Exception as e:
        print(f"Failed to extract PDF: {e}")

if __name__ == "__main__":
    pdf_file = "assets/knowledge_base/books/b060.pdf"
    output_file = "assets/knowledge_base/books/b060_full.txt"
    extract_pdf_to_text(pdf_file, output_file)
