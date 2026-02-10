---
date: '2018-03-10T19:03:34+03:30'
draft: false
title: 'گیت چطور فایل‌ها رو ذخیره می‌کنه؟'
---
## جواب کوتاه
گیت فایل‌ها رو بر اساس محتواشون ذخیره میکنه و تا زمانی که فایل تغییر نکرده، نسخه‌ی ذخیره‌شده توسط گیت ثابت میمونه.

## جواب بلند
اول کار که شما دستور `git init` رو اجرا می‌کنید، گیت داخل پوشه‌ی جاری یه فولدر `.git` می‌سازه که محتویاتش اینه:
```shell
[meysampg@freedom git]$ git init
Initialized empty Git repository in /srv/http/test/git/.git/
[meysampg@freedom git]$ ls -lah .git
total 40K
drwxr-xr-x 7 meysampg users 4.0K Mar 10 11:07 .
drwxr-xr-x 3 meysampg users 4.0K Mar 10 11:07 ..
drwxr-xr-x 2 meysampg users 4.0K Mar 10 11:07 branches
-rw-r--r-- 1 meysampg users   92 Mar 10 11:07 config
-rw-r--r-- 1 meysampg users   73 Mar 10 11:07 description
-rw-r--r-- 1 meysampg users   23 Mar 10 11:07 HEAD
drwxr-xr-x 2 meysampg users 4.0K Mar 10 11:07 hooks
drwxr-xr-x 2 meysampg users 4.0K Mar 10 11:07 info
drwxr-xr-x 4 meysampg users 4.0K Mar 10 11:07 objects
drwxr-xr-x 4 meysampg users 4.0K Mar 10 11:07 refs
```

چیزی که جواب سوال بالاست در پوشه‌ی `objects` نهفته‌ست.

گیت یک سیستم محتوا-آدرسی‌ه، بدین معنی که گیت بدون توجه به نام فایل و بر اساس محتوا یک کلید منحصربفرد برای هر فایل می‌سازه (که همون هش SHA1ی هست که موقع کامیت کردن نشون میده) و اون رو داخل پوشه‌ی `objects` بر اساس قاعده‌ی زیر ذخیره می‌کنه:
1. تو یه رشته بنویس blob و بعدش فاصله و بعدش طول محتوای فایل و بعدش کاراکتر نال رو بذار (مثلا `blob 4\0`).
2. به رشته‌ی بالا محتوای فایل رو بچسبون (مثلا `blob 4\0pgpg`).
3. از رشته‌ی مرحله‌ی ۲ یه هش SHA1 بگیر و از این به بعد این میشه شناسه‌ی این فایل (مثلا برای رشته‌ی بالا میشه `c8f50ec947636ea1e848da84bc6e844f593426a1`).
4. دو کاراکتر اول رشته‌ی حاصل از مرحله‌ی ۳ رو بردار و داخل پوشه‌ی `objects` یه پوشه بساز. با ۳۸ کاراکتر باقی‌مانده یه فایل داخل پوشه‌ای که ساختی بساز (مثلا میشه `objects/c8/f50ec947636ea1e848da84bc6e844f593426a1`).
5. با `ZLib` محتوای مرحله‌ی ۲ رو فشرده کن و اونو داخل فایلی که در مرحله‌ی ۴ ساختی ذخیره کن.

از این به بعد برای هر کاری که به اسم فایل نیازه، گیت از اون هش حاصل از مرحله‌‌ی ۳ استفاده می‌کنه و تا زمانی که محتوای فایل تغییر نکرده باشه، این هش ثابت میمونه.


پ.ن یک: گیت در حقیقت بیشتر از کارهایی که در بخش «جواب بلند» اومد رو برای ذخیره‌سازی انجام میده ولی برای من اون قسمتش دیگه اهمیتی نداره :)). بخش [Git Internals](https://l.vrgl.ir/r?ad=1&l=https%3A%2F%2Fgit-scm.com%2Fbook%2Fen%2Fv2%2FGit-Internals-Plumbing-and-Porcelain&si=dtcn6pnglma7&st=post&k=RBoS7Vq6AL%2FV5DZ1S1lW8Snxr9fdaEkiHxkUsei2Ma0%3D) کتاب گیت کل ماجرا رو خیلی روشن و شفاف توضیح داده.