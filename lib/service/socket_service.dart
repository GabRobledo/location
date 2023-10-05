import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void startSocketConnection() {
    socket =
        IO.io('https://8cc2-49-145-135-84.ngrok-free.app', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket?.onConnect((_) {
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
