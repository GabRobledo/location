import 'package:flutter/material.dart';

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: ListView(
        children: [
          FavoriteItem(
            title: 'Favorite Item 1',
            description: 'Description for Favorite Item 1',
          ),
          FavoriteItem(
            title: 'Favorite Item 2',
            description: 'Description for Favorite Item 2',
          ),
          // Add more favorite items here...
        ],
      ),
    );
  }
}

class FavoriteItem extends StatelessWidget {
  final String title;
  final String description;

  FavoriteItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.favorite,
        color: Colors.red,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(description),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FavoritesPage(),
  ));
}
