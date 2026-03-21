import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> with SingleTickerProviderStateMixin {
  final _supabase = SupabaseService.client;
  late TabController _tabController;
  
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  
  // To-Do State
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchEvents(),
      _fetchTasks(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchEvents() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      final response = await _supabase
          .from('lawyer_events')
          .select()
          .eq('lawyer_id', user.id);
      
      final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};
      for (var event in (response as List)) {
        final date = DateTime.parse(event['start_time']);
        final day = DateTime(date.year, date.month, date.day);
        if (newEvents[day] == null) newEvents[day] = [];
        newEvents[day]!.add(Map<String, dynamic>.from(event));
      }
      if (mounted) setState(() => _events = newEvents);
    } catch (e) {
      debugPrint('Error fetching events: $e');
    }
  }

  Future<void> _fetchTasks() async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      final response = await _supabase
          .from('lawyer_tasks')
          .select()
          .eq('lawyer_id', user.id)
          .order('due_date', ascending: true);
      
      if (mounted) setState(() => _tasks = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _events[d] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.task_alt), text: 'To-Do'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCalendarTab(),
          _buildToDoTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 ? _showAddEventDialog() : _showAddTaskDialog(),
        backgroundColor: AppConstants.accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event, color: AppConstants.accentColor),
              title: const Text('Add Event'),
              onTap: () {
                Navigator.pop(context);
                _showAddEventDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.task_alt, color: AppConstants.accentColor),
              title: const Text('Add Task'),
              onTap: () {
                Navigator.pop(context);
                _showAddTaskDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Calendar Tab ---
  Widget _buildCalendarTab() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(color: AppConstants.secondaryColor, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: AppConstants.accentColor, shape: BoxShape.circle),
            markerDecoration: BoxDecoration(color: AppConstants.accentColor, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    final items = _getEventsForDay(_selectedDay ?? DateTime.now());
    if (items.isEmpty) return const Center(child: Text('No events for this day.'));
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.event, color: AppConstants.accentColor),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('hh:mm a').format(DateTime.parse(item['start_time']))),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _deleteEvent(item['id']),
            ),
          ),
        );
      },
    );
  }

  // --- To-Do Tab (Matches Screenshot) ---
  Widget _buildToDoTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    
    return Container(
      color: AppConstants.primaryColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('To-Do List', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_task, color: Colors.white70, size: 28),
                  onPressed: _showAddTaskDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No tasks yet.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isDone = task['is_done'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleTask(task['id'], !isDone),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDone ? const Color(0xFF6750A4) : Colors.white54, width: 2),
                                  borderRadius: BorderRadius.circular(4),
                                  color: isDone ? const Color(0xFF6750A4) : Colors.transparent,
                                ),
                                child: isDone ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task['title'], style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  )),
                                  if (task['case_name'] != null && task['case_name'].isNotEmpty)
                                    Text('Case: ${task['case_name']}', style: const TextStyle(color: Colors.white60, fontSize: 14)),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(DateTime.parse(task['due_date'])),
                                    style: const TextStyle(color: Color(0xFFA690FF), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteTask(task['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }





  // --- Actions ---
  Future<void> _deleteEvent(String id) async {
    try {
      await _supabase.from('lawyer_events').delete().eq('id', id);
      await NotificationService.cancelNotification(id.hashCode);
      _fetchEvents();
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await _supabase.from('lawyer_tasks').delete().eq('id', id);
      await NotificationService.cancelNotification(id.hashCode);
      _fetchTasks();
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  Future<void> _toggleTask(String id, bool? isDone) async {
    try {
      await _supabase.from('lawyer_tasks').update({'is_done': isDone}).eq('id', id);
      _fetchTasks();
    } catch (e) {
      debugPrint('Error toggling task: $e');
    }
  }

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              ListTile(
                title: Text('Time: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: selectedTime);
                  if (t != null) setDialogState(() => selectedTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final start = DateTime(
                  _selectedDay!.year, _selectedDay!.month, _selectedDay!.day,
                  selectedTime.hour, selectedTime.minute
                );
                try {
                  final response = await _supabase.from('lawyer_events').insert({
                    'lawyer_id': ref.read(authProvider)!.id,
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'start_time': start.toIso8601String(),
                    'end_time': start.add(const Duration(hours: 1)).toIso8601String(),
                  }).select().single();

                  await NotificationService.scheduleNotification(
                    id: response['id'].hashCode,
                    title: 'Upcoming Event: ${titleCtrl.text.trim()}',
                    body: 'Starts at ${DateFormat('hh:mm a').format(start)}',
                    scheduledDate: start.subtract(const Duration(minutes: 15)), // 15 min reminder
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved!')));
                    _fetchEvents();
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final caseCtrl = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Task Title')),
                TextField(controller: caseCtrl, decoration: const InputDecoration(labelText: 'Case Name (Optional)')),
                ListTile(
                  title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context, 
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                ),
                ListTile(
                  title: Text('Time: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: selectedTime);
                    if (t != null) setDialogState(() => selectedTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final due = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute
                );
                try {
                  final response = await _supabase.from('lawyer_tasks').insert({
                    'lawyer_id': ref.read(authProvider)!.id,
                    'title': titleCtrl.text.trim(),
                    'case_name': caseCtrl.text.trim(),
                    'due_date': due.toIso8601String(),
                    'is_done': false,
                  }).select().single();

                  await NotificationService.scheduleNotification(
                    id: response['id'].hashCode,
                    title: 'Task Reminder: ${titleCtrl.text.trim()}',
                    body: 'Your task is due now!',
                    scheduledDate: due,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task saved!')));
                    _fetchTasks();
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save task: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
