import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class Transaction {
  final String id;
  final String bookingId;
  final String action;
  final DateTime timestamp;
  final String mechanicId;
  final String firstName;
  final String lastName;

  Transaction({
    required this.id,
    required this.bookingId,
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

    if (map.containsKey('mechanicDetails') && map['mechanicDetails'] != null) {
      var mechanicDetails = map['mechanicDetails'];
      firstName = mechanicDetails['firstName'] ?? 'Unknown';
      lastName = mechanicDetails['lastName'] ?? 'Unknown';
    }

    return Transaction(
      id: map['_id'],
      bookingId: map['bookingId'],
      mechanicId: mechanicId,
      action: map['action'],
      timestamp: DateTime.parse(map['timestamp']),
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
  }

  void _initSocket() {
    socket = IO.io('hhttps://6b62-2001-4454-415-8a00-1c6a-3f66-7555-ddcc.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to Socket.IO server');
      _fetchTransactions();
    });

    socket.on('transactionsData', (data) {
      var transactionList = List<Transaction>.from(data.map((x) => Transaction.fromMap(x)));
      setState(() {
        transactions = transactionList.where((transaction) => transaction.bookingId == widget.bookingId).toList();
        isLoading = false;
      });
    });

    socket.onError((data) {
      print('Error: $data');
    });
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      isLoading = true;
    });
    socket.emit('requestTransactions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        backgroundColor: Colors.blueGrey,
        actions: <Widget>[
          // IconButton(
          //   icon: Icon(Icons.search, color: Colors.white),
          //   onPressed: () {
          //     // Implement search functionality here
          //   },
          // ),
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
