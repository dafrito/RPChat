package bluespot.events {
	import mx.resources.ResourceManager;
	import bluespot.net.Communicator;
	
	public class InfoChatEvent extends ChatEvent {
	
		override public function get message():String {
			return ResourceManager.getInstance().getString("EventMessages", this.kind, this.params);
		}
		
		private var _params:Array;
		public function get params():Array {
			return this._params;
		}
		
		public function get rawMessage():String {
			return super.message;
		}
		
		private var _kind:String;
		public function get kind():String {
			return this._kind;
		}
		
		public function get category():String {
			return this.kind.match(/^[^.]+/)[0];
		}
		
		public function get subCategory():String {
			return this.kind.match(/\.([^.]+)/)[1];
		}
		
		public function InfoChatEvent(speaker:Communicator, recipient:Communicator, kind:String, rawMessage:String="", params:Array=null, domain:Communicator=null, timestamp:Date=null) {
			super(ChatEvent.INFO, speaker, recipient, rawMessage, domain, timestamp);
			this._kind = kind;
			this._params = params;
		}
		
	}
}