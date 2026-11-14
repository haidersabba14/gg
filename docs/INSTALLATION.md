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
- `PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `TEAM_ID`
- `EXPORT_OPTIONS_PLIST_BASE64`

Encode files locally only for secret entry, for example:

```sh
base64 -i Certificates.p12 | pbcopy
base64 -i GGCustomizer.mobileprovision | pbcopy
base64 -i ExportOptions.plist | pbcopy
```

Never commit these values, certificates, profiles, private keys, or Apple
passwords. After setting the secrets, open **Actions → Signed IPA → Run
workflow**, download the generated artifact, and distribute it only through an
Apple-approved route appropriate for the selected export method (development,
ad hoc, TestFlight, or App Store). The workflow does not use signing-bypass or
jailbreak tooling.

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
- `PROVISIONING_PROFILE_BASE64`
- `KEYCHAIN_PASSWORD`
- `TEAM_ID`
- `EXPORT_OPTIONS_PLIST_BASE64`

حوّل الملفات إلى Base64 محليًا عند إدخالها في Secrets فقط، ولا ترفعها أو كلمات
المرور أو المفاتيح الخاصة إلى Git. بعد إعدادها، افتح **Actions → Signed IPA →
Run workflow**، ثم نزّل artifact الناتج ووزعه فقط عبر طريقة Apple المعتمدة
المناسبة لطريقة التصدير المختارة (development أو ad hoc أو TestFlight أو App
Store). لا يستخدم workflow أي jailbreak أو تجاوز للتوقيع.

### ٣. تطبيق التخصيصات المصدرة

- حزم الأيقونات: صدّر الأصول أو شاركها مع تطبيق أو workflow يدعم الرسومات
  المخصصة رسميًا. لا يغيّر GG Customizer الأيقونة الأصلية لتطبيق آخر.
- الخلفيات: احفظ أو صدّر الصورة، ثم اخترها يدويًا من إعدادات خلفية iOS. يقرر
  iOS وحده ما إذا كان تأثير العمق متاحًا.
- الويدجتات: اضغط مطولًا على الشاشة الرئيسية أو شاشة القفل، واختر **تعديل** ثم
  أضف ويدجت GG Customizer واضبطه من واجهته القياسية.
- مركز التحكم: على iOS 18 أو أحدث، افتح وضع تعديل مركز التحكم وأضف تحكم GG
  Customizer بنفسك عند توفره.
