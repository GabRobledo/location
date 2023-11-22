import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:timezone/standalone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


class Transaction {
  final String id;
  final String bookingId;
  final String userId;  // Add this field
  final String action;
  final DateTime timestamp;
  final String mechanicId;
  final String firstName;
  final String lastName;

  Transaction({
    required this.id,
    required this.bookingId,
    required this.userId,  // Add this parameter
    required this.mechanicId,
    required this.action,
    required this.timestamp,
    required this.firstName,
    required this.lastName,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
  String mechanicId = map['mechanicId'] ?? 'Unknown';
  String firstName = 'Unknown';
  String lastName = 'Unknown';
  // Initialize time zone data
    var location = tz.getLocation('Asia/Manila'); // Get the location for PHT

  if (map.containsKey('mechanicDetails') && map['mechanicDetails'] != null) {
    var mechanicDetails = map['mechanicDetails'];
    firstName = mechanicDetails['firstName'] ?? 'Unknown';
    lastName = mechanicDetails['lastName'] ?? 'Unknown';
  }
  DateTime utcTimestamp = map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now().toUtc();
    DateTime phtTimestamp = tz.TZDateTime.from(utcTimestamp, location); // Convert to PHT

  return Transaction(
    id: map['_id'] ?? 'Unknown',  // Handle potential null
    bookingId: map['bookingId'] ?? 'Unknown',
    userId: map['userId'] ?? 'Unknown',
    mechanicId: mechanicId,
    action: map['action'] ?? 'Unknown',
    timestamp: phtTimestamp,
    firstName: firstName,
    lastName: lastName,
  );
}

}

class TransactionsPage extends StatefulWidget {
  final String bookingId;
  

  TransactionsPage({required this.bookingId});

  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Transaction> transactions = [];
  late IO.Socket socket;
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _initSocket();
    tz.initializeTimeZones();
  }

  void _initSocket() {
    socket = IO.io('https://cf86-2001-4454-415-8a00-20cb-be4f-7389-765c.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to Socket.IO server');
      _fetchTransactions();
    });

    socket.on('transactionsData', (data) {
  print('Received transactions data');
  print ('rawe data: $data');
  
  var transactionList = List<Transaction>.from(
    data.map((x) => Transaction.fromMap(x))
  );

  // Iterate over the transaction list and print userId and widget.bookingId
  for (var transaction in transactionList) {
    print('${transaction.userId}, ${widget.bookingId}${transaction.firstName}${transaction.action}${transaction.firstName}');
  }

  // Update the widget's state
  setState(() {
  // Filter transactions where either 'mechanicId' or 'userId' matches 'widget.bookingId'
  transactions = transactionList.where((transaction) =>
    transaction.mechanicId == widget.bookingId || 
    transaction.userId == widget.bookingId).toList();

  isLoading = false;
});

});





    socket.onError((data) {
      print('Error: $data');
    });
  }

  Future<void> _fetchTransactions() async {
  try {
    setState(() {
      isLoading = true;
    });
    socket.emit('requestTransactions');
  } catch (e) {
    print('Error fetching transactions: $e');
    setState(() {
      isLoading = false;
    });
  }
}
Widget _buildBody() {
  if (isLoading) {
    return Center(child: CircularProgressIndicator());
  } else if (transactions.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text("No transactions available"),
          ElevatedButton(
            onPressed: _fetchTransactions,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  } else {
    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) => TransactionItem(transaction: transactions[index]),
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        backgroundColor: Colors.blueGrey,
        actions: <Widget>[
         
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(child: Text("No transactions available"))
              : RefreshIndicator(
                  onRefresh: _fetchTransactions,
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) => TransactionItem(transaction: transactions[index]),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    String mechanicName = transaction.mechanicId != 'Unknown'
        ? '${transaction.firstName} ${transaction.lastName}'
        : 'Mechanic Unknown';
    IconData actionIcon = _getActionIcon(transaction.action);
    Color actionColor = _getActionColor(transaction.action);

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: actionColor,
          child: Icon(actionIcon, color: Colors.white),
        ),
        title: Text('$mechanicName - ${transaction.action}', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat.yMMMd().add_jm().format(transaction.timestamp)}'),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'complete':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'complete':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}
