package bluespot.net {
	import bluespot.collections.IRecord;
	import bluespot.collections.RecordKeeper;
	import bluespot.events.ServerEvent;
	import bluespot.managers.ServerManager;
	
	import flash.events.*;
	import flash.net.Socket;
	import flash.net.registerClassAlias;
	
	import mx.collections.IViewCursor;
	registerClassAlias("Server", Server);
	
	public class Server extends RecordKeeper {
		
		//---------------------------------------------------------------------
		//
		//  Connection State Constants
		//
		//---------------------------------------------------------------------
		
		/**
		 * The state used to indicate there's not enough information yet available to connect, or the information
		 * is invalid. 
		 */
		public static const INITIALIZING:String = "Initializing";
		
		/**
		 * The state where the Server is able to connect, but is not. 
		 */
		public static const DISCONNECTED:String = "Disconnected";
		
		/**
		 * The state where the Server is attempting to connect, but has received no positive response
		 * from the destination. 
		 */
		public static const CONNECTING:String = "Connecting";
		
		/**
		 * The state where the Server has received a positive response, and is handshaking with its destination. 
		 */		
		public static const AUTHENTICATING:String = "Authenticating";
		
		/**
		 * The state where the Server is fully connected and operational. 
		 */		
		public static const CONNECTED:String = "Connected";
		
		/**
		 * The state where the Server has sent a request to disconnect, but it has not been acknowledged by the destination. 
		 */
		public static const DISCONNECTING:String = "Disconnecting";
				
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function Server(nickname:String, serverName:String, serverPort:uint) {

			super();
			
			// We explicitly only call createCommunicator, rather than procure, to 
			// avoid adding this user until we're connected.
			this._user = this.createCommunicator(nickname);
			
			this.serverName = serverName;
			this.serverPort = serverPort;
		}
				
		//---------------------------------------------------------------------
		//
		//  Properties
		//
		//---------------------------------------------------------------------
		
		/**
		 * The internal Socket used in this connection. 
		 */
		private var socket:Socket;

		/**
		 * The data that was "left over" in the last pass of our socketDataListener. When data received is successfully built
		 * into a message, it's removed from this string, and any partial messages received are appended to it. 
		 */
		private var unhandledData:String = "";

		//--------------------------------
		//  state
		//--------------------------------

		private var _state:String = Server.INITIALIZING;
		
		[Bindable(event="ConnectionChange")]
		public function get state():String { 
			return this._state; 
		}

		/**
		 * The current state of this Server's connection.
		 */
		[Inspectable(enumeration="{Server.INITIALIZING}, {Server.DISCONNECTED}, {Server.CONNECTING}, {Server.AUTHENTICATING}, {Server.CONNECTED}")]
		public function set state(state:String):void {
			if(this._state === state)
				return;
			var previouslyConnected:Boolean = this.connected;
			var oldState:String = this.state;
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
					ServerManager.getInstance().addServer(this);
					this.connected = true;
					break;
				case Server.DISCONNECTING:
					if(!this.connected && this.state !== Server.CONNECTING)
						throw new Error("Cannot set state to '" + state + "' from '" + this.state + "'");
					ServerManager.getInstance().removeServer(this);
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
			this.dispatchEvent(new ServerEvent(ServerEvent.CONNECTION_CHANGE, null, [oldState, state]));
		}
        
        //--------------------------------
		//  user
		//--------------------------------
 
		private var _user:Communicator;
		public function get user():Communicator {
			return this._user;
		}

		//--------------------------------
		//  connected
		//--------------------------------

		[Bindable("connectionChange")]
		public var connected:Boolean = false;
		
		//--------------------------------
		//  active
		//--------------------------------
		
		[Bindable("connectionChange")]
		public function get active():Boolean {
			return this.connected || this.state === Server.CONNECTING;
		}

		//--------------------------------
		//  serverName
		//--------------------------------

		private var _serverName:String;
		
		[Bindable]
		public function get serverName():String {
			return this._serverName;
		}

		/**
		 * The name of this Server's destination. (e.g., "irc.sorcery.net")
		 * It must be a string, and cannot be set while connected. Doing so will result in an Error being thrown. 
		 */
		public function set serverName(serverName:String):void {
			if(this.connected)
				throw new Error("Cannot change server names without disconnecting first.");
			this._serverName = serverName;
			if(this.serverName && this.serverPort)
				this.state = Server.DISCONNECTED;
		}
		
		//--------------------------------
		//  serverPort
		//--------------------------------
		
		private var _serverPort:uint;
		
		[Bindable]
		public function get serverPort():uint {
			return this._serverPort;
		}

		/**
		 *  Server port. Must be a uint greater than 1024. Cannot be set while connected.
		 */
		public function set serverPort(serverPort:uint):void {
			if(this.connected)
				throw new Error("Cannot change server ports without disconnecting first.");
			this._serverPort = serverPort;
			if(this.serverName && this.serverPort)
				this.state = Server.DISCONNECTED;
		}
	
		//---------------------------------------------------------------------
		//
		//  Connection Methods
		//
		//---------------------------------------------------------------------

		/**
		 * Connect to the specified destination using the given credentials. If
		 * left blank, the current ones will be used. If the Server is already
		 * connected, this method will throw an Error. It will also throw if the
		 * credentials either passed or previously set are invalid.
		 * 
		 * The credentials passed into this method have precedence over the previously
		 * set properties of this Server.
		 *  
		 * @param serverName The server name to use. 
		 * @param serverPort The server port to use.
		 * 
		 * @see serverName
		 * @see serverPost
		 * 
		 */
		final public function connect(serverName:String = null, serverPort:uint = undefined):void {
			if(this.connected)
				throw new Error("Cannot connect while connected!");
			this.serverName = serverName || this.serverName;
			this.serverPort = serverPort || this.serverPort;
			if(this.state !== Server.DISCONNECTED)
				throw new Error("Cannot connect in this state '" + this.state + "'");
			this.state = Server.CONNECTING;
		}

		/**
		 * Disconnect from the connected destination. This method will throw an Error
		 * if it's not currently connected.
		 * 
		 * If we're in a CONNECTING state, then this function will immediately close, otherwise
		 * it will set the state to DISCONNECTING and call closeConnection()
		 * 
		 * If it's already in a state of DISCONNECTING, no action is taken.
		 * 
		 * Any other state will cause an Error to be thrown.
		 * 
		 * @see state  
		 */
		final public function disconnect():void {
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
	
		//---------------------------------------------------------------------
		//
		//  Public interface. Inheritors may implement some or all of this
		//  functionality. If the method is not implemented, an Error will
		//  be thrown once called.
		//
		//---------------------------------------------------------------------

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
		
		//---------------------------------------------------------------------
		//
		//  Protected overrideable interface. Inheritors will likely override
		//  all of these to interpret requests from this Server, and commands
		//  received from the Socket.
		//
		//---------------------------------------------------------------------
		
		/**
		 * Return the type of Communicator given the name. What determines the type
		 * is decided by inheritors.
		 * 
		 * @param name The name to coerce a type from.
		 * @return The type of the communicator.
		 */
		protected function getCommunicatorType(name:String):String {
			if(name === Communicator.SERVER)
				return Communicator.SERVER;				
			return Communicator.USER;
		}
		
		/**
		 * Called once the server has connected, but no authentication has been sent. If these commands
		 * succeed, then the state of the connection is connected.
		 * 
		 * The default implementation assumes the connection is immediately valid, and sets the state to
		 * CONNECTED.
		 * 
		 * @see CONNECTED
		 */
		protected function completeConnection():void {
			// No logic here, so assume we always connect successfully.
			this.state = Server.CONNECTED;
		}
		
		/**
		 * This function is called whenever our socket receives new data. It's passed the new data, with the
		 * unhandled data prepended to it. Any string that is returned from this function will become the new
		 * unhandled data for the next time this is called.
		 * 
		 * Inheritors will always override this if they expect to handle any data from the Socket.
		 * 
		 * @param data The data received, with any unhandledData from previous calls prepended to it.
		 * @return The remaining, unhandled data. 
		 * 
		 */
		protected function handleData(data:String):String {
			data = data.replace(/\n/g, "\\n");
			data = data.replace(/\r/g, "\\r");
			trace('S:"' + data + '"');
			return "";
		}	
		
		/**
		 * Called whenever a request is made to disconnect. If the disconnect is "forced", then
		 * this will not be called.
		 * 
		 * A forced disconnect is whenever we're not yet fully connected, and a disconnect was requested.
		 * Another case would be if we've been disconnected by some third-party.
		 */
		protected function closeConnection():void {
			this.state = Server.DISCONNECTED;
		}
		
		//---------------------------------------------------------------------
		//
		//  Convenience functions from RecordKeeper
		//
		//---------------------------------------------------------------------
	
		/**
		 * Gets the Communicator of the Server. If the Server is aggregating service
		 * requests, then this Communicator could be rather chatty.
		 *  
		 * @return The Communicator who's the "speaker" of all Server chat events.
		 */
		public function procureServerCommunicator():Communicator {
			return this.procureCommunicator(Communicator.SERVER);
		}
			
		private function createCommunicator(name:String):Communicator {
			return new Communicator(this.getCommunicatorType(name), this, name);
		}
		
		public function procureCommunicator(name:String):Communicator {
			return Communicator(this.procure(name));
		}

		//---------------------------------------------------------------------
		//
		//  Socket Event Listeners and Senders
		//
		//---------------------------------------------------------------------
		
		protected function sendMessage(message:String):void {
			this.socket.writeUTFBytes(message);
			trace('C:"' + message.replace(/\s*$/, "") + '"');
			this.socket.flush();
		}
	
		/**
		 * Receives data from the socket once connected. This will use present
		 * values in unhandledData, combined with the received data, to try to
		 * form parseable commands. <code>handleData()</code> is the method
		 * receiving the concatenated data.  
		 * 
		 * @param e The event from the Socket
		 * 
		 * @see handleData
		 */
		private function socketDataListener(e:ProgressEvent):void {
			this.unhandledData = this.handleData(this.unhandledData + this.socket.readUTFBytes(this.socket.bytesAvailable));
		}
			
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

		private function ioErrorListener(e:IOErrorEvent):void {
			this.dispatchEvent(new ServerEvent(ServerEvent.ERROR, null, [e.text]));
		}
		
		private function securityErrorEvent(e:SecurityErrorEvent):void {
			this.dispatchEvent(new ServerEvent(ServerEvent.ERROR, null, [e.text]));
		}
		
		//---------------------------------------------------------------------
		//
		// Overridden methods: RecordKeeper
		//
		//---------------------------------------------------------------------
		
		//--------------------------------
		//  name
		//--------------------------------
		
		override public function get name():String {
			return this.serverName;
		}
		
		override public function set name(name:String):void {
			this.serverName = name;
		}
		
		override public function insert(value:*, silent:Boolean=false):IRecord {
			if(this.state === Server.DISCONNECTED || this.state === Server.INITIALIZING) {
				throw new Error("Cannot add Communicators while disconnected.");
			}
			return super.insert(value, silent);
		}
		
		override protected function defaultCreateBlankRecord(hint:*):IRecord {
			return new Communicator(this.getCommunicatorType(hint), this, null);
		}
		
		override public function defaultGetName(value:*):String {
			var name:String;
			if(!(value is String)) {
				name = value.name;
			} else {
				name = value;
			}
			if(this.getCommunicatorType(name) === Communicator.SERVER)
				return Communicator.SERVER;
			return name;
		}
		
	}
}
