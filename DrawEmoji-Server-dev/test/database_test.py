import os
import sys
sys.path.insert(1, os.getcwd())

from src.backend.database import Database

# 測試資料
cookie = "abc123cookie"
image_b64 = "BASE64_IMAGE_STRING_EXAMPLE"
emoji = "😊"
rating = 5
comment = "Great emoji result!"

# 初始化資料庫
db = Database()

# 新增使用者
db.insert_user(cookie)

# 插入圖片轉換結果
image_id = db.insert_image_result(image_b64, emoji)
print(f"ImageResult ID: {image_id}")

# 插入歷史紀錄
db.insert_history(cookie, image_id)
print("History inserted.")

# 插入回饋紀錄
db.insert_feedback(cookie, image_id, rating, comment)
print("Feedback inserted.")

# 查詢歷史紀錄
history = db.get_history_by_cookie(cookie)
for entry in history:
    print(f"History ID: {entry[0]}, Emoji: {entry[2]}, Time: {entry[3]}")
    
# 測試 cookie
user1 = "cookie_user_001"
user2 = "cookie_user_002"

# 測試圖片資料
image_samples = [
    ("img_base64_1", "🐱"),
    ("img_base64_2", "🐶"),
    ("img_base64_3", "🐼"),
]

# 插入使用者
db.insert_user(user1)
db.insert_user(user2)

# 確保重複插入不會造成錯誤
db.insert_user(user1)

# 插入圖片與歷史紀錄（user1）
for img, emoji in image_samples:
    image_id = db.insert_image_result(img, emoji)
    db.insert_history(user1, image_id)
    db.insert_feedback(user1, image_id, rating=5, comment="Perfect!")

# 插入圖片與歷史紀錄（user2）
image_id = db.insert_image_result("img_base64_4", "🐸")
db.insert_history(user2, image_id)
db.insert_feedback(user2, image_id, rating=3, comment="So-so")

# 額外插入另一張圖給 user2，沒提供回饋
image_id_2 = db.insert_image_result("img_base64_5", "🦊")
db.insert_history(user2, image_id_2)

# 查詢 user1 歷史紀錄
print(f"\n📜 User1 ({user1}) History:")
user1_history = db.get_history_by_cookie(user1)
for entry in user1_history:
    print(f"ID={entry[0]}, Emoji={entry[2]}, Time={entry[3]}")

# 查詢 user2 歷史紀錄
print(f"\n📜 User2 ({user2}) History:")
user2_history = db.get_history_by_cookie(user2)
for entry in user2_history:
    print(f"ID={entry[0]}, Emoji={entry[2]}, Time={entry[3]}")

# Edge case: 查詢不存在的使用者
print("\n📜 User3 (不存在) History:")
user3_history = db.get_history_by_cookie("not_exist_cookie")
if not user3_history:
    print("No history found.")
else:
    for entry in user3_history:
        print(entry)

