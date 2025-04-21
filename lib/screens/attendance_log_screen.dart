import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';
import 'notification_page.dart'; // Make sure this exists
import 'change_password_screen.dart';
import 'package:intl/intl.dart';
import '../config/api.dart';
import '../services/attendance_service.dart';

class AttendanceLogScreen extends StatefulWidget {
  const AttendanceLogScreen({super.key});

  @override
  State<AttendanceLogScreen> createState() => _AttendanceLogScreenState();
}

class _AttendanceLogScreenState extends State<AttendanceLogScreen> {
  bool _isLoading = false;
  List<dynamic> _attendanceRecords = [];
  bool _isClockInEnabled = true;
  bool _isClockOutEnabled = false;
  DateTime? _clockInTime;

  @override
  void initState() {
    super.initState();
    // Load attendance with a slight delay to ensure proper widget initialization
    Future.delayed(Duration.zero, () {
      _loadAttendanceData();
    });
  }

  Future<void> _loadAttendanceData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get attendance provider
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);

      // Check if we should use offline mode
      final useOfflineMode = ApiConfig.useOfflineMode;

      if (useOfflineMode) {
        // Use mock data in offline mode
        _loadOfflineAttendanceData();
        return;
      }

      // Try to load attendance data from the server
      await attendanceProvider.loadAttendance(context);

      // Get today's date
      final today = DateTime.now();

      // Update attendance records
      if (!mounted) return;
      setState(() {
        _attendanceRecords = attendanceProvider.attendanceLog;

        // Reset state
        _isClockInEnabled = true;
        _isClockOutEnabled = false;
        _clockInTime = null;

        // Check if user has already clocked in today
        if (_attendanceRecords.isNotEmpty) {
          for (var record in _attendanceRecords) {
            try {
              final recordDate = DateTime.parse(record['date'] ?? '');
              final isSameDay = recordDate.year == today.year &&
                  recordDate.month == today.month &&
                  recordDate.day == today.day;

              if (isSameDay) {
                _isClockInEnabled = false;
                _clockInTime = DateTime.parse(record['timeIn'] ?? '');
                _isClockOutEnabled = record['timeOut'] == null;
                break;
              }
            } catch (e) {
              // Skip records with invalid dates
            }
          }
        }
      });
    } catch (e) {
      print("Error loading attendance data: $e");

      // Check if this is a permission error
      if (e.toString().toLowerCase().contains('permission') ||
          e.toString().toLowerCase().contains('forbidden') ||
          e.toString().contains('403')) {
        print("Permission error detected - using offline mode as fallback");
        _loadOfflineAttendanceData();
      } else if (!mounted) {
        return;
      } else {
        // For all other errors, show the error message
        setState(() {
          _attendanceRecords = [];
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads offline mock data for testing
  void _loadOfflineAttendanceData() {
    setState(() {
      _isLoading = true;
    });

    // Create some mock attendance records
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    _attendanceRecords = [
      {
        '_id': '1',
        'user': '123',
        'date': today.toIso8601String(),
        'timeIn': DateTime(today.year, today.month, today.day, 8, 0)
            .toIso8601String(),
        'timeOut': now.hour >= 17
            ? DateTime(today.year, today.month, today.day, 17, 0)
                .toIso8601String()
            : null,
        'status': 'present',
      },
      {
        '_id': '2',
        'user': '123',
        'date': yesterday.toIso8601String(),
        'timeIn':
            DateTime(yesterday.year, yesterday.month, yesterday.day, 8, 15)
                .toIso8601String(),
        'timeOut':
            DateTime(yesterday.year, yesterday.month, yesterday.day, 17, 30)
                .toIso8601String(),
        'status': 'present',
      },
      {
        '_id': '3',
        'user': '123',
        'date': twoDaysAgo.toIso8601String(),
        'timeIn':
            DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 9, 0)
                .toIso8601String(),
        'timeOut':
            DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day, 16, 45)
                .toIso8601String(),
        'status': 'present',
      },
    ];

    // Check if user has already clocked in today
    final todayRecord = _attendanceRecords.firstWhere((record) {
      try {
        final recordDate = DateTime.parse(record['date'] ?? '');
        return recordDate.year == today.year &&
            recordDate.month == today.month &&
            recordDate.day == today.day;
      } catch (e) {
        return false;
      }
    }, orElse: () => {});

    _isClockInEnabled = todayRecord.isEmpty;
    if (!_isClockInEnabled) {
      _clockInTime = DateTime.parse(todayRecord['timeIn'] ?? '');
      _isClockOutEnabled = todayRecord['timeOut'] == null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _clockIn() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Prepare attendance data
      final attendanceData = {
        'user': authProvider.user!.id,
        'date': now.toIso8601String(),
        'timeIn': now.toIso8601String(),
        'status': 'present',
      };

      // Mark attendance
      await attendanceProvider.markAttendance(context, attendanceData);

      // Update state
      if (!mounted) return;
      setState(() {
        _isClockInEnabled = false;
        _isClockOutEnabled = true;
        _clockInTime = now;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clocked in successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload attendance data
      if (mounted) {
        await _loadAttendanceData();
      }
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clocking in: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clockOut() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);

      // Find today's attendance record ID
      final today = DateTime.now();

      Map<String, dynamic>? todayAttendance;

      if (_attendanceRecords.isNotEmpty) {
        for (var record in _attendanceRecords) {
          try {
            final recordDate = DateTime.parse(record['date'] ?? '');
            final isSameDay = recordDate.year == today.year &&
                recordDate.month == today.month &&
                recordDate.day == today.day;

            if (isSameDay) {
              todayAttendance = Map<String, dynamic>.from(record);
              break;
            }
          } catch (e) {
            // Skip records with invalid dates
          }
        }
      }

      if (todayAttendance == null) {
        throw Exception('No clock-in record found for today');
      }

      // Prepare attendance data for update
      final attendanceData = {
        'id': todayAttendance['_id'],
        'timeOut': now.toIso8601String(),
      };

      // Update attendance record
      await attendanceProvider.updateAttendance(context, attendanceData);

      // Update state
      if (!mounted) return;
      setState(() {
        _isClockOutEnabled = false;
      });

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clocked out successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload attendance data
      if (mounted) {
        await _loadAttendanceData();
      }
    } catch (e) {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clocking out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user data from auth provider
    final user = Provider.of<AuthProvider>(context).user;
    final name = user?.name ?? 'User';
    final schedule = user?.schedule ?? '8:00 AM - 4:00 PM';

    // Format attendance records
    final formattedRecords = _attendanceRecords.map((record) {
      try {
        final date = DateTime.parse(record['date'] ?? '');
        final timeIn = DateTime.parse(record['timeIn'] ?? '');
        final timeOut = record['timeOut'] != null
            ? DateTime.parse(record['timeOut'])
            : null;

        return {
          "date": DateFormat('dd MMM').format(date).toUpperCase(),
          "clockIn": DateFormat('h:mm a').format(timeIn),
          "clockOut":
              timeOut != null ? DateFormat('h:mm a').format(timeOut) : '--:--',
        };
      } catch (e) {
        // Return default values for records with invalid dates
        return {
          "date": "INVALID",
          "clockIn": "INVALID",
          "clockOut": "INVALID",
        };
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar with profile info and home button
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundImage: AssetImage('assets/icon.png'),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $name!',
                      style: const TextStyle(
                          color: Color(0xFF00679D),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Shift Time: $schedule',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Image.asset(
                'assets/home.png',
                width: 30,
                height: 30,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Note: Please make sure you clock in to record your attendance for today.',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isClockInEnabled ? _clockIn : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00679D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text('Clock In'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isClockOutEnabled ? _clockOut : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text('Clock Out'),
                        ),
                      ],
                    ),
                    if (_clockInTime != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Last clock-in: ${DateFormat('MMM d, yyyy hh:mm a').format(_clockInTime!)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    // Attendance History Section
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Attendance History',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          if (formattedRecords.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.history,
                                        size: 50, color: Colors.grey[300]),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'No attendance records yet',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Your attendance history will appear here',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            for (var record in formattedRecords)
                              _buildAttendanceCard(
                                record['date']!,
                                record['clockIn']!,
                                record['clockOut']!,
                              ),
                          const SizedBox(height: 15),
                          Center(
                            child: TextButton.icon(
                              onPressed: _loadAttendanceData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh History'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF00679D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Helper method to build an attendance card.
  Widget _buildAttendanceCard(String date, String clockIn, String clockOut) {
    // Don't show invalid records
    if (date == "INVALID" || clockIn == "INVALID") {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF00679D),
                shape: BoxShape.circle,
              ),
              child: Text(
                date.length >= 2 ? date.substring(0, 2) : "??",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      'In: $clockIn',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      'Out: $clockOut',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
