# گزارش فنی HAFT KOOCHEH — مرحله۱.۳

## ۱. مشخصات مرحله

Collision, Hazard, Death & Restart System؛ فازیک؛ COMPLETE از نظر فنی و در انتظار
بررسی مدیر پروژه. مبنای مجوز: دستور پیوست مرحله۱.۳؛ مرحله۱.۴ آغاز نشده است.

## ۲. وضعیت اولیه

پروژه واقعی در `/workspace/scratch/9fd60dbdba5c/HAFT_KOOCHEH`. پیش از تغییر، ZIP مبنا در tools/phase_1_3/baseline_extracted
استخراج و تمام مسیرها/بایت‌ها با Manifest، Disk و Git Index مقایسه شد؛ PASS.
هفت سند مرجع و کد/صحنه‌های Player، Prototype و تست‌ها بررسی شدند. تعارض محصولی
نیازمند تغییر قرارداد یافت نشد. طرح اجرایی در شواهد ثبت است.

## ۳. تعداد فایل‌های مبنا

140فایل؛ هیچ مسیر مبنا حذف نشده است. baseline_validation.json شاملSHA-256 تمام آن‌هاست.
تعداد نهایی تحویل از فایل‌های واقعی محاسبه و در Manifest و گزارش Git ثبت می‌شود.

## ۴. معماری Player جدید

همان CharacterBody2D با Collider32×48، GDScriptTyped و move_and_slide؛ بدون تغییر
پارامترهای280/1200/-480/0.08/0.10 یا Physics60Hz. حالت DEAD اضافه، configure و
freeze_on_failure اضافه شدند؛ Player نتیجه نهایی Level را تعیین نمی‌کند.

## ۵. قرارداد Collision

پس از move_and_slide، نرمال x<-0.7 در حرکت راست، تماس جانبی محسوب می‌شود؛ blocked
فقط در لبه شروع تماس صادر و پس از جدایی rearm می‌شود. فرود و تماس سقف شکست نیستند.
نرمال‌های واقعی در trace هستند. Player Layer2/Mask1، World Layer1/Mask2 حفظ‌اند.

## ۶. معماری Hazard

hazard.tscn: Area2D، CollisionShape2D و Polygon2D موقت؛ Layer4/Mask2. hazard_id و reason
از نوعStringName؛ فقط hazard/fall معتبرند. configure مرجع Player و attempt را تزریق
می‌کند؛ هویت دقیق، attempt و RUNNING بررسی می‌شوند. Group کافی فرض نشده است.
body_entered فقط hazard_contact می‌سازد؛ Level callback فقط صف را پر می‌کند.
تماس از کنار و بالا با فیزیک واقعی تست شد؛ non-Player و attempt اشتباه با API فیلتر رد شدند.

## ۷. منطق Kill Y

شرط دقیق global_position.y > kill_y؛ برابری امن است. Player در Prototype قدیمی
kill_y=INF دارد تا رفتار قبلی عوض نشود؛ Level صریحاً1000 تنظیم می‌کند. همه Fixtureها
سطح امن600 و clearance400px دارند، بیش از160px الزامی. KillZone یک Hazard با reason=fall
است؛ مرکز860، ارتفاع80، مرز بالا820. مقدار360 طرح قدیمی بدون تطبیق کپی نشد.

## ۸. معماری LevelController

LevelController با priority=-100 پیش از Player0 اجرا می‌شود؛ فعال‌بودن Player، attempt،
صف رویداد و نتیجه را مالک است. failure_prototype.tscn ترکیب فنی Controller است؛ فایل
اضافی ضروری failure_world.tscn کل جهان را در یک PackedScene مستقل نگه می‌دارد تا
Restart بدون بازنشانی شمارنده تلاش، تمام Player/Hazard/Collider/Camera را تازه بسازد.
Autoload، Plugin، EventBus یا سرویس جهانی ساخته نشده است.

## ۹. چرخه READY/RUNNING/FAILED

World تازه ابتداPlayerDISABLED در Start(160,550) دارد. گرانش برای استقرار حفظ است؛
پس از is_on_floor، start_run آن راRUNNING می‌کند. شکست در تیک بعد ابتداFreeze و سپس
FAILED و یک run_failed می‌سازد. PAUSED/COMPLETED فقط قرارداد آینده‌اند و اجرا نشده‌اند.

## ۱۰. Attempt ID

شمارنده محلی با هر جهان تازه افزایش می‌یابد. queue_failure هم مرجع دقیق Player
و هم attempt را کنترل می‌کند؛ صف نیز source instance ID/attempt را دوباره بررسی می‌کند.
اتصال‌های تأخیری WeakRef دارند؛ پس از آزادشدن نمونه، null امن رد می‌شود. Callback
قدیمی در READY و RUNNING تلاش جدید آزمایش و بدون اثر بود.

## ۱۱. رفتار Freeze

DEAD، سرعتVector2.ZERO، Buffer/Coyote/latch پاک، ورودی جدید بی‌اثر؛ _physics_process
در DEAD برمی‌گردد، بنابراین jumped/landed ناخواسته نداریم. enable(true) و configure
همان نمونه را زنده نمی‌کنند. علاوه بر Freeze پس از شکست، در contact_signal_rearm
Coyote واقعی خروج از لبه و Buffer معلق پر و سپس هر دو با Freeze پاک شدند.

## ۱۲. رفتار Restart

restart_run درخواست‌های هم‌زمان را یکی می‌کند؛ تلاش قبلی بسته/Freeze، صف پاک و تعویض
World deferred می‌شود. World قبلی واقعاًfree، همان PackedScene دوبارهInstance و attempt
افزوده می‌شود. WeakRefهای Player/World/Hazard قبلی null، مختصات و Hazardها به مرجع
برگشته و تایمرهاخالی‌اند. پس از استقرار، حرکت و پرش تازه آماده‌اند. این بازگرداندن
صرف موقعیت نیست. ده Restart در هرکدام از سه فرایند مستقل موفق بود.

## ۱۳. تقدم شکست‌های هم‌زمان

fall>hazard>wall، مستقل از ترتیب صف. Callbackها هیچ تغییر صحنه/نتیجه نهایی ندارند.
Engine.get_physics_frames مبنای پنجره است؛ فقط event.tick < current_tick داوری می‌شود.
آزمون priority با دو ترتیب و جفتhazard/wall موفق است؛ آزمون producerpriority=-200
ثابت می‌کند حتی رویداد پیش از Controller در همانframe صرفاًصف است و در تیک بعد
پیش از حرکت بیشتر Freeze می‌شود. در FAILED تمام رویدادهای دیررس/تکراری ردند.

## ۱۴. نتایج TEST-01 تا TEST-15

| تست | سناریو | نتیجه واقعی |
| --- | --- | --- |
| TEST-01 | wall_freeze_late_input | blocked=1، run_failed=1، DEAD، vx/vy=0 |
| TEST-02 | safe_landing_and_ceiling | فرود و سقف واقعی بدون شکست؛ landed درست |
| TEST-03 | hazard_side، hazard_top | Area واقعی از کنار و بالا؛ hazard، یک شکست |
| TEST-04 | kill_y_-0.25،0.0،0.25 | کمتر/برابر امن، بیشتر fall |
| TEST-05 | killzone | Area با reason=fall، یک شکست |
| TEST-06 | wall_freeze_late_input، contact_signal_rearm | Freeze کامل؛ Buffer/Coyote پرشده نیز پاک |
| TEST-07 | wall_freeze_late_input | Space/Touch/API پس از DEAD بی‌اثر |
| TEST-08 | سه priority_* و early_callback_next_tick | fall>hazard>wall؛ Callback فقط صف؛ داوری پیش از حرکت تیک بعد |
| TEST-09 | identity_and_full_restart | هویت/attempt اشتباه و callback نمونه آزادشده رد |
| TEST-10 | identity_and_full_restart | Player/World/Hazard تازه، Start، تایمرها و پرش آماده |
| TEST-11 | ten_consecutive_restarts | attempt1→11، ده شکست/ده Restart، تک‌جهان و بدون انباشت اتصال |
| TEST-12 | exit_menu_unpauses | Main واقعی، Pause=false و Level قبلی آزاد |
| TEST-13 | test_auto_run.gd | 600تیک/10s، dx2800.008789، توقف0 |
| TEST-14 | test_jump.gd | تمام27سناریو PASS، بدون تغییر فایل/assertion |
| TEST-15 | Runtime native دو اجرا | تصاویر واقعی wall/hazard/fall/restart؛17سناریو PASS |

تمام TEST-01 تا12 با مجموعه17سناریویی در سه فرایند مستقل اجرا و هر بارExit0 شدند؛
TEST-13/14 با تست‌های اصلی بدون تغییرExit0؛ TEST-15 دو اجرای واقعی17سناریوییExit0.
trace هر تیک شامل موقعیت، سرعت، attempt، نرمال برخورد، state/reason و شمارSignalهاست.
سناریوهای داوری و دهRestart رویداد معتبر را مستقیم وارد API صف می‌کنند؛ برخوردها،
Hazard ازدو جهت، KillZone و سقوط از فیزیک واقعی‌اند. این تفاوت در نتیجه پنهان نشده است.

## ۱۵. نتایج Regression و فرمان‌های واقعی

E باینری دقیق `/workspace/scratch/9fd60dbdba5c/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64` و P ریشه پروژه است.
فرمان‌های کامل مطلق، stdout/stderr و Exit Code در فایل‌های شواهد زیر ثبت‌اند:

| آزمون | فرمان | Exit | شاهد در docs/phase_1_3_evidence |
| --- | --- | --- | --- |
| Version | E --version |0|version_command.json |
| Import | E --headless --editor --path P --quit |0|import_command.json |
| Main | E --headless --path P --quit-after 3 |0|main_command.json |
| Static | python3 tests/validate_skeleton.py |0|static_validation.json |
| Documentation | python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_2.zip |0|documentation_validation.json |
| حرکت | E --headless --path P --fixed-fps 240 --script res://tests/test_auto_run.gd -- --output=... |0|auto_run_command.json، auto_run.json |
| پرش | E --headless --path P --fixed-fps 240 --script res://tests/test_jump.gd -- --output=... |0|jump_command.json، jump.json |
| Failure/Hazard/KillY/Restart/Layers/Attempt | E --headless --path P --fixed-fps 240 --script res://tests/test_failure_restart.gd -- --output=... |0 هر سه|failure_run_1/2/3_command.json وtraceهای متناظر |
| Native Runtime | E --path P --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 60 --script res://tests/test_failure_restart.gd -- --visual --output=... |0|graphical_command/runtime/exit.txt، graphical.json |
| Native Fall Capture | فرمان بالا با --capture-only=fall_failed |0|graphical_fall_command/runtime/exit.txt، graphical_fall.json |
| بسته‌بندی | python3 tools/phase_1_3/package_project.py |0|نسخه runner در شواهد؛ نتایج درgit_validation_results.json |

fixed-fps240 فقط شتابHeadless است؛ گرافیکی بدون آن اجرا شد. نرخ فیزیک60 تغییر نکرد.
صحنه عنوان، player.tscn، Prototype قبلی، prototype_run.gd، test_auto_run.gd وtest_jump.gd
با مبنا بایت‌به‌بایت یکسان‌اند؛ تمام140مسیر باقی‌اند. تست/Assertion قبلی حذف یا ضعیف نشد.

## ۱۶. تصاویر Runtime واقعی

LinuxDesktop/X11 :0؛ Godot4.7.2 Standard؛ OpenGL4.5، Mesa25.0.7 llvmpipe LLVM19.1.7،
Compatibility؛ پنجره1280×720. چهار JPEG خروجی مستقیم پنجره، بدون تغییر/بازسازی:

- phase_1_3_evidence/wall_failed.jpg: FAILED/wall، x613.997، y599.982، vx/vy0.
- phase_1_3_evidence/hazard_failed.jpg: FAILED/hazard، x323.333، y599.982، vx/vy0.
- phase_1_3_evidence/fall_failed.jpg: FAILED/fall، x1247.333، y1008.315، vx/vy0.
- phase_1_3_evidence/restarted_running.jpg: RUNNING، attempt2، x174.025، vy-480.

Test Harness فقط برای عکس، transforms وCamera scroll را flush وSceneTree را40ثانیه
واقعی متوقف می‌کند. تصویر سقوط از اجرای تکمیلی --capture-only=fall_failed است؛ اجرای نهایی دیگر
با --capture-only=none بدون توقف ثبت عکس، تمامSuite را گرافیکی بررسی کرد. تمام آنSuite نیز
PASS شد. این توقف، Freeze سیستم شکست یا PauseManager محصول نیست. تصویر و لاگ تیک
هر دو حفظ‌اند؛ عکس مصنوعی، Mockup یا Headless جای شاهدگرافیکی استفاده نشده است.

## ۱۷. خطاهای باقی‌مانده

خطای جدید Parse/Resource/Runtime در اجراهای نهایی مشاهده نشد. هشدار VSync نرم‌افزاری
میزبان در log حفظ شده؛ رندر موفق به معنی تضمین کارایی گوشی نیست. نخستین Fixture شروع
به علت بررسی پس از تیک اول گرانش FAIL شد؛ با ترتیب صریح setup پیش از فیزیک اصلاح شد،
assertion مختصات دقیق حفظ و لاگ اولیه نگه داشته شد. ثبت تصویر پس از flush فریم انجام
شد تا موقعیت رندر با همان فریم فیزیک منطبق باشد. در یک تلاش ثبت تصویر، فایل راه‌انداز هنگام انتظار Bash برایGodot ویرایش شد و
ثبت Exit Code آن تلاش با خطایEOF wrapper قابل اتکا نبود. exit قدیمی کنار گذاشته شد؛
آن تلاش با exit=null/NOT RECORDED در شواهد ثبت است و PASS فرایند شمرده نمی‌شود.
دو اجرای نهایی با راه‌انداز ثابت Exit0 دارند؛ launcher_diagnosis.json علت و اصلاح را ثبت می‌کند.
مشکل محصولی باز در محدوده فعلی یافت نشد.

## ۱۸. QAهای باز و موارد خارج محدوده

QA-001B OPEN؛ QA-001C PASS تاریخی؛ QA-002 OPEN؛ QA-003 لمس سخت‌افزاری NOT RUN.
Editorتعاملی و Android در این مرحله آزمایش/بسته نشده‌اند. P1-011/012/013/018/019/020/022
خارج محدوده وNOT RUN؛ P1-014 بخشScoreReset تا وجودScoreManager درمرحله۱.۴ NOT RUN.
خروج از درختpaused فقط TEST-12 است، نه P1-022 یاPauseManager.

## ۱۹. فایل‌های ایجادشده

scripts/gameplay/level_controller.gd؛ scripts/obstacles/hazard.gd؛ tests/test_failure_restart.gd
و سهUID متناظر؛ scenes/obstacles/hazard.tscn؛ scenes/gameplay/failure_prototype.tscn؛
scenes/gameplay/failure_world.tscn (ضروری برای PackedScene جهان تازه)؛ گزارش حاضر؛
phase_1_3_test_results.json؛ phase_1_3_manifest.json؛ پوشهphase_1_3_evidence با شواهد واقعی.

## ۲۰. فایل‌های اصلاح‌شده

scripts/player/player_controller.gd؛ README.md؛ docs/GAMEPLAY_ARCHITECTURE.md؛
docs/QA_TEST_PLAN.md؛ docs/DECISIONS.md؛ docs/PROJECT_STATE.md؛ دوValidator موجود؛
docs/git_validation_results.json. هیچ فایل ضروری حذف نشده، project.godot تغییر نکرده است.

## ۲۱. وضعیت Git

مخزن محلی با HEAD بدونCommit و بدونRemote؛ هیچCommit/Push ایجاد نشده است. تمام فایل‌ها
Stage و گزارش خودارجاعGit در انتها restage می‌شود. فهرست دقیق و تعداد واقعی در
git_validation_results.json و phase_1_3_manifest.json است. بررسی whitespace کامل شامل
لاگ‌های خام تاریخی است؛ Exit2 فقط آن فایل‌ها را گزارش می‌کند. بررسی کد/مستندات با
استثنای raw.txt شواهد Exit0 است؛ شواهد قدیمی برای تمیزکردن ظاهری تغییر نکرده‌اند.

## ۲۲. سلامت ZIP

نام HAFT_KOOCHEH_phase_1_3.zip؛ Disk/Index/Manifest/ZIP در فهرست و بایت برابرند.
SHA-256 همه فایل‌ها، CRC همه ورودی‌ها و استخراج به پوشه مستقل بررسی می‌شوند؛ ساختار
پوشه‌های خالی حفظ و .git/.godot/__pycache__/فایل‌های موقت حذف‌اند. Manifest مسیر/تعداد
دارد تا خودارجاع نشود؛ هش فایل‌ها به‌جز خود گزارشGit در آن گزارش ثبت است. هش ZIP
خارج از خود ZIP ثبت می‌شود. نتیجه فنی فقط پس از گذر همین assertionها تحویل می‌شود.

## ۲۳. Project State جدید

Player حرکت/پرشقبلی را دارد و DEAD/Collision/KillY افزوده شده؛ Hazard وLevelمحلی
تشخیص/داوری وRestartکامل را اجرا می‌کنند. DEC-037تا039 علت و اثر انتخاب‌ها را ثبت
می‌کنند. هیچ Coin/Score/Save/Finish/EnemyAI/Audio/PauseManager/محتوایBazaar/Export ایجاد نشده است.
PROJECT_STATE.md مرجع جاری؛ تعداد نهایی بر اساس Manifest واقعی ثبت می‌شود.

## ۲۴. نتیجه نهایی

COMPLETE از نظر فنی مرحله۱.۳؛ در انتظار بررسی مدیر پروژه. 17سناریو×3 اجرای مستقل،
دهRestartدرهراجرا، Regressionحرکت/27پرش، Import/Main/Validatorها وRuntimeگرافیکی موفق‌اند.
بسته واقعی ZIP و گزارش جداگانه ارائه می‌شوند. تصمیم محصولی تازه لازم نیست؛ ورود۱.۴
تنها پس از تأیید رسمی این مرحله مجاز است و اکنون آغاز نشده است.

تعداد نهایی فایل‌های این تحویل: 197؛ فهرست دقیق مطابق Manifest و Git Index است.
