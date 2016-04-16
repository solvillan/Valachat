using Curses;
using Gee;
/**
 *
 */
public class Valachat : GLib.Object {

  public static Window input;
  public static Window messages;
  public static RenderThread renderer;
  private static string username = "Anon";
  public static Thread<void*> keyThread;

  public static ArrayList<Message> messageList;

  public static NetworkHandler nHandler;

  // Command stuff
  private HashMap<string,Command> commands;
  [CCode (has_target = false)]
  delegate void Command(string[] args);

  /**
   *
   */
  public Valachat() {
    commands = new HashMap<string, Command>();
    registerCommands();

    messageList = new ArrayList<Message>();

    endwin();
    initscr();
    start_color();
    init_pair(1, Color.GREEN, Color.RED);
    messages = new Window (LINES - 3, COLS - 2, 1, 1);
    messages.bkgdset (COLOR_PAIR (1) | Attribute.BOLD);  // set background
    //messages.addstr ("Hello world!\n");   // write string
    messages.clrtobot ();               // clear to bottom (does not move cursor)
    messages.scrollok(true);

    input = new Window(1, COLS - 2, LINES - 1, 1);
    input.bkgdset(COLOR_PAIR(1) | Attribute.BOLD);
    input.addstr("Msg:");
    input.clrtobot();               // read a characterw EOFException();
    input.scrollok(true);

    renderer = new RenderThread("mainRenderer");
    //Thread<void*> renderThread = new Thread<void*>.try("renderer", renderer.render);
    var keyListener = new KeyListener();
    keyThread = new Thread<void*>.try("keyListener", keyListener.listenerLoop);
    keyListener.readLine.connect(processMsg);

    Valachat.input.redrawwin();
    Valachat.messages.redrawwin();

    //renderThread.join();
    keyThread.join();
    /* Reset the terminal mode */
    endwin ();

  }

  private void registerCommands() {
    commands.set("nick", (args) => (Valachat.setNick(args)));
    commands.set("connect", (args) => (Valachat.connect(args)));
    commands.set("quit", (args) => (Valachat.exit(args)));
    commands.set("exit", (args) => (Valachat.exit(args)));
  }

  public static void exit(string[] args) {
    keyThread.exit(null);
    endwin();
  }

  public static void setNick(string[] args) {
    username = args[0];
  }

  public static void connect(string[] args) {
    stderr.printf("Trying to connect!\n");
    messageList.add(new Message("Client", "Connecting..."));
    renderer.render();
    nHandler = new NetworkHandler(args[0]);
    stderr.printf("Created nHandler\n");
    Thread<void*> nListener = new Thread<void*>.try("nHandler", nHandler.networkListener);
    nHandler.recievedMessage.connect(handleMessage);
    messageList.add(new Message("Client", "Connected"));
    renderer.render();

  }

  public static void clientEvent(SocketClientEvent event, SocketConnectable connectable, IOStream connection) {
    if (event == SocketClientEvent.RESOLVING) {
      messageList.add(new Message("Client", "Resolving..."));
    } else if (event == SocketClientEvent.RESOLVED) {
      messageList.add(new Message("Client", "Resolved!"));
    } else if (event == SocketClientEvent.CONNECTING) {
      messageList.add(new Message("Client", "Connecting..."));
    } else if (event == SocketClientEvent.CONNECTED) {
      messageList.add(new Message("Client", "Connected!"));
    }
    renderer.render();
  }

  public static void handleMessage(Message m) {
    stderr.printf("Recieved: " + m.sender + " :: " + m.message + "\n");
    messageList.add(m);
    beep();
    Valachat.renderer.render();
  }

  public void processMsg(string line) {
    Valachat.input.clrtobot();
    Valachat.input.addstr("Msg: ");
    if (line.has_prefix("/")) {
      string[] args = new string[line.split(" ").length-1];
      for (int i = 1; i < line.split(" ").length; i++) {
        args[i-1] = line.split(" ")[i];
      }
      if (line.split(" ")[0].replace("/", "") in commands) {
        Command c = commands.get(line.split(" ")[0].replace("/", ""));
        c(args);
      }
    } else {
      Message m = new Message(username, line);
      nHandler.sendMessage(m);
      messageList.add(m);
      renderer.render();
    }
  }

  public static int main(string [] argv) {
    new Valachat();
    return 0;
  }

}
public class RenderThread : GLib.Object {


  private string name;

  public RenderThread(string name) {
    this.name = name;
  }

  public void render() {
    Valachat.messages.erase();
    foreach (Message m in Valachat.messageList) {
      Valachat.messages.addstr(m.sender + ": " + m.message + "\n");
    }
    Valachat.messages.clrtobot();
    Valachat.messages.refresh();
    Valachat.input.refresh();
  }

}

private class KeyListener : GLib.Object {

  public signal void readLine(string line);

  public KeyListener() {

  }

  public void* listenerLoop() {
    while (true) {
      string buffer = "";
      Valachat.input.getstr(buffer);
      if (buffer != "") readLine(buffer);
    }
  }

}
