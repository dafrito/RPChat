package bluespot.events {
	import flash.events.Event;
	
	import bluespot.net.Server;
	import bluespot.net.ServerAccount;

	public class ServerSelectorEvent extends Event {
		public static const CONNECT:String = "Connect";
		public static const DISCONNECT:String = "Disconnect";
		public static const JOIN_CHANNELS:String = "JoinChannels";
		
		private var _serverAccount:ServerAccount;
		private var _server:Server;
		
		public function get serverAccount():ServerAccount {
			return this._serverAccount;
		}
		
		public function get server():Server {
			return this._server;
		}
		
		public function ServerSelectorEvent(type:String, serverAccount:ServerAccount, server:Server) {
			super(type);
			this._serverAccount = serverAccount;
			this._server = server;
		}
		
	}
}