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
  String get addPhotoSubtitle =>
      'Add a profile photo so your team can recognize you.';

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
  String get taskDeletedForever => 'Task deleted forever';

  @override
  String binItemLocation(Object project, Object workspace) {
    return '$project • $workspace';
  }

  @override
  String daysRemaining(Object count) {
    return '$count days left';
  }

  @override
  String get lastDayRemaining => 'Last day before permanent deletion';

  @override
  String get retry => 'Retry';

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
  String get noWorkspacesSubtitle =>
      'Create your first workspace to get started';

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

  @override
  String get addTask => 'Add Task';

  @override
  String get taskTitleLabel => 'Task Title';

  @override
  String get taskTitleHint => 'Enter task title';

  @override
  String get taskDescriptionLabel => 'Description (optional)';

  @override
  String get taskDescriptionHint => 'Add more details';

  @override
  String get dueDateLabel => 'Due Date';

  @override
  String get selectDueDate => 'Select date';

  @override
  String get important => 'Important';

  @override
  String get notImportant => 'Not important';

  @override
  String get urgent => 'Urgent';

  @override
  String get notUrgent => 'Not urgent';

  @override
  String get importanceLabel => 'Importance';

  @override
  String get urgencyLabel => 'Urgency';

  @override
  String get deleteTaskTitle => 'Delete Task';

  @override
  String deleteTaskConfirm(Object title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get noTasks => 'No tasks yet';

  @override
  String get noTasksSubtitle => 'Add your first task to get started';

  @override
  String get overdue => 'Overdue';

  @override
  String get taskStatusNotStarted => 'Not Started';

  @override
  String get taskStatusInProgress => 'In Progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get selectView => 'Select View';

  @override
  String get viewList => 'List';

  @override
  String get viewBoard => 'Board';

  @override
  String get viewTimeline => 'Timeline';

  @override
  String get viewCalendar => 'Calendar';

  @override
  String get taskDetails => 'Task Details';

  @override
  String get status => 'Status';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get labelField => 'Label';

  @override
  String get addDateLabel => 'Added on';

  @override
  String get attachmentsLabel => 'Attachments';

  @override
  String get filesSelected => 'files selected';

  @override
  String get repeatEveryLabel => 'Repeat Every';

  @override
  String get repeatNone => 'Never';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get labelWork => 'Work';

  @override
  String get labelPersonal => 'Personal';

  @override
  String get labelStudy => 'Study';

  @override
  String get labelHealth => 'Health';

  @override
  String get labelFinance => 'Finance';

  @override
  String get labelOther => 'Other';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editName => 'Edit Name';

  @override
  String get editEmail => 'Edit Email';

  @override
  String get save => 'Save';

  @override
  String get editTaskTitle => 'Edit Title';

  @override
  String get editDescription => 'Edit Description';

  @override
  String get editDueDate => 'Edit Due Date';

  @override
  String get clearDate => 'Clear date';

  @override
  String get editPriority => 'Edit Priority';

  @override
  String get editLabel => 'Edit Label';

  @override
  String get noLabel => 'No Label';

  @override
  String get editRepeat => 'Edit Repeat';

  @override
  String get addAttachment => 'Add Attachment';

  @override
  String get attachmentContentUnavailable =>
      'File content isn\'t available anymore (e.g. after a page refresh). This is a temporary limitation until a real upload server is added.';

  @override
  String get attachmentOpenUnsupported =>
      'Opening files isn\'t supported on this platform yet.';

  @override
  String get attachmentPreviewTitle => 'Attachment Preview';

  @override
  String get attachmentNoPreviewAvailable =>
      'No preview available for this file type, but you can still download it.';

  @override
  String get attachmentDownload => 'Download';

  @override
  String get attachmentDownloadSuccess => 'File saved successfully.';

  @override
  String get attachmentDownloadCancelled => 'Download cancelled.';

  @override
  String get attachmentDownloadFailed => 'Failed to download file.';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get addMoreAttachments => 'Add more attachments';

  @override
  String get today => 'Today';

  @override
  String calendarTasksOn(Object date) {
    return 'Tasks on $date';
  }

  @override
  String get calendarNoTasksForDate => 'No tasks for this date';

  @override
  String get calendarNoTasksForDateSubtitle =>
      'Tasks due on this day will show up here';

  @override
  String get calendarLoadError => 'Couldn\'t load tasks. Pull down to refresh.';

  @override
  String get calendarPickDate => 'Pick a date';

  @override
  String get selectProjectLabel => 'Project';

  @override
  String get selectProjectHint => 'Select a project';

  @override
  String get selectWorkspaceHint => 'Select a workspace';

  @override
  String get noProjectsForTask =>
      'You don\'t have any projects yet. Create a project first to add a task.';

  @override
  String get noProjectsInWorkspace =>
      'This workspace has no projects yet. Create one first.';

  @override
  String get calendarDeleteTaskTooltip => 'Delete task';

  @override
  String get moveToProject => 'Move to Project';

  @override
  String taskMovedSuccess(Object project) {
    return 'Task moved to \"$project\"';
  }

  @override
  String get inboxTaskOptionsTitle =>
      'What would you like to do with this task?';

  @override
  String get boardView => 'Board View';

  @override
  String get eisenhowerDoFirst => 'Important & Urgent';

  @override
  String get eisenhowerPlan => 'Important & Not Urgent';

  @override
  String get eisenhowerDelegate => 'Not Important & Urgent';

  @override
  String get eisenhowerEliminate => 'Not Important & Not Urgent';

  @override
  String get doItNow => 'Do it now';

  @override
  String get planIt => 'Plan it';

  @override
  String get delegateIt => 'Delegate it';

  @override
  String get later => 'Later';

  @override
  String get boardColumnEmpty => 'No tasks in this section';
}
