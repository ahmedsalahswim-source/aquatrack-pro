import json
import os

db_path = r"assets\nutrition\food_database.json"

with open(db_path, "r", encoding="utf-8") as f:
    foods = json.load(f)

# Find the highest ID to continue from
max_id = 0
for food in foods:
    num = int(food["id"].split("_")[1])
    if num > max_id:
        max_id = num

id_counter = max_id + 1

def add_food(name_ar, name_en, cat, cals, prot, carbs, fat, gi, suitable):
    global id_counter
    foods.append({
        "id": f"f_{id_counter:03d}",
        "name_ar": name_ar,
        "name_en": name_en,
        "category": cat,
        "serving_size_g": 100.0,
        "calories": float(cals),
        "protein_g": float(prot),
        "carbs_g": float(carbs),
        "fat_g": float(fat),
        "glycemic_index": gi,
        "suitable_for": suitable
    })
    id_counter += 1

# -- HYDRATION & SPORTS DRINKS (Ready & Homemade) --

# Water
add_food("ماء نقي (بارد أو معتدل)", "Pure Water (Cold or Ambient)", "hydration", 0, 0, 0, 0, "low", ["hydration", "during_workout"])
add_food("ماء جوز الهند الطبيعي", "Natural Coconut Water", "hydration", 19, 0.7, 3.7, 0.2, "low", ["hydration", "electrolytes", "hot_weather"])

# Homemade Sports Drinks
add_food("مشروب رياضي منزلي (ماء، عسل، ليمون، رشة ملح)", "Homemade Sports Drink (Honey & Lemon)", "hydration", 15, 0, 4, 0, "high", ["during_workout", "hydration", "electrolytes"])
add_food("مشروب استشفاء منزلي حار (شاي أخضر، زنجبيل، عسل)", "Hot Homemade Recovery Drink (Green Tea, Ginger, Honey)", "hydration", 10, 0, 2.5, 0, "medium", ["cold_weather", "recovery", "anti_inflammatory"])
add_food("مشروب رياضي منزلي دافئ (ماء دافئ، قرفة، عسل، ملح بحري)", "Warm Homemade Sports Drink (Cinnamon, Honey, Sea Salt)", "hydration", 12, 0, 3, 0, "high", ["during_workout", "cold_weather", "electrolytes"])
add_food("عصير برتقال مخفف بالماء والملح (للبيئة الحارة)", "Diluted Orange Juice with Salt", "hydration", 22, 0.4, 5.2, 0, "high", ["during_workout", "hot_weather", "electrolytes"])

# Ready-Made Sports Drinks
add_food("مشروب إلكتروليتات خالي السعرات (أقراص فوارة)", "Zero Calorie Electrolyte Tablet (Dissolved)", "hydration", 2, 0, 0.5, 0, "low", ["hydration", "hot_weather", "electrolytes"])
add_food("مشروب رياضي هايبرتونيك (عالي الكربوهيدرات لقبل البطولات)", "Hypertonic Sports Drink", "hydration", 60, 0, 15, 0, "high", ["carb_loading", "pre_workout"])
add_food("مشروب رياضي هايبوتونيك (قليل الكربوهيدرات للترطيب السريع)", "Hypotonic Sports Drink", "hydration", 15, 0, 3.5, 0, "high", ["hot_weather", "during_workout", "fast_hydration"])

# Useful Additions for Swimmers
add_food("عصير الشمندر (الشمندر/البنجر) المركز", "Concentrated Beetroot Juice", "hydration", 45, 1, 10, 0, "medium", ["pre_workout", "nitric_oxide", "endurance"])
add_food("عصير الكرز اللاذع (Tart Cherry Juice)", "Tart Cherry Juice", "hydration", 50, 0.5, 12, 0, "medium", ["recovery", "anti_inflammatory", "sleep_aid"])
add_food("حليب الشوكولاتة قليل الدسم (للاستشفاء)", "Low Fat Chocolate Milk", "hydration", 62, 3.2, 10, 1, "medium", ["post_workout", "recovery", "protein_carb_ratio"])
add_food("قهوة سوداء (اسبريسو / فلتر)", "Black Coffee", "hydration", 2, 0.1, 0, 0, "low", ["pre_workout", "focus", "ergogenic_aid"])

with open(db_path, "w", encoding="utf-8") as f:
    json.dump(foods, f, ensure_ascii=False, indent=2)

print(f"Successfully appended hydration drinks. Total food items now: {len(foods)}")
