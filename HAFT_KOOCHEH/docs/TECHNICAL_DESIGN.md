# Technical design — phase 0.1

## Approved scope
Android 2D / 2.5D auto-runner foundation only. No player, movement, jumping,
physics bodies, enemies, obstacles, currency, scoring, failure, progression,
menus, levels, animation, sound, monetization or networking.

## Toolchain and configuration
Required: Godot **4.7.2 Stable Standard**, GDScript, Compatibility renderer.
The project feature tag 4.7 denotes a feature family, not a patch-version lock.
Verify the actual executable's full version and Standard distribution.
1280×720 base viewport; canvas_items stretch; keep aspect (16:9 with bars on
other ratios); landscape enum 0; 60 physics ticks/second. Both desktop and
mobile renderer values are gl_compatibility. Physics tick configuration does
not demonstrate frame rate or device performance.

## Scene
Main (Node2D) contains UI (CanvasLayer) and a full-viewport centered Title
(Label) displaying HAFT KOOCHEH. No external resource or script is needed.
No autoload, manager framework, plugin or extra runtime dependency exists.
Future approved modules are separated into scenes, scripts, resources and assets.

## Official references (checked 2026-11-15)
- https://godotengine.org/download/archive/4.7.2-stable/
- https://docs.godotengine.org/en/stable/classes/class_projectsettings.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

Stable documentation may change. Runtime validation must use the pinned engine.
Actual toolchain and QA results are recorded separately.

# افزوده مرحله ۰.۲ — معماری و استاندارد توسعه

تاریخچه بخش‌های بالا مربوط به اسکلت ۰.۱ است. مدیر پروژه ۰.۱ را با استثنای QA-001
پذیرفته و دستور مستندسازی ۰.۲ صادر کرده است؛ مجوز ساخت Prototype صادر نشده است.
این مرحله project.godot، صحنه اصلی، موتور، Renderer یا تنظیمات اجرایی را تغییر نمی‌دهد.

## مراجع واحد

| موضوع | سند مرجع | وضعیت |
| --- | --- | --- |
| داستان، چهار ستون، MVP و خارج دامنه | [GDD.md](GDD.md) | پیشنهاد طراحی؛ محدوده قطعی از دستور |
| هشت ماژول، Signal، state و مالکیت | [GAMEPLAY_ARCHITECTURE.md](GAMEPLAY_ARCHITECTURE.md) | قرارداد فنی برای بررسی |
| ورودی، ترتیب tick، Coyote و Buffer | [PLAYER_MOVEMENT_SPEC.md](PLAYER_MOVEMENT_SPEC.md) | اعداد آزمایشی |
| هندسه، مرحله‌ها، سکه و رکورد | [LEVEL_DESIGN_SPEC.md](LEVEL_DESIGN_SPEC.md) | جدول ۱۰مرحله‌ای آزمایشی |
| نام‌گذاری، مجوز، فرمت و بودجه هنر | [ASSET_GUIDE.md](ASSET_GUIDE.md) | استاندارد پیشنهادی؛ بدون آرت |
| تصمیم‌ها و وضعیت قطعی/آزمایشی | [DECISIONS.md](DECISIONS.md) | ۱ تا ۱۲ محفوظ، DEC-013 به بعد جدید |
| آزمون‌ها و gateها | [QA_TEST_PLAN.md](QA_TEST_PLAN.md) | QA-001 و QA-002 باز |

CharacterBody2D برای Player و Area2D برای Coin؛ Level تنها مرجع نتیجه تلاش و
Score محلی هر تلاش است. Save/Audio/UI فرزندان App هستند و Autoload اضافه نمی‌شود.
داده ذخیره مستقل از Nodeهای فیزیکی و نسخه‌دار است. خطا در ذخیره پایان موفق را به
شکست تبدیل نمی‌کند و موفقیت persistence بدون نتیجه واقعی اعلام نمی‌شود.
حالت‌های تلاش READY/RUNNING/PAUSED/FAILED/COMPLETED، قرارداد آینده‌اند، نه سیستم فعلی.

## استاندارد کار مرحله‌های بعد

پیش از تغییر، بازرسی فایل واقعی و وضعیت Git؛ حداقل تغییر در محدوده دستور؛ بررسی
Parse و Import و آزمون رفتار تغییرکرده؛ ثبت دستور، خروج و خطای واقعی؛ Stage و
کنترل ZIP با فهرست Index. تست سند و Headless جایگزین آزمون لمس، تصویر یا Android نیست.
فایل GDScript باید typed و در پوشه مصوب باشد؛ script manager خالی، Autoload بی‌نیاز،
کلاس عمومی استفاده‌نشده و وابستگی جدید از قبل ساخته نمی‌شود. هر پیشنهاد محصولی
قبل از تبدیل به رفتار اجرایی نیازمند تأیید مالک است.

## gate اجرا

QA-001 باز: تست بصری روی میزبان گرافیکی پیش از شروع عملی Prototype لازم است؛
استثنای پذیرش مرحله ۰.۱ فقط پیشروی اسناد را مجاز کرده است. QA-002 باز: قبل از
Android Export، نصب و اعتبارسنجی toolchain لازم است. رفع نشدن این دو محدودیت مانع
تحویل اسناد ۰.۲ نیست؛ موفقیت تست‌های مربوط به آن‌ها نیز ادعا نمی‌شود.
