import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lostandfound/l10n/generated/app_localizations.dart';

import '../../data/models.dart';
import '../../data/notification_repository.dart';

String categoryIconLabel(ItemCategory category) => category.name;

String categoryLabel(ItemCategory category, AppStrings strings) {
  return switch (category) {
    ItemCategory.electronics => strings.electronics,
    ItemCategory.keys => strings.keys,
    ItemCategory.bag => strings.bag,
    ItemCategory.cards => strings.cards,
    ItemCategory.other => strings.other,
  };
}

IconData categoryIcon(ItemCategory category) {
  return switch (category) {
    ItemCategory.electronics => Icons.headphones_rounded,
    ItemCategory.keys => Icons.key_rounded,
    ItemCategory.bag => Icons.backpack_rounded,
    ItemCategory.cards => Icons.credit_card_rounded,
    ItemCategory.other => Icons.more_horiz_rounded,
  };
}

String statusLabel(PostStatus status, AppStrings strings) {
  return switch (status) {
    PostStatus.lost => strings.lost,
    PostStatus.found => strings.found,
    PostStatus.recovered => strings.recovered,
  };
}

Color statusColor(PostStatus status) {
  return switch (status) {
    PostStatus.lost => const Color(0xFFE9435A),
    PostStatus.found => const Color(0xFF15A56E),
    PostStatus.recovered => const Color(0xFF2D7DF0),
  };
}

String dateFilterLabel(DateFilter filter, AppStrings strings) {
  return switch (filter) {
    DateFilter.any => strings.anyTime,
    DateFilter.today => strings.today,
    DateFilter.week => strings.last7Days,
    DateFilter.month => strings.last30Days,
  };
}

String relativeTime(DateTime value, AppStrings strings) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)} ${strings.minutesAgo}';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} ${strings.hoursAgo}';
  }
  if (difference.inDays == 1) return strings.yesterday;
  return '${difference.inDays} ${strings.daysAgo}';
}

String longDate(DateTime value, AppStrings strings) {
  return DateFormat.yMMMd(strings.localeName).add_Hm().format(value);
}

String itemPostTitle(ItemPost post, AppStrings strings) {
  if (strings.localeName != 'ar') return post.title ?? post.description;
  return switch (post.id) {
    'p-001' => 'سماعات لاسلكية',
    'p-002' => 'حقيبة ظهر زرقاء',
    'p-003' => 'قارورة ماء سوداء',
    'p-004' => 'مفاتيح مع حلقة',
    'p-005' => 'بطاقة طالب',
    'p-006' => 'جهاز لوحي',
    'p-007' => 'بطاقة دخول الموقف',
    'p-008' => 'تعليقة مفاتيح صغيرة',
    'p-009' => 'حافظة حاسوب رمادية',
    'p-010' => 'حقيبة رياضية',
    'p-011' => 'قارورة قابلة لإعادة الاستخدام',
    'p-012' => 'مفاتيح السكن',
    _ => post.title ?? post.description,
  };
}

String itemPostDescription(ItemPost post, AppStrings strings) {
  if (strings.localeName != 'ar') return post.description;
  return switch (post.id) {
    'p-001' =>
      'تم العثور على سماعات بيضاء على المقعد قرب مدخل البوابة الرئيسية.',
    'p-002' => 'فقدت حقيبة ظهر كحلية تحتوي على دفاتر وآلة حاسبة بعد المحاضرة.',
    'p-003' => 'تم العثور على قارورة معدنية سوداء على مكتب دراسة في المكتبة.',
    'p-004' => 'مجموعة مفاتيح مع حلقة فضية وعلامة سوداء صغيرة.',
    'p-005' => 'تمت إعادة بطاقة الطالب إلى صاحبها هذا الصباح.',
    'p-006' => 'فقدت جهازا لوحيا داخل حافظة سوداء بعد محاضرة الأحياء.',
    'p-007' => 'تم العثور على بطاقة دخول قرب آلات البيع في مركز الطلبة.',
    'p-008' => 'تم العثور على تعليقة مفاتيح خارج درج مختبر الهندسة.',
    'p-009' => 'حافظة رمادية وبداخلها شاحن، شوهدت آخر مرة في المكتبة.',
    'p-010' => 'تم العثور على حقيبة رياضية سوداء قرب ساحة كلية العلوم.',
    'p-011' => 'قارورة خضراء مفقودة بعد الغداء في مركز الطلبة.',
    'p-012' => 'تم تسليم مفاتيح السكن إلى مكتب الإسكان.',
    _ => post.description,
  };
}

String campusLocationLabel(CampusLocation location, AppStrings strings) {
  return campusLocationLabelText(location.placeLabel, strings);
}

String campusLocationLabelText(String placeLabel, AppStrings strings) {
  if (strings.localeName != 'ar') return placeLabel;
  return switch (placeLabel) {
    'Main Gate - Building 2' => 'البوابة الرئيسية - مبنى 2',
    'Engineering College' => 'كلية الهندسة',
    'Central Library' => 'المكتبة المركزية',
    'Student Center' => 'مركز الطلبة',
    'Science Hall' => 'كلية العلوم',
    _ => placeLabel,
  };
}

String contactMethodLabel(String? contactMethod, AppStrings strings) {
  final value = contactMethod ?? strings.postedBy;
  if (strings.localeName != 'ar') return value;
  return switch (value) {
    'security desk' => 'مكتب الأمن',
    'campus chat' => 'دردشة الجامعة',
    'library desk' => 'مكتب المكتبة',
    'student affairs' => 'شؤون الطلبة',
    'front desk' => 'الاستقبال',
    'email' => 'البريد الإلكتروني',
    'housing office' => 'مكتب الإسكان',
    _ => value,
  };
}

class AppStrings {
  AppStrings._(this._l10n);

  final AppLocalizations _l10n;

  static AppStrings of(BuildContext context) {
    return AppStrings._(AppLocalizations.of(context));
  }

  static AppStrings fromLocals(AppLocalizations l10n) {
    return AppStrings._(l10n);
  }

  String get localeName => _l10n.localeName;

  String get appName => _l10n.appName;
  String get home => _l10n.home;
  String get searchHint => _l10n.searchHint;
  String get latestPosts => _l10n.latestPosts;
  String get category => _l10n.category;
  String get date => _l10n.date;
  String get location => _l10n.location;
  String get add => _l10n.add;
  String get addShort => _l10n.addShort;
  String get reports => _l10n.reports;
  String get myPosts => _l10n.myPosts;
  String get noMyPosts => _l10n.noMyPosts;
  String get myPostsEmptyHint => _l10n.myPostsEmptyHint;
  String get favorites => _l10n.favorites;
  String get account => _l10n.account;
  String get lost => _l10n.lost;
  String get found => _l10n.found;
  String get recovered => _l10n.recovered;
  String get open => _l10n.open;
  String get filters => _l10n.filters;
  String get status => _l10n.status;
  String get applyFilters => _l10n.applyFilters;
  String get apply => _l10n.apply;
  String get reset => _l10n.reset;
  String get cancel => _l10n.cancel;
  String get chat => _l10n.chat;
  String get typeMessage => _l10n.typeMessage;
  String get send => _l10n.send;
  String get edit => _l10n.edit;
  String get delete => _l10n.delete;
  String get markRecovered => _l10n.markRecovered;
  String get markRecoveredConfirm => _l10n.markRecoveredConfirm;
  String get openMap => _l10n.openMap;
  String get postedBy => _l10n.postedBy;
  String get viewProfile => _l10n.viewProfile;
  String get loading => _l10n.loading;
  String get retry => _l10n.retry;
  String get itemDeleted => _l10n.itemDeleted;
  String get itemDeletedMessage => _l10n.itemDeletedMessage;
  String get deleteConfirm => _l10n.deleteConfirm;
  String get editReport => _l10n.editReport;
  String get saveChanges => _l10n.saveChanges;
  String get reportUpdated => _l10n.reportUpdated;
  String get allStatuses => _l10n.allStatuses;
  String get allCategories => _l10n.allCategories;
  String get allLocations => _l10n.allLocations;
  String get anyTime => _l10n.anyTime;
  String get today => _l10n.today;
  String get last7Days => _l10n.last7Days;
  String get last30Days => _l10n.last30Days;
  String get electronics => _l10n.electronics;
  String get keys => _l10n.keys;
  String get bag => _l10n.bag;
  String get cards => _l10n.cards;
  String get other => _l10n.other;
  String get noItems => _l10n.noItems;
  String get emptyHint => _l10n.emptyHint;
  String get results => _l10n.results;
  String get addReport => _l10n.addReport;
  String get addPhoto => _l10n.addPhoto;
  String get tapToUpload => _l10n.tapToUpload;
  String get cameraGalleryHint => _l10n.cameraGalleryHint;
  String get camera => _l10n.camera;
  String get gallery => _l10n.gallery;
  String get useSamplePhoto => _l10n.useSamplePhoto;
  String get changePhoto => _l10n.changePhoto;
  String get reportTitle => _l10n.reportTitle;
  String get categorySelectHint => _l10n.categorySelectHint;
  String get reportTitleHint => _l10n.reportTitleHint;
  String get itemDescription => _l10n.itemDescription;
  String get itemDescriptionHint => _l10n.itemDescriptionHint;
  String get titleOptional => _l10n.titleOptional;
  String get shortDescription => _l10n.shortDescription;
  String get pickLocation => _l10n.pickLocation;
  String get locationApproxHint => _l10n.locationApproxHint;
  String get useCurrentGps => _l10n.useCurrentGps;
  String get contactOptional => _l10n.contactOptional;
  String get contactMethodHint => _l10n.contactMethodHint;
  String get itemAttributes => _l10n.itemAttributes;
  String get itemColor => _l10n.itemColor;
  String get itemColorHint => _l10n.itemColorHint;
  String get itemBrand => _l10n.itemBrand;
  String get itemBrandHint => _l10n.itemBrandHint;
  String get distinguishingDetails => _l10n.distinguishingDetails;
  String get distinguishingDetailsHint => _l10n.distinguishingDetailsHint;
  String get lostOptions => _l10n.lostOptions;
  String get urgentReport => _l10n.urgentReport;
  String get urgentReportHint => _l10n.urgentReportHint;
  String get rewardOffered => _l10n.rewardOffered;
  String get rewardOfferedHint => _l10n.rewardOfferedHint;
  String get locationDetail => _l10n.locationDetail;
  String get locationDetailHint => _l10n.locationDetailHint;
  String get publish => _l10n.publish;
  String get submitReport => _l10n.submitReport;
  String get publishing => _l10n.publishing;
  String get publishSuccess => _l10n.publishSuccess;
  String get validationError => _l10n.validationError;
  String get requiredField => _l10n.requiredField;
  String get descriptionTooShort => _l10n.descriptionTooShort;
  String get descriptionTooLong => _l10n.descriptionTooLong;
  String get details => _l10n.details;
  String get reportedFound => _l10n.reportedFound;
  String get reportedLost => _l10n.reportedLost;
  String get description => _l10n.description;
  String get mapLocation => _l10n.mapLocation;
  String get dateTime => _l10n.dateTime;
  String get reportDateTimeHint => _l10n.reportDateTimeHint;
  String get contact => _l10n.contact;
  String get contacting => _l10n.contacting;
  String get minutesAgo => _l10n.minutesAgo;
  String get hoursAgo => _l10n.hoursAgo;
  String get daysAgo => _l10n.daysAgo;
  String get yesterday => _l10n.yesterday;
  String get menu => _l10n.menu;
  String get language => _l10n.language;
  String get notifications => _l10n.notifications;
  String get settings => _l10n.settings;
  String get profile => _l10n.profile;
  String get editProfile => _l10n.editProfile;
  String get preferences => _l10n.preferences;
  String get locationServices => _l10n.locationServices;
  String get locationServicesStatus => _l10n.locationServicesStatus;
  String get theme => _l10n.theme;
  String get themeSystem => _l10n.themeSystem;
  String get themeLight => _l10n.themeLight;
  String get themeDark => _l10n.themeDark;
  String get safetySupport => _l10n.safetySupport;
  String get helpFaq => _l10n.helpFaq;
  String get reportProblem => _l10n.reportProblem;
  String get termsPrivacy => _l10n.termsPrivacy;
  String get signIn => _l10n.signIn;
  String get signOut => _l10n.signOut;
  String get signedOut => _l10n.signedOut;
  String get systemSettingsOpened => _l10n.systemSettingsOpened;
  String get comingSoon => _l10n.comingSoon;
  String get demoUserName => _l10n.demoUserName;
  String get demoUserEmail => _l10n.demoUserEmail;
  String get demoUniversity => _l10n.demoUniversity;
  String get arabicLanguageName => _l10n.arabicLanguageName;
  String get englishLanguageName => _l10n.englishLanguageName;
  String get imageAttachment => _l10n.imageAttachment;
  String get couldNotAttachImage => _l10n.couldNotAttachImage;
  String get copy => _l10n.copy;
  String get messageCopied => _l10n.messageCopied;
  String get report => _l10n.report;
  String get block => _l10n.block;
  String get reportConversationTitle => _l10n.reportConversationTitle;
  String get blockUserTitle => _l10n.blockUserTitle;
  String get reportConversationBody => _l10n.reportConversationBody;
  String get blockUserBody => _l10n.blockUserBody;
  String get conversationReported => _l10n.conversationReported;
  String get userBlocked => _l10n.userBlocked;
  String aboutItem(String itemTitle) => _l10n.aboutItem(itemTitle);
  String get chatSafetyNote => _l10n.chatSafetyNote;
  String get attachImage => _l10n.attachImage;
  String get startConversation => _l10n.startConversation;
  String get startConversationHint => _l10n.startConversationHint;
  String get campusMember => _l10n.campusMember;
  String get skip => _l10n.skip;
  String get next => _l10n.next;
  String get startNow => _l10n.startNow;
  String get getStarted => _l10n.getStarted;
  String get continueAsGuest => _l10n.continueAsGuest;
  String get locationPermissionTitle => _l10n.locationPermissionTitle;
  String get locationPermissionBody => _l10n.locationPermissionBody;
  String get allow => _l10n.allow;
  String get notNow => _l10n.notNow;
  String get splashTitle => _l10n.splashTitle;
  String get splashSubtitle => _l10n.splashSubtitle;
  String get onboardingWelcomeTitle => _l10n.onboardingWelcomeTitle;
  String get onboardingWelcomeSubtitle => _l10n.onboardingWelcomeSubtitle;
  String get onboardingPage1Title => _l10n.onboardingPage1Title;
  String get onboardingPage1Subtitle => _l10n.onboardingPage1Subtitle;
  String get onboardingPage2Title => _l10n.onboardingPage2Title;
  String get onboardingPage2Subtitle => _l10n.onboardingPage2Subtitle;
  String get onboardingPage3Title => _l10n.onboardingPage3Title;
  String get onboardingPage3Subtitle => _l10n.onboardingPage3Subtitle;

  String get noNotifications => _l10n.noNotifications;
  String get notificationsEmptyHint => _l10n.notificationsEmptyHint;
  String get clearAll => _l10n.clearAll;
  String get markAllRead => _l10n.markAllRead;
  String get clearAllConfirm => _l10n.clearAllConfirm;
  String get clearAllConfirmMessage => _l10n.clearAllConfirmMessage;
  String get notificationDeleted => _l10n.notificationDeleted;
  String get allNotificationsCleared => _l10n.allNotificationsCleared;
  String get allNotificationsMarkedRead => _l10n.allNotificationsMarkedRead;

  // Authentication strings
  String get login => localeName == 'ar' ? 'تسجيل الدخول' : 'Log in';
  String get signUp => localeName == 'ar' ? 'إنشاء حساب' : 'Sign up';
  String get email => localeName == 'ar' ? 'البريد الإلكتروني' : 'Email';
  String get password => localeName == 'ar' ? 'كلمة المرور' : 'Password';
  String get confirmPassword => localeName == 'ar' ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get fullName => localeName == 'ar' ? 'الاسم الكامل' : 'Full Name';
  String get dontHaveAccount => localeName == 'ar' ? 'ليس لديك حساب؟' : 'Don\'t have an account?';
  String get alreadyHaveAccount => localeName == 'ar' ? 'لديك حساب بالفعل؟' : 'Already have an account?';
  String get forgotPassword => localeName == 'ar' ? 'هل نسيت كلمة المرور؟' : 'Forgot Password?';
  String get loginRequiredTitle => localeName == 'ar' ? 'تسجيل الدخول مطلوب' : 'Login Required';
  String get pleaseLoginToContinue => localeName == 'ar' ? 'يرجى تسجيل الدخول للوصول إلى هذه الميزة.' : 'Please log in to access this feature.';
}

String notificationTitle(NotificationModel notification, AppStrings strings) {
  if (strings.localeName != 'ar') return notification.title;
  if (notification.id.startsWith('n-')) {
    if (notification.type == NotificationType.chat) {
      if (notification.title.startsWith('New message from')) {
        final sender = notification.title.substring('New message from '.length);
        return 'رسالة جديدة من $sender';
      }
      return 'رسالة جديدة';
    }
    if (notification.type == NotificationType.match) {
      return 'تم العثور على مطابقة!';
    }
  }
  return switch (notification.id) {
    'n-001' => 'مطابقة محتملة!',
    'n-002' => 'إعلان جديد بالقرب منك',
    'n-003' => 'رسالة جديدة',
    'n-004' => 'أهلاً بك في التطبيق',
    _ => notification.title,
  };
}

String notificationBody(NotificationModel notification, AppStrings strings) {
  if (strings.localeName != 'ar') return notification.body;
  if (notification.id.startsWith('n-')) {
    if (notification.type == NotificationType.chat) {
      return 'الرسالة: "${notification.body}"';
    }
    if (notification.type == NotificationType.match) {
      if (notification.body.contains('matching your')) {
        return notification.body
            .replaceAll('Someone found an item matching your', 'عثر شخص ما على غرض يطابق')
            .replaceAll('matching your', 'يطابق')
            .replaceAll('at', 'في')
            .replaceAll('A found', 'العنصر الموجود')
            .replaceAll('matches a lost item reported near', 'يطابق غرضاً مفقوداً بالقرب من')
            .replaceAll('!', '');
      }
    }
  }
  return switch (notification.id) {
    'n-001' => 'قد يكون هناك من عثر على حقيبتك الزرقاء بالقرب من كلية الهندسة! انقر للتحقق.',
    'n-002' => 'تم نشر عنصر جديد في الإلكترونيات بالقرب من المكتبة المركزية: "سماعات لاسلكية".',
    'n-003' => 'أرسل لك موظف الأمن رسالة بخصوص مفاتيحك.',
    'n-004' => 'مرحباً بك في تطبيق المفقودات! نتمنى لك العثور على ممتلكاتك.',
    _ => notification.body,
  };
}
