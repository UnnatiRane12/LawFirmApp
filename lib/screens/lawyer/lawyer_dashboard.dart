import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/review_service.dart';
import '../../models/review_model.dart';
import 'case_management_screen.dart';
import 'appointment_management_screen.dart';
import 'lawyer_profile_screen.dart';
import 'legal_templates_screen.dart';
import '../common/chat_list_screen.dart';

class LawyerDashboard extends ConsumerStatefulWidget {
  const LawyerDashboard({super.key});

  @override
  ConsumerState<LawyerDashboard> createState() => _LawyerDashboardState();
}

class _LawyerDashboardState extends ConsumerState<LawyerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const LawyerHomeScreen(),
    const CaseManagementScreen(),
    const AppointmentManagementScreen(),
    const ChatListScreen(),
    const LegalTemplatesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor.withOpacity(0.8),
        elevation: 0,
        title: Row(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.matrix([
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                1, 1, 1, 0, -1,
              ]),
              child: Image.asset(
                AppConstants.logoAsset,
                height: 32,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Mercury Legal',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 22),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_shared_rounded), label: 'Cases'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Appts'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.description_rounded), label: 'Drafts'),
          ],
          selectedItemColor: AppConstants.accentColor,
          unselectedItemColor: AppConstants.textSecondaryColor.withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppConstants.primaryColor,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class LawyerHomeScreen extends ConsumerStatefulWidget {
  const LawyerHomeScreen({super.key});

  @override
  ConsumerState<LawyerHomeScreen> createState() => _LawyerHomeScreenState();
}

class _LawyerHomeScreenState extends ConsumerState<LawyerHomeScreen> {
  final _supabase = SupabaseService.client;

  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _tasks = [];
  List<ReviewModel> _lawyerReviews = [];
  double _currentRating = 5.0;
  int _currentReviewCount = 0;
  bool _loadingEvents = true;
  bool _loadingTasks = true;
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchUpcomingEvents(), _fetchTasks(), _fetchReviews(), _fetchRating()]);
  }

  Future<void> _fetchRating() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      final data = await ReviewService.getLawyerRating(user.id);
      setState(() {
        _currentRating = (data['average_rating'] == null || (data['average_rating'] ?? 0) == 0) ? 5.0 : (data['average_rating'] as num).toDouble();
        _currentReviewCount = data['review_count'] ?? 0;
      });
    } catch (e) {
      debugPrint('Error fetching rating: $e');
    }
  }

  Future<void> _fetchReviews() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    setState(() => _loadingReviews = true);
    try {
      final reviews = await ReviewService.getLawyerReviews(user.id);
      setState(() {
        _lawyerReviews = reviews;
        _currentRating = ReviewService.calculateAverage(reviews);
        _currentReviewCount = reviews.length;
        _loadingReviews = false;
      });
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      setState(() => _loadingReviews = false);
    }
  }

  Future<void> _fetchUpcomingEvents() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    setState(() => _loadingEvents = true);
    try {
      final todayStart = DateTime.utc(
        DateTime.now().year, DateTime.now().month, DateTime.now().day,
      ).toIso8601String();

      final response = await _supabase
          .from('lawyer_events')
          .select()
          .eq('lawyer_id', user.id)
          .gte('start_time', todayStart)
          .order('start_time', ascending: true)
          .limit(10);

      setState(() {
        _upcomingEvents = List<Map<String, dynamic>>.from(response);
        _loadingEvents = false;
      });
    } catch (e) {
      debugPrint('Error fetching events: $e');
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _fetchTasks() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    setState(() => _loadingTasks = true);
    try {
      final response = await _supabase
          .from('lawyer_tasks')
          .select()
          .eq('lawyer_id', user.id)
          .order('due_date', ascending: true);

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _loadingTasks = false;
      });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
      setState(() => _loadingTasks = false);
    }
  }

  Future<void> _toggleTask(String id, bool isDone) async {
    try {
      await _supabase.from('lawyer_tasks').update({'is_done': isDone}).eq('id', id);
      _fetchTasks();
    } catch (e) {
      debugPrint('Toggle task error: $e');
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await _supabase.from('lawyer_tasks').delete().eq('id', id);
      _fetchTasks();
    } catch (e) {
      debugPrint('Delete task error: $e');
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _supabase.from('lawyer_events').delete().eq('id', id);
      _fetchUpcomingEvents();
    } catch (e) {
      debugPrint('Delete event error: $e');
    }
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppConstants.primaryColor,
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title', prefixIcon: Icon(Icons.event))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes)), maxLines: 2),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppConstants.accentColor),
                  title: Text(DateFormat('EEE, MMM dd yyyy').format(selectedDate)),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setS(() => selectedDate = d);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppConstants.accentColor),
                  title: Text(selectedTime.format(ctx)),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                    if (t != null) setS(() => selectedTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                try {
                  await _supabase.from('lawyer_events').insert({
                    'lawyer_id': ref.read(authProvider)!.id,
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'start_time': start.toIso8601String(),
                    'end_time': start.add(const Duration(hours: 1)).toIso8601String(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchUpcomingEvents();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final caseCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppConstants.primaryColor,
          title: const Text('Add To-Do Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title', prefixIcon: Icon(Icons.task_alt))),
                const SizedBox(height: 12),
                TextField(controller: caseCtrl, decoration: const InputDecoration(labelText: 'Case Name (optional)', prefixIcon: Icon(Icons.folder))),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppConstants.accentColor),
                  title: Text(DateFormat('EEE, MMM dd yyyy').format(selectedDate)),
                  onTap: () async {
                    final d = await showDatePicker(context: ctx, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                    if (d != null) setS(() => selectedDate = d);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppConstants.accentColor),
                  title: Text(selectedTime.format(ctx)),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: selectedTime);
                    if (t != null) setS(() => selectedTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondaryColor),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final due = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                try {
                  await _supabase.from('lawyer_tasks').insert({
                    'lawyer_id': ref.read(authProvider)!.id,
                    'title': titleCtrl.text.trim(),
                    'case_name': caseCtrl.text.trim(),
                    'due_date': due.toIso8601String(),
                    'is_done': false,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchTasks();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        color: AppConstants.accentColor,
        backgroundColor: AppConstants.primaryColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 40),
            _buildSectionHeader('Priority Schedule', Icons.calendar_today_rounded, _fetchUpcomingEvents, onAdd: _showAddEventDialog),
            const SizedBox(height: 16),
            _buildEventsContent(),
            const SizedBox(height: 44),
            _buildSectionHeader('To-Do Management', Icons.checklist_rtl_rounded, _fetchTasks, onAdd: _showAddTaskDialog),
            const SizedBox(height: 16),
            _buildTasksContent(),
            const SizedBox(height: 48),
            _buildPerformanceOverview(),
            const SizedBox(height: 40),
            _buildReviewsSection(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onRefresh, {VoidCallback? onAdd, Color color = AppConstants.accentColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (onAdd != null)
              IconButton(
                icon: Icon(Icons.add_circle_rounded, color: color, size: 26),
                onPressed: onAdd,
                tooltip: 'Add',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventsContent() {
    if (_loadingEvents) return const Center(child: CircularProgressIndicator());
    if (_upcomingEvents.isEmpty) {
      return _emptyState(Icons.event_available, 'No upcoming events.', 'Tap + to add one.');
    }
    return Column(children: _upcomingEvents.map((e) => _buildEventCard(e)).toList());
  }

  Widget _buildTasksContent() {
    if (_loadingTasks) return const Center(child: CircularProgressIndicator());
    if (_tasks.isEmpty) {
      return _emptyState(Icons.checklist, 'No tasks yet.', 'Tap + to add one.');
    }
    return Column(children: _tasks.map((t) => _buildTaskItem(t)).toList());
  }

  Widget _emptyState(IconData icon, String msg, String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.white24),
          const SizedBox(height: 8),
          Text(msg, style: const TextStyle(color: Colors.white54)),
          Text(hint, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final title = event['title'] ?? 'Event';
    final description = event['description'] ?? '';
    final startTime = DateTime.tryParse(event['start_time'] ?? '') ?? DateTime.now();
    final isToday = DateUtils.isSameDay(startTime, DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isToday ? const Color(0xFFF59E0B).withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFFF59E0B).withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(startTime),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isToday ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(startTime).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isToday ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isToday)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isToday ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TODAY',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isToday ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, size: 14, color: AppConstants.textSecondaryColor),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('hh:mm a').format(startTime),
                            style: TextStyle(
                              color: AppConstants.textSecondaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: TextStyle(color: AppConstants.textSecondaryColor.withOpacity(0.7), fontSize: 13, height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, color: Colors.redAccent.withOpacity(0.5), size: 24),
                  onPressed: () => _deleteEvent(event['id']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final isDone = task['is_done'] == true;
    final title = task['title'] ?? 'Task';
    final caseName = task['case_name'] ?? '';
    String dueStr = '';
    try {
      final due = DateTime.parse(task['due_date']);
      dueStr = DateFormat('MMM dd, hh:mm a').format(due);
    } catch (_) {}

    final isOverdue = !isDone && task['due_date'] != null &&
        DateTime.tryParse(task['due_date'])?.isBefore(DateTime.now()) == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDone ? Colors.white.withOpacity(0.05) : const Color(0xFF8B5CF6).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _toggleTask(task['id'], !isDone),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF8B5CF6) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: isDone ? const Icon(Icons.check_rounded, color: Colors.black, size: 20) : null,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDone ? Colors.white60 : Colors.white,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (caseName.isNotEmpty || dueStr.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (caseName.isNotEmpty) ...[
                              Icon(Icons.folder_shared_rounded, size: 12, color: AppConstants.textSecondaryColor),
                              const SizedBox(width: 6),
                              Text(
                                caseName,
                                style: TextStyle(color: AppConstants.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (dueStr.isNotEmpty) ...[
                              Icon(Icons.history_toggle_off_rounded, size: 12, color: isOverdue ? Colors.redAccent : AppConstants.textSecondaryColor),
                              const SizedBox(width: 6),
                              Text(
                                dueStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue ? Colors.redAccent : AppConstants.textSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, color: Colors.redAccent.withOpacity(0.5), size: 22),
                  onPressed: () => _deleteTask(task['id']),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildPerformanceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Performance Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPerformanceStat('Rating', _currentRating.toStringAsFixed(1), Icons.star_rounded, AppConstants.secondaryColor),
              _buildPerformanceStat('Reviews', '$_currentReviewCount', Icons.rate_review_rounded, const Color(0xFF10B981)),
              _buildPerformanceStat('Success', '96%', Icons.verified_rounded, const Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        if (_loadingReviews)
          const Center(child: CircularProgressIndicator())
        else if (_lawyerReviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppConstants.primaryColor, borderRadius: BorderRadius.circular(24)),
            child: const Center(child: Text('No reviews yet. Build your reputation!', style: TextStyle(color: Colors.white24))),
          )
        else
          Container(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _lawyerReviews.length,
              itemBuilder: (context, index) {
                final r = _lawyerReviews[index];
                return _buildReviewSummaryCard(r.clientName ?? 'Verified Client', r.comment, r.rating);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildReviewSummaryCard(String name, String comment, int rating) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < rating ? AppConstants.secondaryColor : Colors.white10, size: 14))),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: Text(comment, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }


  Widget _buildProfileHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final user = ref.watch(authProvider);
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.backgroundColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1E293B),
                  child: Text(
                    user?.userMetadata?['full_name']?[0]?.toUpperCase() ?? 'L',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Counsel at Law',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      user?.userMetadata?['full_name'] ?? 'Lawyer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerProfileScreen())),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
