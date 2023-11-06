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
  // String SUV,
  // String Motorcycle,
  // String Tricycle,
  List<String> selectedVehicleTypes,
) async {
  final db = await getDb();
  final collection = db.collection('users');

  // final SelectedVehicleTypes = {
  //   'SUV': SUV,
  //   'Motorcycle': Motorcycle,
  //   'Tricycle': Tricycle,
  // };

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

Future<void> bookMechanic(
  String userId,
  String mechanicId,
  Map<String, dynamic> location,
  String bookingTime,
) async {
  final db = await getDb();
  final bookingCollection = db.collection('bookings');
  final userCollection = db.collection('users');

  // Check if the mechanic is valid and available
  final mechanic = await userCollection.findOne({
    '_id': mechanicId,
    'role': 'Mechanic',
    // Add other conditions to check if the mechanic is available
  });

  if (mechanic == null) {
    // Handle case where mechanic is not found or not available
    print('Mechanic not found or not available');
    return;
  }

  // Create the booking document
  final booking = {
    'userId': userId,
    'mechanicId': mechanicId,
    'userLocation': location,
    'bookingTime': bookingTime,
    // Add other booking details as needed
    'status': 'pending', // Initial booking status
  };

  // Insert the booking into the database
  await bookingCollection.insertOne(booking);
  print('Booking created successfully');
}

Future<void> saveChatMessage(
    String senderId, String content, String chatRoomId) async {
  final db = await getDb();
  final collection = db.collection('messages');

  final newMessage = {
    'senderId': senderId,
    'content': content,
    'timestamp': DateTime.now(),
    'chatRoomId': chatRoomId,
  };

  await collection.insert(newMessage);
}

Future<void> closeDb() async {
  if (_db != null) {
    await _db!.close();
    _db = null;
  }
}
