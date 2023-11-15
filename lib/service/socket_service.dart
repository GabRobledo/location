import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void startSocketConnection() {
    socket =
        IO.io('https://6b62-2001-4454-415-8a00-1c6a-3f66-7555-ddcc.ngrok-free.app/', <String, dynamic>{
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
