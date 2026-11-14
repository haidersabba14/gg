# Installation / التثبيت

## English

### 1. Build from Xcode

1. Use a Mac with Xcode 16 or newer.
2. Clone this repository and open `GGCustomizer.xcodeproj`.
3. In **Signing & Capabilities**, choose your Apple Developer team for the app
   and each extension target. Enable App Groups / WeatherKit only if you intend
   to use those optional Apple services.
4. Select a simulator to run the unsigned test build, or select your registered
   iPhone and press Run.
5. On a physical device, trust the developer certificate only through the normal
   iOS Settings flow if iOS asks. Do not install profiles or tools that claim to
   bypass Apple signing.

### 2. Install a signed IPA produced by GitHub Actions

The `Signed IPA` workflow is intentionally manual. It cannot create an
installable IPA until the repository owner has configured a valid Apple
Development or Distribution certificate, matching provisioning profiles, and
the required GitHub Actions Secrets:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `PROVISIONING_PROFILES_ZIP_BASE64` (recommended: a Base64 ZIP containing
  the `.mobileprovision` files for the app and every extension), **or**
  `PROVISIONING_PROFILE_BASE64` when one valid profile truly covers every
  signed target
- `KEYCHAIN_PASSWORD`
- `TEAM_ID`
- `EXPORT_OPTIONS_PLIST_BASE64`

The profile set and `ExportOptions.plist` must cover
`com.haidersabba14.ggcustomizer`, `.widgets`, `.activity`, and `.control`, plus
their shared App Group entitlement. The workflow gives a profile ZIP priority
when both profile secrets are present. This prevents a misleading “successful”
archive that later cannot export its extensions.

Encode files locally only for secret entry, for example:

```sh
base64 -i Certificates.p12 | pbcopy
base64 -i GGCustomizer.mobileprovision | pbcopy
base64 -i ExportOptions.plist | pbcopy
```

Never commit these values, certificates, profiles, private keys, or Apple
passwords. After setting the secrets, open **Actions → Signed IPA → Run
workflow**. Leave **Publish release** enabled and enter the intended release tag
(for example, `v1.0.0`) to attach a successfully exported IPA to that GitHub
Release; the same IPA is also retained as a private Actions artifact for 14
days. Distribute it only through an Apple-approved route appropriate for the
selected export method (development, ad hoc, TestFlight, or App Store). The
workflow does not use signing-bypass or jailbreak tooling.

### 3. Apply exported customizations

- Icon packs: export or share the rendered assets to an app or workflow that
  officially supports custom graphics. GG Customizer does not alter other apps'
  original icons.
- Wallpapers: save/export the image, then choose it manually in iOS Wallpaper
  settings. iOS decides whether a depth effect is available.
- Widgets: long-press the Home or Lock Screen, choose **Edit**, add a GG
  Customizer widget, then use the widget's standard configuration UI.
- Control Center: on iOS 18+, open Control Center's edit mode and add the GG
  Customizer control yourself when it is available.

## العربية

### ١. البناء من Xcode

1. استخدم Mac مع Xcode 16 أو أحدث.
2. استنسخ هذا المستودع وافتح `GGCustomizer.xcodeproj`.
3. من **Signing & Capabilities** اختر فريق Apple Developer للتطبيق ولكل extension.
   فعّل App Groups أو WeatherKit فقط إن كنت تحتاج خدمات Apple الاختيارية.
4. اختر محاكيًا لبناء الاختبارات غير الموقعة، أو اختر iPhone مسجلًا واضغط Run.
5. عند التثبيت على جهاز فعلي، ثق بشهادة المطور فقط عبر مسار إعدادات iOS الرسمي
   إذا طلب النظام ذلك. لا تثبت ملفات أو أدوات تدعي تجاوز توقيع Apple.

### ٢. تثبيت IPA موقّع من GitHub Actions

إن workflow باسم `Signed IPA` يدوي عمدًا. لا يمكنه إنتاج IPA قابل للتثبيت قبل أن
يضيف مالك المستودع شهادة Apple صالحة وprovisioning profiles متطابقة وGitHub
Secrets التالية:

- `BUILD_CERTIFICATE_BASE64`
- `P12_PASSWORD`
- `PROVISIONING_PROFILES_ZIP_BASE64` (المفضّل: ملف ZIP مرمّز Base64 يحوي ملفات
  `.mobileprovision` للتطبيق ولكل extension)، **أو**
  `PROVISIONING_PROFILE_BASE64` إذا كان ملف واحد صالحًا يغطي كل targets الموقعة
- `KEYCHAIN_PASSWORD`
- `TEAM_ID`
- `EXPORT_OPTIONS_PLIST_BASE64`

يجب أن تغطي مجموعة ملفات التعريف و`ExportOptions.plist` المعرفات
`com.haidersabba14.ggcustomizer` و`.widgets` و`.activity` و`.control`، مع
صلاحية App Group المشتركة. يفضّل workflow ملف ZIP عند وجود السرين معًا، لتفادي
أرشفة تبدو ناجحة ثم تفشل عند تصدير extensions.

حوّل الملفات إلى Base64 محليًا عند إدخالها في Secrets فقط، ولا ترفعها أو كلمات
المرور أو المفاتيح الخاصة إلى Git. بعد إعدادها، افتح **Actions → Signed IPA →
Run workflow**. اترك **Publish release** مفعّلًا واكتب وسم الإصدار المقصود
(مثل `v1.0.0`) ليرفق workflow ملف IPA الناتج بنجاح مع GitHub Release نفسه؛
ويُحتفَظ بالملف أيضًا كـ Actions artifact خاص لمدة 14 يومًا. وزّعه فقط عبر
طريقة Apple المعتمدة لطريقة التصدير المختارة (development أو ad hoc أو
TestFlight أو App Store). لا يستخدم workflow أي jailbreak أو تجاوز للتوقيع.

### ٣. تطبيق التخصيصات المصدرة

- حزم الأيقونات: صدّر الأصول أو شاركها مع تطبيق أو workflow يدعم الرسومات
  المخصصة رسميًا. لا يغيّر GG Customizer الأيقونة الأصلية لتطبيق آخر.
- الخلفيات: احفظ أو صدّر الصورة، ثم اخترها يدويًا من إعدادات خلفية iOS. يقرر
  iOS وحده ما إذا كان تأثير العمق متاحًا.
- الويدجتات: اضغط مطولًا على الشاشة الرئيسية أو شاشة القفل، واختر **تعديل** ثم
  أضف ويدجت GG Customizer واضبطه من واجهته القياسية.
- مركز التحكم: على iOS 18 أو أحدث، افتح وضع تعديل مركز التحكم وأضف تحكم GG
  Customizer بنفسك عند توفره.
