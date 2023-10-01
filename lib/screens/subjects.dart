import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'environmental_education_screen.dart';

class MySubject {
  final String name;
  final Color color; // Add color property to Subject

  MySubject(this.name, this.color);
}

class Subjects extends StatefulWidget {
  const Subjects({super.key});

  @override
  State<Subjects> createState() => _SubjectsState();
}

class _SubjectsState extends State<Subjects> {
  List<MySubject> subjects = [];
  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  Future<void> fetchSubjects() async {
    try {
      debugPrint("Fetching subjects...");
      final http.Response response = await http.get(
        Uri.parse(
          'https://www.eschool2go.org/api/v1/project/ba7ea038-2e2d-4472-a7c2-5e4dad7744e3',
        ),
      );
      debugPrint("Response status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        var colorIndex = 0;
        subjects = data.keys.map((key) {
          final subjectData = data[key];
          final name = subjectData['name'];
          final color = _getUniqueColor(colorIndex); // Assign a unique color.
          colorIndex++;
          return MySubject(name, color);
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
    } finally {
      setState(() {});
    }
  }

  Color _getUniqueColor(int index) {
    // This function returns a unique color based on the index.
    final List<Color> subjectColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.deepPurple,
      Colors.deepOrange,
      Colors.lightGreen,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.blueGrey,
      Colors.lime,
    ];

    return subjectColors[index % subjectColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color.fromARGB(255, 29, 55, 142),
        title: const Center(child: Text('Class 12 Books')),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: subjects.isEmpty
              ? const CircularProgressIndicator()
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (BuildContext context, int index) {
                    final subject = subjects[index];
                    return SubjectCard(
                      subject: subject,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class SubjectCard extends StatefulWidget {
  final MySubject subject;

  const SubjectCard({super.key, required this.subject});

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width / 2 -
        20; // Two cards in a row with some padding.
    double circleSize =
        cardWidth * 0.23; // Adjust the circle size based on card width.

    return GestureDetector(
      onTap: () {
        debugPrint("Tapped subject: ${widget.subject.name}");
        if (widget.subject.name == "Environmental Education") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnvironmentalEducationScreen(),
            ),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.5),
            width: 2.0,
          ),
        ),
        elevation: isTapped ? 8.0 : 4.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.subject.color
                      .withOpacity(0.20), // Use the assigned color.
                ),
                child: Center(
                  child: Text(
                    widget.subject.name[0],
                    style: TextStyle(
                      fontSize: circleSize * 0.3,
                      fontWeight: FontWeight.bold,
                      color: widget.subject.color
                          .withOpacity(1), // Use white color for text.
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.subject.name,
                style: TextStyle(
                  fontSize:
                      cardWidth * 0.08, // Adjust text size based on card width.
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis, // Handle text overflow.
                maxLines: 2, // Limit the number of lines to prevent overflow.
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
