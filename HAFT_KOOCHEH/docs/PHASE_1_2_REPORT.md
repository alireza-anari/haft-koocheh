# گزارش مرحله ۱.۲ — پرش ثابت، ورودی تک‌لمسی و فیزیک پرش

## ۱. مشخصات مرحله

فاز یک، ۱.۲؛ وضعیت فنی COMPLETE، منتظر پذیرش مدیر پروژه. مجوز بر پایه پذیرش
مرحله ۱.۱-R1 است؛ مرحله ۱.۳ آغاز نشده است. زمان اجرای نهایی 2026-11-16 UTC.

## ۲. وضعیت اولیه پروژه

بسته مبنا HAFT_KOOCHEH_phase_1_1_R1.zip، 90 فایل. قبل از تغییر، ساختار و کد Player،
صحنه‌ها، test_auto_run و PLAYER_MOVEMENT_SPEC خوانده شدند؛ baseline_checks.json
هش‌ها و نتایج سلامت مبنا را حفظ می‌کند. Godot واقعی 4.7.2.stable.official.ed1daf0bf
Standard؛ محیط CLI Linux، میزبان Desktop Linux/X11 :0، Mesa25.0.7 llvmpipe LLVM19.1.7،
OpenGL4.5 Compatibility. موتور پیش‌فرض میزبان استفاده نشد؛ باینری دقیق پروژه اجرا شد.

## ۳. فایل‌های ایجادشده

- tests/test_jump.gd و tests/test_jump.gd.uid: تست رفتار همین مرحله با Fixture در حافظه.
- docs/PHASE_1_2_REPORT.md و docs/phase_1_2_test_results.json.
- docs/phase_1_2_manifest.json: فهرست نهایی مسیرها؛ بدون هش خودارجاع.
- docs/phase_1_2_evidence/: لاگ خام، trace JSON، فرمان/Exit Code و سه تصویر واقعی.

## ۴. فایل‌های اصلاح‌شده

scripts/player/player_controller.gd؛ tests/validate_skeleton.py؛ tests/validate_documentation.py؛
README.md؛ docs/PLAYER_MOVEMENT_SPEC.md؛ docs/QA_TEST_PLAN.md؛ docs/DECISIONS.md؛
docs/PROJECT_STATE.md؛ docs/git_validation_results.json. فایل ضروری حذف نشده است.
Validatorها فقط allowlist مرحله، مقایسه مبنای90فایلی و DECهای جدید را گسترش داده‌اند؛
کنترل‌های تنظیمات، حفظ تاریخچه، صحنه‌ها و دامنه ممنوع باقی‌اند.

## ۵. معماری نهایی پرش

Player همان CharacterBody2D است؛ منطق فیزیک در _physics_process و حرکت با
move_and_slide. request_jump یک درخواست معلق می‌سازد؛ Player داور نهایی پرش است.
DISABLED/RUNNING حفظ شده‌اند؛ تشخیص زمین از فیزیک داخلی است. Coyote فقط خروج طبیعی
از لبه است؛ پرش عمدی آن را مصرف می‌کند. jumped هنگام پرش و landed هنگام تماس واقعی
از هوا صادر می‌شوند. هیچ Autoload، Plugin یا سیستم جانبی اضافه نشده است.

## ۶. تنظیمات واقعی فیزیک

run_speed=280 px/s؛ gravity=1200 px/s²؛ jump_velocity=-480 px/s؛ coyote_time=0.08 s؛
jump_buffer=0.10 s؛ Physics60 Hz. تیک اول پرش بدون گرانش، بقیه با delta؛ پس از فرود vy=0.
project.godot و سه صحنه قبلی دقیقاً حفظ شده‌اند. همه اعداد آزمایشی‌اند.

## ۷. پیاده‌سازی Space و Touch

_input فقط وضعیت فشردن/رهاسازی و انگشت اصلی را ثبت می‌کند؛ _unhandled_input فقط press
نخست مصرف‌نشده را به request_jump می‌دهد. Key Echo، Release، Drag و انگشت دوم درخواست
نمی‌سازند. وضعیت نگه‌داشتن از DISABLED عبور می‌کند اما درخواست‌ها پاک می‌شوند؛ از
press مصنوعی پس از فعال‌سازی جلوگیری می‌شود. InputMap نیاز نبود و project.godot تغییر نکرد.

## ۸. نتایج پرش معمولی

27 سناریوی یکتا PASS، Exit0. normal_api: درخواست پایان tick31، پرش tick32 با vy=-480،
بدون گرانش همان تیک، حرکت افقی280، فرودtick81. تمام موقعیت‌ها و سرعت‌های هر تیک در
jump_suite.json هستند. تست ابتدا روی Player بدون قابلیت اجرا و عمداً Exit1 شد؛
red_test.json شاهد چرخه تست پیش از پیاده‌سازی است.

## ۹. اندازه‌گیری ارتفاع اوج

100.042358398438 px در محدوده96±8. مدل پیوسته96 و مدل گسسته با تیک اول بدون گرانش
حدود100 است؛ اصلاح تماس حدود0.042 نیز در trace دیده می‌شود. آستانه تغییر نکرده است.
Space/Touch کوتاه و بلند اوج برابر دارند؛ رهاسازی یا نگه‌داشتن vy را تغییر نمی‌دهد.

## ۱۰. اندازه‌گیری مدت پرواز

از تیک آغاز32 تا فرود81، شامل هر دو:50 تیک، 0.833333333 s؛ در محدوده0.80±0.04.
نمونه tick80 هنوز بالای تماس و tick81 روی زمین است. تشخیص تماس یک تیک بعد از مسیر
ایده‌آل49مرحله رخ می‌دهد. زمان‌ها از شبیه‌سازی‌اند؛ زمان توقف گرفتن تصویر به آن اضافه نشده است.

## ۱۱. جلوگیری از Double Jump

double_early و double_mid هر دو فقط یک پرش دارند. پرش عمدی Coyote نمی‌سازد؛ درخواست
هوایی بیرون مهلت فقط Buffer است و قبل از فرود منقضی می‌شود. جهش عمدی کد در کپی مستقل
که Coyote پس از پرش می‌ساخت با assertion «2 پرش به جای1» Exit1 شد؛ کد اصلی دست‌نخورده ماند.

## ۱۲. Coyote Time

| سناریو | خروج لبه | درخواست | تأخیر واقعی | پرش | نتیجه |
| --- | --- | --- | --- | --- | --- |
| coyote_4 |55|59|4/60=0.066667s|60|PASS، پذیرفته |
| coyote_5 |55|60|5/60=0.083333s|ندارد|PASS، رد |
| coyote_6 |55|61|6/60=0.10s|ندارد|PASS، رد |

0.06 دقیق در60Hz قابل نمایش نیست؛ نزدیک‌ترین آزمون دیرتر0.066667 است. بررسی درخواست
در ابتدای تیک بعد و پیش از افزایش ساعت انجام می‌شود. disable_coyote نیز PASS است.

## ۱۳. Jump Buffer

فرود Fixture سقوط درtick27. درخواستtick22 (5تیک=0.083333پیش از فرود) به پرشtick28
منجر شد؛ درخواستtick20 (7تیک=0.116667) منقضی و بدون پرش بود. برابری دقیق0.10 درtick21
معتبر و پرشtick28 است. deadline inclusive باepsilon1e-8؛ در پایان تیک فرود اعتبار سنجیده
و برای تیک بعد latch می‌شود. یک درخواست، بدون تمدید تکراری، مصرف و DISABLED پاک می‌کنند.
buffer_multi فقط یک پرش؛ buffer_disable_latch هیچ پرش ندارد. جهش‌های عمدی Buffer
نامنقضی و پاک‌نشدن در DISABLED در کپی مستقل هر دو Exit1 شدند.

## ۱۴. ورودی‌های نامعتبر

Echo، Release، Drag، press تکراری، لمس دوم هم‌زمان، Space/Touch مصرف‌شده توسط Control
واقعی _gui_input، لمس اصلی UI همراه انگشت دوم بیرون UI و DISABLED همگی PASS با تزریق
InputEvent. نخستین Fixture لمس UI به علت تبدیل‌نکردن مختصات Viewport Headless FAIL شد؛
با root.get_final_transform اصلاح و همان assertion حفظ شد. لاگ نخست و تشخیص علت در
first_suite_command.json، ui_touch_isolated.json و ui_fixture_diagnosis.json نگه داشته شده‌اند.
آزمون لمس سخت‌افزار واقعی NOT RUN؛ دستگاه Android/لمسی در دسترس نیست.

## ۱۵. مقایسه نرخ رندر

اجرای واقعی گرافیکی با max-fps، بدون fixed-fps و بدون توقف ثبت تصویر:

| هدف FPS | FPS واقعی متوسط | فریم | زمان واقعی s | تیک/زمان شبیه‌سازی | dx px | اوج px | نتیجه/Exit |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 30 | 29.997948 | 300 | 10.000684 | 600 / 10.0 | 2800.033447 | 100.042358 | PASS / 0 |
| 60 | 59.997984 | 600 | 10.000336 | 600 / 10.0 | 2800.033447 | 100.042358 | PASS / 0 |
| 120 | 119.870760 | 1198 | 9.994097 | 600 / 10.0 | 2800.033447 | 100.042358 | PASS / 0 |

ورودی پایانtick90، پرشtick91 و فرودtick140 در هر سه یکسان است. اختلاف اوج0px و
خطای جابه‌جایی0.033447px؛ هیچ کمبود تیک مخفی نشده است. نرخ واقعی متوسط اندازه‌گیری
شده است؛ این آزمون تضمین عملکرد گوشی میان‌رده یا اندازه‌گیری frame pacing دستگاه نیست.

## ۱۶. Regression و فرمان‌ها

در فرمان‌های زیر E مسیر باینری دقیق4.7.2 و P ریشه پروژه است. آرگومان‌های مطلق واقعی،
stdout/stderr و Exit Code در JSONهای شواهد ثبت‌اند. fixed-fps240 فقط شتاب تست Headless است.

| آزمون | فرمان | Exit | نتیجه/شاهد |
| --- | --- | --- | --- |
| Engine | E --version |0|PASS؛ engine_version.json |
| Project Import | E --headless --editor --path P --quit |0|PASS؛ import.json |
| Main Runtime | E --headless --path P --quit-after 3 |0|PASS؛ main_runtime.json |
| Jump Suite | E --headless --path P --fixed-fps 240 --script res://tests/test_jump.gd -- --output=... |0|PASS27؛ jump_suite_command.json |
| Auto-Run قبلی | E --headless --path P --fixed-fps 240 --script res://tests/test_auto_run.gd -- --output=... |0|PASS؛ auto_run_regression.json |
| Auto-Start | همان تست قبلی با --auto-start-smoke |0|PASS؛ auto_start_regression.json |
| Static | python3 tests/validate_skeleton.py |0|PASS؛ static_validation.json |
| Documentation | python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_1_1_R1.zip |0|PASS؛ documentation_validation.json |
| Graphical | E --path P --rendering-method gl_compatibility --rendering-driver opengl3 --max-fps N --script res://tests/test_jump.gd -- --fps-target=N --output=... |0 هر سه|PASS؛ native_command_N.txt و native_exit_N.txt |
| Capture | فرمان گرافیکی با --max-fps60 و --visual |0|PASS؛ native_command_visual.txt |
| آزمون قرمز پیش از کد | API پرش روی مبنای قبلی |1 مورد انتظار|PASS کنترل تست؛ red_test.json |
| سه Mutation مستقل | test_jump با --case در کپی‌های مستقل |1 هر سه مورد انتظار|PASS تشخیص assertion؛ mutation_*.json |

بازبینی مستقل کد بدون یافته Critical/Important انجام شد؛ code_review.json.

test_auto_run.gd بدون تغییر بایتی:600تیک/10s، dx=2800.008789، تماس زمین600/600،
vy=0، دامنه y ثابت، توقف60تیک و جابه‌جایی توقف0. هیچ خطای Parse/Resource/Runtime جدید
در Import، Headless یا اجراهای گرافیکی نیست. اعتبارسنجی مستندات کنترل مکانیکی لینک‌های
محلی و محدوده است؛ لینک خارجی را HTTP تست نمی‌کند. جدول10مرحله و GDD بدون تغییرند.

## ۱۷. شواهد گرافیکی واقعی

سه JPEG واقعی1280×720 از پنجره Godot، بدون بازسازی/ویرایش تصویر:

- آغاز: phase_1_2_evidence/jump_launch.jpg؛ tick32، vy=-480، y591.939.
- اوج: phase_1_2_evidence/jump_apex.jpg؛ tick56، vy=0، y499.939.
- فرود: phase_1_2_evidence/jump_landed.jpg؛ tick81، vy=0، y599.925.

Camera بازیکن را دنبال می‌کند؛ فاصله کف تا بازیکن در تصویر اوج افزایش یافته است.
فقط تست --visual در هرکدام20ثانیه زمان واقعی SceneTree را برای عکس متوقف می‌کند؛
خود Player و صحنه Prototype توقف ندارند. trace و لاگ CAPTURE_PAUSE این تفکیک را ثبت می‌کنند.

## ۱۸. خطاها و محدودیت‌های باقی‌مانده

لاگ میزبان هشدار تنظیم VSync در X11 دارد؛ رندر با llvmpipe موفق و نرخ‌های واقعی
اندازه‌گیری شدند. این هشدار حذف یا پنهان نشده است. شکست اولیه Fixture UI اصلاح شده؛
فایل خام آن حفظ است. لمس سخت‌افزاری، Android، کارایی دستگاه و تعامل Editor این مرحله
NOT RUN هستند. هیچ آزمون اجرا‌نشده‌ای PASS اعلام نشده است.

## ۱۹. QA-001B

OPEN؛ این تحویل اثبات ویرایش تعاملی Editor نیست. طبق DEC-033 پیش از Vertical Slice
باید تعیین تکلیف شود؛ QA-001C قبلی PASS و مجوز توسعه متن‌محور حفظ است.

## ۲۰. QA-002

OPEN؛ ابزارهای Android آماده نیستند؛ پیش از Android Export باید بسته شود. هیچ
Export، کلید Release یا درخواست محرمانه ایجاد نشده است.

## ۲۱. Git و ZIP

Git محلی، بدون Commit و Remote؛ 140 فایل تحویلی Stage شده‌اند. تعداد و فهرست
نهایی دقیق در git_validation_results.json و phase_1_2_manifest.json است. مرحله
بسته‌بندی همه بایت‌های دیسک، Git Index و ZIP را مقایسه می‌کند. فرمان نهایی بسته‌بندی python3 tools/phase_1_2/package_project.py با Exit0 ثبت می‌شود؛
نسخه فرمان در شواهد است. Manifest فقط مسیر/تعداد
دارد تا هش خودارجاع نسازد؛ هش تک‌فایل و نتیجه byte comparison در گزارش Git است.
.git، .godot، __pycache__ و کپی‌های Mutation وارد بسته نمی‌شوند. تمام90فایل مبنا حفظ‌اند.
Git diff --cached --check کامل فقط whitespace لاگ خام نگه‌داری‌شده را گزارش می‌کند؛
بررسی کد و مستندات با مستثناکردن فایل‌های خام .txt شواهد جداگانه ثبت می‌شود.

## ۲۲. Project State جدید

پروژه شامل Player واقعی حرکت/پرش، Prototype قبلی و تست‌های پیشین/جدید است. تصمیم‌های
DEC-034 تا036 ترتیب زمان، مسیر ورودی و تفکیک تست گرافیکی/FPS را ثبت می‌کنند. موتور،
Renderer، معماری پایه و Main Scene بدون تغییرند. هیچ دشمن، سکه، امتیاز، شکست، Restart،
Audio، Save یا سیستم مرحله جدید وجود ندارد. PROJECT_STATE.md مرجع وضعیت جاری است.

## ۲۳. نتیجه نهایی

COMPLETE از نظر فنی این مرحله؛ همه آزمون‌های الزامی نرم‌افزاری و گرافیکی اجرا و موفق
شدند. پذیرش مدیریتی جداست؛ QA-001B و QA-002 باز باقی‌اند. لمس دستگاه واقعی NOT RUN
است و جایگزین ادعایی برای آن ارائه نشده است. نیاز به تصمیم محصولی جدید وجود ندارد؛
منتظر بررسی مدیر پروژه می‌مانیم و مرحله۱.۳ شروع نمی‌شود.
