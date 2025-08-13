# Simple Note App

تطبيق ملاحظات بسيط يدعم كلاً من SQLite و MariaDB/MySQL.

## المتطلبات

```bash
pip install -r requirements.txt
```

## الإعداد

### 1. إعداد قاعدة البيانات

**للـ SQLite (الأسهل):**
```bash
./sqlite.sh
```

**للـ MariaDB/MySQL:**
```bash
./mariadb.sh
```

### 2. تشغيل التطبيق

```bash
python3 frontend.py
```

### 3. فتح المتصفح

```
http://localhost:5000
```

## إعدادات قاعدة البيانات (.env)

```env
# نوع قاعدة البيانات (auto, mysql, sqlite)
DB_TYPE=auto

# إعدادات SQLite
DB_PATH=notes.db

# إعدادات MariaDB/MySQL
DB_HOST=localhost
DB_USER=notes_user
DB_PASSWORD=amr
DB_NAME=notes_db
DB_PORT=3306

# إعدادات الخادم
FLASK_PORT=5000
```

## النسخ الاحتياطي

**إنشاء نسخة احتياطية:**
```bash
./backup.sh
```

**استعادة من نسخة احتياطية:**
```bash
./restore.sh
```

## الملاحظات

- النظام يجرب الاتصال بـ MariaDB أولاً، ثم SQLite
- تأكد من تشغيل MariaDB server قبل استخدامه
- النسخ الاحتياطية تُحفظ في مجلد `./backups/` 