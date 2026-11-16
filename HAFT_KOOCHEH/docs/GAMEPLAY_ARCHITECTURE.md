# قرارداد معماری گیم‌پلی — مرحله ۰.۲

وضعیت: قرارداد پیشنهادی برای تصویب این مرحله؛ هیچ Node، کلاس، Signal یا اسکریپت
این سند فعلاً ایجاد نشده است. تصمیمات موتور، CharacterBody2D و دامنه MVP از دستور
مدیر پروژه‌اند؛ مسیرها و APIهای زیر قرارداد فنی برای پیاده‌سازی آینده هستند.
[PLAYER_MOVEMENT_SPEC.md](PLAYER_MOVEMENT_SPEC.md) مرجع حرکت و
[LEVEL_DESIGN_SPEC.md](LEVEL_DESIGN_SPEC.md) مرجع محتوای مرحله است.

## ۱. ترکیب و طول عمر

Root صحنه app در آینده مالک SaveManager، AudioManager و UI Layer خواهد بود؛
LevelController و ScoreManager متعلق به نمونه Level هستند. Player، Hazard و Coin
فرزندان جهان Level هستند. اتصال Signalها و تزریق referenceها در composition صحنه
انجام می‌شود؛ مسیر مطلق /root برای یافتن سرویس، EventBus عمومی و Service Locator نداریم.
هیچ‌یک از هشت سیستم در MVP نیاز به Autoload ندارد. عوض‌شدن مرحله فقط فرزند Level
را تعویض می‌کند؛ App و سرویس‌های محلی آن زنده‌اند. شروع فعلی فقط صحنه عنوان R1 است.
هنگام خروج/Restart اتصال‌های سطح Level از بین می‌روند و نمونه تازه ساخته می‌شود.
App در آینده فقط اتصال و lifecycle را در اسکریپت کوچک main.gd انجام می‌دهد؛ سیستم
جدید یا framework نیست. start_requested به ساخت Level و start_run وصل می‌شود؛
audio_settings_requested هم تنظیم حافظه/ذخیره و هم set_volume را به‌روز می‌کند؛
خطای ذخیره در UI نمایش داده می‌شود. save_reset_requested تنها پس از تأیید کاربر
به reset_save می‌رسد. تغییر run_state_changed برای هماهنگی Pause و Audio مصرف می‌شود.

| سیستم | محل و نوع پیشنهادی آینده | طول عمر / Autoload |
| --- | --- | --- |
| PlayerController | scenes/player/player.tscn؛ scripts/player/player_controller.gd روی CharacterBody2D | هر تلاش؛ خیر |
| LevelController | scenes/levels/bazaar_01.tscn تا bazaar_10.tscn؛ scripts/gameplay/level_controller.gd روی Node2D | هر تلاش؛ خیر |
| Collision / Hazard System | زمین StaticBody2D؛ scenes/obstacles/hazard.tscn و scripts/obstacles/hazard.gd روی Area2D؛ دشمن ثابت از همین قرارداد | هر تلاش؛ خیر |
| Collectible System | scenes/collectibles/coin.tscn؛ scripts/gameplay/coin.gd روی Area2D | هر سکه/تلاش؛ خیر |
| ScoreManager | scripts/systems/score_manager.gd روی Node فرزند Level | هر تلاش؛ خیر |
| SaveManager | scripts/systems/save_manager.gd روی Node فرزند App | نشست برنامه؛ خیر |
| AudioManager | scripts/systems/audio_manager.gd روی Node فرزند App، AudioStreamPlayerهای محلی | نشست برنامه؛ خیر |
| UI Layer | scenes/ui/game_ui.tscn؛ scripts/ui/game_ui.gd روی CanvasLayer با Controlهای فرزند | نشست برنامه؛ خیر |

این مسیرها «آینده» هستند و نباید لینک فایل موجود یا مدرک پیاده‌سازی تلقی شوند.
برای دشمن ثابت به EnemyManager جدا نیاز نیست. موسیقی و افکت فعلاً فایل ندارند.

## ۲. انواع مشترک و مالکیت

`level_id` و `coin_id` از نوع StringName و در مرز JSON به String تبدیل می‌شوند.
شناسه مراحل دقیقاً bazaar_01 تا bazaar_10 است؛ coin_id در هر مرحله یکتا و ثابت است.
شناسه تلاش یک شمارنده int محلی است؛ رویداد نمونه قبلی پس از Restart رد می‌شود.
Dictionary خروجی snapshot است و مصرف‌کننده نباید آن را به منبع state تبدیل کند.
`Error` همان کد خطای Godot است؛ قرارداد فایل و رفع خرابی در بخش Save آمده است.
هیچ Resource سفارشی یا schema اجرایی این مرحله ساخته نمی‌شود.

## ۳. PlayerController

- مسئولیت: تبدیل درخواست مجاز به پرش ثابت، حرکت با گام 60 Hz، ثبت تماس زمین و
  وضعیت GROUNDED/AIRBORNE/DISABLED/DEAD. تکرار لمس، Coyote و Buffer محلی‌اند.
- ورودی: `configure(start: Vector2, kill_y: float)`، `set_gameplay_enabled(enabled: bool)`،
  `request_jump()` و `freeze_on_failure()`؛ پارامترهای آزمایشی از مشخصات حرکت.
- خروجی: position/velocity و وضعیت حرکت؛ امتیاز، UI و دیسک را تغییر نمی‌دهد.
- Signal: `jumped()`، `landed()`، `blocked()`، `out_of_bounds()`.
  دو رویداد آخر حداکثر یک بار تا freeze/خروج از تماس؛ Level نیز idempotent است.
- وابستگی: CharacterBody2D، collider و زمین؛ reference به SaveManager یا UI ندارد.
- دریافت مستقیم press در _unhandled_input فقط پس از شرط RUNNING؛ Space و touch
  به request_jump مشترک می‌رسند. input از دکمه UI در این مسیر مصرف شده است.
- پایان تلاش set_gameplay_enabled(false) و Buffer/Coyote را پاک می‌کند؛ freeze_on_failure
  علاوه بر آن DEAD می‌کند. فرود مصونیت یا امتیاز تولید نمی‌کند.

## ۴. LevelController

- تنها مالک وضعیت READY، RUNNING، PAUSED، FAILED، COMPLETED و مسیر Restart است.
- ورودی: `start_run()`، `pause_run()`، `resume_run()`، `restart_run()`، `exit_to_menu()`،
  رویدادهای Player و body_entered مربوط به Finish/Hazard/Coin.
- خروجی: فعال/غیرفعال‌کردن Player، lifecycle جهان، snapshot نتیجه و ارسال تکمیل معتبر
  به SaveManager تزریق‌شده. از AudioManager فقط درخواست پخش می‌کند.
- Signal: `run_state_changed(state: StringName)`، `run_failed(reason: StringName)`،
  `run_completed(result: Dictionary)`؛ فقط یک terminal Signal در هر تلاش.
- وابستگی: محتوای مرحله، PlayerController، ScoreManager، SaveManager تزریق‌شده؛
  UI مصرف‌کننده Signal است و داخل controller خوانده نمی‌شود.
- reason معتبر: wall، hazard، fall. completed جدا از reason شکست است.
- مسیر Restart: درخواست UI → خروج از pause → آزادکردن جهان قبلی و ساخت نمونه تازه
  از همان فایل مرحله → Score صفر و Player مستقر → READY → RUNNING؛ ساخت لزوماً
  داخل callback برخورد انجام نمی‌شود. خروج از منو SceneTree را در حالت pause رها نمی‌کند.

## ۵. Collision / Hazard System

- مسئولیت: تفکیک تماس سطح امن، مانع جامد، خطر و KillZone؛ هیچ منطق امتیاز/ذخیره ندارد.
- ورودی: تماس move_and_slide در Player برای جامدات، `body_entered(body: Node2D)`
  داخلی Area2D برای Hazard؛ فقط Player همین تلاش پذیرفته می‌شود.
- خروجی: جامد مسیر را فیزیکی محدود می‌کند؛ Hazard درخواست شکست به Level می‌دهد.
- Signal قراردادی Hazard: `hazard_contact(hazard_id: StringName, reason: StringName)`؛
  مقدار reason برای Hazard عادی hazard و برای KillZone برابر fall است.
- Player blocked و out_of_bounds به‌ترتیب wall و fall را در صف همان Level قرار می‌دهند.
- وابستگی: فیلتر layer/mask، collider و attempt فعال؛ گروه Player به‌تنهایی کافی نیست،
  هویت نمونه Player نیز باید تطبیق داده شود. تعامل فیزیکی دشمن با سکه وجود ندارد.
- مانع قابل فرود StaticBody2D است؛ خطر Area2D است. راهکار ترکیبی فقط در صورت نیاز
  طراحی و تفکیک روشن سطح امن/خطر استفاده می‌شود؛ آرت collider را تعیین نمی‌کند.

### نقشه برخورد پیشنهادی

| لایه (شماره انسانی / مقدار بیت) | شیء | Mask |
| --- | --- | --- |
| World: 1 / 1 | زمین و مانع جامد | Player: 2 |
| Player: 2 / 2 | CharacterBody2D | World: 1 |
| Hazard: 3 / 4 | Area خطر و دشمن ثابت | Player: 2 |
| Collectible: 4 / 8 | Area سکه | Player: 2 |
| Finish: 5 / 16 | Area پایان | Player: 2 |

Areaها monitoring دارند؛ برای تشخیص body کافی است Player روی لایه 2 باشد؛
Mask خود Player برای دریافت Area لازم نیست. این تنظیمات هنوز در project.godot نیستند.

## ۶. Collectible System

- مسئولیت: تشخیص ورود Player به سکه، جلوگیری از درخواست تکراری و تأیید برداشتن؛
  ثبت امتیاز مستقیماً انجام نمی‌دهد. هر سکه یک coin_id یکتا دارد.
- ورودی: body_entered، `confirm_pickup()` از Level پس از پذیرش ScoreManager؛
  نمونه تازه در Restart مقدار pending/collected را پاک می‌کند.
- Signal: `pickup_requested(coin_id: StringName)`؛ در هر نمونه تا تصمیم Level یک بار.
- خروجی: پس از confirm، خاموش‌کردن monitoring/collider به‌صورت امن و آزادسازی deferred؛
  حذف/تغییر collider داخل flush برخورد ممنوع است. تا تأیید، سکه pending است.
- وابستگی: Area2D، Player همان تلاش، Level محلی؛ SaveManager و UI را نمی‌شناسد.
- اگر شکست در همان tick برنده شود، confirm اجرا نمی‌شود؛ نمونه جهان هنگام Restart
  بازسازی می‌شود. اگر attempt قدیمی باشد رویداد کلاً نادیده گرفته می‌شود.

## ۷. ScoreManager

- مسئولیت: فقط وضعیت سکه و امتیاز تلاش جاری؛ نه بازکردن مرحله یا نوشتن فایل.
- ورودی: `reset_run(level_id: StringName)`، `record_coin(coin_id: StringName) -> bool`،
  `build_result(completed: bool) -> Dictionary`.
- record_coin فقط برای شناسه معتبر همان مرحله از طرف Level فراخوانی می‌شود؛ set
  داخلی مانع امتیاز تکراری است. بازگشت true یعنی سکه تازه پذیرفته شده است.
- خروجی: `coins_collected: int`، `score: int` با فرمول آزمایشی `score = 10 * coins_collected`.
  build_result کلیدهای level_id:String، score:int، coins:int و completed:bool دارد.
- Signal: `score_changed(score: int, coins: int)` پس از reset یا پذیرش سکه تازه.
- وابستگی: فقط داده تلاش؛ نه UI، Player، Save یا فایل. امتیاز زمانی/مسافتی نداریم.

## ۸. SaveManager

- مسئولیت: بارگذاری، اعتبارسنجی و نوشتن پیشرفت/تنظیم محلی، مستقل از فیزیک.
- ورودی: `load_save() -> Error`، `record_completion(level_id: StringName, score: int) -> Error`،
  `set_audio_settings(music: float, sfx: float) -> Error`، `get_snapshot() -> Dictionary`
  و `reset_save() -> Error` فقط پس از تأیید صریح Reset در UI.
- خروجی: snapshot داده معتبر و وضعیت persistence؛ Signalهای
  `save_loaded(snapshot: Dictionary)`، `save_written()` و `save_failed(operation: StringName, code: int)`.
- وابستگی: FileAccess، JSON، DirAccess و فهرست ثابت شناسه مرحله‌ها؛ سرویس شبکه ندارد.
- مسیر: user://save_v1.json؛ قرارداد داده: schema_version:int=1،
  completed_levels:Array[String] از شناسه‌های شناخته‌شده، best_scores:Dictionary[String,int]،
  audio:Dictionary با music و sfx عدد 0..1. امتیاز صحیح نامنفی و مضرب 10 است.
- پیش‌فرض: completed_levels خالی، best_scores خالی، music=1.0 و sfx=1.0؛ مرحله اول باز.
  بازبودن مرحله از ترتیب تکمیل‌شده‌ها محاسبه می‌شود، نه فیلد تکراری unlocked.
- record_completion فقط پس از terminal موفق Level و یک بار برای آن تلاش می‌آید؛
  رکورد max(old,score) است و تساوی تغییری نمی‌دهد. شکست هرگز این متد را صدا نمی‌زند.
  موفقیت مرحله بدون سکه با score=0 نیز معتبر است و مرحله بعد را باز می‌کند.
- فایل غایب: پیش‌فرض معتبر و load موفق بدون نیاز به نوشتن. JSON اعداد را باید از
  نظر صحیح‌بودن مقدار اعتبارسنجی و به int تبدیل کرد؛ تبدیل بی‌بررسی مقدار اعشاری ممنوع.
- فایل خراب/schema ناشناخته: پیش‌فرض موقت در حافظه، save_failed و حفظ بایت‌های فایل؛
  حالت read-only تا تأیید Reset توسط کاربر، بدون overwrite خاموش یا ادعای migration.
  reset_save ابتدا فایل معیوب را با نام backup حفظ می‌کند؛ فقط در صورت موفقیت این
  کار، پیش‌فرض نسخه۱ را می‌نویسد و از read-only خارج می‌شود؛ خطا همان فایل را حفظ می‌کند.
- نوشتن عادی: validate → فایل موقت هم‌پوشه → flush/close → حفظ backup معتبر →
  جایگزینی فایل اصلی با rename بررسی‌شده؛ شکست عملیات rollback/حفظ backup و Error می‌دهد.
  این روش تضمین مصونیت مطلق در قطع برق نیست و روی Android بعداً تست می‌شود.
- در خطای نوشتن، نتیجه مرحله موفق باقی می‌ماند و UI پیام «پیشرفت ذخیره نشد» می‌گیرد؛
  snapshot حافظه می‌تواند پیشرفت نشست را نگه دارد، ولی persistence موفق ادعا نمی‌شود.

## ۹. AudioManager

- مسئولیت: مالک پخش موسیقی و افکت، تنظیم volume و جلوگیری از انباشته‌شدن playerها.
- ورودی: `play_music(track_id: StringName)`، `play_sfx(event_id: StringName)`،
  `set_volume(music: float, sfx: float)`، `set_paused(paused: bool)`، `stop_level_audio()`.
- خروجی: پخش در باس‌های Music و SFX آینده؛ Signal ضروری گیم‌پلی ندارد.
- وابستگی: AudioStreamPlayer، منابع مجاز و تنظیمات تزریق‌شده از SaveManager؛
  خود AudioManager فایل تنظیمات نمی‌نویسد و نتیجه برخورد را تغییر نمی‌دهد.
- event_idهای پیشنهادی jump، coin، fail و complete هستند. اولویت terminal sound
  با fail است و در هر تلاش یک بار؛ صدا برای پذیرش ورودی یا رکورد الزام نیست.
- Pause، صدای جهان را متوقف و UI مستقل را فعال نگه می‌دارد؛ قبل از وجود صدا،
  مدیر خالی یا Autoload نمایشی ساخته نمی‌شود. سقف آزمایشی ۸ افکت هم‌زمان است.

## ۱۰. UI Layer

- مسئولیت: نمایش HUD، منوهای ساده و وضعیت خطا؛ تولید درخواست، نه تغییر مستقیم state.
- ورودی: run_state_changed، score_changed، run_failed، run_completed و save_failed.
- خروجی Signal: `start_requested(level_id: StringName)`، `pause_requested()`،
  `resume_requested()`، `restart_requested()`، `menu_requested()`،
  `audio_settings_requested(music: float, sfx: float)` و `save_reset_requested()`
  پس از تأیید دوباره کاربر برای بازنشانی فایل خراب.
- وابستگی: CanvasLayer/Control و snapshotها؛ جسم Player یا سکه را جابه‌جا نمی‌کند.
- Controlهای تعاملی ورودی را مصرف می‌کنند؛ UI در Pause قابل استفاده می‌ماند؛
  شرط فعال‌بودن Player حتی در حضور Signal متصل کنترل می‌شود.
- «شروع مرحله قفل» در App/Save نیز رد می‌شود؛ صرفاً مخفی‌بودن دکمه کافی نیست.

## ۱۱. ترتیب رویدادها و خطا

تمام رویدادهای برخورد، سکه و پایان فقط صف Level را پر می‌کنند و همان callback
صحنه را عوض نمی‌کند. در ابتدای tick فیزیک بعدی و پیش از حرکت بعدی Player،
رویدادهای پنجره قبلی رسیدگی می‌شوند؛ حداکثر یک tick تأخیر فیزیک پذیرفته است.
برای مستقل‌بودن از ترتیب scene tree، Level در آینده process_physics_priority پایین‌تر
(پیشنهاد -100) از Player (0) دارد؛ Signalهای یک پنجره پیش از داوری جمع می‌شوند.
این ترتیب باید در تست هم‌زمانی عملاً ثابت شود و به ترتیب اتصال Signal تکیه نکند.

اولویت: failure > coin > finish. اگر failure باشد همه coin/finishهای همان پنجره
رد می‌شوند. چند علت شکست هم‌زمان: fall سپس hazard سپس wall، فقط یک نتیجه.
اگر شکست نیست، coin_idهای معتبر و یکتا با ترتیب پایدار پردازش، confirm و سپس
Finish پذیرفته می‌شود؛ سکه همان پنجره پایان در نتیجه حساب می‌شود.
terminal flag بلافاصله بسته می‌شود و رویدادهای دیررس/تکراری نادیده گرفته می‌شوند.
در PAUSED/FAILED/COMPLETED هیچ تغییر Score یا شکست جدید پذیرفته نمی‌شود.
Pause پنجره برخورد نیمه‌تمام را با همان تقدم پیش از pause نهایی می‌کند؛ اگر terminal
شد درخواست Pause بی‌اثر است. Buffer پرش در ورود و خروج Pause پاک می‌شود.

پایان موفق → build_result(true) → record_completion → نتیجه UI؛ ذخیره ناموفق
پایان موفق را به شکست فیزیکی تبدیل نمی‌کند. هیچ controller وضعیت نتیجه را از صدای
پخش‌شده یا متن Label حدس نمی‌زند. Logging تست با tick، attempt و reason است، نه شبکه.

## ۱۲. استاندارد توسعه و منابع فنی

GDScript typed، نام فایل/متد/Signal به snake_case و نام کلاس به PascalCase؛
واحدها و exported parameterها مشخص؛ بدون hard-code وابستگی به sibling path پنهان.
تغییر رفتار نیازمند دستور مرحله، کوچک‌ترین اصلاح و آزمون مرتبط است. API عمومی فقط
به اندازه قرارداد فوق؛ معماری ECS، افزونه، dependency injection framework و Autoload اضافی لازم نیست.

منابع رسمی بررسی‌شده در ۲۰۲۶-۱۱-۱۵؛ رفتار Pause و input باید با نسخه pinned تست شود:
- https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html
- https://docs.godotengine.org/en/stable/classes/class_area2d.html
- https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html

- مرجع ترتیب پردازش Node: https://docs.godotengine.org/en/4.7/classes/class_node.html

## ۱۳. وضعیت اجرایی مرحله ۱.۳

بخش‌های قبلی قرارداد تاریخی/آینده‌اند. اکنون فقط Player، Hazard و زیرمجموعه
READY/RUNNING/FAILED از LevelController اجرا شده‌اند؛ PAUSED/COMPLETED، Coin، Finish،
Score، Save، Audio و UI نهایی وجود ندارند. P1-014 بخش Score Reset همچنان معوق است.
LevelController روی failure_prototype.tscn پایدار است و جهان فرزندش از
failure_world.tscn ساخته می‌شود؛ این PackedScene همان واحدی است که هر Restart کامل
بازسازی می‌کند. Player، زمین، Hazard، KillZone و دوربین همگی داخل آن‌اند.

restart_run درخواست تکراری معلق را یکی می‌کند، Player قبلی را Freeze و وضعیت را
READY می‌کند؛ تعویض در call_deferred است. World قبلی آزاد، attempt_id افزایش، World
تازه Instance و Player ابتدا DISABLED در Start قرار می‌گیرد. پس از تماس واقعی زمین،
start_run آن را RUNNING می‌کند. auto_start فقط گزینه ترکیب همین Fixture است.
Controller نه Score را می‌سازد و نه متن UI را می‌خواند. Main عنوان پیش‌فرض حفظ است.

رویدادها شامل source instance ID، attempt و Engine physics frame هستند. Callback
فقط صف را پر می‌کند؛ Controller تنها frame کوچک‌تر از frame فعلی را داوری می‌کند.
حتی Callback دارای priority=-200 نیز در همان frame نهایی نمی‌شود. در تیک بعد قبل از
حرکت Player، اولویت fall/hazard/wall انتخاب و Freeze انجام می‌شود؛ تنها یک run_failed.
Signalهای متصل WeakRef دارند تا callback دیررس پس از آزادشدن نمونه نیز امن رد شود.
Hazard.configure مرجع دقیق Player و attempt را می‌گیرد؛ Group یا Mask به‌تنهایی کافی نیست.

Player.configure نقطه جهانی شروع و kill_y را می‌گیرد؛ DEAD با configure یا enable زنده
نمی‌شود. blocked تنها نرمال x<-0.7 در حرکت راست است؛ زمین/سقف آن را ایجاد نمی‌کنند.
هر تماس/خروج تا رفع تماس تکرار نمی‌شود. Kill Y پیش‌فرض Player بدون Level برابر INF
است تا Prototype و تست‌های قبلی رفتار قبلی را حفظ کنند؛ Level آن را صریح تنظیم می‌کند.
Fixtureهای این مرحله سطح امن y=600 و kill_y=1000 دارند؛ فاصله400px و بیش از160px.
KillZone مرز بالای820 دارد؛ یک Hazard با reason=fall است، نه سیستم مستقل.

exit_to_menu تلاش را می‌بندد، Player را Freeze، SceneTree.paused را false و بازگشت
به Main را deferred می‌کند. این API، PauseManager یا منوی جدید نیست.
