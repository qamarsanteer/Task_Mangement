// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Masar';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get logout => 'Log Out';

  @override
  String get skip => 'Skip';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get welcome => 'Welcome to Masar';

  @override
  String get welcomeSubtitle => 'Manage your tasks efficiently';

  @override
  String get workspace => 'Workspace';

  @override
  String get inbox => 'Inbox';

  @override
  String get calendar => 'Calendar';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get language => 'App Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get about => 'About Masar';

  @override
  String get bin => 'Bin';

  @override
  String get deletedTasks => 'Deleted Tasks';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete Forever';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordLength => 'Password must be at least 6 characters';

  @override
  String get welcomeBack => 'Welcome back! Please enter your details.';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get createAccount => 'Create your account to get started.';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get createPassword => 'Create a password';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get addPhotoTitle => 'Add a Photo';

  @override
  String get addPhotoSubtitle => 'Add a profile photo so your team can recognize you.';

  @override
  String get continueText => 'Continue';

  @override
  String get choosePhoto => 'Choose Photo';

  @override
  String get takePhoto => 'Take a Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get noDeletedTasks => 'No deleted tasks';

  @override
  String deletedAgo(Object time) {
    return 'Deleted $time';
  }

  @override
  String get daysAgo => 'days ago';

  @override
  String get hoursAgo => 'hours ago';

  @override
  String get justNow => 'Just now';

  @override
  String get taskRestored => 'Task restored';

  @override
  String get areYouSureLogout => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get logOutTitle => 'Log Out';

  @override
  String get userName => 'User Name';

  @override
  String get userEmail => 'user@example.com';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone.';

  @override
  String get preferencesSectionTitle => 'Preferences';

  @override
  String get aboutSectionTitle => 'About';

  @override
  String get darkModeSubtitle => 'Switch between light and dark theme';

  @override
  String get appTagline => 'Your personal task management companion.';

  @override
  String get appVersionLabel => 'Masar v1.0.0';

  @override
  String get workspacesTitle => 'Workspaces';

  @override
  String get addWorkspace => 'Add Workspace';

  @override
  String get workspaceNameLabel => 'Workspace Name';

  @override
  String get workspaceNameHint => 'Enter workspace name';

  @override
  String get deleteWorkspaceTitle => 'Delete Workspace';

  @override
  String deleteWorkspaceConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get noWorkspaces => 'No workspaces yet';

  @override
  String get noWorkspacesSubtitle => 'Create your first workspace to get started';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get create => 'Create';

  @override
  String get addProject => 'Add Project';

  @override
  String get projectNameLabel => 'Project Name';

  @override
  String get projectNameHint => 'Enter project name';

  @override
  String get deleteProjectTitle => 'Delete Project';

  @override
  String deleteProjectConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get noProjects => 'No projects yet';

  @override
  String get noProjectsSubtitle => 'Create your first project to get started';
}
