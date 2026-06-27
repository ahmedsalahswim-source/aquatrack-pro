import PyPDF2
from pathlib import Path

pdf_path = Path(r"E:\res\نتجيه بطولة الصعيد 2025 سينزو.pdf")

with open(pdf_path, "rb") as f:
    reader = PyPDF2.PdfReader(f)
    print(f"Total pages: {len(reader.pages)}")
    
    with open(r"c:\Users\ِAhmed\Desktop\AquaTrack Pro\scratch\sample_output.txt", "w", encoding="utf-8") as out:
        if len(reader.pages) > 5:
            out.write(reader.pages[5].extract_text()[:2000])
