package bluespot.net {
	
	import bluespot.collections.Record;
	import bluespot.collections.IRecord;
	import flash.net.registerClassAlias;
	
	registerClassAlias("Communicator", Communicator);
			
	public class Communicator extends Record {
		public static const CHANNEL:String = "Channel";
		public static const SERVER:String = "Server";
		public static const USER:String = "User";

		private static const NAME_CHANGE:String = "CommunicatorNameChange";

		private var _server:Server;
		
		public function get server():Server {
			return this._server;
		}

		[Inspectable(enumeration="{Communicator.USER}, {Communicator.CHANNEL}, {Communicator.SERVER}")]
		public var type:String;

		public function getFormattedName():String {
			return Communicator.getFormattedName(this.name);
		}
		
		public static function getFormattedName(name:String):String {
			return name;
		}

		public var status:String;

		public function Communicator(type:String, server:Server, name:String, status:String = null) {
			super(name);
			this.type = type;
			this._server = server;
			this.status = status;
		}
		
		public function isClient():Boolean {
			return this.server.user === this;
		}
		
		public function disconnect():void {
			this._server = null;	
		}
		
		override public function fromXML(node:XML):IRecord {
			this.name = node.@name;
			this.type = node.@type;
			return this;
		}
		
		override public function toXML():XML {
			return <Communicator name={this.name} type={this.type}/>;	
		}
		
	}
}
