import os
import PyPDF2

pdf_files = [
    r"E:\كتب التدريب\nutrition\Eat-Right_-Swim-Faster_-Nutrition-for-Maximum-Performance-Abby-Knox-_-WeLib.org-_.pdf",
    r"E:\كتب التدريب\nutrition\Essentials of Sports Nutrition and Supplements ( PDFDrive ).pdf"
]

out_dir = r"assets\knowledge_base\books"
os.makedirs(out_dir, exist_ok=True)

for i, pdf_path in enumerate(pdf_files):
    if not os.path.exists(pdf_path):
        print(f"File not found: {pdf_path}")
        continue
        
    out_path = os.path.join(out_dir, f"nutrition_{i+1}.txt")
    print(f"Extracting {pdf_path} to {out_path} ...")
    
    with open(pdf_path, 'rb') as f_in, open(out_path, 'w', encoding='utf-8') as f_out:
        reader = PyPDF2.PdfReader(f_in)
        for page_num in range(len(reader.pages)):
            try:
                text = reader.pages[page_num].extract_text()
                if text:
                    f_out.write(text + "\n")
            except Exception as e:
                pass
                
    print(f"Done extracting to {out_path}")
