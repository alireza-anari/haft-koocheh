# Project State — HAFT KOOCHEH ۱.۳

وضعیت فنی COMPLETE؛ منتظر بررسی مدیر پروژه. مرحله۱.۴ آغاز نشده است.
مبنا: HAFT_KOOCHEH_phase_1_2.zip، 140فایل، همه مسیرها حفظ شده‌اند.

- Godot4.7.2.stable.official.ed1daf0bf Standard؛ GDScript؛ Compatibility.
- 1280×720، Landscape، canvas_items/keep، Physics60Hz؛ project.godot بدون تغییر بایتی.
- Main عنوان، Player Scene، Prototype قبلی و هر دو تست قبلی دقیقاً حفظ شده‌اند.
- Player همان CharacterBody2D، Collider32×48 و move_and_slide؛ حالت‌های DISABLED/RUNNING/DEAD.
- حرکت280، گرانش1200، پرش-480، Coyote0.08 و Buffer0.10 بدون تغییر؛ DEAD روی همان نمونه برگشت ندارد.
- blocked از نرمال واقعی سمت راست؛ out_of_bounds از global_y > kill_y؛ زمین و سقف امن‌اند.
- Hazard/‌KillZone از Area2D با هویت دقیق Player و attempt فعال؛ Layer4/Mask2.
- LevelController پایدار با READY/RUNNING/FAILED و priority=-100؛ صف frameقبلی، fall>hazard>wall، یک شکست.
- failure_prototype.tscn مالک World ساخته‌شده از failure_world.tscn است؛ Restart کل World را تازه می‌سازد.
- attempt_id افزایش می‌یابد؛ WeakRef نمونه قدیمی و رویداد دیررس را امن رد می‌کند.
- Playerتازه ابتداDISABLED، سپس پس از استقرار زمین RUNNING؛ exit_to_menu Pause را پاک و Main را بارگذاری می‌کند.
- سطح امن y600، kill_y1000 (400pxحاشیه)، بالایKillZone820؛ Fixtureها محتوای مرحله نهایی نیستند.
- 17سناریوی شکست، سه فرایند مستقل PASS؛ هرکدام10Restart؛ حرکت قبلی و27پرش PASS.
- Runtime گرافیکی واقعی با Mesa llvmpipe، دو اجرای17سناریویی PASS؛ چهار تصویر واقعی موجود.
- QA-001B OPEN؛ QA-001C PASS تاریخی؛ QA-002 OPEN؛ QA-003 NOT RUN.
- هیچ Coin/Finish/Score/Save/EnemyAI/Audio/PauseManager/منوی نهایی/AndroidExport ساخته نشده است.
- P1-014 بخش Score Reset و سایر موارد خارج محدوده NOT RUN هستند.
- Git محلی بدون Commit/Remote/Push؛ همه فایل‌های تحویل Stage می‌شوند؛ فهرست و بایت Disk/Index/Manifest/ZIP بررسی می‌شود.

فهرست و تعداد نهایی واقعی در phase_1_3_manifest.json و git_validation_results.json است.
گزارش کامل: PHASE_1_3_REPORT.md. فقط بررسی مدیر و سپس دستور مرحله بعد مجاز است.

تعداد نهایی فایل‌های این تحویل: 197؛ فهرست دقیق مطابق Manifest و Git Index است.
