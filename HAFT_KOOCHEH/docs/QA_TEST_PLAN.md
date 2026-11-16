# QA plan and actual results — phase 0.1

Use Godot 4.7.2 Stable Standard only. Commands below run from the project root;
ENGINE means the actual absolute binary recorded in ENVIRONMENT_AUDIT.md.
Raw command arguments, exit codes, stdout and stderr: engine_test_results.json.

| Test | Command | Actual result |
| --- | --- | --- |
| A: Engine Version | ENGINE --version | PASS: 4.7.2.stable.official.ed1daf0bf; exit 0; Standard download |
| B: Project Import | ENGINE --headless --editor --path . --quit | PASS: exit 0; stderr empty |
| C: Main Scene | ENGINE --headless --path . --quit-after 3 | PASS: exit 0; stderr empty; brief headless smoke only |
| D: Editor Validation | ENGINE --editor --path . --quit-after 120 | BLOCKED: exit 1; no X11/Wayland display |
| E: Android Preflight | java -version; javac -version; sdkmanager --version; adb version; cmake --version; scoped path audit | Executed; prerequisites incomplete; export NOT run |
| F: Git Validation | git status --short; git ls-files; git check-ignore --no-index -v --stdin; git diff --cached --check | Actual results in git_validation_results.json |
| Static acceptance | python3 tests/validate_skeleton.py | Actual output in static_validation_results.json |

No production GDScript exists, so no script parse error occurred during the
successful import and main-scene smoke. The static Python test only checks
configuration values, paths, bootstrap node types, folders and required docs;
it does not replace Godot parsing or runtime execution.

## Pending manual / toolchain checks
1. On a graphical host with exact engine: open Editor, inspect Main and settings,
   verify no missing resources or errors; run F5/F6 and inspect the title.
2. Check 1280×720 plus wider/narrower windows: centered title and retained aspect.
3. Install JDK 17, documented SDK packages, matching Standard export templates;
   configure editor paths; create and validate Android Debug preset.
4. Export Debug APK only, install on available device and check landscape,
   launch/quit and Compatibility graphics. Record exact commands/device/logs.
5. No release build or new gameplay is authorized in this phase.

## Acceptance mapping
1 engine: verified; 2 structural import: verified headless; 3 main scene: configured
and loaded; 4 execution: verified headless only; 5 no parse errors: observed in
import/runtime (no scripts); 6 renderer: configured, GPU not tested; 7 resolution
and orientation: configured, device/visual not tested; 8 structure: statically
checked; 9 docs: created; 10 previous files: none existed and none overwritten;
11 Android status: audited, export blocked; 12 run instructions: README supplied.
Full phase sign-off remains pending graphical Editor validation.

## R1 rerun
Version, import, headless main scene and static checks were repeated with the
same exact engine; all exited 0, with no stderr. Graphical validation remains
blocked: Xvfb unavailable; Xorg dummy cannot create its /tmp lock; forced-software
Godot cannot open a display. No screenshot or visual centering approval exists.
Git results were regenerated after staging all deliverables; 18 Index entries
match the recorded list exactly, including the report itself. Disk report bytes
match staged bytes. See R1_REPORT.md, r1_test_results.json and git_validation_results.json.
Earlier 16-file state is historical; the R1 delivery contains 18 files.

# برنامه جاری QA — مرحله ۰.۲

مرحله ۰.۱ با استثنای مستند QA-001 طبق دستور مدیر پذیرفته شده است. نتایج بالا
تاریخی‌اند؛ به معنی بسته‌شدن gateها یا مجوز گیم‌پلی نیستند. مرحله ۰.۲ فقط اسناد
و قرارداد می‌سازد. آزمون‌های فاز یک زیر **تعریف‌شده و اجرا‌نشده** هستند.

## موانع باز و مسیر رفع

| شناسه | وضعیت | gate | مالک اقدام |
| --- | --- | --- | --- |
| QA-001 | باز؛ تأیید گرافیکی انجام نشده | پیش از شروع هر پیاده‌سازی عملی Prototype | میزبان گرافیکی توسط مدیر فراهم و تست توسط توسعه‌دهنده/QA |
| QA-002 | باز؛ Android Toolchain کامل نیست | پیش از Android Export | مسئول محیط توسعه و QA |

### QA-001 — Main Scene روی میزبان گرافیکی دیگر

شواهد موجود R1: Xvfb روی PATH نبود؛ Xorg با خطای قفل /tmp/.tX91-lock بالا نیامد؛
تلاش اجرای Godot گرافیکی به نمایشگر متصل نشد. این‌ها شواهد شکست‌اند، نه PASS تصویر.
در ۰.۲ این آزمون دوباره موفق فرض نمی‌شود؛ وضعیت فعلی فقط در گزارش probe ثبت می‌شود.

روش انجام روی Linux/Windows دارای desktop یا میزبان آزمایش محصول:

1. ZIP همین تحویل را استخراج و SHA-256 آن را در برگه تست ثبت کنید؛ موتور دقیق
   4.7.2 Stable Standard را جدا نصب کنید، خروجی --version و صفحه About را ذخیره کنید.
2. project.godot را در Editor باز کنید؛ صحنه main.tscn، tree و خطاهای Editor را ببینید.
3. F6 صحنه و F5 پروژه را اجرا کنید. در 1280×720 عنوان HAFT KOOCHEH باید کامل
   و در مرکز باشد. تصویر واقعی پنجره و log بدون Parse/Resource/Runtime error ثبت شود.
4. نمونه‌های 1600×720 و 1024×768 را تست کنید؛ نسبت پایه ثابت و نوارهای جانبی/بالا پایین
   متناسب باشد، عنوان بریده نشود. مرکز bounding box دیداری حداکثر 8 px از مرکز
   محدوده محتوای 16:9 فاصله داشته باشد؛ حاشیه بصری فونت را از rect کنترل تفکیک کنید.
5. Compatibility و دستگاه/driver واقعی در log ثبت شود؛ تست نرم‌افزاری llvmpipe
   در صورت اجرا با نام دقیق خودش ثبت شود و تست GPU میان‌رده یا Android نام نگیرد.
6. برگه شواهد شامل نام tester، تاریخ، OS، GPU/driver، نسخه موتور، hash بسته، دستورها،
   exit/log و تصویر باشد. QA-001 فقط پس از بررسی همین شواهد PASS/بسته می‌شود.

تا ارائه شواهد و تعیین تکلیف توسط مدیر، پیاده‌سازی عملی Prototype شروع نمی‌شود.
Headless، تصویر تولیدی و عکس از متن گزارش جای تصویر واقعی اجرا نیستند.

### QA-002 — پیش‌نیاز خروجی Android

طبق ممیزی قبلی Java runtime 21.0.13 موجود است ولی JDK 17 و javac پیدا نشدند؛ SDK،
adb، sdkmanager و Templates منطبق نیز یافت نشدند. فهرست بسته لازم:
OpenJDK 17، Platform Tools>=35، Build Tools 35.0.1، Platform android-35،
NDK 28.1.13356709/r28b، CMake 3.10.2.4988404 و Templates Standard 4.7.2.stable.
پیش از Export مسیرها، نسخه‌ها و editor settings با خروجی دستور و فایل source.properties
ثبت شوند؛ قالب و باینری دقیقاً یک نسخه داشته باشند. سپس در مرحله مجاز، preset Debug
ساخته و APK Debug و نصب روی دستگاه با log واقعی تست شود. کلید Release نیاز نیست.
نبود ابزار یا دستگاه صریحاً BLOCKED است؛ تا رفع QA-002 هیچ Export موفق اعلام نمی‌شود.

## آزمون‌های فاز یک — همه PLANNED / NOT RUN

پیش‌شرط مشترک: QA-001 تعیین تکلیف شده، دستور اجرای مرحله مربوط صادر شده و
پیاده‌سازی همان سیستم موجود باشد. وجود جدول به معنی مجوز ساخت همه MVP در ۱.۱ نیست.
با فیزیک ثابت 60 Hz و مقادیر آزمایشی سند حرکت تست شود؛ داده ورودی، tick، attempt،
position/velocity، signalهای خروج و state نهایی ثبت شوند. هر تست دست‌کم سه بار تکرار شود.

| شناسه | سناریو / ورودی | معیار پذیرش اولیه | وضعیت |
| --- | --- | --- | --- |
| P1-001 | RUNNING روی زمین صاف، 10 s بدون ورودی | حرکت +X حدود 2800±5 px؛ بدون حرکت دستی یا سقوط | PLANNED / NOT RUN |
| P1-002 | یک press لمس و معادل Space روی زمین | یک jumped، vy آغاز -480؛ اوج 96±8 px و پرواز 0.80±0.04 s هم‌تراز | PLANNED / NOT RUN |
| P1-003 | نگه‌داشتن لمس/Space، release، key echo و drag | طول لمس ارتفاع را تغییر ندهد؛ هیچ پرش خودکار دوم | PLANNED / NOT RUN |
| P1-004 | فرود روی زمین و سکوی امن | عدم نفوذ، vy=0؛ landed فقط در گذار هوایی به زمین؛ بدون شکست | PLANNED / NOT RUN |
| P1-005 | تماس جانبی مانع جامد و تماس Hazard | wall یا hazard؛ فقط یک run_failed؛ DEAD و سرعت صفر | PLANNED / NOT RUN |
| P1-006 | خروج از لبه بدون پرش؛ درخواست در 0.06 s و 0.10 s پس از خروج | 0.06 مجاز؛ 0.10 بیرون Coyote؛ خطای مرزی جدا با تلرانس tick ثبت شود | PLANNED / NOT RUN |
| P1-007 | پرش عمدی سپس press دوباره در 0.04 s | دوپرش رخ ندهد؛ Coyote قبلاً مصرف شده باشد | PLANNED / NOT RUN |
| P1-008 | press در 0.08 s و 0.12 s پیش از فرود | اولی تا tick بعد فرود مصرف شود؛ دومی منقضی و بدون پرش | PLANNED / NOT RUN |
| P1-009 | مرزهای 0.08 Coyote و 0.10 Buffer در tick ثبت‌شده | تساوی مجاز؛ مصرف یک بار؛ quantization حداکثر یک tick مستند | PLANNED / NOT RUN |
| P1-010 | لمس دوم، UI Pause/Resume، منو و press منقضی | صفر درخواست پرش از UI/انگشت دوم؛ پس از Resume بدون پرش خودبه‌خود | PLANNED / NOT RUN |
| P1-011 | تماس یک Coin چند بار و رویداد تکراری coin_id | فقط یک سکه و +10 score؛ collider حذف‌شده امن و بدون خطا | PLANNED / NOT RUN |
| P1-012 | Coin و Hazard و Finish در یک پنجره، جابه‌جایی ترتیب callbacks | فقط FAILED؛ بدون score/رکورد/پایان همان پنجره | PLANNED / NOT RUN |
| P1-013 | Coin و Finish بدون Hazard در یک پنجره | Coin یک بار حساب و فقط یک COMPLETED؛ نتیجه مستقل از ترتیب callback | PLANNED / NOT RUN |
| P1-014 | y برابر و بزرگ‌تر از kill_y، سپس Restart | در برابری هنوز out نیست؛ بعدش فقط یک fall؛ نمونه تازه و score صفر | PLANNED / NOT RUN |
| P1-015 | شکست، pressهای دیررس، Restart ده‌باره و خروج به منو | بدون Signal تلاش قبلی، تماس/Buffer باقی‌مانده یا duplicate؛ pause رها نشود | PLANNED / NOT RUN |
| P1-016 | رندر 30/60/120 FPS، فیزیک ثابت60، ورودی tick یکسان | اختلاف مسافت 10s≤5 px و اوج≤2 px؛ quantization رندر و stall گزارش شود | PLANNED / NOT RUN |
| P1-017 | pause هنگام هوا/Buffer و بازگشت بعد 2 s | جهان و زمان فعال متوقف؛ Buffer پاک؛ سرعت هوا حفظ؛ UI قابل استفاده | PLANNED / NOT RUN |
| P1-018 | تکرار مرحله، شکست با امتیاز، سپس پایان با امتیاز کمتر/بیشتر | شکست رکورد را تغییر ندهد؛ max فقط موفقیت؛ بازشدن مرحله بعد صحیح | PLANNED / NOT RUN |
| P1-019 | save غایب، JSON خراب، نسخه ناشناخته، خطای نوشتن | پیش‌فرض/خطای صریح؛ داده خراب محفوظ؛ بدون موفقیت ذخیره ادعایی | PLANNED / NOT RUN |
| P1-020 | بازاجرای هر layout ثابت و مسیر بدون سکه | چیدمان و IDs ثابت؛ Finish بدون سکه ممکن؛ checkpoint/تصادف ندارد | PLANNED / NOT RUN |
| P1-021 | چند علت شکست هم‌زمان و تماس Player قدیمی | یک نتیجه با تقدم fall/hazard/wall؛ attempt قدیمی رد شود | PLANNED / NOT RUN |
| P1-022 | pause هم‌زمان با تماس terminal | ابتدا داوری پنجره؛ نتیجه terminal به PAUSED تبدیل نشود | PLANNED / NOT RUN |

این تست‌ها متناسب با مرحله‌ای که سیستمش ساخته می‌شود اجرا می‌شوند. بعد از هر تغییر
پارامتر، تست‌های وابسته هندسه، Coyote/Buffer و نرخ فریم تکرار می‌شوند؛ آستانه‌های فوق
آزمایشی‌اند. افت دستگاه واقعی، latency لمس و UI فارسی به میزبان گرافیکی/Android نیاز دارند.

## آزمون‌های اجباری ۰.۲ — نتایج جاری در گزارش مرحله

Static Validation فعلی بدون تغییر، Import و Runtime با باینری دقیق؛ بررسی مستندات با
`python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_0_1_R1.zip`؛
تطبیق فایل/پوشه، عدم ایجاد gameplay و حفظ بایت فایل‌های اجرایی مبنا؛ Git Ignore،
Index و محتوای stage؛ ZIP CRC، فهرست فایل و برابری بایتی با Index.

تست مستندات فقط لینک نسبی موجود، جدول‌های ده‌مرحله‌ای، مقادیر مرجع، مسیرها و
محدوده فایل را مکانیکی کنترل می‌کند؛ درک داستان یا کیفیت بازی را اثبات نمی‌کند.
بازبینی انسانی/مهندسی قراردادها جدا در گزارش ثبت می‌شود. فایل git_validation_results.json
و گزارش مرحله جاری جای شمارش تاریخی R1 را برای تحویل فعلی می‌گیرند.

# اصلاحیه جاری ۰.۲-R1 — DOC-001 و QA-001

این بخش و PROJECT_STATE.md بر وضعیت‌های تاریخی ۰.۲ و R1 قبلی اولویت دارند.
DOC-001 اصلاح شده: نام/ترتیب مناطق و هسته جادویی داستان مطابق دستور مالک ثبت است.

| مورد | نتیجه جاری | شواهد / مانع |
| --- | --- | --- |
| QA-001: اجرای Main Scene | PASS در سه اندازه | تصاویر واقعی و runtime/exit در qa001_evidence |
| QA-001: Editor و بررسی کامل ساختار در نمای گرافیکی | FAIL | نمای ناقص Editor و خطای VK_KHR_surface در اجرای دقیق 4.7.2 |
| QA-001: نتیجه کلی | FAIL؛ باز و بسته‌نشده | موفقیت Main Scene کافی برای پوشاندن مشکل Editor نیست |
| QA-002 | باز؛ NOT RUN برای Export | ابزارهای Android طبق ممیزی قبلی؛ تغییری در این مرحله انجام نشد |

میزبان Desktop واقعی در دسترس ابزار کنترل بومی: Debian 13.6، DISPLAY=:0؛
Xvfb/xvfb-run در PATH یافت نشدند. نمایشگر Desktop از قبل موجود استفاده شد، نه
راه‌اندازی دستی Xorg با شماره ثابت. برای پنجره 1600×720، فضای Desktop از 1364×1024
به 1920×1080 آماده شد؛ خروجی xrandr هر دو حالت در شواهد است.
موتور پیش‌فرض میزبان 4.6.3 بود و فقط --version آن بررسی شد؛ پروژه با آن اجرا نشد.
تمام اجراهای پروژه با مسیر دقیق Standard 4.7.2.stable.official.ed1daf0bf بودند.
Renderer اجرا Compatibility/OpenGL 4.5، Mesa 25.0.7، llvmpipe LLVM19.1.7 بود؛
این نتیجه، تست GPU گوشی یا Android محسوب نمی‌شود.

| پنجره واقعی | محدوده محتوای 16:9 | خطای مرکز عنوان x/y | Exit Code |
| --- | --- | --- | --- |
| 1280×720 | تمام پنجره | -0.5 / +0.5 px | 0 |
| 1600×720 | x=160..1439، y=0..719 | -0.5 / +0.5 px | 0 |
| 1024×768 | x=0..1023، y=96..671 | 0 / +0.5 px | 0 |

تصاویر اصلی JPEG خروجی مستقیم capture پنجره‌اند؛ بازطراحی، rescale یا تصویرسازی
نشده‌اند. تحلیل threshold پیکسل فقط برای اندازه‌گیری روی فایل‌های اصلی انجام شد.
نام .png اولیه captureها به پسوند واقعی .jpg اصلاح شد؛ import error آن تلاش در
لاگ تاریخی حفظ شده است. فایل .gdignore شواهد را از import منابع بازی جدا می‌کند؛
هیچ Asset بازی برای این تست اضافه نشده است.

سه اجرای Main Scene خطای Runtime/Resource/Renderer ندارند؛ هشدار ناتوانی تنظیم
V-Sync driver وجود دارد و پنهان نشده است. Editor با همان موتور باز شد و خروج طبیعی
0 داشت، اما خطای Vulkan و نمای ناقص/فاقد درخت Main قابل تأیید باقی ماند. انتخاب صریح
OpenGL، رفع پسوند شواهد و Cache تازه مشکل نمایش Editor را برطرف نکردند.
تصویر editor_clean_cache.jpg نشان‌دهنده همان نقص است، نه تأیید ساختار Editor.

برای بستن QA-001: در میزبان/driver سازگار با همین موتور، Editor و Main را مجدداً
طبق روش بالا بررسی کنید؛ tree واقعی Main/UI/Title و تصویر Editor سالم، همراه لاگ
و عکس سه اندازه ثبت شود. ریشه دقیق مشکل Editor در این محیط اثبات نشده و تغییر
موتور/Renderer یا project.godot برای پنهان‌کردن آن مجاز نیست. تا رفع و تأیید مدیر، ۱.۱ شروع نمی‌شود.

کنترل Regression این اصلاحیه: validate_skeleton.py و validate_documentation.py
بدون تغییر اجرا می‌شوند. گزینه تاریخی --baseline در تست مستندات به دامنه ۱۸فایلی R1
مربوط است و سیاست تغییرات ۰.۲ را ثابت فرض می‌کند؛ برای این اصلاحیه، تست بدون آن گزینه
و مقایسه بایتی/دامنه مستقل با بسته مبنای ۲۶فایلی ۰.۲ انجام می‌شود. این مقایسه در
phase_0_2_r1_test_results.json ثبت است و بررسی مبنای جاری حذف نشده است.

# وضعیت جاری ۱.۱-R1 — مجوز DEC-033 و نتایج اجرا

این بخش وضعیت جاری است؛ جدول‌های PLANNED / NOT RUN پیشین، تاریخچه طرح کامل MVP
هستند و تأیید اجرای همه مکانیک‌های آن‌ها نیستند. فقط رفتار حرکت این مرحله تست شده است.

| Gate | وضعیت | حدود اعتبار |
| --- | --- | --- |
| QA-001A | PASS قبلی؛ Runtime Prototype این مرحله نیز موفق | رندر نرم‌افزاری Linux، نه Android |
| QA-001B | OPEN / BLOCKED در محیط Editor | قبل از Vertical Slice تعیین تکلیف؛ مجوز DEC-033 آن را PASS نمی‌کند |
| QA-001C | PASS | ویرایش متنی کپی، Import، Headless، تصویر واقعی متن جدید؛ هش ۵۶ فایل اصلی یکسان |
| QA-002 | OPEN | قبل از Android Export لازم است؛ این مرحله Export ندارد |

توسعه متن‌محور Prototype مطابق DEC-033 مجاز است؛ ممنوعیت قبلی شروع Prototype
تا بسته‌شدن QA-001B در این محدوده با این تصمیم مدیریتی جایگزین شده است.

## اجرای واقعی تست‌های حرکت

مرجع بازتولید: tests/test_auto_run.gd. نمونه واقعی prototype_run ساخته، auto_start
فقط برای تست خاموش و پس از استقرار فعال می‌شود. probe با اولویت فیزیک100 بعد از
Player نمونه می‌گیرد؛ شمارش حرکت دقیقاً ۶۰۰ tick با delta ثابت60 Hz است. ۶۰ tick
بعدی برای توقف‌اند. مقدار y پس از استقرار حدود599.98175 است؛ فاصله کوچک با600
ناشی از margin تماس است و نفوذ به زمین محسوب نمی‌شود.

| تست | نتیجه واقعی |
| --- | --- |
| TEST-01 ده ثانیه | PASS؛ 600 tick، 10.000000 s شبیه‌سازی؛ x=160 تا2960.008789؛ Δx=2800.008789 px |
| TEST-02 زمین | PASS؛ 600/600 تماس؛ دامنه y صفر؛ حداکثر abs(vy)=0 |
| TEST-03 توقف | PASS؛ 60 tick پس از disable؛ Δx=0 و vx=0 |
| TEST-04 رندر30 | PASS؛ 300 frame در10.000081 s؛ میانگین29.999757 FPS |
| TEST-04 رندر60 | PASS؛ 600 frame در9.999724 s؛ میانگین60.001656 FPS |
| TEST-05 گرافیکی | PASS؛ تصاویر واقعی هنگام حرکت و پایان، همراه marker و مختصات؛ خطای جدید Runtime/Resource/Parse ندارد |
| TEST-06 Regression | PASS؛ config و Main بایتی بدون تغییر، Import و تست‌ها موفق؛ همه مسیرهای مبنا محفوظ |

هدف هردو اجرای FPS ۶۰۰ tick و ۱۰ ثانیه شبیه‌سازی بود؛ زمان واقعی نیز مستقل ثبت شد.
هیچ stall یا تعداد tick متفاوت پنهان نشده است. آزمایش Headless با --fixed-fps60
برای سرعت اجراست؛ wall time کوتاه آن تست نرخ رندر واقعی نیست و FPS آن NOT RUN است.
دو مقایسه FPS بالا فقط از Runtime گرافیکی بدون --fixed-fps و با --max-fps واقعی‌اند.
میانگین FPS/زمان دیواری ثبت شده، نه اندازه‌گیری دقیق jitter تک‌فریم یا benchmark گوشی.

پیش از پیاده‌سازی، تست فقدان Prototype با exit1 شکست مورد انتظار داشت. در کپی‌های
جدا، حالت default RUNNING و نادیده‌گرفتن disable عمداً تزریق و توسط تست رد شدند.
این fixtureها وارد پروژه/ZIP نمی‌شوند. تست اولیه DISABLED در Headless نیز کنترل شد.
پرش، Coyote، Buffer، برخورد خطر، شکست، سکه، Save و Audio اجرا/پیاده‌سازی نشده‌اند.

## محدوده و روش تست‌های ایستا

هر دو validator قدیمی حفظ و برای مرحله جاری به‌روز شدند: بررسی تنظیمات، صحنه عنوان،
پوشه‌ها، لینک‌ها و قراردادهای مستندات باقی است؛ ممنوعیت کلی .gd/.tscn اضافی با
allowlist دقیق سه اسکریپت و سه صحنه همین مرحله جایگزین شده است. فایل‌های دیگر،
Autoload، Asset خارجی، Resource اجرایی اضافی و Export preset همچنان رد می‌شوند.
مقایسه --baseline اکنون بسته مبنای ۵۶فایلی ۰.۲-R1 را می‌پذیرد؛ config و Main و GDD
باید یکسان باشند و تغییر فقط در فایل‌های مجاز باشد. تصمیم‌های تاریخی تا DEC-032
محفوظ و DEC-033 اضافه شده است؛ بازنگری معیار مرحله، خاموش‌کردن تست نیست.

دستورهای اجرای فعلی از ریشه پروژه و باینری واقعی Godot:

```sh
python3 tests/validate_skeleton.py
python3 tests/validate_documentation.py --baseline ../HAFT_KOOCHEH_phase_0_2_R1.zip
godot --headless --editor --path . --quit
godot --headless --path . --quit-after 3
godot --headless --path . --fixed-fps 60 --script res://tests/test_auto_run.gd
godot --path . --max-fps 30 --script res://tests/test_auto_run.gd -- --hold --fps-target=30
godot --path . --max-fps 60 --script res://tests/test_auto_run.gd -- --hold --fps-target=60
```

پرچم --hold فقط در تست، نتیجه را۳۰ ثانیه برای capture نگه می‌دارد؛ رفتار صحنه عادی
Prototype را عوض نمی‌کند. هشدار V-Sync در llvmpipe ثبت است؛ UI Editor اینجا تست نشده.
پرش ۱.۲ و خروجی Android نیازمند دستور جدیدند.

# اصلاحیه برنامه QA — مرحله ۱.۲

ردیف‌های PLANNED / NOT RUN قدیمی تاریخچه‌اند؛ نتیجه جاری زیر آن‌ها را در محدوده
همین مرحله تکمیل می‌کند. QA-001B باز است و پیش از Vertical Slice تعیین تکلیف شود؛
QA-002 باز و پیش از Android Export الزامی است. QA-001C قبلی PASS باقی می‌ماند.

| آزمون مرحله ۱.۲ | نتیجه واقعی | شواهد |
| --- | --- | --- |
| TEST-01 پرش معمولی | PASS؛ یک پرش با vy=-480؛ بازگشت زمین | normal_api در jump_suite.json |
| TEST-02 ارتفاع | PASS؛ 100.042358 px در محدوده 96±8 | trace تمام تیک‌ها |
| TEST-03 پرواز | PASS؛ 50 تیک شامل آغاز، 0.833333 s | پرش tick32، فرود tick81 |
| TEST-04 Double Jump | PASS؛ درخواست زودهنگام و میانه هوا رد | double_early و double_mid |
| TEST-05 نگه‌داشتن | PASS؛ Space/Touch کوتاه و بلند اوج یکسان؛ بدون تکرار | space_short/hold، touch_short/hold |
| TEST-06 Coyote | PASS؛ 4 تیک پذیرفته، 5 و 6 تیک رد؛ disable پاک می‌کند | coyote_4/5/6، disable_coyote |
| TEST-07 Buffer | PASS؛ 5 تیک و برابری 6 تیک پذیرفته؛ 7 تیک رد؛ مصرف یک‌باره | buffer_5/7/exact6/multi/disable_latch |
| TEST-08 ورودی نامعتبر | PASS با تزریق رویداد؛ Echo/Release/Drag/لمس دوم/UI/DISABLED | invalid_events، secondary_touch، ui_*، disabled_input |
| TEST-09 توقف/فعال‌سازی | PASS؛ بدون درخواست باقی‌مانده و پرش ناخواسته | disable_reenable |
| TEST-10 FPS | PASS؛ اجرای واقعی گرافیکی 30/60/120، 600 تیک، اوج یکسان | jump_fps_30/60/120.json |
| TEST-11 حرکت قبلی | PASS؛ تست قبلی بدون تغییر؛ 2800.008789 px و توقف صفر | auto_run_regression.json، auto_run.json |
| TEST-12 Runtime گرافیکی | PASS؛ تصاویر واقعی آغاز/اوج/فرود و خروج 0 | jump_launch/apex/landed.jpg، native_visual.txt |
| لمس سخت‌افزاری | NOT RUN؛ دستگاه Android/لمسی در دسترس نیست | فقط InputEvent تأیید شده |

همه مسیرهای شواهد بالا زیر docs/phase_1_2_evidence هستند. آزمون suite دارای 27 سناریوی
یکتا است. تصویرها در تست جدا با توقف 20 ثانیه‌ای ثبت شده‌اند؛ زمان پرواز از تیک‌ها
و آزمون FPS از اجرای بدون توقف گزارش شده است. headless جایگزین تست گرافیکی نیست.

در اولین اجرای UI Touch، تست FAIL شد: مختصات منطقی به مختصات واقعی Viewport
Headless تبدیل نشده بود. با root.get_final_transform در Fixture اصلاح شد؛ هیچ
assertion یا آستانه حذف/تضعیف نشد و UI واقعی همچنان رویداد را از _gui_input مصرف می‌کند.
لاگ شکست نخست و تشخیص علت حفظ شده‌اند. سه جهش عمدی کد در کپی‌های مستقل نیز با
Exit Code=1 در assertion رفتاری شکست خوردند: Coyote پس از پرش، Buffer نامنقضی،
و باقی‌ماندن Buffer پس از DISABLED. هیچ‌یک وارد کد تحویلی نشده‌اند.

# برنامه و نتایج جاری — مرحله ۱.۳

تمام ردیف‌های پیشین تاریخچه‌اند. دستور مدیریتی۱.۳ مجوز زیرمجموعه Collision/Hazard/
Failure/Restart را داده است؛ سکه، پایان موفق، Score، Save و PauseManager ساخته نشده‌اند.

| تست | پوشش اجرایی | نتیجه |
| --- | --- | --- |
| TEST-01 برخورد جانبی | wall_freeze_late_input؛ blocked و run_failed یک‌باره، نرمال واقعی | PASS، سه اجرای مستقل |
| TEST-02 فرود امن | safe_landing_and_ceiling؛ زمین و سقف شکست نیستند | PASS، سه اجرا |
| TEST-03 Hazard | hazard_side و hazard_top؛ Area2D واقعی | PASS، سه اجرا |
| TEST-04 Kill Y | کمتر/برابر/بیشتر از1000؛ global_position، برابری امن | PASS، سه اجرا |
| TEST-05 KillZone | همان Hazard با reason=fall | PASS، سه اجرا |
| TEST-06 Freeze | DEAD، سرعت صفر، پاک‌شدن Buffer/Coyote حتی پس از پرشدن واقعی | PASS، سه اجرا |
| TEST-07 ورودی دیررس | Space، Touch و request_jump پس از DEAD؛ enable/configure زنده نمی‌کنند | PASS با InputEvent، سه اجرا |
| TEST-08 تقدم | دو ترتیب fall/hazard/wall و hazard/wall؛ داوری تیک بعد | PASS، سه اجرا |
| TEST-09 Attempt | source/attempt نادرست، callback با WeakRef نمونه آزادشده | PASS، سه اجرا |
| TEST-10 Restart | World/Player/Hazard تازه، Start و تایمرها، پرش آماده | PASS، سه اجرا |
| TEST-11 ده Restart | هر اجرا ده تلاش جدید و شکست مستقل؛ عدم انباشت اتصال/نمونه | PASS، سه اجرای مستقل |
| TEST-12 خروج به منو | SceneTree.paused پاک، Main واقعی بارگذاری، Level قبلی آزاد | PASS، سه اجرا |
| TEST-13 حرکت قبلی | test_auto_run.gd بایت‌به‌بایت حفظ | PASS |
| TEST-14 پرش قبلی | تمام27سناریوی test_jump.gd بدون تغییر | PASS |
| TEST-15 گرافیکی | Runtime واقعی و تصاویر wall/hazard/fall/restart | نتیجه نهایی در گزارش/JSON همین مرحله |

Suite فعلی17سناریو دارد؛ چند تست الزامی در یک سناریو یکپارچه پوشش داده می‌شوند.
early_callback_next_tick با producer دارای priority=-200 ثابت می‌کند رویداد زودرس
هم در همان frame نهایی نمی‌شود. contact_signal_rearm تماس ثابت را تکرار نمی‌کند و
پس از جدایی دوباره blocked می‌دهد. trace هر تیک شامل attempt، موقعیت، سرعت، نرمال
برخورد، وضعیت و تعداد Signalهاست. لاگ فرمان‌ها stdout/stderr/Exit Code را حفظ می‌کند.
سناریوهای تقدم و ده Restart، رویداد معتبر را از API صف وارد می‌کنند؛ تست‌های دیواره،
Hazard، KillZone و سقوط از فیزیک واقعی استفاده می‌کنند. شواهد این دو روش مخلوط نیستند.

P1-011،012،013،018،019،020،022 خارج محدوده و NOT RUN باقی‌اند.
P1-014 فقط بازسازی جهان/Player بررسی شده؛ Score Reset تا مرحله۱.۴ معوق و NOT RUN است.
تست خروج از Pause فقط قرارداد exit_to_menu است، نه پیاده‌سازی P1-022 یا PauseManager.

| QA جاری | وضعیت | شرط آینده |
| --- | --- | --- |
| QA-001B | OPEN | پیش از Vertical Slice؛ تعامل Editor اثبات نشده |
| QA-001C | PASS تاریخی | مجوز متن‌محور DEC-033 حفظ |
| QA-002 | OPEN | پیش از Android Export |
| QA-003 | NOT RUN | دستگاه لمسی واقعی در دسترس نیست |

در Fixture شروع، بررسی مختصات باید قبل از نخستین تیک گرانش باشد؛ ایجاد صحنه هنگام
توقف موقت تست و سپس آزادکردن فیزیک این ترتیب را صریح می‌کند. نخستین شکست assertion
و دلیل آن در evidence حفظ شده است؛ معیار صحت مختصات حذف یا ضعیف نشده است.
برای عکس، تست گرافیکی پس از force_update_transform و force_update_scroll توقف
40ثانیه‌ای دارد؛ این فقط ابزار ثبت شاهد است و هیچ Pause در Player/Prototype ایجاد نمی‌کند.

# نتایج جاری مرحله۱.۴

جدول‌های PLANNED پیشین تاریخچه‌اند. دستور۱.۴ مجوز Coin و Score هر تلاش است؛
۱۲ سناریوی جدید در سه فرایند مستقل اجرا و موفق شدند؛ هر اجرا دهRestart دارد.

| تست | پوشش | نتیجه |
| --- | --- | --- |
| TEST-01/02 | تماس واقعی، pending، رویداد تکراری، تأیید و Collider deferred | PASS |
| TEST-03/04 | ثبت تکراری و چهار ID نامعتبر؛ diagnostic، بدون افزایش امتیاز/Signal | PASS |
| TEST-05 | سه تماس واقعی، coins3 و score30 | PASS |
| TEST-06 | Player/attempt قدیمی، World خارجی، منبع تغییرکرده، READY/FAILED | PASS |
| TEST-07 | دو ترتیب Callback و هم‌پوشانی فیزیکی واقعی همانframe | PASS؛ Failure برنده، بدون confirm |
| TEST-08 | Snapshot دقیق4کلید با completed=false/true و نوع‌های صحیح | PASS؛ چرخهCOMPLETED ساخته نشده |
| TEST-09 | جمع‌آوری2سکه، World/Player/Coin تازه و score0 | PASS |
| TEST-10 | دهRestart، ScoreManager ثابت و بدون انباشت Callback | PASS، سه فرایند مستقل |
| TEST-11 | رندرواقعی30/60/120 بافیزیک60 و ورودی یکسان | نتیجه واقعی در گزارش و JSON۱.۴ |
| TEST-12 | تصاویر واقعی قبل/تماس/حذف/افزایشScore/Restart | نتیجه نهایی در گزارش۱.۴ |
| TEST-13 | test_auto_run قبلی بدون تغییر | PASS |
| TEST-14 | تمام27سناریوی test_jump بدون تغییر | PASS |
| TEST-15 | تمام17سناریوی test_failure_restart در سه فرایند مستقل | PASS |

| شناسهQA فازیک | وضعیت جاری | دلیل/مرز |
| --- | --- | --- |
| P1-011 | PASS | تماس تکراری، coin_id تکراری، +10 یک‌باره و Collider امن آزمایش شد |
| P1-014 | PASS | kill_y برابر و بیشتر، fallیک‌باره، Restart نمونه تازه و Score Reset، در case kill_y_score_reset_after_failure و Regression۱.۳ |
| P1-012 | NOT RUN به صورت کامل | زیرآزمونCoin+Hazard موفق؛ Finish وجود ندارد |
| P1-013 | NOT RUN | Finish ساخته نشده |
| P1-018 | NOT RUN | رکورد/Unlock/Save خارج محدوده |
| P1-019 | NOT RUN | Save خارج محدوده |
| P1-020 | NOT RUN | چیدمان نهایی مراحل ساخته نشده |

QA-001B OPEN؛ QA-001C PASS تاریخی؛ QA-002 OPEN؛ QA-003 NOT RUN بدون تغییرند.
Score Reset هم از RUNNING و هم پس از FAILED/fall تست شده است. در تست ایزوله state
فقط وضعیت Level موقتاً عوض می‌شود تا guard آن مستقل از guard Player بررسی شود؛
این کار رفتار اجرایی محصول نیست. سناریوهای دو ترتیب Callback مستقیماً API واقعی
Coin/Hazard را فراخوانی می‌کنند؛ یک سناریوی جدا تماس هم‌زمان از فیزیک واقعی است.

تلاش‌های ناموفق در evidence۱.۴ حفظ‌اند: نام متغیر تکراری تست، آرگومان اضافی observer
Signal، و ازدست‌رفتن override شکل داخلی هنگامPackedScene.pack. دو مورد اول فقط
اسکریپت تست بودند؛ مورد سوم با مشاهده32×32 پیش ازpack و48×48 پس ازpack تشخیص داده
و روی نمونه زنده قبل از تیک اول فیزیک اصلاح شد. assertion هم‌زمانی حفظ شده است.
Warningهای ID نامعتبر/تکراری در تست منفی عمدی‌اند؛ Parse/RuntimeError در اجرای نهایی نیست.


نتیجه قطعی TEST-11 مرحله۱.۴: 30/60 PASS؛ هدف120 FAIL (آخرین نرخ واقعی101.635969).
با وجود Score30/Coin3 صحیح، این مورد رفع‌شده محسوب نمی‌شود و وضعیت مرحله INCOMPLETE است.
TEST-12 PASS با پنج تصویر واقعی و Exit0؛ QAهای باز تغییری ندارند.
