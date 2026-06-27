import json
import os

foods = []
id_counter = 1

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

# -- CARBOHYDRATES (Starches & Grains) --
add_food("أرز أبيض مسلوق", "White Rice (Cooked)", "carbs", 130, 2.7, 28, 0.3, "high", ["post_workout", "carb_loading"])
add_food("أرز بني مسلوق", "Brown Rice (Cooked)", "carbs", 111, 2.6, 23, 0.9, "medium", ["pre_workout", "breakfast"])
add_food("شوفان جاف", "Dry Oats", "carbs", 389, 16.9, 66.3, 6.9, "low", ["breakfast", "pre_workout"])
add_food("مكرونة قمح كامل مسلوقة", "Whole Wheat Pasta (Cooked)", "carbs", 124, 5.3, 26.5, 0.5, "medium", ["carb_loading", "pre_workout"])
add_food("مكرونة بيضاء مسلوقة", "White Pasta (Cooked)", "carbs", 131, 5, 25, 1.1, "high", ["post_workout", "carb_loading"])
add_food("بطاطا حلوة مسلوقة", "Sweet Potato (Boiled)", "carbs", 86, 1.6, 20.1, 0.1, "medium", ["pre_workout", "recovery"])
add_food("بطاطس مشوية", "Baked Potato", "carbs", 93, 2.5, 21, 0.1, "high", ["post_workout", "recovery"])
add_food("كينوا مسلوقة", "Quinoa (Cooked)", "carbs", 120, 4.4, 21.3, 1.9, "low", ["pre_workout", "dinner"])
add_food("خبز أسمر", "Whole Wheat Bread", "carbs", 252, 12.5, 42.7, 3.4, "medium", ["breakfast", "snack"])
add_food("خبز أبيض", "White Bread", "carbs", 265, 9, 49, 3.2, "high", ["post_workout", "immediate_energy"])
add_food("حنطة سوداء مسلوقة", "Buckwheat (Cooked)", "carbs", 92, 3.4, 20, 0.6, "low", ["pre_workout", "dinner"])
add_food("برغل مسلوق", "Bulgur (Cooked)", "carbs", 83, 3.1, 18.6, 0.2, "low", ["lunch", "dinner"])
add_food("كسكسي مسلوق", "Couscous (Cooked)", "carbs", 112, 3.8, 23.2, 0.2, "medium", ["lunch", "dinner"])
add_food("كورن فليكس سادة", "Cornflakes", "carbs", 357, 8, 84, 0.4, "high", ["breakfast", "post_workout"])
add_food("موسلي", "Muesli", "carbs", 366, 11, 66, 6, "medium", ["breakfast", "snack"])
add_food("شعير مسلوق", "Barley (Cooked)", "carbs", 123, 2.3, 28, 0.4, "low", ["pre_workout", "lunch"])
add_food("تورتيلا ذرة", "Corn Tortilla", "carbs", 218, 5.7, 46.5, 2.8, "medium", ["lunch", "dinner"])
add_food("أرز بسمتي مسلوق", "Basmati Rice (Cooked)", "carbs", 121, 3.5, 25.2, 0.4, "medium", ["lunch", "dinner"])

# -- PROTEINS (Meats, Fish, Eggs, Plant-based) --
add_food("صدر دجاج مشوي", "Grilled Chicken Breast", "protein", 165, 31, 0, 3.6, "low", ["recovery", "lunch", "dinner"])
add_food("فخذ دجاج مشوي", "Grilled Chicken Thigh", "protein", 209, 26, 0, 10.9, "low", ["dinner"])
add_food("لحم بقري مفروم قليل الدسم (5%)", "Lean Ground Beef (5% Fat)", "protein", 137, 21.4, 0, 5, "low", ["recovery", "dinner"])
add_food("ستيك بقري مشوي", "Grilled Beef Steak", "protein", 271, 25, 0, 19, "low", ["dinner"])
add_food("ديك رومي مشوي", "Grilled Turkey Breast", "protein", 135, 30, 0, 1, "low", ["recovery", "lunch"])
add_food("سلمون مشوي", "Grilled Salmon", "protein", 206, 22, 0, 13, "low", ["recovery", "dinner", "anti_inflammatory"])
add_food("تونة معلبة في ماء", "Canned Tuna in Water", "protein", 86, 19.4, 0, 1, "low", ["recovery", "snack"])
add_food("تونة معلبة في زيت", "Canned Tuna in Oil", "protein", 198, 29, 0, 8, "low", ["dinner"])
add_food("بيض كامل مسلوق", "Whole Boiled Egg", "protein", 155, 12.6, 1.1, 10.6, "low", ["breakfast", "recovery"])
add_food("بياض بيض مسلوق", "Boiled Egg White", "protein", 52, 10.9, 0.7, 0.2, "low", ["breakfast", "recovery"])
add_food("توفو صلب", "Firm Tofu", "protein", 144, 15.8, 2.8, 8.7, "low", ["vegan", "dinner"])
add_food("عدس مسلوق", "Boiled Lentils", "protein", 116, 9, 20.1, 0.4, "low", ["vegan", "lunch"])
add_food("حمص مسلوق", "Boiled Chickpeas", "protein", 164, 8.9, 27.4, 2.6, "low", ["vegan", "lunch"])
add_food("فاصوليا سوداء مسلوقة", "Boiled Black Beans", "protein", 132, 8.9, 23.7, 0.5, "low", ["vegan", "dinner"])
add_food("لحم غنم مشوي", "Grilled Lamb", "protein", 294, 25, 0, 21, "low", ["dinner"])
add_food("سمك بلطي مشوي", "Grilled Tilapia", "protein", 128, 26, 0, 2.7, "low", ["lunch", "recovery"])
add_food("سمك قد مشوي", "Grilled Cod", "protein", 105, 23, 0, 0.9, "low", ["lunch", "recovery"])
add_food("سردين معلب", "Canned Sardines", "protein", 208, 24.6, 0, 11.5, "low", ["dinner", "anti_inflammatory"])
add_food("فاصوليا بيضاء مسلوقة", "White Beans (Cooked)", "protein", 139, 9.7, 25.1, 0.4, "low", ["vegan", "lunch"])
add_food("إدامامي مسلوق", "Edamame (Boiled)", "protein", 121, 11.9, 8.9, 5.2, "low", ["vegan", "snack"])

# -- DAIRY & ALTERNATIVES --
add_food("حليب بقري كامل الدسم", "Whole Milk", "dairy", 61, 3.2, 4.8, 3.3, "low", ["breakfast", "recovery"])
add_food("حليب بقري خالي الدسم", "Skim Milk", "dairy", 35, 3.4, 5, 0.1, "low", ["recovery", "shake_base"])
add_food("زبادي يوناني سادة قليل الدسم", "Greek Yogurt (Low Fat)", "dairy", 59, 10, 3.6, 0.4, "low", ["breakfast", "bedtime_snack"])
add_food("جبن قريش (Cottage Cheese)", "Cottage Cheese", "dairy", 98, 11, 3.4, 4.3, "low", ["bedtime_snack", "recovery"])
add_food("جبن شيدر", "Cheddar Cheese", "dairy", 402, 25, 1.3, 33, "low", ["snack"])
add_food("حليب صويا مدعم", "Fortified Soy Milk", "dairy", 33, 2.9, 1.8, 1.6, "low", ["vegan", "breakfast"])
add_food("حليب لوز غير محلى", "Unsweetened Almond Milk", "dairy", 15, 0.6, 0.3, 1.2, "low", ["vegan", "shake_base"])
add_food("جبن موزاريلا قليل الدسم", "Low Fat Mozzarella", "dairy", 254, 24, 2.8, 16, "low", ["dinner"])
add_food("لبن عيران / زبادي شرب", "Ayran / Drinking Yogurt", "dairy", 40, 2.5, 4, 1.5, "low", ["hydration", "snack"])
add_food("كفير (Kefir)", "Kefir", "dairy", 60, 3.3, 5, 3, "low", ["digestion", "breakfast"])

# -- FRUITS --
add_food("موز", "Banana", "fruits", 89, 1.1, 22.8, 0.3, "high", ["pre_workout", "immediate_energy"])
add_food("تفاح", "Apple", "fruits", 52, 0.3, 13.8, 0.2, "low", ["snack"])
add_food("برتقال", "Orange", "fruits", 47, 0.9, 11.8, 0.1, "low", ["snack", "hydration"])
add_food("عنب", "Grapes", "fruits", 69, 0.7, 18.1, 0.2, "medium", ["pre_workout", "immediate_energy"])
add_food("بطيخ", "Watermelon", "fruits", 30, 0.6, 7.6, 0.2, "high", ["hydration", "post_workout"])
add_food("فراولة", "Strawberries", "fruits", 32, 0.7, 7.7, 0.3, "low", ["snack", "antioxidants"])
add_food("توت أزرق", "Blueberries", "fruits", 57, 0.7, 14.5, 0.3, "low", ["snack", "antioxidants"])
add_food("أناناس", "Pineapple", "fruits", 50, 0.5, 13.1, 0.1, "medium", ["recovery", "digestion"])
add_food("مانجو", "Mango", "fruits", 60, 0.8, 15, 0.4, "medium", ["snack", "pre_workout"])
add_food("كيوي", "Kiwi", "fruits", 61, 1.1, 14.7, 0.5, "low", ["recovery", "vitamin_c"])
add_food("رمان", "Pomegranate", "fruits", 83, 1.7, 18.7, 1.2, "low", ["recovery", "blood_flow"])
add_food("خوخ", "Peach", "fruits", 39, 0.9, 9.5, 0.3, "low", ["snack"])
add_food("كمثرى", "Pear", "fruits", 57, 0.4, 15.2, 0.1, "low", ["snack"])
add_food("كرز", "Cherries", "fruits", 63, 1.1, 16, 0.2, "low", ["recovery", "sleep_aid"])
add_food("شمام", "Melon / Cantaloupe", "fruits", 34, 0.8, 8.2, 0.2, "medium", ["hydration", "recovery"])
add_food("جريب فروت", "Grapefruit", "fruits", 42, 0.8, 10.7, 0.1, "low", ["breakfast", "hydration"])
add_food("تين طازج", "Fresh Figs", "fruits", 74, 0.8, 19.2, 0.3, "medium", ["snack", "energy"])
add_food("مشمش", "Apricot", "fruits", 48, 1.4, 11.1, 0.4, "low", ["snack"])
add_food("أفوكادو", "Avocado", "fruits", 160, 2, 8.5, 14.7, "low", ["healthy_fats", "lunch"])
add_food("تمر (مجفف)", "Dates (Dried)", "fruits", 282, 2.5, 75, 0.4, "high", ["during_workout", "immediate_energy"])
add_food("زبيب", "Raisins", "fruits", 299, 3.1, 79.2, 0.5, "medium", ["during_workout", "energy"])
add_food("تين مجفف", "Dried Figs", "fruits", 249, 3.3, 63.9, 0.9, "medium", ["pre_workout", "energy"])

# -- VEGETABLES --
add_food("بروكلي مسلوق", "Boiled Broccoli", "vegetables", 35, 2.4, 7.2, 0.4, "low", ["lunch", "dinner", "fiber"])
add_food("سبانخ مطبوخة", "Cooked Spinach", "vegetables", 23, 3, 3.8, 0.3, "low", ["lunch", "dinner", "iron"])
add_food("جزر طازج", "Fresh Carrots", "vegetables", 41, 0.9, 9.6, 0.2, "low", ["snack", "lunch"])
add_food("طماطم طازجة", "Fresh Tomato", "vegetables", 18, 0.9, 3.9, 0.2, "low", ["salad", "hydration"])
add_food("خيار", "Cucumber", "vegetables", 15, 0.7, 3.6, 0.1, "low", ["salad", "hydration"])
add_food("فلفل حلو", "Bell Pepper", "vegetables", 20, 0.9, 4.6, 0.2, "low", ["salad", "vitamin_c"])
add_food("كوسا مطبوخة", "Cooked Zucchini", "vegetables", 15, 1.1, 2.7, 0.3, "low", ["dinner"])
add_food("قرنبيط مسلوق", "Boiled Cauliflower", "vegetables", 23, 1.8, 4.1, 0.5, "low", ["lunch", "dinner"])
add_food("باذنجان مطبوخ", "Cooked Eggplant", "vegetables", 35, 0.8, 8.7, 0.2, "low", ["lunch", "dinner"])
add_food("خس", "Lettuce", "vegetables", 14, 0.9, 2.9, 0.2, "low", ["salad", "hydration"])
add_food("ملفوف / كرنب", "Cabbage", "vegetables", 25, 1.3, 5.8, 0.1, "low", ["salad"])
add_food("فاصوليا خضراء مطبوخة", "Cooked Green Beans", "vegetables", 35, 1.9, 7.9, 0.3, "low", ["lunch", "dinner"])
add_food("بازلاء خضراء مطبوخة", "Cooked Green Peas", "vegetables", 84, 5.4, 15.6, 0.2, "low", ["lunch"])
add_food("بصل أحمر طازج", "Fresh Red Onion", "vegetables", 40, 1.1, 9.3, 0.1, "low", ["salad"])
add_food("ثوم", "Garlic", "vegetables", 149, 6.4, 33, 0.5, "low", ["immunity", "seasoning"])
add_food("فطر / مشروم مطبوخ", "Cooked Mushrooms", "vegetables", 28, 2.2, 5.3, 0.3, "low", ["lunch", "dinner"])
add_food("بنجر / شمندر مسلوق", "Boiled Beetroot", "vegetables", 44, 1.7, 10, 0.2, "medium", ["pre_workout", "nitric_oxide"])
add_food("هليون مسلوق", "Boiled Asparagus", "vegetables", 22, 2.4, 4.1, 0.2, "low", ["dinner"])

# -- FATS, NUTS, & SEEDS --
add_food("لوز غير محمص", "Raw Almonds", "fats", 579, 21.2, 21.6, 49.9, "low", ["snack", "healthy_fats"])
add_food("جوز (عين الجمل)", "Walnuts", "fats", 654, 15.2, 13.7, 65.2, "low", ["snack", "omega_3"])
add_food("كاجو", "Cashews", "fats", 553, 18.2, 30.2, 43.8, "low", ["snack"])
add_food("فستق", "Pistachios", "fats", 562, 20.2, 27.2, 45.3, "low", ["snack"])
add_food("فول سوداني", "Peanuts", "fats", 567, 25.8, 16.1, 49.2, "low", ["snack", "protein_boost"])
add_food("زبدة فول سوداني طبيعية", "Natural Peanut Butter", "fats", 588, 25, 20, 50, "low", ["breakfast", "snack"])
add_food("بذور شيا", "Chia Seeds", "fats", 486, 16.5, 42.1, 30.7, "low", ["omega_3", "hydration_boost"])
add_food("بذور كتان", "Flaxseeds", "fats", 534, 18.3, 28.9, 42.2, "low", ["omega_3"])
add_food("زيت زيتون بكر", "Extra Virgin Olive Oil", "fats", 884, 0, 0, 100, "low", ["salad_dressing", "anti_inflammatory"])
add_food("زيت جوز هند", "Coconut Oil", "fats", 862, 0, 0, 100, "low", ["cooking"])
add_food("زبدة حيوانية", "Butter", "fats", 717, 0.9, 0.1, 81.1, "low", ["cooking"])
add_food("طحينة السمسم", "Tahini", "fats", 595, 17, 21.2, 53.8, "low", ["dinner"])
add_food("بذور اليقطين", "Pumpkin Seeds", "fats", 559, 30.2, 10.7, 49.1, "low", ["snack", "magnesium"])
add_food("بذور دوار الشمس", "Sunflower Seeds", "fats", 584, 20.8, 20, 51.5, "low", ["snack"])

# -- SUPPLEMENTS & SPORTS NUTRITION --
add_food("بروتين مصل اللبن (Whey Protein)", "Whey Protein Powder", "supplements", 359, 78, 5, 2, "low", ["post_workout", "recovery"])
add_food("بروتين الكازين (Casein)", "Casein Protein Powder", "supplements", 365, 75, 10, 2, "low", ["bedtime_snack"])
add_food("كرياتين مونوهيدرات", "Creatine Monohydrate", "supplements", 0, 0, 0, 0, "low", ["strength_building"])
add_food("مشروب رياضي (مثل إيزوتونيك)", "Sports Drink (Isotonic)", "supplements", 24, 0, 6, 0, "high", ["during_workout", "hydration"])
add_food("جيل طاقة رياضي", "Energy Gel", "supplements", 260, 0, 65, 0, "high", ["during_workout", "immediate_energy"])
add_food("لوح بروتين رياضي", "Protein Bar", "supplements", 380, 30, 35, 12, "medium", ["snack", "post_workout"])
add_food("مسحوق BCAAs", "BCAA Powder", "supplements", 40, 10, 0, 0, "low", ["during_workout", "muscle_sparing"])

# -- SNACKS & SWEETS --
add_food("عسل طبيعي", "Natural Honey", "sweets", 304, 0.3, 82.4, 0, "high", ["pre_workout", "immediate_energy"])
add_food("شوكولاتة داكنة (70%+)", "Dark Chocolate (70%+)", "sweets", 598, 7.8, 45.9, 42.6, "low", ["snack", "antioxidants"])
add_food("مربى فواكه", "Fruit Jam", "sweets", 278, 0.4, 68.9, 0.1, "high", ["breakfast", "pre_workout"])

output_path = r"assets\nutrition\food_database.json"
os.makedirs(os.path.dirname(output_path), exist_ok=True)
with open(output_path, "w", encoding="utf-8") as f:
    json.dump(foods, f, ensure_ascii=False, indent=2)

print(f"Successfully generated {len(foods)} food items to {output_path}")
