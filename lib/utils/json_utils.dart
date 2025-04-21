// Utility class for working with JSON data from the server
class JsonUtils {
  // Generic method to safely get a value from a JSON map
  static T getValueOrDefault<T>(
      Map<String, dynamic> json, String key, T defaultValue) {
    final value = json[key];
    if (value == null) return defaultValue;

    if (value is T) return value;

    // Try to convert value to the expected type
    if (T == int && value is num) return value.toInt() as T;
    if (T == double && value is num) return value.toDouble() as T;
    if (T == String && value is! String) return value.toString() as T;

    return defaultValue;
  }

  // Method to parse a DateTime from JSON
  static DateTime parseDateTime(Map<String, dynamic> json, String key) {
    final dateStr = json[key];
    if (dateStr == null) return DateTime.now();

    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Method to calculate days between two dates
  static int daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  // Method to format a JSON list for display
  static String formatJsonList(List<dynamic> list) {
    return list.map((item) => item.toString()).join(', ');
  }

  // Seedling-specific utility methods
  static String getSeedlingBatchName(Map<String, dynamic> seedling) {
    return '${seedling['batchCode'] ?? ''} - ${seedling['plantType'] ?? ''}';
  }

  static int getSeedlingDaysSincePlanting(Map<String, dynamic> seedling) {
    if (seedling['plantedDate'] == null) return 0;

    final plantedDate = DateTime.parse(seedling['plantedDate']);
    return DateTime.now().difference(plantedDate).inDays;
  }

  static DateTime getSeedlingExpectedTransplantDate(
      Map<String, dynamic> seedling) {
    if (seedling['plantedDate'] == null)
      return DateTime.now().add(Duration(days: 28));

    final plantedDate = DateTime.parse(seedling['plantedDate']);
    return plantedDate.add(Duration(days: 28));
  }

  // Task-specific utility methods
  static bool isTaskOverdue(Map<String, dynamic> task) {
    if (task['dueDate'] == null) return false;

    final dueDate = DateTime.parse(task['dueDate']);
    return dueDate.isBefore(DateTime.now()) && task['status'] != 'Completed';
  }

  static String getTaskPriorityColor(Map<String, dynamic> task) {
    final priority = task['priority'] ?? 'Medium';

    switch (priority) {
      case 'High':
        return '#FF0000'; // Red
      case 'Medium':
        return '#FFA500'; // Orange
      case 'Low':
        return '#008000'; // Green
      default:
        return '#808080'; // Grey
    }
  }

  // Attendance-specific utility methods
  static bool isAttendancePresent(Map<String, dynamic> attendance) {
    return attendance['status'] == 'Present';
  }

  // Transplant-specific utility methods
  static bool isTransplantSuccessful(Map<String, dynamic> transplant) {
    return transplant['status'] == 'Success';
  }
}
