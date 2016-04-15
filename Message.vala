/**
 *
 */
public class Message : GLib.Object {

  private string _sender = "";
  private string  _message = "";

  public string sender {
    get {return _sender;}
  }
  public string message {
    get { return _message; }
  }

  /**
   *
   */
  public Message(string sender, string message) {
    this._sender = sender;
    this._message = message;
  }

}
