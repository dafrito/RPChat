package bluespot.events {
	import flash.events.Event;
	import bluespot.net.Server;

	public class ConnectionErrorEvent extends Event	{
		private var _text:String;
		private var _server:Server;
		
		public function get text():String {
			return this._text;
		}
		
		public function get server():Server {
			return this._server;
		}
		
		public function ConnectionErrorEvent(server:Server, text:String) {
			super(Server.CONNECTION_ERROR);
			this._server = server;
			this._text = text;
		}
		
	}
}