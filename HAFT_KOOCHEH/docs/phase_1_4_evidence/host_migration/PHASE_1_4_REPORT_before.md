# گزارش مرحله ۱.۴ — Coin Collection & Attempt Score System

## ۱. وضعیت اولیه و ۱۹۷ فایل مبنا

مسیر پروژه: `/workspace/scratch/9fd60dbdba5c/HAFT_KOOCHEH`.
بسته `HAFT_KOOCHEH_phase_1_3.zip` پیش از تغییر استخراج شد؛ هر ۱۹۷ مسیر و محتوای
آن‌ها با Manifest، دیسک و Git Index مقایسه و منطبق بودند. شش سند مرجع و تصمیمات
مرتبط مطالعه شدند. شواهد: `phase_1_4_evidence/baseline_validation.json`.

موتور واقعی `4.7.2.stable.official.ed1daf0bf`، نسخه Standard، زبان GDScript،
Compatibility، پایه 1280×720، Landscape و Physics 60 Hz حفظ شده‌اند.
**وضعیت نهایی مرحله: INCOMPLETE؛ آزمون نرخ واقعی ۱۲۰ FPS هنوز موفق نشده است.**

## ۲. معماری Coin

Coin یک Area2D با CollisionShape2D مستطیلی 32×32 و Polygon2D موقت است.
ورود Player دقیق همان تلاش، فقط در RUNNING و در صورت نبود pending/collected،
یک `pickup_requested` صادر می‌کند. Coin امتیاز را تغییر نمی‌دهد.

تا تصمیم Level، سکه pending می‌ماند. پس از پذیرش ScoreManager، `confirm_pickup()`
آن را collected می‌کند، pending را پاک و نمایش را مخفی می‌کند. monitoring و Collider
با `set_deferred` خاموش می‌شوند. `reject_pickup()` درخواست ردشده را امن پاک می‌کند.

## ۳. معماری ScoreManager

ScoreManager یک Node فرزند مستقیم Level در Prototype سکه است؛ داخل World/Player
یا Autoload نیست. در Restart همان نمونه باقی می‌ماند و فقط داده تلاش reset می‌شود.
صحنه Failure قبلی که Coin ندارد، عمداً همان ساختار قبلی را حفظ کرده است تا تست
قدیمی بدون تغییر Assertion موفق بماند. World دارای Coin بدون Manager شروع نمی‌شود.

Manager فقط امتیاز، مجموعه IDهای ثبت‌شده، Reset و Snapshot را مدیریت می‌کند؛
به Player، UI، Save یا فایل وابسته نیست. `score_changed` پس از Reset و پذیرش جدید صادر می‌شود.

## ۴. قرارداد coin_id

شناسه StringName، ثابت، مستقل از Instance ID، غیرخالی و در هر World یکتا است.
الگوی فنی `[a-z][a-z0-9_]*` در DEC-042 ثبت شده است. چیدمان خالی/تکراری با
`layout_error` و Warning قابل تشخیص در READY متوقف می‌شود.

ScoreManager برای شناسه تکراری false و بدون امتیاز جدید برمی‌گرداند. شناسه نامعتبر
false، `last_rejection=invalid_coin_id` و Warning ایجاد می‌کند. تعلق شناسه به نمونه
دقیق World را Registry در Level کنترل می‌کند.

## ۵. تنظیمات Collision

Coin: Layer=8، Mask=2 و monitoring=true. تنظیمات قبلی Player=2/1، World=1/2 و
Hazard=4/2 حفظ شده‌اند. تماس واقعی و غیرفعال‌شدن deferred شکل پس از تأیید آزمایش شدند.
هیچ تغییر Collider داخل flush فیزیک انجام نمی‌شود. تمام صحنه‌های قبلی بدون تغییرند.

## ۶. اتصال به LevelController

Level هنگام ساخت World، سکه‌ها را شناسایی و شناسه‌ها را اعتبارسنجی می‌کند و مرجع
Player و Attempt را متصل می‌کند. رویداد صف شامل ID، WeakRef و Instance ID سکه،
Player ID، Attempt ID و شماره فریم فیزیک است.

هویت Player فعال، وضعیت RUNNING، Attempt، تعلق Coin به World فعال و Registry همان
نمونه هم هنگام صف‌بندی و هم هنگام داوری بررسی می‌شوند. رویداد World/Player/Coin
قدیمی، منبع تغییرکرده یا Callback نمونه آزادشده امتیاز ایجاد نمی‌کند.

## ۷. منطق Failure > Coin

داوری در ابتدای تیک بعد و پیش از حرکت Player حفظ شده است. ابتدا Failure با تقدم
`fall > hazard > wall` انتخاب می‌شود. در صورت شکست، Coinهای pending رد می‌شوند؛
امتیاز تغییر نمی‌کند، confirm اجرا نمی‌شود و فقط یک run_failed صادر می‌شود.

بدون Failure، درخواست‌ها با ترتیب پایدار coin_id به ScoreManager می‌روند و تنها
پس از true تأیید می‌شوند. هر دو ترتیب فراخوانی واقعی APIهای Coin/Hazard بررسی شدند.
در آزمون فیزیکی جداگانه، هر دو Area در engine_tick=479 درخواست دادند؛ تیک 480 فقط
FAILED ثبت شد و Score صفر باقی ماند. این زیرآزمون شامل Finish نیست.

## ۸. فرمول امتیاز و وضعیت آن

`score = 10 * coins_collected`؛ امتیاز صحیح و نامنفی است. هر سکه ۱۰ امتیاز آزمایشی
دارد؛ DEC-022 و R1-D03 تغییر نکرده‌اند. کیف پول، Currency، رکورد یا ذخیره دائمی نداریم.

`build_result()` دقیقاً level_id:String، score:int، coins:int و completed:bool می‌دهد.
هر دو مقدار completed در سطح API تست شدند؛ وضعیت واقعی COMPLETED در Level ساخته نشده است.

## ۹. نتایج TEST-01 تا TEST-15

| آزمون | نتیجه واقعی | سناریو یا شاهد |
| --- | --- | --- |
| TEST-01 عادی | PASS؛ یک درخواست، pending با Score صفر، سپس coins=1 و score=10 | normal_duplicate_contact_and_visual |
| TEST-02 تکرار | PASS؛ تماس pending/collected امتیاز اضافه نمی‌دهد؛ Collider امن خاموش می‌شود | همان سناریو |
| TEST-03 ID تکراری | PASS؛ اولین ثبت true، تکرار false، بدون Signal اضافی | score_api_dedupe_invalid_snapshots |
| TEST-04 ID نامعتبر | PASS؛ خالی، فاصله، شروع عددی و خط تیره رد و تشخیص داده شدند | همان سناریو و invalid_layout_* |
| TEST-05 سه سکه | PASS؛ سه تماس فیزیکی، coins=3 و score=30 | three_real_coins |
| TEST-06 هویت/Attempt | PASS؛ قدیمی، خارج World، Player نامجاز و READY/FAILED رد شدند | identity_states_and_old_attempt |
| TEST-07 هم‌زمانی | PASS؛ دو ترتیب Callback و تماس فیزیکی هم‌فریم | arbitration_* و real_simultaneous_contact |
| TEST-08 Snapshot | PASS؛ دقیقاً چهار کلید، نوع/مقدار صحیح و Dictionary مستقل | score_api_dedupe_invalid_snapshots |
| TEST-09 Restart | PASS؛ پس از دو سکه، جهان تازه و Score صفر | restart_after_two_coins_and_ten_cycles |
| TEST-10 ده Restart | PASS در سه فرایند مستقل؛ Manager ثابت و بدون انباشت اتصال | همان سناریو |
| TEST-11 FPS | PASS در ۳۰/۶۰؛ FAIL در هدف ۱۲۰ | fps_30/60/120.json |
| TEST-12 گرافیکی | PASS؛ پنج تصویر واقعی و Exit 0 | graphical_visual.json و JPEGها |
| TEST-13 حرکت | PASS؛ تست قبلی بدون تغییر | auto_run.json |
| TEST-14 پرش | PASS؛ تمام ۲۷ سناریو بدون تغییر | jump.json |
| TEST-15 شکست | PASS؛ تمام ۱۷ سناریو در سه فرایند مستقل | failure_run_1/2/3.json |

مجموعه جدید شامل ۱۲ سناریو است و در سه فرایند مستقل Exit 0 داشت. آزمون ۱۲۰ FPS
جداگانه Exit 1 دارد. Traceها شامل تیک، Attempt، موقعیت، سرعت، Score/Coin، وضعیت و
Signalها هستند. آزمون مستقیم Callback از تماس فیزیکی واقعی در گزارش تفکیک شده است.

## ۱۰. نتیجه P1-011 و P1-014

P1-011: PASS؛ تماس تکراری، ID تکراری، افزایش یک‌باره ۱۰ امتیاز و Collider امن بررسی شدند.
P1-014: PASS؛ پس از کسب ۲۰ امتیاز، برابری y با Kill Y همچنان RUNNING بود؛ عبور 0.25px
یک fall ایجاد کرد. پس از FAILED، Restart نمونه تازه و Score صفر داد. تست‌های مرز و
Restart مرحله ۱.۳ نیز بدون تغییر موفق‌اند. Reset از RUNNING و FAILED هر دو بررسی شده‌اند.

## ۱۱. وضعیت P1-012 و P1-013

کل P1-012: NOT RUN؛ زیرآزمون Coin+Hazard موفق است، اما Finish وجود ندارد.
P1-013 و P1-018/019/020: NOT RUN؛ Finish، رکورد، Unlock، Save و چیدمان نهایی خارج محدوده‌اند.

## ۱۲. نتایج Restart

در هر یک از سه فرایند، ده چرخه جمع‌آوری دو سکه و Restart کامل اجرا شد؛ Attempt از ۱
به ۱۱ رسید. WeakRef نمونه‌های قبلی null، سکه‌ها تازه و قابل مشاهده، IDها ثابت و Score
و شمارنده صفر شدند. ScoreManager همان Instance ماند و تنها یک Reset در هر Restart داشت.
اتصال pickup در هر سکه تازه دو مورد، یعنی Level و Observer تست، و فقط یک World فعال بود.

## ۱۳. مقایسه FPS

ورودی یکسان: ۳۰ تیک استقرار، start_run، بدون Jump یا Restart. هر آزمون ۶۰۰ تیک با
Physics 60 Hz، معادل ۱۰ ثانیه شبیه‌سازی، داشت. اجرا گرافیکی، بدون fixed-fps و بدون
توقف ثبت تصویر بود. نرخ واقعی از تعداد فریم و زمان واقعی اندازه‌گیری شد:

| هدف FPS | FPS واقعی | فریم | زمان واقعی ثانیه | Coin/Score | نتیجه / Exit |
| --- | --- | --- | --- | --- | --- |
| 30 | 29.903687 | 299 | 9.998767 | 3 / 30 | PASS / 0 |
| 60 | 59.597443 | 596 | 10.000429 | 3 / 30 | PASS / 0 |
| 120، آخرین اجرا | 101.635969 | 1015 | 9.986622 | 3 / 30 | FAIL / 1 |

هدف ۱۲۰ در چهار بررسی با نرخ‌های واقعی 99.342974، 95.053680، 75.545932 و 101.635969
محقق نشد. Threadهای پیش‌فرض، ۲، ۱ و ۴ بررسی و همه نتایج حفظ شدند. آخرین تنظیم محیطی
LP_NUM_THREADS=4 بود؛ کد بازی، موتور، Renderer و آستانه تست تغییر نکردند.

Score=30، Coins=3 و ۶۰۰ تیک در همه اجراها صحیح بود؛ این موضوع جای تأیید نرخ واقعی
۱۲۰ را نمی‌گیرد. آستانه از ابتدا ±۱۰٪ نرخ و 10±1 ثانیه بود و ضعیف نشده است.
تأیید TEST-11 روی میزبان مناسب باقی مانده است.

## ۱۴. Regression و فرمان‌های واقعی

E مسیر باینری دقیق زیر و P ریشه پروژه است:
`/workspace/scratch/9fd60dbdba5c/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`

| آزمون | فرمان | Exit | شاهد در phase_1_4_evidence |
| --- | --- | --- | --- |
| Version | E --version | 0 | version_command.json |
| Import | E --headless --editor --path P --quit | 0 | import_command.json |
| Main | E --headless --path P --quit-after 3 | 0 | main_command.json |
| Static | python3 tests/validate_skeleton.py | 0 | static_validation.json |
| Docs | python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_3.zip | 0 | documentation_validation.json |
| Coin، سه فرایند | E --headless --path P --fixed-fps 240 --script res://tests/test_coin_score.gd -- --output=... | 0 هر اجرا | coin_run_1/2/3_command.json |
| حرکت | فرمان بالا با test_auto_run.gd | 0 | auto_run_command.json |
| پرش | فرمان بالا با test_jump.gd | 0 | jump_command.json |
| شکست، سه فرایند | فرمان بالا با test_failure_restart.gd | 0 هر اجرا | failure_run_1/2/3_command.json |
| Runtime تصویری | E --path P --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 60 --script res://tests/test_coin_score.gd -- --visual --output=... | 0 | native_command_visual.txt و log/exit متناظر |
| FPS | فرمان گرافیکی با --max-fps N و --fps-target=N به جای --visual | 0 / 0 / 1 | native_command_30/60/120.txt و log/exit متناظر |
| بسته‌بندی | python3 tools/phase_1_4/package_project.py | 0 | packaging_runner.txt و git_validation_results.json |

آرگومان‌های کامل و مطلق، stdout، stderr و Exit Code در فایل‌های خام ثبت شده‌اند.
Player، Hazard، project.godot، Main، صحنه‌های قبلی و هر سه تست قبلی بایت‌به‌بایت حفظ‌اند.
هیچ Assertion قدیمی حذف یا ضعیف نشده است. حرکت قبلی 2800.008789px در ۶۰۰ تیک و توقف صفر دارد.

## ۱۵. تصاویر Runtime واقعی

Linux/X11؛ OpenGL 4.5، Mesa 25.0.7، llvmpipe LLVM 19.1.7؛ Compatibility، پنجره 1280×720.
پنج JPEG مستقیم از پنجره، بدون بازسازی یا ویرایش، در phase_1_4_evidence هستند:

- before_contact.jpg: تلاش ۱، READY، Score صفر و سه سکه قابل مشاهده.
- contact_pending.jpg: تماس واقعی، pending=true، Score صفر و x=341.9999.
- coin_collected.jpg: سکه اول مخفی، collected=true و Score=10.
- score_increased.jpg: coins=1 و Score=10، سکه اول همچنان برداشته‌شده.
- restart_coins_restored.jpg: تلاش ۲، READY، Score صفر و سکه‌ها دوباره موجودند.

Harness برای هر عکس ۳۵ ثانیه توقف واقعی دارد؛ فریم و دوربین پیش از آن flush می‌شوند.
این توقف فقط ابزار تست تصویری است؛ در آزمون FPS استفاده نشده و PauseManager محصول نیست.
Debug Label و R در اسکریپت مخصوص Prototype هستند؛ Level به UI وابسته نیست.

## ۱۶. خطاها و محدودیت‌های باقی‌مانده

TEST-11 در ۱۲۰ FPS حل نشده است؛ از این رو مرحله INCOMPLETE است. داده امتیاز صحیح است،
اما نرخ واقعی هدف تأیید نشده است. Warning تنظیم VSync میزبان حفظ شده است.
Warningهای ID نامعتبر/تکراری عمداً در تست منفی ایجاد می‌شوند؛ در اجرای نهایی
Parse Error یا Runtime Error جدید مشاهده نشد.

تلاش‌های اولیه ناموفق حفظ شده‌اند: متغیر محلی تکراری و آرگومان اضافی Observer در تست،
و حفظ‌نشدن override Collider داخلی در PackedScene.pack. مورد آخر با مشاهده اندازه
32×32 پیش از Pack و 48×48 پس از آن تشخیص داده شد. اصلاح روی نمونه زنده Fixture،
پیش از شروع فیزیک انجام شد؛ Assertion هم‌زمانی حفظ شده است.

## ۱۷. QAهای باز

QA-001B OPEN؛ QA-001C PASS تاریخی؛ QA-002 OPEN؛ QA-003 NOT RUN.
Editor تعاملی، Android Export و لمس سخت‌افزاری در این مرحله تأیید نشده‌اند.

## ۱۸. فایل‌های جدید و اصلاح‌شده

جدید: coin.gd، score_manager.gd، coin_score_prototype.gd، test_coin_score.gd و چهار UID؛
coin.tscn، coin_score_prototype.tscn، coin_score_world.tscn؛ گزارش، نتایج، Manifest و
پوشه شواهد ۱.۴. اسکریپت Prototype اضافی برای جداسازی Debug UI/R از Level ضروری است.

اصلاح: level_controller.gd، README، GAMEPLAY_ARCHITECTURE، QA_TEST_PLAN، DECISIONS،
PROJECT_STATE، دو Validator و git_validation_results.json. هیچ مسیر مبنا حذف نشده است.

## ۱۹. وضعیت Git

مخزن محلی بدون Commit، Remote یا Push؛ تمام فایل‌های تحویل Stage شده‌اند. گزارش Git
در پایان restage می‌شود. فهرست و تعداد دقیق در Manifest و گزارش Git است.
بررسی whitespace کامل Exit 2 فقط لاگ‌های خام محفوظ را گزارش می‌کند؛ بررسی کد و
مستندات با استثنای فایل‌های raw.txt شواهد Exit 0 است. لاگ‌های قدیمی دستکاری نشده‌اند.

## ۲۰. سلامت ZIP

بسته واقعی HAFT_KOOCHEH_phase_1_4.zip شامل پروژه، کد، صحنه‌ها، تست‌ها، اسناد، لاگ‌ها،
تصاویر و تمام ۱۹۷ مسیر قبلی است. Disk، Index، Manifest و ZIP از نظر فهرست و بایت
مقایسه می‌شوند؛ SHA-256، CRC و استخراج مستقل نیز بررسی می‌شوند. فایل‌های Cache،
.git و __pycache__ وارد بسته نمی‌شوند. Manifest فقط مسیر/تعداد دارد تا خودارجاع نباشد؛
هش تک‌فایل‌ها به‌جز خود گزارش Git در آن گزارش و هش ZIP خارج از آرشیو ثبت می‌شود.
سلامت بسته، به معنی موفقیت آزمون ۱۲۰ FPS نیست.

## ۲۱. Project State جدید

Coin و Score با Failure/Restart یکپارچه شده‌اند؛ حرکت، پرش و شکست قبلی سالم‌اند.
DEC-040 تا DEC-042 قراردادها را ثبت می‌کنند. Save، کیف پول، رکورد، Finish، مراحل بازار
یا سیستم خارج از ۱.۴ ایجاد نشده است. Project State و Manifest مرجع وضعیت جاری‌اند.
پارامترهای حرکت و پرش بدون تغییرند.

## ۲۲. نتیجه نهایی

INCOMPLETE. کد مکانیک، ۱۲ سناریو در سه فرایند، Regression قبلی، اجرای گرافیکی واقعی
و تصاویر موفق‌اند؛ ولی آزمون الزامی نرخ واقعی ۱۲۰ FPS موفق نشده است. بسته کامل با
شواهد موفق و ناموفق تحویل می‌شود. مرحله ۱.۵ آغاز نشده است.

کار باقی‌مانده: فراهم‌کردن مسیر اجرای معتبر ۱۲۰ FPS و تکرار TEST-11 بدون تغییر معیار؛
سپس بررسی مدیر پروژه. هیچ آزمون ناموفق یا اجرا‌نشده‌ای PASS اعلام نشده است.

تعداد نهایی فایل‌های تحویل: 294؛ تمام ۱۹۷ مسیر مبنا حفظ شده‌اند.
