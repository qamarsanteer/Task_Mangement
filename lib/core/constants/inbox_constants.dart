/// معرّف المشروع الوهمي (pseudo-project) تبع الـ Inbox. أي تاسك ما
/// انحدد إلو مشروع وقت الإنشاء بيتخزن بـ projectId = kInboxProjectId،
/// وبيستخدم نفس منطق TasksScreen/TaskRepository الموجود أصلاً للمشاريع
/// العادية (getTasks/createTask/deleteTask...) بدون أي تخصيص إضافي —
/// الفرق الوحيد إنه ما إلو workspace حقيقي، وإنه من شاشته بيقدر المستخدم
/// "ينقل" التاسك لمشروع حقيقي (شوفي MoveTaskToProjectUseCase).
const String kInboxProjectId = 'inbox';