import 'package:flutter/material.dart';

class MechanicBookRequest {
  final String userId;
  final String mechanicId;
  final DateTime requestedTime;
  String status; // e.g., "pending", "confirmed", "completed", "cancelled"

  MechanicBookRequest({
    required this.userId,
    required this.mechanicId,
    required this.requestedTime,
    this.status = 'pending',
  });
}

class MechanicBookRequestsPage extends StatefulWidget {
  @override
  _MechanicBookRequestsPageState createState() =>
      _MechanicBookRequestsPageState();
}

class _MechanicBookRequestsPageState extends State<MechanicBookRequestsPage> {
  List<MechanicBookRequest> mechanicBookRequests = [];

  @override
  void initState() {
    super.initState();
    // Adding a few example requests for demonstration
    mechanicBookRequests.add(MechanicBookRequest(
      userId: 'user123',
      mechanicId: 'mech456',
      requestedTime: DateTime.now().add(Duration(hours: 2)),
    ));
    mechanicBookRequests.add(MechanicBookRequest(
      userId: 'user124',
      mechanicId: 'mech457',
      requestedTime: DateTime.now().add(Duration(hours: 4)),
      status: 'confirmed',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mechanic Book Requests'),
      ),
      body: ListView.builder(
        itemCount: mechanicBookRequests.length,
        itemBuilder: (context, index) {
          MechanicBookRequest request = mechanicBookRequests[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Mechanic ID: ${request.mechanicId}'),
              subtitle: Text(
                  'Requested Time: ${request.requestedTime} - Status: ${request.status}'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Here you could navigate to another page to edit the request or update the status
                  print('Edit button tapped for request ${request.mechanicId}');
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // For example purposes, add a new request with current time
          setState(() {
            mechanicBookRequests.add(MechanicBookRequest(
              userId: 'user125',
              mechanicId: 'mech458',
              requestedTime: DateTime.now().add(Duration(hours: 1)),
            ));
          });
        },
        tooltip: 'Add Request',
        child: Icon(Icons.add),
      ),
    );
  }
}
