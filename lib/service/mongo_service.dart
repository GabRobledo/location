import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

final connectionUri =
    'mongodb+srv://cravewolf:fBQcL0gSMNpOw0zg@cluster0.manlfyy.mongodb.net/?retryWrites=true&w=majority';

Db? _db;

Future<Db> getDb() async {
  if (_db == null) {
    _db = await Db.create(connectionUri);
    await _db!.open();
  }
  return _db!;
}

Future<Map<String, dynamic>?> registerUser(
  String email,
  String firstName,
  String lastName,
  String phoneNumber,
  String password,
  String role,
  
  List<String> selectedVehicleTypes,
) async {
  final db = await getDb();
  final collection = db.collection('users');


  final existingUser = await collection.findOne({'email': email});

  if (existingUser != null) {
    print(existingUser.toString());
    print("user");

    return {"success": false, "user": null};
  }

  final newUser = {
    '_id': ObjectId().toHexString(),
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
    'password': password,
    'role': role,
    'VehicleType': selectedVehicleTypes,
    'isLogged': false
  };

  await collection.insertOne(newUser);

  return {"success": true, "user": newUser};
}

Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final db = await getDb();
  final collection = db.collection('users');

  final user = await collection.findOne({'email': email, 'password': password});

  if (user != null) {
    print("logged");
    return user;
  } else {
    print("invalid credentials");
  }
  return null;
}

Future<Map<String, dynamic>?> getUserData(String? sessionId) async {
  final db = await getDb();
  final collection = db.collection('users');

  print(sessionId);
  print("sessionid");

  final user = await collection.findOne({'_id': sessionId});

  if (user != null) {
    return user;
  } else {
    print("User not found");
  }

  return null;
}

Future<void> selectedVehiclyTypes(
  String Automotive,
  String Motorcycle,
  String Tricycle,
) async {
  final db = await getDb();
  final collection = db.collection('users');

  final selectedVehicleTypes = {
    'Automotive': Automotive,
    'Motorcycle': Motorcycle,
    'Tricycle': Tricycle,
  };
}

Future<void> updateLocationInDb(
  String userId,
  double latitude,
  double longitude,
  String address,
  String city,
) async {
  final db = await getDb();
  final collection = db.collection('users');

  final location = {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'city': city,
  };

  await collection.updateOne(
    {'_id': userId},
    {
      '\$set': {'location': location}
    },
  );
}

Future<void> updateUserStatusInDb(String userId, bool isLogged) async {
  final db = await getDb();
  final collection = db.collection('users');

  await collection.updateOne(
    {'_id': userId},
    {
      '\$set': {'isLogged': isLogged}
    },
  );
}

Future<List<Map<String, dynamic>>?> getMechanicUsers() async {
  final db = await getDb();
  final collection = db.collection('users');

  final mechanicUsers = await collection
      // .find(where.eq('role', 'Mechanic').eq('isLogged', true))
      // .toList();
      .find(where.eq('role', 'Mechanic'))
      .toList();

  if (mechanicUsers.isNotEmpty) {
    return mechanicUsers;
  } else {
    print("No mechanics found.");
  }

  return null;
}

Future<List<Map<String, dynamic>>?> getDriverUsers() async {
  final db = await getDb();
  final collection = db.collection('users');

  final driverUsers = await collection
      .find(where.eq('role', 'Driver').eq('isLogged', true))
      .toList();

  if (driverUsers.isNotEmpty) {
    return driverUsers;
  } else {
    print("No drivers found.");
  }

  return null;
}

Future<void> sendMessageToDb(String senderId, String receiverId, String content) async {
  final db = await getDb();
  final collection = db.collection('messages');

  final messageDocument = {
    '_id': ObjectId().toHexString(),
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'timestamp': DateTime.now(),
    'read': false,
  };

  await collection.insertOne(messageDocument);
}

Future<List<Map<String, dynamic>>> getChatHistory(String sessionId, String user) async {
 final db = await getDb();
  final collection = db.collection('messages');

  final messagesDocuments = await collection.find({
    '\$or': [
      {
        'senderId': (sessionId),
        'receiverId': (user)
      },
      {
        'senderId': (user),
        'receiverId': (sessionId)
      },
    ]
  }).toList();

  return messagesDocuments;
}


Future<List<Map<String, dynamic>>> getMessagesFromDb(String sessionId, String user) async {
  final db = await getDb();
  final collection = db.collection('messages');

  final messagesDocuments = await collection.find({
    '\$or': [
      {'senderId': sessionId, 'receiverId': user},
      {'senderId': user, 'receiverId': sessionId},
    ]
  }).toList();

  return messagesDocuments;
}

Future<void> markMessageAsReadInDb(Db _db, String messageId) async {
  final db = await getDb();
  final collection = db.collection('messages');
  await collection.updateOne(
    where.id(ObjectId.fromHexString(messageId)),
    modify.set('read', true),
  );
}



Future<void> closeDb() async {
  if (_db != null) {
    await _db!.close();
    _db = null;
  }
}
