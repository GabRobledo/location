import 'package:flutter/material.dart';

class TransactionHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaction History'),
      ),
      body: ListView(
        children: [
          TransactionItem(
            date: '2023-10-01',
            amount: '100',
            type: 'payment',
          ),
          TransactionItem(
            date: '2023-10-02',
            amount: '50',
            type: 'withdrawal',
          ),
          // Add more transaction items here...
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String date;
  final String amount;
  final String type;

  TransactionItem({
    required this.date,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        type == 'payment' || type == 'withdrawal'
            ? Icons.payment
            : Icons.attach_money,
        color: type == 'payment' || type == 'withdrawal'
            ? Colors.red
            : Colors.green,
      ),
      title: Text(
        '$type',
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(date),
      trailing: Text(
        type == 'payment' || type == 'withdrawal'
            ? '-\$ $amount'
            : '+\$ $amount',
        style: TextStyle(
          color: type == 'payment' || type == 'withdrawal'
              ? Colors.red
              : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TransactionHistoryPage(),
  ));
}
