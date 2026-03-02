import 'dart:math';

/// In-memory demo data so the app works without a backend.
class DemoData {
  static final DemoData _i = DemoData._();
  factory DemoData() => _i;
  DemoData._();

  final List<Map<String, dynamic>> _courses = [];
  final Map<String, List<Map<String, dynamic>>> _messages = {};
  int _courseCounter = 0;

  // Moderator tracking: sectionId -> set of userIds
  final Map<String, Set<String>> _moderators = {};

  // DM storage: sorted pairKey -> messages
  final Map<String, List<Map<String, dynamic>>> _dmMessages = {};
  // Track DM conversations per user
  final Map<String, Set<String>> _dmPartners = {};

  bool isDemoUser(String? token) =>
      token != null && token.startsWith('demo-token-');

  List<Map<String, dynamic>> getCourses(String? role, String? userId) {
    if (_courses.isEmpty) _seed();
    return List.from(_courses);
  }

  void _seed() {
    addCourse(
      name: 'Data Structures & Algorithms',
      code: 'CSE221',
      semester: 'Spring 2026',
      roomId: 'CSE221-A',
      roomPass: 'pass',
      teacherName: 'Dr. Ahmed',
      teacherId: 'demo-teacher-001',
    );
    addCourse(
      name: 'Database Management Systems',
      code: 'CSE311',
      semester: 'Spring 2026',
      roomId: 'CSE311-B',
      roomPass: 'pass',
      teacherName: 'Dr. Ahmed',
      teacherId: 'demo-teacher-001',
    );
    addCourse(
      name: 'Software Engineering',
      code: 'CSE327',
      semester: 'Spring 2026',
      roomId: 'CSE327-C',
      roomPass: 'pass',
      teacherName: 'Prof. Rahman',
      teacherId: 'demo-teacher-002',
    );
    addCourse(
      name: 'Computer Networks',
      code: 'CSE322',
      semester: 'Fall 2025',
      roomId: 'CSE322-D',
      roomPass: 'pass',
      teacherName: 'Dr. Karim',
      teacherId: 'demo-teacher-003',
      active: false,
    );

    // Seed messages with realistic timestamps
    final now = DateTime.now();
    _seedMessages(_courses[0]['sections'][0]['id'], [
      _msg(
          'Please review Chapter 7 on AVL trees before next class.',
          'demo-teacher-001',
          'Dr. Ahmed',
          now.subtract(const Duration(minutes: 12))),
      _msg('Will the AVL tree topic be in the midterm?', 'demo-student-001',
          'Demo Student', now.subtract(const Duration(minutes: 8))),
    ]);
    _seedMessages(_courses[1]['sections'][0]['id'], [
      _msg(
          'Submission for Assignment 3 is extended to Friday.',
          'demo-teacher-001',
          'Dr. Ahmed',
          now.subtract(const Duration(hours: 2))),
    ]);
    _seedMessages(_courses[2]['sections'][0]['id'], [
      _msg('Group project presentations start next week.', 'demo-teacher-002',
          'Prof. Rahman', now.subtract(const Duration(hours: 5))),
      _msg('Can we get the rubric for the presentation?', 'demo-student-001',
          'Demo Student', now.subtract(const Duration(hours: 4))),
      _msg(
          'Already shared on the portal. Check your email.',
          'demo-teacher-002',
          'Prof. Rahman',
          now.subtract(const Duration(hours: 3, minutes: 45))),
    ]);
    _seedMessages(_courses[3]['sections'][0]['id'], [
      _msg(
          'Final grades are posted. Great semester everyone!',
          'demo-teacher-003',
          'Dr. Karim',
          now.subtract(const Duration(days: 30))),
    ]);

    // Seed a demo DM
    _addDM('demo-student-001', 'Demo Student', 'demo-teacher-001', 'Dr. Ahmed',
        'Hi Dr., can I get extra time on the assignment?',
        time: now.subtract(const Duration(hours: 1)));
    _addDM('demo-teacher-001', 'Dr. Ahmed', 'demo-student-001', 'Demo Student',
        'Sure, you have until Monday.',
        time: now.subtract(const Duration(minutes: 45)));
  }

  void _seedMessages(String secId, List<Map<String, dynamic>> msgs) {
    _messages[secId] = msgs;
  }

  Map<String, dynamic> _msg(
      String content, String senderId, String name, DateTime time) {
    return {
      'id': 'msg-${Random().nextInt(99999)}',
      'content': content,
      'senderId': senderId,
      'sender': {'name': name},
      'createdAt': time.toIso8601String(),
    };
  }

  Map<String, dynamic> addCourse({
    required String name,
    required String code,
    required String semester,
    required String roomId,
    required String roomPass,
    required String teacherName,
    required String teacherId,
    bool active = true,
  }) {
    _courseCounter++;
    final secId = 'sec-$_courseCounter-${roomId.hashCode.abs()}';
    final course = {
      'id': 'course-$_courseCounter',
      'name': name,
      'code': code,
      'semester': semester,
      'chatRoomId': roomId,
      'teacher': {'id': teacherId, 'name': teacherName},
      'sections': [
        {
          'id': secId,
          'isActive': active,
          'chatRoomId': roomId,
        }
      ],
    };
    _courses.add(course);
    _messages[secId] = [];
    return course;
  }

  Map<String, dynamic>? joinCourse(String roomId, String pass) {
    final c = _courses.firstWhere(
      (c) => c['chatRoomId'] == roomId,
      orElse: () => <String, dynamic>{},
    );
    if (c.isEmpty) return null;
    return c;
  }

  List<Map<String, dynamic>> getMessages(String sectionId) {
    return _messages[sectionId] ?? [];
  }

  /// Get the last message for a section
  Map<String, dynamic>? getLastMessage(String sectionId) {
    final msgs = _messages[sectionId];
    if (msgs == null || msgs.isEmpty) return null;
    return msgs.last;
  }

  int getMessageCount(String sectionId) {
    return _messages[sectionId]?.length ?? 0;
  }

  void addMessage(
      String sectionId, String content, String senderId, String senderName) {
    _messages.putIfAbsent(sectionId, () => []);
    _messages[sectionId]!.add({
      'id': 'msg-${Random().nextInt(99999)}',
      'content': content,
      'senderId': senderId,
      'sender': {'name': senderName},
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  List<Map<String, dynamic>> getMembers(String sectionId) {
    final mods = _moderators[sectionId] ?? {};
    return [
      {
        'id': 'demo-teacher-001',
        'name': 'Dr. Ahmed',
        'email': 'ahmed@diu.edu.bd',
        'role': 'teacher',
      },
      {
        'id': 'demo-student-001',
        'name': 'Demo Student',
        'email': 'student@diu.edu.bd',
        'role': mods.contains('demo-student-001') ? 'moderator' : 'student',
      },
      {
        'id': 'demo-student-002',
        'name': 'Fahim Hassan',
        'email': 'fahim@diu.edu.bd',
        'role': mods.contains('demo-student-002') ? 'moderator' : 'student',
      },
      {
        'id': 'demo-student-003',
        'name': 'Nusrat Jahan',
        'email': 'nusrat@diu.edu.bd',
        'role': mods.contains('demo-student-003') ? 'moderator' : 'student',
      },
    ];
  }

  void endClass(String sectionId) {
    for (final c in _courses) {
      for (final s in c['sections']) {
        if (s['id'] == sectionId) s['isActive'] = false;
      }
    }
  }

  // ─── Moderator methods ───
  void setModerator(String sectionId, String userId) {
    _moderators.putIfAbsent(sectionId, () => {});
    _moderators[sectionId]!.add(userId);
  }

  void removeModerator(String sectionId, String userId) {
    _moderators[sectionId]?.remove(userId);
  }

  bool isModerator(String sectionId, String userId) {
    return _moderators[sectionId]?.contains(userId) ?? false;
  }

  // ─── DM methods ───
  String _dmKey(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void _addDM(String fromId, String fromName, String toId, String toName,
      String content,
      {DateTime? time}) {
    final key = _dmKey(fromId, toId);
    _dmMessages.putIfAbsent(key, () => []);
    _dmMessages[key]!.add({
      'id': 'dm-${Random().nextInt(99999)}',
      'content': content,
      'senderId': fromId,
      'sender': {'name': fromName},
      'createdAt': (time ?? DateTime.now()).toIso8601String(),
    });
    // Track partners
    _dmPartners.putIfAbsent(fromId, () => {});
    _dmPartners[fromId]!.add(toId);
    _dmPartners.putIfAbsent(toId, () => {});
    _dmPartners[toId]!.add(fromId);
  }

  void sendDM(String fromId, String fromName, String toId, String content) {
    _addDM(fromId, fromName, toId, '', content);
  }

  List<Map<String, dynamic>> getDMMessages(String userId1, String userId2) {
    return _dmMessages[_dmKey(userId1, userId2)] ?? [];
  }

  /// Returns list of DM conversation summaries for a user
  List<Map<String, dynamic>> getDMConversations(String userId) {
    final partners = _dmPartners[userId] ?? {};
    final result = <Map<String, dynamic>>[];
    for (final pid in partners) {
      final msgs = getDMMessages(userId, pid);
      if (msgs.isEmpty) continue;
      final last = msgs.last;
      result.add({
        'partnerId': pid,
        'partnerName': last['senderId'] == pid
            ? (last['sender']?['name'] ?? 'Unknown')
            : _findName(pid),
        'lastMessage': last['content'],
        'lastTime': last['createdAt'],
        'unread': 0,
      });
    }
    // Sort by last time
    result.sort((a, b) => (b['lastTime'] as String).compareTo(a['lastTime']));
    return result;
  }

  String _findName(String userId) {
    // Search member lists
    for (final c in _courses) {
      final teacher = c['teacher'];
      if (teacher != null && teacher['id'] == userId) return teacher['name'];
    }
    final names = {
      'demo-student-001': 'Demo Student',
      'demo-student-002': 'Fahim Hassan',
      'demo-student-003': 'Nusrat Jahan',
      'demo-teacher-001': 'Dr. Ahmed',
      'demo-teacher-002': 'Prof. Rahman',
      'demo-teacher-003': 'Dr. Karim',
      'demo-admin-001': 'Admin User',
    };
    return names[userId] ?? 'Unknown';
  }
}
