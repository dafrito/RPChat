package bluespot.net {
	import mx.collections.*;
	
	import bluespot.collections.*;
	import bluespot.net.Server;
	
	import flash.net.registerClassAlias;
	registerClassAlias("ServerAccount", ServerAccount);
	
	public class ServerAccount extends Record {
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		/**
		 * @param nickname The nickname to use when connecting to this Server. 
		 * @param serverName This serverName of this Server.
		 * @param serverPort This serverPort of this Server.
		 * @param channels The list of channels to join on connect for this Server.
		 */
		public function ServerAccount(nickname:String = null, serverName:String = null, serverPort:uint = undefined, channels:ICollectionView = null) {
			super(serverName);
			this._nickname = nickname;
			this._serverPort = serverPort;
			this.channels = channels || new ArrayCollection();
			this.channels.sort = new Sort();
			this.channels.sort.fields = [new SortField(null, true)];
			this.channels.refresh();
		}
		
		/**
		 * Creates a Server using this ServerAccount's credentials. The Server will not be automatically connected.
		 * @return The Server with this name and port.
		 */
		public function createServer():Server {
			this.lastConnected = new Date();
			return new IRCServer(this.nickname, this.serverName, this.serverPort);
		}
		
		//---------------------------------------------------------------------
		//
		//  Public Properties
		//
		//--------------------------------------------------------------------- 
		
		//--------------------------------
		//  channels
		//--------------------------------
		
		private var _channels:ICollectionView;
		
		[Bindable]
		public function get channels():ICollectionView {
			return this._channels;
		}
		
		public function set channels(channels:ICollectionView):void {
			this._channels = channels;
		}
		
		//--------------------------------
		// serverName
		//--------------------------------
		
		/**
		 * This is simply an alias for .name
		 */
		public function get serverName():String {
			return this.name;
		}
		
		/**
		 * This is simply an alias for .name
		 */
		public function set serverName(serverName:String):void {
			this.name = serverName;
		}
		
		//--------------------------------
		//  nickName
		//--------------------------------
		
		private var _nickname:String;
		[Bindable]
		public function get nickname():String {
			return this._nickname;
		}
		
		public function set nickname(nickname:String):void {
			this._nickname = nickname;
		}
		
		//--------------------------------
		// serverPort
		//--------------------------------
		
		private var _serverPort:uint;
		[Bindable]
		public function set serverPort(serverPort:uint):void {
			this._serverPort = serverPort;
		}
		
		public function get serverPort():uint {
			return this._serverPort;
		}
		
		//--------------------------------
		// lastConnected
		//--------------------------------

		[Bindable]
		public var lastConnected:Date;
		
		//---------------------------------------------------------------------
		//
		// Overridden methods: Record
		//
		//---------------------------------------------------------------------
		
		override public function toXML():XML {
			var node:XML = 
				<Server name={this.serverName}>
					<Nickname>{this.nickname}</Nickname>
					<Port>{this.serverPort}</Port>
				</Server>;
			if(this.lastConnected)
				node.@lastConnected = this.lastConnected;
			for each(var channel:String in this.channels)
				node.appendChild(<Channel name={channel}/>);
			return node;
		}
		
		override public function fromXML(node:XML):IRecord {
			this.serverName = node.@name;
			this.serverPort = uint(node.Port.text());
			this.nickname = node.Nickname.text();
			var lastConnected:String = String(node.@lastConnected);
			if(lastConnected)
				this.lastConnected = new Date(lastConnected);
			var channels:Array = [];
			var cursor:IViewCursor = this.channels.createCursor();
			for each(var channel:XML in node.Channel)
				cursor.insert(channel.@name.toString());
			return this;
		}

	}
}