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

## API Endpoints

### Greeting Endpoints
```bash
# Say hello to the app
curl http://localhost:5000/hi
curl http://localhost:5000/hello
```

### Health Check
```bash
# Check application health and database status
curl http://localhost:5000/health
```

### Notes API
```bash
# Get all notes
curl http://localhost:5000/api/notes

# Search notes
curl http://localhost:5000/api/search?q=keyword
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