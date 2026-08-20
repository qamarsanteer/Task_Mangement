enum ProjectMemberRole {
  readOnly,
  readWrite;

  String get apiValue {
    switch (this) {
      case ProjectMemberRole.readOnly:
        return 'read_only';
      case ProjectMemberRole.readWrite:
        return 'read_write';
    }
  }
}