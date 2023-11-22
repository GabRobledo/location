import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void startSocketConnection() {
    socket =
        IO.io('https://cf86-2001-4454-415-8a00-20cb-be4f-7389-765c.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket?.onConnect((_) {
       socket?.emit('getBookings');
      

      print('Socket connected');
    });
    

    socket?.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void closeConnection() {
    socket?.dispose();
  }
}
