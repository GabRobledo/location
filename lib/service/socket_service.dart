import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void startSocketConnection() {
    socket =
        IO.io('https://0dde-2001-4454-415-8a00-410c-ed4c-8569-e71.ngrok-free.app/', <String, dynamic>{
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
