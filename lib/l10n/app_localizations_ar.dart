// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مسار';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get skip => 'تخطي';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get welcome => 'مرحباً بك في مسار';

  @override
  String get welcomeSubtitle => 'أدر مهامك بكفاءة';

  @override
  String get workspace => 'مساحة العمل';

  @override
  String get inbox => 'البريد الوارد';

  @override
  String get calendar => 'التقويم';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get language => 'لغة التطبيق';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get about => 'حول مسار';

  @override
  String get bin => 'سلة المحذوفات';

  @override
  String get deletedTasks => 'المهام المحذوفة';

  @override
  String get restore => 'استعادة';

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'يرجى إدخال بريد إلكتروني صحيح';

  @override
  String get passwordMismatch => 'كلمات المرور غير متطابقة';

  @override
  String get passwordLength => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get welcomeBack => 'أهلاً بعودتك! أدخل بياناتك.';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get createAccount => 'أنشئ حسابك للبدء.';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String get createPassword => 'أنشئ كلمة مرور';

  @override
  String get confirmYourPassword => 'أكد كلمة المرور';

  @override
  String get addPhotoTitle => 'إضافة صورة';

  @override
  String get addPhotoSubtitle =>
      'أضف صورة ملفك الشخصي حتى يتمكن فريقك من التعرف عليك.';

  @override
  String get continueText => 'متابعة';

  @override
  String get choosePhoto => 'اختيار صورة';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get noDeletedTasks => 'لا توجد مهام محذوفة';

  @override
  String deletedAgo(Object time) {
    return 'محذوف منذ $time';
  }

  @override
  String get daysAgo => 'أيام';

  @override
  String get hoursAgo => 'ساعات';

  @override
  String get justNow => 'الآن';

  @override
  String get taskRestored => 'تم استعادة المهمة';

  @override
  String get areYouSureLogout => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get logOutTitle => 'تسجيل الخروج';

  @override
  String get userName => 'اسم المستخدم';

  @override
  String get userEmail => 'user@example.com';

  @override
  String get actionCannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get preferencesSectionTitle => 'التفضيلات';

  @override
  String get aboutSectionTitle => 'حول التطبيق';

  @override
  String get darkModeSubtitle => 'التبديل بين الوضع الفاتح والداكن';

  @override
  String get appTagline => 'رفيقك الشخصي لإدارة المهام بكفاءة.';

  @override
  String get appVersionLabel => 'مسار الإصدار 1.0.0';

  @override
  String get workspacesTitle => 'مساحات العمل';

  @override
  String get addWorkspace => 'إضافة مساحة عمل';

  @override
  String get workspaceNameLabel => 'اسم مساحة العمل';

  @override
  String get workspaceNameHint => 'أدخل اسم مساحة العمل';

  @override
  String get deleteWorkspaceTitle => 'حذف مساحة العمل';

  @override
  String deleteWorkspaceConfirm(Object name) {
    return 'هل أنت متأكد أنك تريد حذف \"$name\"؟';
  }

  @override
  String get noWorkspaces => 'لا توجد مساحات عمل بعد';

  @override
  String get noWorkspacesSubtitle => 'أنشئ أول مساحة عمل للبدء';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get create => 'إنشاء';

  @override
  String get addProject => 'إضافة مشروع';

  @override
  String get projectNameLabel => 'اسم المشروع';

  @override
  String get projectNameHint => 'أدخل اسم المشروع';

  @override
  String get deleteProjectTitle => 'حذف مشروع';

  @override
  String deleteProjectConfirm(Object name) {
    return 'هل أنت متأكد أنك تريد حذف \"$name\"؟';
  }

  @override
  String get noProjects => 'لا توجد مشاريع بعد';

  @override
  String get noProjectsSubtitle => 'أنشئ أول مشروع للبدء';

  @override
  String get addTask => 'إضافة مهمة';

  @override
  String get taskTitleLabel => 'عنوان المهمة';

  @override
  String get taskTitleHint => 'أدخل عنوان المهمة';

  @override
  String get taskDescriptionLabel => 'الوصف (اختياري)';

  @override
  String get taskDescriptionHint => 'أضف تفاصيل إضافية';

  @override
  String get dueDateLabel => 'تاريخ الاستحقاق';

  @override
  String get selectDueDate => 'اختر التاريخ';

  @override
  String get important => 'مهم';

  @override
  String get notImportant => 'غير مهم';

  @override
  String get urgent => 'مستعجل';

  @override
  String get notUrgent => 'غير مستعجل';

  @override
  String get importanceLabel => 'الأهمية';

  @override
  String get urgencyLabel => 'الاستعجال';

  @override
  String get deleteTaskTitle => 'حذف مهمة';

  @override
  String deleteTaskConfirm(Object title) {
    return 'هل أنت متأكد أنك تريد حذف \"$title\"؟';
  }

  @override
  String get noTasks => 'لا توجد مهام بعد';

  @override
  String get noTasksSubtitle => 'أضف أول مهمة للبدء';

  @override
  String get overdue => 'متأخرة';

  @override
  String get taskStatusNotStarted => 'لم تبدأ';

  @override
  String get taskStatusInProgress => 'قيد التنفيذ';

  @override
  String get taskStatusCompleted => 'مكتملة';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get selectView => 'اختر طريقة العرض';

  @override
  String get viewList => 'قائمة';

  @override
  String get viewBoard => 'لوحة';

  @override
  String get viewTimeline => 'الجدول الزمني';

  @override
  String get viewCalendar => 'التقويم';

  @override
  String get taskDetails => 'تفاصيل المهمة';

  @override
  String get status => 'الحالة';

  @override
  String get priorityLabel => 'الأولوية';

  @override
  String get labelField => 'التصنيف';

  @override
  String get addDateLabel => 'تاريخ الإضافة';

  @override
  String get attachmentsLabel => 'المرفقات';

  @override
  String get filesSelected => 'ملفات محددة';

  @override
  String get repeatEveryLabel => 'التكرار';

  @override
  String get repeatNone => 'بدون تكرار';

  @override
  String get repeatDaily => 'يومياً';

  @override
  String get repeatWeekly => 'أسبوعياً';

  @override
  String get repeatMonthly => 'شهرياً';

  @override
  String get labelWork => 'عمل';

  @override
  String get labelPersonal => 'شخصي';

  @override
  String get labelStudy => 'دراسة';

  @override
  String get labelHealth => 'صحة';

  @override
  String get labelFinance => 'مالية';

  @override
  String get labelOther => 'أخرى';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get editEmail => 'تعديل البريد الإلكتروني';

  @override
  String get save => 'حفظ';

  @override
  String get editTaskTitle => 'تعديل العنوان';

  @override
  String get editDescription => 'تعديل الوصف';

  @override
  String get editDueDate => 'تعديل تاريخ الاستحقاق';

  @override
  String get clearDate => 'إزالة التاريخ';

  @override
  String get editPriority => 'تعديل الأولوية';

  @override
  String get editLabel => 'تعديل التصنيف';

  @override
  String get noLabel => 'بدون تصنيف';

  @override
  String get editRepeat => 'تعديل التكرار';

  @override
  String get addAttachment => 'إضافة مرفق';

  @override
  String get attachmentContentUnavailable =>
      'محتوى الملف غير متوفر حالياً (مثلاً بعد تحديث الصفحة). هاد قيد مؤقت لحد ما ينضاف سيرفر رفع حقيقي.';

  @override
  String get attachmentOpenUnsupported =>
      'فتح الملفات مش مدعوم حالياً على هالمنصة.';

  @override
  String get attachmentPreviewTitle => 'معاينة المرفق';

  @override
  String get attachmentNoPreviewAvailable =>
      'ما في معاينة متوفرة لهذا النوع من الملفات. بس لسا فيك تحمّله.';

  @override
  String get attachmentDownload => 'تحميل';

  @override
  String get attachmentDownloadSuccess => 'تم حفظ الملف بنجاح.';

  @override
  String get attachmentDownloadCancelled => 'تم إلغاء التحميل.';

  @override
  String get attachmentDownloadFailed => 'فشل تحميل الملف.';

  @override
  String get removeAttachment => 'إزالة المرفق';

  @override
  String get addMoreAttachments => 'إضافة مرفقات أكتر';

  @override
  String get today => 'اليوم';

  @override
  String calendarTasksOn(Object date) {
    return 'المهام ليوم $date';
  }

  @override
  String get calendarNoTasksForDate => 'ما في مهام بهاد التاريخ';

  @override
  String get calendarNoTasksForDateSubtitle =>
      'المهام يلي تاريخ استحقاقها هاد اليوم رح تظهر هون';

  @override
  String get calendarLoadError => 'ما قدرنا نحمّل المهام. اسحبي للتحت للتحديث.';

  @override
  String get calendarPickDate => 'اختيار تاريخ';
}
