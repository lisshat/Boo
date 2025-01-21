import 'package:boo/screens/services/utilities/confirmationmessage.dart';
import 'package:flutter/material.dart';

class AvailabilityCalendar extends StatefulWidget {
  @override
  _AvailabilityCalendarState createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  int selectedDays = 0;
  final int pricePerDay = 33;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CalendarViewer(
          onDaySelected: (days) {
            setState(() {
              selectedDays = days;
            });
          },
        ),
        Text('Selected Days: $selectedDays'),
        Text('Total Price: \$${selectedDays * pricePerDay}'),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MessageSentPage()),
            );
          },
          child: Text('Continue Process'),
        ),
      ],
    );
  }
}
