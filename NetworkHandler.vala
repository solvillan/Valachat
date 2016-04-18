/**
 * Handles the connection to the server
 */
public class NetworkHandler : GLib.Object {

   private static SocketConnection conn;
   public signal void recievedMessage(Message m);

   public NetworkHandler(string addressIn) {
     stderr.printf("Begin connection init!\n");
     var resolver = Resolver.get_default();
     var adresses = resolver.lookup_by_name(addressIn, null);
     var address = adresses.nth_data(0);

     var client = new SocketClient ();
     conn = client.connect (new InetSocketAddress (address, 1342));
     conn.get_socket().set_keepalive(true);
     stderr.printf("Is connected: " + conn.is_connected().to_string() + "\n");
   }

   public void sendMessage(Message m) {
     string s = m.sender + ";" + m.message + "\n";
     conn.output_stream.write(s.data);
   }

   public void* networkListener() {
     var response = new DataInputStream (conn.input_stream);
     while (true) {
       var status_line = response.read_line ().strip ();
       stderr.printf("Incomming string" + status_line + "\n");
       string[] parts = status_line.split(";");
       recievedMessage(new Message(parts[0], parts[1]));
     }
   }

}
