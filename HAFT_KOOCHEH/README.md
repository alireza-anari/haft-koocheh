# وضعیت جاری: HAFT KOOCHEH ۱.۴

Coin و امتیاز هر تلاش به Prototype افزوده شده‌اند؛ QA-001B و QA-002 بازند.
روش اجرای جاری در بخش «تحویل جاری: ۱.۴» پایین همین فایل است؛ بخش‌های پیشین تاریخچه‌اند.
Main Scene پیش‌فرض همچنان عنوان است. بخش ۰.۲ زیر مرجع تاریخی پیش از گیم‌پلی است.

# HAFT KOOCHEH — مرحله ۰.۲

پایه مستند یک بازی 2D Auto-Runner برای Android؛ **هیچ گیم‌پلی پیاده‌سازی نشده است**.
مرحله ۰.۱/R1 با استثنای QA-001 طبق دستور مدیر پروژه پذیرفته شده؛ تحویل جاری
اسناد طراحی و استاندارد توسعه برای بررسی مرحله ۰.۲ است و مجوز ساخت Prototype نیست.

## محیط و اجرای اسکلت

Godot **4.7.2 Stable Standard**، GDScript، Compatibility؛ بدون .NET، Beta یا Dev.
1280×720، Landscape، stretch=canvas_items، aspect=keep و physics=60 Hz.
ZIP کامل را استخراج و project.godot را با همین موتور باز کنید. F5 پروژه یا F6 صحنه
scenes/app/main.tscn را اجرا می‌کند؛ خروجی مورد انتظار فقط عنوان مرکزی HAFT KOOCHEH است.
تأیید بصری این عنوان هنوز انجام نشده و QA-001 باز است.

از ریشه پروژه، godot را با مسیر واقعی باینری جایگزین کنید:

```sh
godot --version
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --editor --path .
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py
```

تست مستندات با ZIP مبنای R1 برای بررسی بایتی کامل:

```sh
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_0_1_R1.zip
```

ZIP مبنای R1 جزو بسته جاری نیست؛ از تحویل قبلی نگه دارید. بدون --baseline بخش
مقایسه بایتی NOT RUN می‌شود و بقیه بررسی‌ها اجرا می‌شوند. Python 3.12 محیط آزمون است؛
کتابخانه اضافه لازم نیست. تست ایستا کیفیت بازی، تصویر یا Android را اثبات نمی‌کند.
config/features قفل patch موتور نیست؛ --version باید دقیقاً 4.7.2.stable باشد.
باینری موتور و .git در ZIP نیستند؛ مخزن محلی Workspace Stage شده ولی Commit/Remote ندارد.
پس از clone پوشه‌های خالی را طبق [PROJECT_STRUCTURE.md](docs/PROJECT_STRUCTURE.md) بازسازی کنید.

## نقشه اسناد جاری

| موضوع | سند |
| --- | --- |
| طراحی بازی و MVP | [GDD.md](docs/GDD.md) |
| قرارداد هشت سیستم | [GAMEPLAY_ARCHITECTURE.md](docs/GAMEPLAY_ARCHITECTURE.md) |
| حرکت، لمس و فیزیک آزمایشی | [PLAYER_MOVEMENT_SPEC.md](docs/PLAYER_MOVEMENT_SPEC.md) |
| ده طرح مرحله دستی | [LEVEL_DESIGN_SPEC.md](docs/LEVEL_DESIGN_SPEC.md) |
| استاندارد هنر و مجوز | [ASSET_GUIDE.md](docs/ASSET_GUIDE.md) |
| مبانی فنی | [TECHNICAL_DESIGN.md](docs/TECHNICAL_DESIGN.md) |
| تصمیمات و وضعیت آن‌ها | [DECISIONS.md](docs/DECISIONS.md) |
| QA و میزبان گرافیکی جایگزین | [QA_TEST_PLAN.md](docs/QA_TEST_PLAN.md) |
| ممیزی قبلی محیط | [ENVIRONMENT_AUDIT.md](docs/ENVIRONMENT_AUDIT.md) |
| وضعیت قابل ادامه | [PROJECT_STATE.md](docs/PROJECT_STATE.md) |
| گزارش تحویل جاری | [PHASE_0_2_REPORT.md](docs/PHASE_0_2_REPORT.md) |

مسیرهای .gd/.tscn ماژول‌های آینده داخل اسناد پیشنهاد معماری‌اند و هنوز فایل واقعی نیستند.
عددهای حرکت، جدول مراحل، فرمول امتیاز و جزئیات داستان/هنر آزمایشی یا پیشنهادی‌اند؛
نوشتن آن‌ها تصویب نهایی محصول نیست. دامنه قطعی MVP فقط یک شخصیت و بازار هزاررنگ است.

## gateهای باز

QA-001: اعتبارسنجی گرافیکی پیش از شروع پیاده‌سازی عملی Prototype؛ روش انجام روی
میزبان گرافیکی دیگر و شواهد لازم در QA آمده است. استثنای مدیریتی ۰.۱ این تست را PASS نمی‌کند.
QA-002: JDK/SDK/Templates مطابق ممیزی، پیش از Android Export؛ Debug APK ساخته نشده است.
تا مرحله مجاز هیچ Export، Release key یا اطلاعات امضا تولید/درخواست نمی‌شود.
بدون تأیید مدیر پروژه وارد ۱.۱ نمی‌شویم.

# تحویل جاری: ۱.۱-R1 — Prototype حرکت خودکار

DEC-033 توسعه متن‌محور Prototype را پس از QA-001C مجاز کرده است. QA-001C اکنون
PASS است؛ QA-001B هنوز باز و پیش از Vertical Slice لازم است؛ QA-002 قبل از Export.
بخش‌های قبلی README وضعیت تاریخی اسکلت‌اند. اکنون Player و صحنه فنی حرکت وجود دارند؛
F5/اجرای پیش‌فرض همچنان فقط عنوان HAFT KOOCHEH است و Main Scene تغییر نکرده است.

## اجرای Prototype

با **Godot 4.7.2 Stable Standard** از ریشه پروژه:

```sh
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 res://scenes/gameplay/prototype_run.tscn
```

Player مستطیلی موقت، پس از استقرار روی زمین به راست حرکت می‌کند؛ ورودی لازم نیست.
Camera تعقیب می‌کند. زمین ازx=-400 تا11600 است؛ برای تست ده‌ثانیه‌ای کافی است، ولی
صحنه مرحله نهایی/بی‌نهایت نیست و پس از حدود40 ثانیه دویدن به انتهای زمین می‌رسد.
سیستم شکست/Restart/پرش وجود ندارد. DISABLED حرکت افقی را صفر می‌کند؛ گرانش همچنان
برای استقرار عمودی اعمال می‌شود. Player به‌طور پیش‌فرض DISABLED و فعال‌سازی فقط
در کنترل‌کننده کوچک صحنه فنی است؛ عنوان و منوی آینده حرکت را خودکار شروع نمی‌کنند.

## بازتولید آزمون

```sh
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_0_2_R1.zip
godot --headless --editor --path . --quit
godot --headless --path . --fixed-fps 60 --script res://tests/test_auto_run.gd
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 30 --script res://tests/test_auto_run.gd -- --hold --fps-target=30
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 60 --script res://tests/test_auto_run.gd -- --hold --fps-target=60
```

تست JSON نتیجه و نمونه موقعیت هر60tick را در stdout چاپ و با کد0/1 خارج می‌شود.
`--output=/absolute/path/result.json` پس از `--` خروجی JSON را در مسیر دلخواه می‌نویسد.
در --hold تست پس از نتیجه۳۰ ثانیه برای عکس باقی می‌ماند؛ overlay فنی فقط در harness
تست ساخته می‌شود و UI محصول نیست. tick روی overlay هنگام حرکت می‌تواند یک نمونه
عقب‌تر از position باشد؛ اندازه‌گیری دقیق در POSITION_SAMPLE و TEST_RESULT است.
--fixed-fps در Headless زمان شبیه‌سازی را سریع پیش می‌برد و benchmark FPS نیست.
در Linux نرم‌افزاری برای بازتولید محیط ما می‌توان LIBGL_ALWAYS_SOFTWARE=1 تنظیم کرد؛
هشدار V-Sync میزبان را ثبت کنید و خطاها را با خروج صفر یکسان نگیرید.

گزارش جاری: docs/PHASE_1_1_R1_REPORT.md؛ وضعیت: docs/PROJECT_STATE.md؛
شواهد، تصاویر و داده‌ها: docs/phase_1_1_r1_evidence/؛ نتایج: docs/phase_1_1_r1_test_results.json.
باینری موتور، کپی QA-001C و fixtureهای منفی داخل بسته نیستند؛ هیچ متن آزمایشی وارد Main نشده است.
تا تأیید مدیر، مرحله ۱.۲ و پرش شروع نمی‌شوند.

## تحویل جاری: ۱.۲

از ریشه پروژه، با Godot 4.7.2 Stable Standard:

```sh
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 res://scenes/gameplay/prototype_run.tscn
```

Player خودکار به راست می‌رود؛ Space یا Touch Press نخست یک پرش ثابت ایجاد می‌کند.
رهاسازی ارتفاع را تغییر نمی‌دهد؛ پرش دوم در هوا مجاز نیست. UI مصرف‌کننده ورودی
اولویت دارد. Main Scene پیش‌فرض همان عنوان اولیه است؛ این صحنه فقط Prototype است.
لمس از طریق InputEvent آزمایش شده؛ لمس سخت‌افزاری Android هنوز NOT RUN است.

```sh
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_1_R1.zip
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --headless --path . --fixed-fps 240 --script res://tests/test_auto_run.gd -- --output=/tmp/auto_run.json
godot --headless --path . --fixed-fps 240 --script res://tests/test_jump.gd -- --output=/tmp/jump_suite.json
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 30 --script res://tests/test_jump.gd -- --fps-target=30 --output=/tmp/jump_fps_30.json
```

برای 60 و 120 FPS هر دو مقدار max-fps و fps-target را تغییر دهید. fixed-fps فقط
برای شتاب آزمون Headless است؛ آزمون FPS گرافیکی از زمان واقعی و شمارش فریم استفاده می‌کند.
گزینه --visual تست پرش را در سه فریم واقعی 20 ثانیه متوقف می‌کند تا تصویر ثبت شود؛
این توقف‌ها صرفاً در تست‌اند و در اندازه‌گیری FPS استفاده نمی‌شوند.

[گزارش مرحله](docs/PHASE_1_2_REPORT.md)، [نتایج ماشین‌خوان](docs/phase_1_2_test_results.json)
و [وضعیت پروژه](docs/PROJECT_STATE.md) مرجع تحویل فعلی‌اند. هیچ مرحله بعدی خودکار آغاز نمی‌شود.

## تحویل جاری: ۱.۳

Main Scene پیش‌فرض هنوز عنوان است؛ برای صحنه فنی شکست از ریشه پروژه اجرا کنید:

```sh
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 res://scenes/gameplay/failure_prototype.tscn
godot --headless --path . --fixed-fps 240 --script res://tests/test_failure_restart.gd -- --output=/tmp/failure.json
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 60 --script res://tests/test_failure_restart.gd -- --visual --output=/tmp/failure_visual.json
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_2.zip
```

همه فرمان‌ها با Godot4.7.2 Stable Standard اجرا شوند. تست failure را سه بار در فرایندهای
مستقل اجرا کنید؛ هر بار17سناریو و ده Restart متوالی بررسی می‌شود. --visual در چهار
وضعیت40ثانیه برای تصویر واقعی توقف می‌کند. نمایش Label فقط متعلق به Test Harness است؛
UI نهایی و کلید Restart محصول ساخته نشده‌اند. API مستقیم LevelController شامل
start_run، restart_run و exit_to_menu است؛ Restart کل failure_world.tscn را تازه می‌سازد.
زمین امن y600، kill_y1000 و KillZone با مرز بالا820 است؛ عدد360 طرح قدیمی کپی نشده است.

[گزارش۱.۳](docs/PHASE_1_3_REPORT.md)، [نتایج۱.۳](docs/phase_1_3_test_results.json)
و [Project State](docs/PROJECT_STATE.md) مرجع جاری‌اند. تست‌های قبلی حرکت و پرش حفظ‌اند؛
بخش‌های۱.۲ و پیش‌تر تاریخچه‌اند. QA-003 لمس دستگاه واقعی NOT RUN است؛ مرحله۱.۴ مجاز نیست.

## تحویل جاری: ۱.۴

با Godot4.7.2 Stable Standard از ریشه پروژه:

```sh
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 res://scenes/gameplay/coin_score_prototype.tscn
godot --headless --path . --fixed-fps 240 --script res://tests/test_coin_score.gd -- --output=/tmp/coin_score.json
godot --path . --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps 30 --script res://tests/test_coin_score.gd -- --fps-target=30 --output=/tmp/coin_fps30.json
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_3.zip
```

Space/Touch پرش قبلی و R فقط Restart آزمایشی است. سهCoin با ID ثابت و امتیاز10هرکدام
Placeholder مکانیک‌اند؛ محتوای نهایی بازار یاHUD نهایی نیستند. ScoreManager درRestart
همان نمونه باقی و داده‌هاصفر می‌شوند. هیچ Save، کیف پول، رکورد یاFinish نداریم.
برایFPS60/120، هر دو مقدار max-fps و fps-target را تغییر دهید؛ فیزیک60 باقی می‌ماند.
تست جدید را سه بار مستقل اجرا کنید؛ هر بار12سناریو و دهRestart جمع‌آوری/Reset دارد.
--visual پنج حالت واقعی را هرکدام35ثانیه برای ثبت تصویر متوقف می‌کند؛ توقف فقط در
Harness است و در تستFPS استفاده نمی‌شود. Main پیش‌فرض همچنان عنوان اولیه است.

[گزارش۱.۴](docs/PHASE_1_4_REPORT.md)، [نتایج۱.۴](docs/phase_1_4_test_results.json)
و [Project State](docs/PROJECT_STATE.md) مرجع فعلی‌اند؛ بخش‌های قبل تاریخچه‌اند.
مرحله۱.۵ نیازمند بررسی و مجوز جدید است. QAهای باز بدون تغییرند.


وضعیت پذیرش۱.۴: INCOMPLETE؛ هدف واقعی120FPS روی میزبان فعلی تأیید نشده است.
آزمون‌های مکانیک وRegression موفق‌اند؛ برای تکمیل پذیرش،TEST-11 باید روی میزبان
مناسب دوباره اجرا شود. داده‌های نرخ واقعی و همه تلاش‌های ناموفق داخل بسته حفظ‌اند.
