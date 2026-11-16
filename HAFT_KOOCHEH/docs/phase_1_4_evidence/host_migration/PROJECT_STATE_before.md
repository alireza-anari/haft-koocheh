# Project State — HAFT KOOCHEH ۱.۴

وضعیت نهایی: INCOMPLETE. کد و تست‌های عملکرد Coin/Score موفق‌اند؛ تأیید رندرواقعی120FPS باقی است.
مبنا HAFT_KOOCHEH_phase_1_3.zip،197فایل؛ تمام مسیرهای مبنا حفظ شده‌اند.

- Godot4.7.2.stable.official.ed1daf0bf Standard، GDScript، Compatibility،1280×720،Landscape،Physics60Hz بدون تغییر.
- Player، Hazard، Main Scene، تمام صحنه‌های قبلی و سه تست قبلی بایت‌به‌بایت حفظ شده‌اند.
- Coin Area2D با Layer8/Mask2، IDثابت، هویتPlayer/attempt، pending، confirm/reject و Colliderdeferred.
- ScoreManager Node فرزندLevel و پایدار درRestart؛ Scoreصحیح10×coins، IDتکراری/نامعتبررد، Snapshot مستقل4کلیدی.
- Level داور Failure>Coin؛ سپسfall>hazard>wall؛ صف frameقبلی، RegistryWorld،WeakRef/instanceID/attempt در دریافت و مصرف.
- Prototype جدید با سهCoin و Hazard و DebugLabel/R؛ محتوای نهاییBazaar یاHUD نهایی نیست.
- World/Player/Coinها درRestart تازه، امتیاز0 و Coinها دوباره ظاهر؛ Managerبازسازی نمی‌شود.
- 12سناریویCoin×3فرایند مستقل PASS؛ هرباردهRestart؛ Regression حرکت،27پرش و17شکست×3 PASS.
- Runtime واقعی و5عکس1280×720 PASS؛ توقف35ثانیه‌ای فقط درHarness ثبت تصویر است.
- FPS30/60 موفق؛ هدف120با نرخ‌های واقعی99.34/95.05/75.55/101.64 موفق نشد، اما هر اجراScore30/Coins3/600tick صحیح داشت.
- TEST-11 در120FPS FAIL؛ نیاز به تکرار روی میزبان توانمندتر یا بررسی عملکرد محیط بدون تغییر فناوری/معیار.
- P1-011 وP1-014 PASS؛ P1-012 فقطCoin/HazardزیرآزمونPASS وکلNOT RUN؛ P1-013/018/019/020 NOT RUN.
- QA-001B OPEN، QA-001C PASSتاریخی، QA-002 OPEN، QA-003 NOT RUN.
- بدونSave/کیف‌پول/BestScore/Unlock/Finish/COMPLETED/EnemyAI/Audio/PauseManager/AndroidExport.
- Gitمحلی بدونCommit/Remote/Push؛ همه فایل‌های تحویلStage وDisk/Index/Manifest/ZIP تطبیق می‌شوند.

گزارش PHASE_1_4_REPORT.md وManifest واقعی phase_1_4_manifest.json مرجع تحویل‌اند.
مرحله۱.۵ آغاز نشده؛ پذیرش مرحله۱.۴ تا رفعTEST-11 در120FPS کامل نیست.

تعداد نهایی فایل‌های تحویل: 294؛ تمام ۱۹۷ مسیر مبنا حفظ شده‌اند.
