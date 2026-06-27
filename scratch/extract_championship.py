import PyPDF2
import json
import re
from pathlib import Path

pdf_path = Path(r"E:\res\نتجيه بطولة الصعيد 2025 سينزو.pdf")
output_json = Path(r"C:\Users\ِAhmed\Desktop\AquaTrack Pro\assets\data\championships_db.json")

def parse_championship():
    results = []
    
    current_event = "Unknown"
    current_gender = "Unknown"
    current_age = "Unknown"
    
    # Regex to catch: time like 11.09.23 followed immediately by position like 1 or 12, then points
    # e.g., 11.09.231 18 -> Time: 11.09.23, Pos: 1, Pts: 18
    # e.g., 00.32.4510 5 -> Time: 00.32.45, Pos: 10, Pts: 5
    row_pattern = re.compile(r'^(\d+)\s+(.+?)\s+(\d{2}\.\d{2}\.\d{2})(\d+)\s*(\d*)$')
    
    try:
        with open(pdf_path, "rb") as f:
            reader = PyPDF2.PdfReader(f)
            total_pages = len(reader.pages)
            
            for i in range(total_pages):
                text = reader.pages[i].extract_text()
                if not text:
                    continue
                
                lines = text.split('\n')
                
                for line in lines:
                    line = line.strip()
                    
                    # Extract Context (Headers)
                    if "اﺳﻢ اﻟﺴﺒﺎق" in line:
                        # e.g., "4 رﻗﻢ اﻟﺴﺒﺎق ﺣﺮة800 اﺳﻢ اﻟﺴﺒﺎق"
                        parts = line.split("اﺳﻢ اﻟﺴﺒﺎق")
                        if len(parts) > 1:
                            current_event = parts[1].strip()
                            
                    if "اﻟﻨﻮع" in line:
                        if "ناشئات" in line or "ﻧﺎﺷﺌﺎت" in line or "بنات" in line or "سيدات" in line:
                            current_gender = "female"
                        elif "ناشئين" in line or "ﻧﺎﺷﺌﻴﻦ" in line or "بنين" in line or "رجال" in line:
                            current_gender = "male"
                            
                    if "ﻣﺮﺣﻠﺔ" in line:
                        # e.g., "13 ﻣﺮﺣﻠﺔ"
                        match = re.search(r'(\d+)\s*ﻣﺮﺣﻠﺔ', line)
                        if match:
                            current_age = match.group(1)
                            
                    # Extract Rows
                    # Looking for a line that starts with a number, has name/club, and ends with time+pos
                    # Let's clean the line first. Sometimes Club and Time don't have spaces.
                    # We will use a more resilient regex
                    # Pattern: Starts with number, contains Arabic text, ends with XX.XX.XXXX
                    row_match = re.search(r'^(\d+)\s+(.+?)\s+(\d{2}\.\d{2}\.\d{2})(\d+)', line)
                    if row_match:
                        rank_col1 = row_match.group(1)
                        name_and_club = row_match.group(2).strip()
                        time_str = row_match.group(3)
                        position = row_match.group(4)
                        
                        # Fix Arabic reversed text if needed, but PyPDF2 might extract it correctly
                        results.append({
                            "event": f"{current_event} (Age {current_age})",
                            "gender": current_gender,
                            "swimmer": name_and_club,
                            "time": time_str.replace('.', ':'), # normalize to MM:SS:MS
                            "time_seconds": time_to_seconds(time_str),
                            "position": int(position)
                        })
    except Exception as e:
        print(f"Error reading PDF: {e}")

    # Save to JSON
    out_dir = output_json.parent
    if not out_dir.exists():
        out_dir.mkdir(parents=True, exist_ok=True)
        
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump({"championship": "Upper Egypt 2025", "results": results}, f, ensure_ascii=False, indent=2)
        
    print(f"Successfully extracted {len(results)} race results.")

def time_to_seconds(time_str):
    try:
        # Expected format: MM.SS.MS or MM:SS:MS
        parts = time_str.replace(':', '.').split('.')
        m = int(parts[0])
        s = int(parts[1])
        ms = int(parts[2])
        return (m * 60) + s + (ms / 100.0)
    except:
        return 9999.0

if __name__ == "__main__":
    parse_championship()
