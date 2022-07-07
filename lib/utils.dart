
class Utils {
  static const int _timeFormatIncludeHourTwoZero = 1;
  static const int _timeFormatIncludeMinuteTwoZero = 2;
  static const int _timeFormatIncludeSecondTwoZero = 3;

  String formatTimeToString(int time) {
    var timeFormat = chooseTimeFormat(time);

    var hours = time ~/ 3600000;
    var remainingTime = (time - hours * 3600000).toInt();
    var minutes = remainingTime ~/ 60000;
    remainingTime = (remainingTime - minutes * 6e4).toInt();
    var seconds = remainingTime ~/ 1000;

    switch (timeFormat) {
      case _timeFormatIncludeHourTwoZero:
        return "$hours:$minutes:$seconds";
      case _timeFormatIncludeMinuteTwoZero:
        return "$minutes:$seconds";
      case _timeFormatIncludeSecondTwoZero:
        return "0:$seconds";
    }

    return "$hours:$minutes:$seconds";
  }

  int chooseTimeFormat(int duration) {
    var hours = duration ~/ 3600000;
    var remainingTime = (duration - hours * 3600000).toInt();
    var minutes = remainingTime ~/ 60000;
    if (hours > 0) {
      return _timeFormatIncludeHourTwoZero;
    } else {
      if (minutes > 0) {
        return _timeFormatIncludeMinuteTwoZero;
      } else {
        return _timeFormatIncludeSecondTwoZero;
      }
    }
  }

  String getTimeString(Duration time) {
    final minutes =
    time.inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = time.inSeconds
        .remainder(Duration.secondsPerMinute)
        .toString()
        .padLeft(2, '0');
    return time.inHours > 0
        ? "${time.inHours}:${minutes.padLeft(2, "0")}:$seconds"
        : "$minutes:$seconds";
  }
}