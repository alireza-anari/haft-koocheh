# گزارش تکمیلی R1 — مرحله ۰.۱

## وضعیت اجرا
ناقص: اصلاح گزارش Git انجام شده؛ اجرای گرافیکی به محدودیت محیط برخورد کرده است.

## تغییرات
علت مغایرت گزارش قبلی: خروجی git ls-files قبل از ایجاد و stage کردن خود
فایل docs/git_validation_results.json ذخیره شده بود. در بررسی R1، این فایل
از ابتدا در Index وجود داشت؛ فهرست واقعی ۱۶ فایل و فهرست ذخیره‌شده ۱۵ فایل بود.
خروجی Git پس از ایجاد تمام فایل‌های R1 بازتولید و خود JSON نیز دوباره stage شد.

## فایل‌ها
- اصلاح‌شده: docs/git_validation_results.json، docs/PROJECT_STATE.md،
  docs/QA_TEST_PLAN.md، docs/ENVIRONMENT_AUDIT.md، docs/PHASE_0_1_REPORT.md.
- ایجادشده: docs/R1_REPORT.md و docs/r1_test_results.json.
- حذف‌شده: هیچ‌کدام.
- مجموع فایل‌های Index و فایل‌های ZIP: **۱۸**؛ فهرست کامل در git_validation_results.json.
- project.godot، main.tscn، تست ایستا و .gitignore با ZIP اولیه یکسان مانده‌اند.

## تست
مسیر ENGINE: ../tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
دستورها از ریشه پروژه؛ مسیرهای مطلق، خروجی‌ها و کد خروج در r1_test_results.json.

| آزمون | دستور / بررسی | نتیجه |
| --- | --- | --- |
| نسخه | ENGINE --version | 4.7.2.stable.official.ed1daf0bf؛ خروج صفر |
| Import | ENGINE --headless --editor --path . --quit | خروج صفر، stderr خالی |
| Main Headless | ENGINE --headless --path . --quit-after 3 | خروج صفر، stderr خالی؛ فقط آزمون Headless |
| ایستا | python3 tests/validate_skeleton.py | موفق |
| Git | ls-files، status، check-ignore، diff --cached --check، remote -v | موفق؛ ۱۸ فایل؛ خود گزارش در فهرست است |
| رگرسیون گزارش | مقایسه فهرست JSON با Index | قبل از اصلاح: اختلاف ۱۵/۱۶؛ بعد: تطابق ۱۸/۱۸ |
| محدودیت محدوده | مقایسه فایل‌های اصلی با ZIP اولیه | بدون تغییر |
| Xvfb | جستجوی Xvfb و xvfb-run در PATH | یافت نشد |
| رندر نرم‌افزاری | وجود swrast_dri.so و ldd | کتابخانه موجود؛ وابستگی‌های نمایش‌داده‌شده حل شده‌اند؛ context آزموده نشد |
| Xorg dummy | Xorg :91 با driver dummy و config محلی | راه‌اندازی ناموفق؛ Could not create lock file in /tmp/.tX91-lock |
| اتصال نمایشگر | DISPLAY=:91 xwininfo -root | اتصال ناموفق |
| اجرای گرافیکی | DISPLAY=:91 LIBGL_ALWAYS_SOFTWARE=1 ENGINE --path . --rendering-method gl_compatibility --display-driver x11 --audio-driver Dummy --quit-after 120 | ناموفق؛ X11/Wayland در دسترس نیست |

## مشکلات
عنوان، مرکز بودن آن و خروجی واقعی Compatibility از نظر بصری تأیید نشدند؛
تصویر واقعی اجرا تولید نشده است. حضور Mesa به معنی موفقیت رندر نیست.
Xvfb نصب نشده و محدودیت ایجاد فایل قفل Xorg مانع نمایشگر مجازی شد.
نتیجه Headless به عنوان نتیجه گرافیکی استفاده نشده است.
Android Export طبق ممیزی قبلی آماده نیست و در R1 اجرا نشده است.

## نتیجه
بند اصلاح Git تکمیل شده است. بررسی امکان گرافیکی انجام شده و محدودیت آن
مستند است؛ خود معیار نمایش بصری همچنان تأیید نشده است. مرحله ۰.۱ ناقص می‌ماند.

## اطلاعات فنی
موتور و معماری تغییر نکرده‌اند. Compatibility، 1280×720، Landscape،
canvas_items، keep و physics ticks=60 حفظ شده‌اند. Commit و Remote وجود ندارد.
تمام ۱۸ فایل در Index هستند؛ کش .godot و خروجی ساخت وارد ZIP نشده‌اند.
ZIP شامل metadata مخزن Git یا باینری موتور نیست و پوشه‌های خالی را حفظ می‌کند.

## نیاز به تصمیم
تصمیم محصولی جدید لازم نیست؛ تأیید گرافیکی نیازمند محیط دارای نمایشگر قابل دسترس است.
پس از تحویل منتظر بررسی مدیر پروژه هستیم؛ مرحله ۰.۲ شروع نشده است.
