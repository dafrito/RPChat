package bluespot.net {
	import bluespot.collections.IRecord;
	import bluespot.collections.RecordKeeper;
	import bluespot.events.ConnectionErrorEvent;
	
	import flash.events.*;
	import flash.net.Socket;
	import flash.net.registerClassAlias;
	
	import mx.collections.IViewCursor;
	registerClassAlias("Server", Server);
	
	public class Server extends RecordKeeper implements IEventDispatcher {
		public static const INITIALIZING:String = "Initializing";
		public static const DISCONNECTED:String = "Disconnected";
		public static const CONNECTING:String = "Connecting";
		public static const AUTHENTICATING:String = "Authenticating";
		public static const CONNECTED:String = "Connected";
		public static const DISCONNECTING:String = "Disconnecting";

		public static const CONNECTION_CHANGE:String = "ConnectionChange";
		public static const CONNECTION_ERROR:String = "ConnectionError";

		private var socket:Socket;

		private var unhandledData:String = "";

		private var _state:String = Server.INITIALIZING;
		private var _serverName:String;
		private var _serverPort:uint;
		
		private var dispatcher:IEventDispatcher;
		
				
		//*** Constructor
		
		public function Server(nickname:String, serverName:String, serverPort:uint) {

			this.dispatcher = new EventDispatcher(this);

			super();
			
			this._user = this.createCommunicator(nickname);
			
			this.serverName = serverName;
			this.serverPort = serverPort;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void {
			this.dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void {
			this.dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		override public function dispatchEvent(event:Event):Boolean {
			return this.dispatcher.dispatchEvent(event);
		}
		
		override public function hasEventListener(type:String):Boolean {
			return this.dispatcher.hasEventListener(type);
		}
		
		override public function willTrigger(type:String):Boolean {
			return this.dispatcher.willTrigger(type);
		}

		private var _user:Communicator;
		
		public function get user():Communicator {
			return this._user;
		}

		[Bindable]
		public var connected:Boolean = false;

		// Connection State. 
		[Bindable(event="ConnectionChange")]
		public function get state():String { 
			return this._state; 
		}

		[Inspectable(enumeration="{Server.INITIALIZING, Server.DISCONNECTED}, {Server.CONNECTING}, {Server.AUTHENTICATING}, {Server.CONNECTED}")]
		public function set state(state:String):void {
			if(this._state === state)
				return;
			var previouslyConnected:Boolean = this.connected;
			trace("Attempting to set state from " + this.state + " to " + state);
			switch(state) {
				case Server.INITIALIZING:
					if(this.state !== Server.DISCONNECTED)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					this._state = state;
					this.connected = false;
				case Server.DISCONNECTED:
					if(this.connected || this._state === Server.CONNECTING) {
						this.connected = false;
						this.socket.removeEventListener(Event.CONNECT, this.socketConnectListener);
						this.socket.removeEventListener(Event.CLOSE, this.socketCloseListener);
						this.socket.removeEventListener(ProgressEvent.SOCKET_DATA, this.socketDataListener);
						this.socket.removeEventListener(IOErrorEvent.IO_ERROR, this.ioErrorListener);
						this.socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.securityErrorEvent);
						this.socket = null;
					}
					this._state = state;
					break;
				case Server.CONNECTING:
					if(this.state !== Server.DISCONNECTED)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					this._state = state;
					this.insert(this.user);
					this.socket = new Socket();
					this.socket.addEventListener(Event.CONNECT, this.socketConnectListener);
					this.socket.addEventListener(Event.CLOSE, this.socketCloseListener);
					this.socket.addEventListener(ProgressEvent.SOCKET_DATA, this.socketDataListener);
					this.socket.addEventListener(IOErrorEvent.IO_ERROR, this.ioErrorListener);
					this.socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.securityErrorEvent);
					this.socket.connect(this.serverName, this.serverPort);
					break;
				case Server.AUTHENTICATING:
					if(this.state !== Server.CONNECTING)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					if(!this.socket.connected)
						throw new Error("Socket is not connected!");
					this._state = state;
					this.connected = true;
					this.completeConnection();
					break;
				case Server.CONNECTED:
					if(this.state === Server.INITIALIZING)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					this._state = state;
					this.connected = true;
					break;
				case Server.DISCONNECTING:
					if(!this.connected && this.state !== Server.CONNECTING)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					this._state = state;
					break;
				default:
					throw new Error("Invalid state given to Server '" + state + "'");
			}
			if(this.connected !== previouslyConnected) {
				if(!this.connected) {
					// We're no longer connected, so remove our communicators.
					var cursor:IViewCursor = this.records.createCursor();
					while(cursor.current)
						cursor.remove();
				}
			}
			this.dispatchEvent(new Event(Server.CONNECTION_CHANGE));
		}

		/**
		 *  Server name. Must be a string. Cannot be set while connected.
		 */
		[Bindable]
		public function get serverName():String {
			return this._serverName;
		}

		public function set serverName(serverName:String):void {
			if(this.connected)
				throw new Error("Cannot change server names without disconnecting first.");
			this._serverName = serverName;
			if(this.serverName && this.serverPort)
				this.state = Server.DISCONNECTED;
		}
		
		override public function get name():String {
			return this.serverName;
		}
		
		override public function set name(name:String):void {
			this.serverName = name;
		}
		
		/**
		 *  Server port. Must be a uint greater than 1024. Cannot be set while connected.
		 */
		[Bindable]
		public function get serverPort():uint {
			return this._serverPort;
		}

		public function set serverPort(serverPort:uint):void {
			if(this.connected)
				throw new Error("Cannot change server ports without disconnecting first.");
			this._serverPort = serverPort;
			if(this.serverName && this.serverPort)
				this.state = Server.DISCONNECTED;
		}
		
		private function createCommunicator(name:String):Communicator {
			return new Communicator(this.getCommunicatorType(name), this, name);
		}
		
		public function procureCommunicator(name:String):Communicator {
			return Communicator(this.procure(name));
		}
		
		//*** Overridden stuff from RecordKeeper
		
		override protected function defaultCreateRecord(value:*):IRecord {
			if(value is Communicator)
				return value;
			return this.createCommunicator(this.getName(value));
		}
		
		override protected function defaultCreateBlankRecord(hint:*):IRecord {
			return new Communicator(Communicator.USER, this, null);
		}
		
		//*** Public interface, though features not implemented by respective subclasses will throw if called.
		
		public function joinChannel(channelName:String, password:String = null):void {
			throw new Error("joinChannel is unimplemented.");
		}
		
		public function leaveChannel(channelName:String):void {
			throw new Error("leaveChannel is unimplemented.");			
		}
		
		public function changeName(newName:String):void {
			throw new Error("changeName is unimplemented.");
		}
		
		public function speak(message:String, domain:Communicator):void {
			throw new Error("speak is unimplemented.");
		}
		
		public function emote(message:String, domain:Communicator):void {
			throw new Error("emote is unimplemented.");
		}
		
		// Called once the server has connected, but no authentication has been sent. If these commands
		// succeed, then the state of the connection is connected.
		protected function completeConnection():void {
			// No logic here, so assume we always connect successfully.
			this.state = Server.CONNECTED;
		}
		
		protected function closeConnection():void {
			this.state = Server.DISCONNECTED;
		}

		// This function is called whenever our socket receives new data. It's passed the new data, with the
		// unhandled data prepended to it. Any string that is returned from this function will become the new
		// unhandled data for the next time this is called.
		protected function handleData(data:String):String {
			data = data.replace(/\n/g, "\\n");
			data = data.replace(/\r/g, "\\r");
			trace('S:"' + data + '"');
			return "";
		}
		
		//*** Communicator list functions and utility
		
		// Return the type of Communicator given the name. This is normally overridden.
		protected function getCommunicatorType(name:String):String {
			if(name === Communicator.SERVER)
				return Communicator.SERVER;				
			return Communicator.USER;
		}

		public function procureServerCommunicator():Communicator {
			return this.procureCommunicator(Communicator.SERVER);
		}
		
		override public function insert(value:*, silent:Boolean=false):IRecord {
			if(this.state === Server.DISCONNECTED || this.state === Server.INITIALIZING) {
				throw new Error("Cannot add Communicators while disconnected.");
			}
			return super.insert(value, silent);
		}
		
		//*** Connection Functions

		// Connect to the server.
		public function connect(serverName:String = null, serverPort:uint = undefined):void {
			if(this.connected)
				throw new Error("Cannot connect while connected!");
			this.serverName = serverName || this.serverName;
			this.serverPort = serverPort || this.serverPort;
			if(this.state !== Server.DISCONNECTED)
				throw new Error("Cannot connect in this state '" + this.state + "'");
			this.state = Server.CONNECTING;
		}

		// Called to disconnect us from the server. Intended to be overwritten. 
		public function disconnect():void {
			if(this.state === Server.CONNECTING) {
				// We haven't really "connected" yet, so force an immediate close.
				this.state = Server.DISCONNECTING;
				this.state = Server.DISCONNECTED;
			} else if(this.connected) {
				if(this.state !== Server.DISCONNECTING) {
					// We're connected.
					this.state = Server.DISCONNECTING;
					this.closeConnection();
				}
			} else {
				throw new Error("Cannot disconnect while not connected!");
			}
			
		}

		//*** Connection utility and response functions

		protected function sendMessage(message:String):void {
			this.socket.writeUTFBytes(message);
			trace('C:"' + message.replace(/\s*$/, "") + '"');
			this.socket.flush();
		}

		//*** Socket Event Listeners

		private function socketConnectListener(e:Event):void {
			if(this.state === Server.CONNECTING) {
				this.state = Server.AUTHENTICATING;
			} else {
				this.socket.close();
			}
		}
		
		private function socketCloseListener(e:Event):void {
			if(this.state !== Server.DISCONNECTED) {
				this.state = Server.DISCONNECTING;
				this.state = Server.DISCONNECTED;
			}
		}

		private function socketDataListener(e:ProgressEvent):void {
			this.unhandledData = this.handleData(this.unhandledData + this.socket.readUTFBytes(this.socket.bytesAvailable));
		}

		private function ioErrorListener(e:IOErrorEvent):void {
			this.dispatchEvent(new ConnectionErrorEvent(this, e.text));
		}
		
		private function securityErrorEvent(e:SecurityErrorEvent):void {
			this.dispatchEvent(new ConnectionErrorEvent(this, e.text));
		}

	}
}
