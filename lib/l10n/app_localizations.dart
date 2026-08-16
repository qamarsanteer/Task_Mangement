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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Masar'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Masar'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your tasks efficiently'**
  String get welcomeSubtitle;

  /// No description provided for @workspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspace;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Masar'**
  String get about;

  /// No description provided for @bin.
  ///
  /// In en, this message translates to:
  /// **'Bin'**
  String get bin;

  /// No description provided for @deletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Deleted Tasks'**
  String get deletedTasks;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete Forever'**
  String get deleteForever;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @passwordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLength;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Please enter your details.'**
  String get welcomeBack;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account to get started.'**
  String get createAccount;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @addPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Photo'**
  String get addPhotoTitle;

  /// No description provided for @addPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a profile photo so your team can recognize you.'**
  String get addPhotoSubtitle;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @noDeletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No deleted tasks'**
  String get noDeletedTasks;

  /// No description provided for @deletedAgo.
  ///
  /// In en, this message translates to:
  /// **'Deleted {time}'**
  String deletedAgo(Object time);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @taskRestored.
  ///
  /// In en, this message translates to:
  /// **'Task restored'**
  String get taskRestored;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutTitle;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get userEmail;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @preferencesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSectionTitle;

  /// No description provided for @aboutSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSectionTitle;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get darkModeSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your personal task management companion.'**
  String get appTagline;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Masar v1.0.0'**
  String get appVersionLabel;

  /// No description provided for @workspacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspacesTitle;

  /// No description provided for @addWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Add Workspace'**
  String get addWorkspace;

  /// No description provided for @workspaceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Workspace Name'**
  String get workspaceNameLabel;

  /// No description provided for @workspaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter workspace name'**
  String get workspaceNameHint;

  /// No description provided for @deleteWorkspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Workspace'**
  String get deleteWorkspaceTitle;

  /// No description provided for @deleteWorkspaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteWorkspaceConfirm(Object name);

  /// No description provided for @noWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'No workspaces yet'**
  String get noWorkspaces;

  /// No description provided for @noWorkspacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first workspace to get started'**
  String get noWorkspacesSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @addProject.
  ///
  /// In en, this message translates to:
  /// **'Add Project'**
  String get addProject;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectNameLabel;

  /// No description provided for @projectNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter project name'**
  String get projectNameHint;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteProjectConfirm(Object name);

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get noProjects;

  /// No description provided for @noProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first project to get started'**
  String get noProjectsSubtitle;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter task title'**
  String get taskTitleHint;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add more details'**
  String get taskDescriptionHint;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDateLabel;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDueDate;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @notImportant.
  ///
  /// In en, this message translates to:
  /// **'Not important'**
  String get notImportant;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @notUrgent.
  ///
  /// In en, this message translates to:
  /// **'Not urgent'**
  String get notUrgent;

  /// No description provided for @importanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Importance'**
  String get importanceLabel;

  /// No description provided for @urgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgencyLabel;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteTaskConfirm(Object title);

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasks;

  /// No description provided for @noTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first task to get started'**
  String get noTasksSubtitle;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @taskStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get taskStatusNotStarted;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @selectView.
  ///
  /// In en, this message translates to:
  /// **'Select View'**
  String get selectView;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @viewBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get viewBoard;

  /// No description provided for @viewTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get viewTimeline;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get viewCalendar;

  /// No description provided for @taskDetails.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @labelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelField;

  /// No description provided for @addDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Added on'**
  String get addDateLabel;

  /// No description provided for @attachmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsLabel;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'files selected'**
  String get filesSelected;

  /// No description provided for @repeatEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat Every'**
  String get repeatEveryLabel;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNone;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get labelWork;

  /// No description provided for @labelPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get labelPersonal;

  /// No description provided for @labelStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get labelStudy;

  /// No description provided for @labelHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get labelHealth;

  /// No description provided for @labelFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get labelFinance;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get labelOther;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @editEmail.
  ///
  /// In en, this message translates to:
  /// **'Edit Email'**
  String get editEmail;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTaskTitle;

  /// No description provided for @editDescription.
  ///
  /// In en, this message translates to:
  /// **'Edit Description'**
  String get editDescription;

  /// No description provided for @editDueDate.
  ///
  /// In en, this message translates to:
  /// **'Edit Due Date'**
  String get editDueDate;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDate;

  /// No description provided for @editPriority.
  ///
  /// In en, this message translates to:
  /// **'Edit Priority'**
  String get editPriority;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Label'**
  String get editLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No Label'**
  String get noLabel;

  /// No description provided for @editRepeat.
  ///
  /// In en, this message translates to:
  /// **'Edit Repeat'**
  String get editRepeat;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachment;

  /// No description provided for @attachmentContentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'File content isn\'t available anymore (e.g. after a page refresh). This is a temporary limitation until a real upload server is added.'**
  String get attachmentContentUnavailable;

  /// No description provided for @attachmentOpenUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Opening files isn\'t supported on this platform yet.'**
  String get attachmentOpenUnsupported;

  /// No description provided for @attachmentPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment Preview'**
  String get attachmentPreviewTitle;

  /// No description provided for @attachmentNoPreviewAvailable.
  ///
  /// In en, this message translates to:
  /// **'No preview available for this file type, but you can still download it.'**
  String get attachmentNoPreviewAvailable;

  /// No description provided for @attachmentDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get attachmentDownload;

  /// No description provided for @attachmentDownloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully.'**
  String get attachmentDownloadSuccess;

  /// No description provided for @attachmentDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled.'**
  String get attachmentDownloadCancelled;

  /// No description provided for @attachmentDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download file.'**
  String get attachmentDownloadFailed;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @addMoreAttachments.
  ///
  /// In en, this message translates to:
  /// **'Add more attachments'**
  String get addMoreAttachments;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @calendarTasksOn.
  ///
  /// In en, this message translates to:
  /// **'Tasks on {date}'**
  String calendarTasksOn(Object date);

  /// No description provided for @calendarNoTasksForDate.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this date'**
  String get calendarNoTasksForDate;

  /// No description provided for @calendarNoTasksForDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks due on this day will show up here'**
  String get calendarNoTasksForDateSubtitle;

  /// No description provided for @calendarLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load tasks. Pull down to refresh.'**
  String get calendarLoadError;

  /// No description provided for @calendarPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get calendarPickDate;
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
      'that was used.');
}
