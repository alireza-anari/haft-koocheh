# گزارش مرحله ۱.۱-R1 — حرکت خودکار متن‌محور

## ۱. مشخصات مرحله

فاز یک، ۱.۱-R1؛ تاریخ۲۰۲۶-۱۱-۱۵. وضعیت: **COMPLETE در محدوده مصوب؛ منتظر تأیید مدیر**.
مجوز DEC-033 مشروط به QA-001C رعایت شد؛ هیچ Player پیش از PASS این gate ایجاد نشد.

## ۲. وضعیت اولیه

بسته HAFT_KOOCHEH_phase_0_2_R1.zip با۵۶ فایل مبنا، همه بایت‌های واقعی و Index
در شروع یکسان بود. تنها صحنه عنوان موجود؛ DOC-001 بسته، QA-001B و QA-002 باز بودند.
موتور دقیق Standard 4.7.2.stable.official.ed1daf0bf و تنظیمات پایه حفظ شدند.

## ۳. نتیجه QA-001C

**PASS.** در کپی مستقل tools/phase_1_1_r1/gate_copy، متن Label به
QA-001C TEXT EDIT VERIFIED تغییر متنی داده و ذخیره شد. Import و اجرای Headless
هر دو با خروج۰ و stderr خالی موفق شدند. اجرای بدون Headless با باینری دقیق و
Compatibility متن جدید را واقعاً نمایش داد؛ تصویر اصلی در شواهد است. خروج گرافیکی۰.
هش هر۵۶ فایل اصلی قبل/بعد gate یکسان بود؛ صحنه اصلی دست‌نخورده ماند.
کپی آزمایشی در ZIP نیست؛ عکس و گزارش آن مدرک‌اند، نه جایگزین Main Scene.

## ۴. فایل‌های ایجادشده

- scenes/player/player.tscn
- scripts/player/player_controller.gd
- scenes/gameplay/prototype_run.tscn
- scripts/gameplay/prototype_run.gd
- tests/test_auto_run.gd
- سه فایل .gd.uid واقعی تولیدشده موتور برای اسکریپت‌ها
- docs/PHASE_1_1_R1_REPORT.md و docs/phase_1_1_r1_test_results.json
- پوشه docs/phase_1_1_r1_evidence با تصاویر واقعی، JSON، دستورها، لاگ و .gdignore

فهرست دقیق نهایی در git_validation_results.json است؛ فایل بی‌استفاده Resource یا
Asset خارجی وجود ندارد. تمام پوشه‌های پایه حفظ شده‌اند.

## ۵. فایل‌های اصلاح‌شده

README.md، docs/DECISIONS.md، docs/QA_TEST_PLAN.md، docs/PROJECT_STATE.md،
docs/git_validation_results.json، tests/validate_skeleton.py و tests/validate_documentation.py.
دو validator به‌دلیل منع تاریخی کل gameplay باید به مرحله جاری تطبیق داده می‌شدند:
بررسی‌های قبلی حفظ و allowlist دقیق جای منع کلی را گرفت؛ تستی برای گرفتن PASS حذف نشد.
project.godot، scenes/app/main.tscn، .gitignore، GDD، مشخصات مراحل/حرکت و معماری
از نظر بایتی با مبنا یکسان‌اند. هیچ فایل مبنا حذف نشده است.

## ۶. معماری Player

Root از CharacterBody2D؛ RectangleShape2D به اندازه32×48 و Polygon2D هم‌اندازه.
مبدأ پای وسط و collider با offset=-24 است. لایه Player=2 و mask زمین=1؛
زمین StaticBody2D با طول12000 ازx=-400 تا11600 است. Camera2D همراه Player حرکت می‌کند.
Player تایپ‌دار، بدون ورودی و بدون وابستگی UI است؛ MotionState دو مقدار DISABLED/RUNNING
دارد. set_gameplay_enabled(bool) وضعیت افقی را کنترل می‌کند؛ DISABLED پیش‌فرض است.
گرانش مستقل از فعال‌بودن حرکت افقی برای استقرار عمودی اعمال می‌شود. velocity در
واحد px/s و شتاب در delta ضرب می‌شود؛ move_and_slide در _physics_process است.
کنترل‌کننده کوچک Prototype فقط پس از تماس زمین حرکت را فعال می‌کند؛ LevelController
یا Autoload/Plugin ساخته نشده. اجرای عادی عنوان هیچ Player فعال نمی‌کند.

## ۷. پارامترهای واقعی

run_speed=280 px/s و gravity=1200 px/s² به صورت export float قابل تنظیم‌اند؛
Physics60 Hz از پروژه اصلی حفظ شده است. رزولوشن1280×720، Landscape، canvas_items،
keep و Compatibility بدون تغییرند. مقدارها آزمایشی‌اند. زمین برای بیش از۱۰ ثانیه
کافی است؛ این صحنه مسیر بی‌نهایت یا مرحله محصول نیست.

## ۸. نتایج اندازه‌گیری حرکت

پس از استقرار، دقیقاً600 tick در60 Hz ثبت شد؛ زمان شبیه‌سازی10.0000000000001s.
شروع x=160 و پایان x=2960.0087890625؛ جابه‌جایی2800.0087890625px و خطا0.008789px
است که زیر تلرانس5px است. vx در تمام tickها280 بود؛ ورودی کاربر استفاده نشد.
POSITION_SAMPLE هر60tick و TEST_RESULT نتیجه دقیق را در لاگ دارند؛ overlay فنی حین
حرکت می‌تواند شمارنده tick قبلی را نشان بدهد، بنابراین داده دقیق از JSON خوانده می‌شود.

## ۹. نتیجه تماس زمین

PASS؛ تماس زمین600/600tick؛ y کمینه/بیشینه599.981750488281 یکسان؛ دامنه عمودی۰؛
حداکثر قدرمطلق vy=0. فاصله حدود0.01825px با سطح600 ناشی از margin تماس است، نه نفوذ.
نه سقوط و نه خروج از سطح معتبر در بازه آزمون رخ داد. auto_start صحنه عادی نیز
در120tick جدا بررسی شد: x=640.666748 و vx=280 روی زمین، بدون فعال‌سازی دستی harness.

## ۱۰. نتیجه توقف

PASS؛ پس از set_gameplay_enabled(false)،60tick دیگر: vx=0 و جابه‌جایی افقی۰.
حالت DISABLED اولیه هم در تست Headless کنترل شد. رویداد پرش یا شکست وجود ندارد؛
این سیستم‌ها در کد پیاده‌سازی نشده‌اند.

## ۱۱. مقایسه FPS

| محیط واقعی | render frames در بازه حرکت | زمان واقعی s | FPS اندازه‌گیری‌شده | tick / زمان شبیه‌سازی | Δx px |
| --- | --- | --- | --- | --- | --- |
| گرافیکی با محدودیت30 | 300 | 10.000081 | 29.999757 | 600 / 10s | 2800.008789 |
| گرافیکی با محدودیت60 | 600 | 9.999724 | 60.001656 | 600 / 10s | 2800.008789 |

هر دو PASS؛ اختلاف جابه‌جایی۰. فیزیک درهر دو60 Hz است و --fixed-fps در این اجراها
استفاده نشد. نرخ واقعی از تعداد _process و زمان دیواری محاسبه شد؛ نه از مقدار cap.
افت tick یا زمان متفاوت ثبت‌نشده وجود ندارد. این میانگین FPS است، نه benchmark
jitter/latency گوشی. Headless سریع با --fixed-fps60 فقط زمان شبیه‌سازی را تست می‌کند؛
FPS در آن NOT RUN است و wall time کوتاه آن به‌عنوان۱۰ ثانیه واقعی معرفی نمی‌شود.

## ۱۲. شواهد Runtime گرافیکی

میزبان Linux Desktop، DISPLAY=:0؛ OpenGL4.5، Mesa25.0.7 و llvmpipe LLVM19.1.7،
Compatibility. تمام اجراها بدون Editor و با Standard4.7.2 بودند. تصاویر اصلی JPEG
بدون بازسازی/تولید ذخیره شده‌اند:

- [متن تغییرکرده QA-001C](phase_1_1_r1_evidence/qa001c_text_edit.jpg)
- [بازیکن حین اجرای30](phase_1_1_r1_evidence/motion_30_start.jpg)
- [پایان600tick و توقف](phase_1_1_r1_evidence/motion_30_end.jpg)
- [حین اجرای60](phase_1_1_r1_evidence/motion_60_during.jpg)

دوربین Player را دنبال می‌کند؛ مختصات جهان و marker زمین جابه‌جایی را نشان می‌دهند.
عکس نهایی60 پس از خروج پنجره درخواست شد و ثبت نشد؛ عکس حین60 و عکس‌های حین/پایان30
موجودند. این محدودیت capture به‌عنوان خطای Runtime بازی یا عکس موجود معرفی نمی‌شود.
لاگ Renderer، نمونه موقعیت و JSON/Exit Code هردو اجرا در شواهد است؛ هر دو خروج۰.

## ۱۳. نتیجه Regression و آزمون‌ها

Static، Documentation با مبنای جاری۵۶فایلی، Import، Main Headless، تست حرکت Headless،
smoke فعال‌سازی صحنه عادی و Runtime گرافیکی PASS هستند؛ دستور و خروج کامل در JSON.
ابتدا تست قبل از ساخت Prototype با exit1 و پیام missing auto-run prototype شکست
مورد انتظار داشت؛ سپس با کد واقعی موفق شد. دو fixture خرابی default RUNNING و
نادیده‌گرفتن disable با exit1 رد شدند؛ این شکست‌های مورد انتظار مدرک تست‌اند، نه
نقص باز. fixtureها خارج از پروژه و ZIP نگه داشته شدند.
فهرست صحنه/اسکریپت مجاز دقیق است؛ بدون Asset، Autoload، Export یا manager اضافی.
تست‌های پرش، دشمن، Save و سایر MVP همچنان اجرا نشده‌اند؛ موفقیت این مرحله آن‌ها را پوشش نمی‌دهد.

## ۱۴. QA-001B

OPEN / محیط Editor قبلاً مسدود بود؛ در این مرحله موفق فرض یا دوباره بسته نشد.
DEC-033 فقط توسعه متن‌محور Prototype را مجاز کرده؛ قبل از Vertical Slice تعیین تکلیف لازم است.

## ۱۵. QA-002

OPEN؛ Android Toolchain و Export و دستگاه تست نشدند؛ قبل از Android Export لازم‌اند.
هیچ APK یا keystore ایجاد نشد.

## ۱۶. خطاهای باقی‌مانده

هیچ خطای جدید Parse، Resource یا Runtime در اجراهای مثبت این مرحله دیده نشد.
هشدار ناتوانی تغییر V-Sync در driver نرم‌افزاری در لاگ حفظ شده است. خطاهای تاریخی
Editor در شواهد قبلی باقی‌اند و با PASS متن‌محور پاک یا بی‌اهمیت اعلام نمی‌شوند.
برای portability و عملکرد گوشی هنوز مدرک Android نداریم. Overlay آزمون UI محصول نیست.

## ۱۷. Git و ZIP

90 فایل نهایی در Index و ZIP؛ فهرست و بایت تک‌تک فایل‌ها بین دیسک، Index
و ZIP تطبیق داده شدند؛ CRC آرشیو معتبر است. همه۵۶ مسیر قبلی حفظ‌اند و تغییر فقط
در محدوده مجاز انجام شده. JSON خودارجاع پس از stage همه مسیرها ساخته و restage شد.
Cache، باینری موتور، کپی gate و fixtureها در ZIP نیستند؛ پوشه‌های خالی پایه حفظ‌اند.
Git whitespace کامل ممکن است برای قالب خروجی خام شواهد تاریخی exit2 بدهد؛ این
فاصله‌ها دستکاری نمی‌شوند. بررسی source/docs با استثنای محدود txt شواهد exit0 است؛
دستور و نتیجه واقعی هر دو در گزارش Git ثبت می‌شود. Commit، Remote و Push ایجاد نشد.

## ۱۸. Project State

[PROJECT_STATE.md](PROJECT_STATE.md) مرجع جاری فایل‌های اجرایی، داده‌ها، تصمیم DEC-033
و gateهای باز است. [README.md](../README.md) اجرای عنوان، Prototype و harness را جدا توضیح می‌دهد.

## ۱۹. نتیجه نهایی

**COMPLETE در محدوده۱.۱-R1؛ آماده بررسی مدیر پروژه.** QA-001C، Player، حرکت، زمین،
توقف، مقایسه FPS و شواهد واقعی فراهم‌اند. پرش، Buffer/Coyote، دشمن، سکه، امتیاز،
شکست، Restart، Save، Audio و Export ساخته نشده‌اند. تا تأیید مدیر وارد۱.۲ نمی‌شویم.
