import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:table_calendar/table_calendar.dart';
import '../services/event_service.dart'; // Import the event service
import 'notification_page.dart';

// Simple Event model (consider moving to models/ folder if it grows)
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String type;
  final String status;
  final String assignee;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    required this.assignee,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      // Parse date string - Ensure robust parsing
      date: DateTime.parse(json['date'] as String).toLocal(), 
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      type: json['type'] as String,
      status: json['status'] as String? ?? 'Pending', // Handle potential null status
      assignee: json['assignee'] as String,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // State variables
  late DateTime _focusedDay;
  DateTime? _selectedDay; // Made nullable
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<Event>> _events = {}; // Use Event model
  bool _isLoading = false;
  DateTime _currentMonth = DateTime.now(); // Track currently viewed month

  // Keep track of fetched months to avoid redundant calls
  final Set<DateTime> _fetchedMonths = {}; 

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay; // Select today initially
    _currentMonth = DateTime(_focusedDay.year, _focusedDay.month);
    _fetchEventsForMonth(_currentMonth); // Fetch events for initial month
  }

  // Refresh events functionality
  void _refreshEvents() async {
    setState(() {
      _isLoading = true;
      _events.clear(); // Clear existing events
      _fetchedMonths.clear(); // Clear cache of fetched months
    });

    await _fetchEventsForMonth(_currentMonth);

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calendar refreshed')),
    );
  }

  // Fetch events for a given month
  Future<void> _fetchEventsForMonth(DateTime month) async {
    final monthKey = DateTime(month.year, month.month);

    // Avoid fetching if already fetched or currently loading
    if (_isLoading || _fetchedMonths.contains(monthKey)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedEventData = await EventService.fetchEventsForMonth(monthKey);
      final Map<DateTime, List<Event>> eventsForMonth = {};

      for (var eventJson in fetchedEventData) {
        try {
          final event = Event.fromJson(eventJson as Map<String, dynamic>);
          final eventDate = DateTime.utc(event.date.year, event.date.month, event.date.day);
          eventsForMonth.putIfAbsent(eventDate, () => []).add(event);
        } catch (e) {
          print("[CalendarScreen] Error parsing event JSON: $e");
        }
      }

      setState(() {
        _events.addAll(eventsForMonth); // Merge new events with existing ones
        _fetchedMonths.add(monthKey); // Mark month as fetched
      });
    } catch (e) {
      print("[CalendarScreen] Error fetching events: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  // Get events for a specific day (used by TableCalendar)
  List<Event> _getEventsForDay(DateTime day) {
    // Normalize day to UTC midnight to match the map keys
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    final eventsFound = _events[normalizedDay] ?? [];
    print('[CalendarScreen - _getEventsForDay] For day: $day (Normalized: $normalizedDay), Found events: ${eventsFound.length}');
    return eventsFound;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Calendar",
          style: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _isLoading ? null : _refreshEvents,
            tooltip: 'Refresh Calendar',
          ),
          IconButton(
            // icon: Image.asset('assets/icons/notification_icon.png', width: 24, height: 24), // Use correct asset path
            icon: Image.asset('assets/notif.png', width: 24, height: 24), // Corrected path
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Keep SingleChildScrollView
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                   // Consider Theme.of(context).primaryColor or a specific blue
                  color: const Color(0xFF0D47A1), // Example: Darker blue
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [ // Optional shadow
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar<Event>( // Specify type argument
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2026, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay, // Use the event loader function
                  startingDayOfWeek: StartingDayOfWeek.monday, // Optional: Set start day
                  
                  // Style the calendar
                   calendarStyle: CalendarStyle(
                    // Use WeekendDayBuilder instead of weekendTextStyle
                    outsideDaysVisible: false, // Hide days outside month
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white), // Still needed for non-builder days
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.5), // More subtle highlight
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.lightBlueAccent, // Brighter selection
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration( // Style for event markers
                      color: Colors.white, // Use white for better contrast
                      shape: BoxShape.circle,
                    ),
                     markersMaxCount: 1, // Show only one marker per day max
                     markerSize: 6.0,
                     markersAlignment: Alignment.bottomCenter,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Slightly larger title
                        fontWeight: FontWeight.bold),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),

                  // Handle day selection
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // Update focused day as well
                      });
                       // Check if the selected day's month needs fetching
                       final selectedMonth = DateTime(selectedDay.year, selectedDay.month);
                       if (!_fetchedMonths.contains(selectedMonth)){
                         _fetchEventsForMonth(selectedMonth);
                       }
                    }
                  },

                  // Handle format changes
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },

                  // Handle page (month) changes
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay; // Update the focused day when page changes
                    final newMonth = DateTime(focusedDay.year, focusedDay.month);
                    // Fetch events only if the month actually changed and hasn't been fetched
                     if (newMonth.month != _currentMonth.month || newMonth.year != _currentMonth.year) {
                       _currentMonth = newMonth;
                       _fetchEventsForMonth(_currentMonth);
                     }
                  },
                ),
              ),
            ),
             // Loading indicator below calendar (optional)
            // if (_isLoading) // We might handle loading within the list view
            //    const Padding(
            //      padding: EdgeInsets.all(8.0),
            //      child: Center(child: CircularProgressIndicator()),
            //    ),
            
            // New: Display events for the selected day below the calendar
            _buildSelectedDayEventsList(),
            
          ],
        ),
      ),
    );
  }

  // Widget to build the list of events for the selected day
  Widget _buildSelectedDayEventsList() {
    if (_selectedDay == null) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("Select a day to see events.")),
      );
    }

    final events = _getEventsForDay(_selectedDay!); // Get events for the selected day

    // Check if the month is still loading and we don't have events yet
    final selectedMonthKey = DateTime(_selectedDay!.year, _selectedDay!.month);
    final bool isMonthLoading = _isLoading && !_fetchedMonths.contains(selectedMonthKey);

    if (isMonthLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(child: CircularProgressIndicator()),
        );
    }

    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/calendar.png', width: 60, height: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                "No events scheduled for ${DateFormat('MMMM d').format(_selectedDay!)}.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Build the list view if events exist
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
              "Events on ${DateFormat('MMMM d').format(_selectedDay!)}",
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true, // Important inside SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the ListView itself
              itemCount: events.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                final timeFormatted = "${event.startTime} - ${event.endTime}";

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  leading: SizedBox(
                    width: 70,
                    child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                          Text(
                            event.startTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            event.endTime,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2), // Adjusted spacing
                          Text(
                            event.type,
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                       ],
                    ),
                  ),
                  title: Column( // Use Column for title and description
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(event.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: Colors.grey[700])), // Slightly smaller font for description
                     ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0), // Add padding above assignee
                    child: Text( // Assignee goes in subtitle
                        'Assignee: ${event.assignee}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                  isThreeLine: true, // Allow subtitle to take more space if needed
                  // Optional: Add trailing icons or onTap for details if needed later
                );
              },
            ),
        ],
      ),
    );
  }
}
