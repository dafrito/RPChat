package bluespot.net {
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	import bluespot.collections.Record;
	import bluespot.collections.IRecord;
	import bluespot.net.Server;
	
	import flash.net.registerClassAlias;
	registerClassAlias("ServerAccount", ServerAccount);
	
	public class ServerAccount extends Record {
		
		private var _channels:ICollectionView;
		
		[Bindable]
		public function get channels():ICollectionView {
			return this._channels;
		}
		
		public function set channels(channels:ICollectionView):void {
			this._channels = channels;
		}
		
		public function get serverName():String {
			return this.name;
		}
		
		public function set serverName(serverName:String):void {
			this.name = serverName;
		}
		
		private var _nickname:String;
		[Bindable]
		public function get nickname():String {
			return this._nickname;
		}
		
		public function set nickname(nickname:String):void {
			this._nickname = nickname;
		}
		
		private var _serverPort:uint;
		[Bindable]
		public function set serverPort(serverPort:uint):void {
			this._serverPort = serverPort;
		}
		
		public function get serverPort():uint {
			return this._serverPort;
		}
		
		public function ServerAccount(nickname:String = null, serverName:String = null, serverPort:uint = undefined, channels:ICollectionView = null) {
			super(serverName);
			this._nickname = nickname;
			this._serverPort = serverPort;
			this.channels = channels || new ArrayCollection();
			this.channels.sort = new Sort();
			this.channels.sort.fields = [new SortField(null, true)];
			this.channels.refresh();
		}
		
		public var lastConnected:Date;
		
		public function createServer():Server {
			this.lastConnected = new Date();
			return new IRCServer(this.nickname, this.serverName, this.serverPort);
		}
		
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