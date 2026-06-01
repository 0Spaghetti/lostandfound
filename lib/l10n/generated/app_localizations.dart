import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lost & Found Campus App'**
  String get appName;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for an item...'**
  String get searchHint;

  /// No description provided for @latestPosts.
  ///
  /// In en, this message translates to:
  /// **'Latest posts'**
  String get latestPosts;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addShort.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get addShort;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @noMyPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noMyPosts;

  /// No description provided for @myPostsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Publish your first report to see it here.'**
  String get myPostsEmptyHint;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @lost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get lost;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @recovered.
  ///
  /// In en, this message translates to:
  /// **'Recovered'**
  String get recovered;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilters;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @markRecovered.
  ///
  /// In en, this message translates to:
  /// **'Mark as recovered'**
  String get markRecovered;

  /// No description provided for @markRecoveredConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark this item as recovered?'**
  String get markRecoveredConfirm;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get openMap;

  /// No description provided for @postedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedBy;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get viewProfile;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @itemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Item deleted'**
  String get itemDeleted;

  /// No description provided for @itemDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available.'**
  String get itemDeletedMessage;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get deleteConfirm;

  /// No description provided for @editReport.
  ///
  /// In en, this message translates to:
  /// **'Edit report'**
  String get editReport;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @reportUpdated.
  ///
  /// In en, this message translates to:
  /// **'Report updated successfully'**
  String get reportUpdated;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStatuses;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All locations'**
  String get allLocations;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @keys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get keys;

  /// No description provided for @bag.
  ///
  /// In en, this message translates to:
  /// **'Bag'**
  String get bag;

  /// No description provided for @cards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cards;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItems;

  /// No description provided for @emptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search or reset filters.'**
  String get emptyHint;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get results;

  /// No description provided for @addReport.
  ///
  /// In en, this message translates to:
  /// **'Add report'**
  String get addReport;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Report photo'**
  String get addPhoto;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Take or upload a photo'**
  String get tapToUpload;

  /// No description provided for @cameraGalleryHint.
  ///
  /// In en, this message translates to:
  /// **'Add a clear photo of the missing item.'**
  String get cameraGalleryHint;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @useSamplePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use sample photo'**
  String get useSamplePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report title'**
  String get reportTitle;

  /// No description provided for @categorySelectHint.
  ///
  /// In en, this message translates to:
  /// **'Select item category'**
  String get categorySelectHint;

  /// No description provided for @reportTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short, clear title'**
  String get reportTitleHint;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item description'**
  String get itemDescription;

  /// No description provided for @itemDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a detailed item description (color, type, brand, and any distinguishing details)'**
  String get itemDescriptionHint;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @shortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get shortDescription;

  /// No description provided for @pickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get pickLocation;

  /// No description provided for @locationApproxHint.
  ///
  /// In en, this message translates to:
  /// **'Select the approximate location where you last saw the item'**
  String get locationApproxHint;

  /// No description provided for @useCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useCurrentGps;

  /// No description provided for @contactOptional.
  ///
  /// In en, this message translates to:
  /// **'Contact method (optional)'**
  String get contactOptional;

  /// No description provided for @contactMethodHint.
  ///
  /// In en, this message translates to:
  /// **'Phone, email, or campus chat'**
  String get contactMethodHint;

  /// No description provided for @itemAttributes.
  ///
  /// In en, this message translates to:
  /// **'Item attributes'**
  String get itemAttributes;

  /// No description provided for @itemColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get itemColor;

  /// No description provided for @itemColorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. navy blue'**
  String get itemColorHint;

  /// No description provided for @itemBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get itemBrand;

  /// No description provided for @itemBrandHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Apple, Nike'**
  String get itemBrandHint;

  /// No description provided for @distinguishingDetails.
  ///
  /// In en, this message translates to:
  /// **'Distinguishing details'**
  String get distinguishingDetails;

  /// No description provided for @distinguishingDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Sticker, initials, scratch, serial mark'**
  String get distinguishingDetailsHint;

  /// No description provided for @lostOptions.
  ///
  /// In en, this message translates to:
  /// **'Lost item options'**
  String get lostOptions;

  /// No description provided for @urgentReport.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentReport;

  /// No description provided for @urgentReportHint.
  ///
  /// In en, this message translates to:
  /// **'Highlight this lost report'**
  String get urgentReportHint;

  /// No description provided for @rewardOffered.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get rewardOffered;

  /// No description provided for @rewardOfferedHint.
  ///
  /// In en, this message translates to:
  /// **'Show that a reward is offered'**
  String get rewardOfferedHint;

  /// No description provided for @locationDetail.
  ///
  /// In en, this message translates to:
  /// **'Building / floor / room'**
  String get locationDetail;

  /// No description provided for @locationDetailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Library, 2nd floor, room 204'**
  String get locationDetailHint;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get publishing;

  /// No description provided for @publishSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report published successfully'**
  String get publishSuccess;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Complete photo, description, category, and location.'**
  String get validationError;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @descriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 10 characters'**
  String get descriptionTooShort;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Maximum is 200 characters'**
  String get descriptionTooLong;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @reportedFound.
  ///
  /// In en, this message translates to:
  /// **'Reported as found'**
  String get reportedFound;

  /// No description provided for @reportedLost.
  ///
  /// In en, this message translates to:
  /// **'Reported as lost'**
  String get reportedLost;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @mapLocation.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get mapLocation;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get dateTime;

  /// No description provided for @reportDateTimeHint.
  ///
  /// In en, this message translates to:
  /// **'When was it lost/found?'**
  String get reportDateTimeHint;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contacting.
  ///
  /// In en, this message translates to:
  /// **'Contacting'**
  String get contacting;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'min ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hr ago'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @locationServices.
  ///
  /// In en, this message translates to:
  /// **'Location services'**
  String get locationServices;

  /// No description provided for @locationServicesStatus.
  ///
  /// In en, this message translates to:
  /// **'Manage permission in system settings'**
  String get locationServicesStatus;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @safetySupport.
  ///
  /// In en, this message translates to:
  /// **'Safety & Support'**
  String get safetySupport;

  /// No description provided for @helpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help / FAQ'**
  String get helpFaq;

  /// No description provided for @reportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportProblem;

  /// No description provided for @termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms & Privacy'**
  String get termsPrivacy;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get signedOut;

  /// No description provided for @systemSettingsOpened.
  ///
  /// In en, this message translates to:
  /// **'System settings opened'**
  String get systemSettingsOpened;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @demoUserName.
  ///
  /// In en, this message translates to:
  /// **'Mohaned Noah'**
  String get demoUserName;

  /// No description provided for @demoUserEmail.
  ///
  /// In en, this message translates to:
  /// **'mohaned.noah@uot.edu'**
  String get demoUserEmail;

  /// No description provided for @demoUniversity.
  ///
  /// In en, this message translates to:
  /// **'Tripoli University'**
  String get demoUniversity;

  /// No description provided for @arabicLanguageName.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicLanguageName;

  /// No description provided for @englishLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageName;

  /// No description provided for @imageAttachment.
  ///
  /// In en, this message translates to:
  /// **'Image attachment'**
  String get imageAttachment;

  /// No description provided for @couldNotAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Could not attach image.'**
  String get couldNotAttachImage;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied.'**
  String get messageCopied;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @reportConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Report conversation?'**
  String get reportConversationTitle;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockUserTitle;

  /// No description provided for @reportConversationBody.
  ///
  /// In en, this message translates to:
  /// **'This sends the conversation to campus support for review.'**
  String get reportConversationBody;

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'You will leave this conversation and stop receiving messages here.'**
  String get blockUserBody;

  /// No description provided for @conversationReported.
  ///
  /// In en, this message translates to:
  /// **'Conversation reported.'**
  String get conversationReported;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @aboutItem.
  ///
  /// In en, this message translates to:
  /// **'About: {itemTitle}'**
  String aboutItem(String itemTitle);

  /// No description provided for @chatSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Keep personal info private. Meet in safe places.'**
  String get chatSafetyNote;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Attach image'**
  String get attachImage;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation'**
  String get startConversation;

  /// No description provided for @startConversationHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a clear question about the item and keep meetups public.'**
  String get startConversationHint;

  /// No description provided for @campusMember.
  ///
  /// In en, this message translates to:
  /// **'Campus member'**
  String get campusMember;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get startNow;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow location?'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Location helps suggest nearby places and match reports to the right area. You can continue without it.'**
  String get locationPermissionBody;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost & Found'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our campus community'**
  String get splashSubtitle;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Campus Lost & Found'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The simple and safe way to find lost items and return what is found on campus.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Post lost or found items fast'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit the essential details in moments and help the campus community return items.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Use photo + location to match items'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'A clear photo and a precise place make searching and matching easier for everyone.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Chat securely with the poster'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Coordinate the return in-app while keeping personal information private.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @notificationsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be notified when matches or updates are found.'**
  String get notificationsEmptyHint;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @clearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get clearAllConfirm;

  /// No description provided for @clearAllConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get clearAllConfirmMessage;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @allNotificationsCleared.
  ///
  /// In en, this message translates to:
  /// **'All notifications cleared'**
  String get allNotificationsCleared;

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedRead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
