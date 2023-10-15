# SSH TUI Panel
A simple Text User-Interface to manage and monitor ssh users.

## Installation
```bash
sudo rm -f ssh-panel-install.sh && wget -O ssh-panel-install.sh https://raw.githubusercontent.com/vfarid/ssh-panel/main/install.sh && sudo sh ssh-panel-install.sh && sudo rm -f ssh-panel-install.sh
```

دستور بالا را کپی کرده و پس از لاگین روی ترمینال سرور بر روی مسیر دلخواه (ترجیحا در همان مسیر پیش فرض) اجرا کنید.
پس از اتمام نصب، یک فولدر به نام ssh-panel ایجاد می‌گردد. با ورود به این فولدر، پنل را فعال کنید:

```bash
cd ssh-panel && sh panel.sh
```

با اجرای دستور بالا، پنل را فعال کرده و با استفاده از گزینه‌های موجود می توانید:
 - ترافیک مصرفی هر کاربر را مشاهده کنید
 - کاربران موجود را مدیریت کنید (شامل حذف/غیرفعال/تغییر رمز/مشاهده مصرف)
 - کاربر جدید ایجاد کنید
 - در بین کاربران جستجو کنید

ترافیک کاربران در پس زمینه ثبت می شود و پنل تنها برای مشاهده و مدیریت می باشد. پس از اتمام کار با انتخاب گزینه‌ی Exit از پنل خارج شوید.

`توجه داشته باشید که بعد از فعال شدن پنل، لازم است حدود ۱۰ دقیقه صبر کنید تا پنل به لاگ ترافیک مصرفی دسترسی پیدا کند. گزارشات هر ۵ دقیقه آپدیت می شوند.`

## Upgrade / Uninstall
برای ارتقا یا حذف برنامه، همان اسکریپت نصب را اجرا کنید. در این صورت از شما در خصوص ارتقا یا حذف برنامه سوال می‌شود:
 - گزینه‌ی اول برای ارتقای پنل می‌باشد (Upgrade)
 - از گزینه‌ی دوم برای حذف پنل استفاده کنید (Remove)
 - گزینه‌ی سوم برای حذف همزمان پنل و لاگ‌ فایل‌ها می باشد (Remove panel & statistics)

