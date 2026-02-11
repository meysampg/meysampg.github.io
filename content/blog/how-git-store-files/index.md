---
date: '2018-03-10T19:03:34+03:30'
draft: false
title: 'گیت چطور فایل‌ها رو ذخیره می‌کنه؟'
categories:
  - Software
  - Internal of Things
tags:
  - git
---

## جواب خیلی کوتاه
گیت فایل‌ها رو بر اساس محتواشون ذخیره میکنه.

## جواب کوتاه نسبتاً بلند
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

یعنی اگر بخوایم با پایتون این پنج مرحله رو کد بزنیم به اینطور چیزی می‌رسیم:
```python
import hashlib
import os
import zlib


def get_file_content(path) -> str:
    with open(path) as f:
        return f.read()

# step 1 & 2
def generate_blob_text(content: str) -> str:
    return 'blob {}\0{}'.format(len(content), content)


# step 3
def generate_hash(content: str) -> str:
    return hashlib.sha1(content.encode('utf-8')).hexdigest()


# step 5 :)
def generate_zlib_content(content: str) -> bytes:
    return zlib.compress(content.encode('utf-8'))

# step 4
def create_file(hash: str, content: str) -> int:
    folder = hash[:2]
    filename = hash[2:]
    path = os.path.join('./', folder, filename)

    os.makedirs(folder, exist_ok=True)

    with open(path, 'w') as f:
        return f.write(content)


# all together
def store_like_git(path: str):
    content = get_file_content(path)
    blob = generate_blob_text(content)
    blob_hash = generate_hash(blob)
    compressed_blob = generate_zlib_content(blob).hex()


    return create_file(blob_hash, compressed_blob)


store_like_git('./file.txt')
```

## پس اسم فایل‌ها چی میشن؟

### همه چی آبجکته
تا اینجا گفتیم گیت فایل‌ها رو بر اساس محتوا ذخیره می‌کنه، نه اسم فایل. و خب سوال پیش میاد که چطور میشه رد تغییرات یک فایل مشخص رو گرفت؟ پرمیژن فایل‌ها چی میشن؟ کی کجا رفت و این داستانا.
اینجاست که باید یه کم برگردیم عقب‌تر: «اصن اون `blob` چی بود؟». جواب این سوال مشخص می‌کنه که تروالدز چه مغز خفنی داره. داخل گیت خبری از تایپ‌های مختلف برای ذخیره‌سازی اطلاعات مختلف نیست. «تو گیت همه چی آبجکته». 
آبجکت یعنی همون چیزی که تو مرحله‌ی قبل ساخته شد. همه چی به همون صورت ساخته میشه ولی برای اینکه هش یه فایل و یه آبجکت از نوع دیگه (که در ادامه می‌بینیم چیا هستن) از شانس ما یکی در نیاد، با گذاشتن `blob` اول کار انگار یه فضای نام برای هر کدوم از تایپ‌ها اختصاص می‌دیم.
در کل گیت چهار نوع آبجکت اصلی داره:
- blob
- tree
- commit
- tag

### درخت
و اینجا بر می‌گردیم به سوال اصلی. تو قسمت قبل متوجه شدیم که محتوای هر فایل به صورت `blob` ذخیره میشه. برای تکمیل پازل، گیت از آبجکت `tree` استفاده می‌کنه تا هر چیز مرتبط با ساختار مخزن (repository) رو ذخیره کنه. ساختارش هم خیلی ساده‌ست. یه آبکجت `tree` شامل یک یا چند خطه که:
- در خط اول کلمه‌ی `tree` میاد و بعد یه فاصله و بعد اندازه‌ی خط بعد و در انتها یه کاراکتر نال `\0`.
- بعد از خط اول، در هر خط، اول پرمیژن و اجازه‌ی اجرا مشخص میشه:
	- `100644`: فایل معمولی
	- `100755`: فایل اجرایی
	- `120000`: لینک نمادین (sym link)
	- `040000`: پوشه (در واقع یه `tree` دیگه)
- بعد یه فاصله میاد و اسم اون آبجکت
- بعد یه کاراکتر نال میاد و بعدش هش به سبک قسمت اول که به آبجکتی که دخیره شده اشاره می‌کنه
یعنی اگه بخوایم خودمونی‌تر به ماجرا اشاره کنیم، برای ذخیره‌ی `a/b/c/d.txt` تا الان با دوتا آبجکت `blob` و `tree` که تعریف کردیم، گیت این مسیر رو میره:
```shell
a (tree)
└─ b (tree)
   └─ c (tree)
      └─ d (blob)
```
یعنی فولدر گیت ما (با آبجکت‌هایی که تا حالا شناختیم) میشه ۳تا درخت و یه blob.

تا اینجا تونستیم یه شکلی از ذخیره‌سازی فایل‌ها رو داشته باشیم و به جواب سوال «گیت چطور فایل‌ها رو ذخیره می‌کنه؟» رسیدیم. گیت فایل رو نه بر اساس اسم و کپی کردن، که بر اساس محتوا هش می‌کنه و فایل‌ها رو هم داخل یه درخت قرار می‌ده. و خب یچی کمه هنوز.

## گیت چطور تاریخچه نگه می‌داره؟
اگه صرفا دنبال نگه داشتن فایل بودیم واقعاً این همه دنگ و فنگ نیاز نبود. خود سیستم‌عامل تقریباً همه‌ی این چیزایی که صحبت شد رو داره و داشت کارش رو می‌کرد. کل ماجرا از اونجا شروع میشه که کی چیکار کرد و کِی؟ در جواب این مسئله گیت میاد آبجکت `commit` رو معرفی می‌کنه. کامیت همون آبجکتیه که به صورت روزمره باهاش سر و کله می‌زنیم با دستور `git log` عموماً می‌بینیمش:
```shell
meysam@Meysams-Mac git % git log
commit 46fc19645c43b01d3291f76304a8058112193138
Author: Meysam P. Ganji <p.g.meysam@gmail.com>
Date:   Wed Feb 11 02:19:20 2026 +0330

    first commit
```
### وقتی کامیت می‌کنیم
برای اینکه ببینیم، آبجکت کامیت چیه، اول می‌ریم سر وقت زیردستور کامیت. فرض کنیم فایل‌های زیر تغییر پیدا کردن:
```shell
└─ a
   └─ b
      └─ c.txt
   └─ d
      └─ e.txt
└─ f
   └─ g.txt
h.txt 
```
وقتی ما کامند `git add` رو می‌زنیم، گیت `blob` هر کدوم از فایل‌هایی که تغییر کردن رو می‌سازه و بعد از اون وقتی`git commit` می‌کنیم، از برگ‌ها شروع می‌کنه و شروع به ساختن آبجکت‌های `tree` می‌کنه. یعنی در مرحله‌ی اول ۳تا آبجکت درخت ساخته میشه:
```shell
T(b) -> c.txt
T(d) -> e.txt
T(f) -> g.txt
```
در مرحله‌ی بعد، یه لول از برگ‌هایی که بهشون اشاره کرده بالاتر میاد و یه آبجکت درخت برای `a` می‌سازه:
```shell
T(a) -> T(b), T(d)
```
و در نهایت آبجکت نهایی رو می‌سازه که اسمش رو می‌ذاریم T:
```shell
T -> T(a), T(f), h.txt
```
الان ما با داشتن T، می‌تونیم هر زمان به حالتی که این درخت ساخته برگردیم و این همون چیزیه که آبجکت کامیت نگه می‌داره.

### آبجکت کامیت
بالطبع، مثل بقیه‌ی آبجکت‌ها، اول فایل `commit` میاد و طول خطوط بعدی و کاراکتر نال و بعدش:
- کلمه‌ی `tree` و هش درختی داره بهش اشاره می‌کنه (در مثال بالا میشه `T`) و در آخر کاراکتر `\n`
- کلمه‌ی `parent` و هش کامیت قبلی (کامیتـ(هایـ)ـی که موقع ساختن این کامیت فعال بوده/ن) و کاراکتر `\n`
- کلمه‌ی `author` و اسم و ایمیل و زمان ایجاد کامیت توسط سازنده اصلی `\n`
- کلمه‌ی `committer` و اسم و ایمیل و زمان کامیت کردن `\n`
- اطلاعات مربوط با ساین اگه باشه
- مسیج کامیت `\n`

## نشانه‌گذاری حالت‌های خاص
در نهایت حالت‌هایی در تاریخچه‌ی گیت هست که نیازه در خود تاریخچه با یه اسم و رسم درست مشخص شن و برای این منظور آبجکت `tag` معرفی میشه.

### تفاوت تگ و برنچ چیه؟
به نظر می‌رسه که برنچ و تگ یکی باشن. هر دو دارن اسم می‌ذارن روی یک حالت خاص. ولی اینطور نیست. برنچ‌ها فقط رفرنس‌هایی هستن به یه کامیت مشخص و هر زمان می‌تونن تغییر کنن. این تیکه کد می‌تونه ماجرا رو واضح‌تر کنه:
```shell
meysam@Meysams-Mac git % gch -b "fdf"
Switched to a new branch 'fdf'
meysam@Meysams-Mac git % gch -
Switched to branch 'main'
meysam@Meysams-Mac refs % cd .git/refs/heads
meysam@Meysams-Mac heads % ll
total 16
-rw-r--r--@ 1 meysam  staff    41B Feb 11 14:09 fdf
-rw-r--r--@ 1 meysam  staff    41B Feb 11 02:19 main
meysam@Meysams-Mac heads % cat fdf
46fc19645c43b01d3291f76304a8058112193138
meysam@Meysams-Mac heads % cat main
46fc19645c43b01d3291f76304a8058112193138
```
یه برنچ فقط یه فایل ساده‌ست که داخلش هش یه کامیته. هر لحظه می‌تونه پاک شه یا به کامیت دیگه‌ای اشاره کنه. ولی تگ، یک آبجکته که داخل هیستوری گیت می‌شینه و نمیشه تغییرش داد (میشه ولی باید تاریخچه‌ی گیت رو بازنویسی کرد). پس برای موارد موقتی برنچ‌ها سریع و کار راه اندازن، ولی برای مواردی که نیازه که یک حالت مشخص در تاریخ گیت ثبت شه و اسم و رسم کسی که ثبت کرده هم باقی بمونه (مثل ریلیزها) از تگ استفاده میشه.

## نمونه‌ی جمع و جور
این اسنیپت نشون میده که چطور میشه محتویات یه مخزن گیت رو دید و تریس کرد و رفت جلو. دستور `cat-file` محتویات رو نشون میده با دوتا سوئیچ کاربردی:
- سوئیچ `t`: تایپ آبجکت
- سوئیچ `p`: چاپ خوشگل

```shell
meysam@Meysams-Mac git % git init
Initialized empty Git repository in /Users/meysam/test/git/.git/

meysam@Meysams-Mac git % ga file.txt

meysam@Meysams-Mac git % gc "first commit"
[main (root-commit) 08ec49b] first commit
 1 file changed, 1 insertion(+)
 create mode 100644 file.txt
 
meysam@Meysams-Mac git % git cat-file -t 08ec49b
commit

meysam@Meysams-Mac git % git cat-file -p 08ec49b
tree 70bd082dc4cdea292e136794fcab576352451191
author Meysam P. Ganji <p.g.meysam@gmail.com> 1770759888 +0330
committer Meysam P. Ganji <p.g.meysam@gmail.com> 1770759888 +0330
gpgsig -----BEGIN PGP SIGNATURE-----

 iQIzBAABCAAdFiEE9KVakJAdWESNuaZ6/uk7It4xDeQFAmmLptAACgkQ/uk7It4x
 DeQjyA//dSA+N+WEr+qdftbjCj6yOxpcv070FIJNz1TGr8pPBo9oXaMOxmeF8GtD
 PBJ7LC/AGLiQIsiTMABC2vqX6Mu0nvjZ7xNabXzJsWhg7IiXc5492Crtg6KYr9ld
 GMqrFHwhim/FVvS/MhFEDMRObSstCs1ThBFcn/vMcw43HyQsy9YEhwMRQB/d0WTI
 qFbeHVF65gUlMPnVHPGJg4uWwT0cG3Z/oEQUed0xvQ54TV9aX3UFGTOYkvkAHYDz
 ut85s/hnDbmlfw0bP10nWiSJKISQw7xQdudsZwqOC4+/uxdmMQQ2m0naftZCWN9b
 2LA+girvaykXuFSJwtVSHW5jHjrRPhoG6cjovr/N0pQOyhip7RbrNXgQEo5Ok5fH
 2td+v3nP8v31JaqGwN02JQukNmXyP3GyDr/WQVf3VvU8i71KRUUJVae1Nw+8owJM
 qvZUSRznKHZoP5/bMoJ5rgIzHBueyZiJfN3XbfAQrysKFsg3qjND8CMGkDdpS7ed
 0umD5ngzfBF7fl06se9NiWIUUZxqKIONawadffXMwuB43dSLCurSZ8gGY+YHWn3p
 Il8SdQxnnjqxWf28xJZL0c5fWSoV/0KLGxNzlutPxswNyaz20tAnrixg39ZNxyZL
 uhLxTuPljKJkuGC1FFZIaraIMnU9sam+yEKTGKI4+WoAaDWcGws=
 =nQAD
 -----END PGP SIGNATURE-----

first commit

meysam@Meysams-Mac git % git cat-file -p 70bd08
100644 blob 6fe0c98f9b56645abb217983d4f2180a4fdce66b	file.txt

meysam@Meysams-Mac git % git cat-file -t 6fe0c
blob

meysam@Meysams-Mac git % git cat-file -p 6fe0c
pgpg
```

و برای دیدن محتویات خام، این بش فانکشن کمک می‌کنه:
```shell
function view_object() { 
	python3 -c 'import sys,zlib;print(zlib.decompress(sys.stdin.buffer.read()))' < .git/objects/"${1:0:2}"/"${1:2}" | cat -v 
}
```
## خب که چه فایده؟

آبجکت دیدن هر چیزی بر اساس محتوای فایل داخل گیت، چندتا فایده‌ی اساسی داره.
### دو فایل با محتوای یکسان = یک blob
برای گیت فرقی نمی‌کنه اگه فایل‌های یکسان، اسم یا مسیرشون فرق کنه. چون محتواشون یکیه blobشون هم یکیه. این دست‌آورد حجم مخزن رو کنترل‌شده نگه می‌داره (جدا از اینکه خود مخزن بعداً فشرده هم میشه و گاربج کالکتور داره) و برای داشتن تاریخچه‌های مختلف نیاز نیست کل کد رو با هر بار تغییر کپی کرد. برای تست کردن میشه از کد اول کار استفاده کرد یا راحت‌تر از زیردستور `hash-object` بهره برد:
```shell
meysam@Meysams-Mac git % printf "pgpg" > a.txt
meysam@Meysams-Mac git % printf "pgpg" > b.txt
meysam@Meysams-Mac git % git hash-object a.txt
6fe0c98f9b56645abb217983d4f2180a4fdce66b
meysam@Meysams-Mac git % git hash-object b.txt
6fe0c98f9b56645abb217983d4f2180a4fdce66b
```

### تغییر اسم تقریباً رایگانه
گفتیم که ساختار با `tree` مشخص می‌شه و `blob`ها هم فقط بر اساس محتوای فایل ساخته میشن. این یعنی با تغییر اسم یه فایل یا دایرکتوری، فقط یه آبجکت جدید درخت ساخته می‌شه که به ساختار جدید اشاره می‌کنه. طبعاً نتیجه‌ی مستقیم این مورد، داشتن چیزی مثل اسنپ‌شات و سفر در زمانه.
### جهان‌های موازی
با داشتن امکان پریدن بین درخت‌های مختلف (که ساختارهای مختلف رو نشون میدن)، ابزارهایی مثل `git blame` و `git bisect` ساخته میشن. شما برای اینکه هر حالت ممکنی از تاریخچه رو ببینی، کافیه هش آبجکت کامیت رو داشته باشی و یک یا چند درخت رو پیمایش کنی تا به وضعیت کد در اون حالت برسی.

## پایان
در نهایت باید گیت رو به عنوان یک دیتابیس فایل بر اساس محتوا دید. ما هر بار در حال ساختن `blob`ها و احتمالاً `tree`های مربوط به فایلا هستیم و این یعنی رفتن از یک اسنپ‌شات به یه اسنپ‌شات دیگه (مثل time travel در delta fromatها). همین.