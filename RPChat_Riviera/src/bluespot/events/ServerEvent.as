package bluespot.events {
	import bluespot.net.Server;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	import mx.resources.ResourceManager;

	public class ServerEvent extends Event {
		
		//*********************************************************************
		//
		// Event types and the respective registration method.
		//
		//*********************************************************************
	
		public static const INFO:String = "Info";
		public static const ERROR:String = "Error";
		public static const CONNECTION_CHANGE:String = "ConnectionChange";
		
		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			var types:Array = ["INFO", "ERROR", "CONNECTION_CHANGE"];
			for each(var type:String in types)
				source[action](ServerEvent[type], listener);			
		}

		
		//*********************************************************************
		//
		// Constructor
		//
		//*********************************************************************
		
		public function ServerEvent(type:String = ServerEvent.INFO, messageType:String = null, params:Array = null, category:String = "ServerEvent", timestamp:Date = null) {
			super(type || ServerEvent.INFO);
			this.category = category || "ServerEvent";
			this.messageType = messageType;
			this._timestamp = timestamp || new Date();
			this._params = params;
		}
		
		//*********************************************************************
		//
		// Event Getters
		//
		//*********************************************************************
		
		//*****************************
		//    params
		//*****************************
		
		protected var _params:Array;
		
		public function get params():Array {
			var params:Array = [this.server, this.timestamp];
			if(this._params)
				params = params.concat(this._params);
			return params; 
		}
		
		//*****************************
		//   category
		//*****************************
		
		private var _category:String;
		
		public function get category():String {
			return this._category;
		}
		
		public function set category(category:String):void {
			this._category = category;
		}
		
		//*****************************
		//   messageType
		//*****************************
		
		private var _messageType:String;
		
		public function get messageType():String {
			return this._messageType;
		}
		
		public function set messageType(messageType:String):void {
			this._messageType = messageType;
		}
		
		//*****************************
		//   timestamp
		//*****************************
		
		protected var _timestamp:Date;
		
		public function get timestamp():Date { 
			return this._timestamp; 
		}
		
		//*********************************************************************
		//
		// Convenience Functions.
		//
		//*********************************************************************
		
		public function get server():Server {
			return Server(this.target);
		}
		
		public const resourceGroup:String = "ServerEvent";
		
		public function get debugMessage():String {
			var string:String = ResourceManager.getInstance().getString("ServerEvent", this.kind, this.params);
			if(!string) {
				string = "Unformatted message: (kind: '" + this.kind + "', '" + this.params + "')";
			}
			return string;
		}
		
		public function get kind():String {
			// i.e., ServerEvent.Info
			var kind:String = this.category + "." + this.type;
			if(this.messageType) {
				// i.e., ServerEvent.Info.Ping
				kind += "." + this.messageType;
			}
			return kind;
		}
		
		//*********************************************************************
		//
		// Generic, static functions for adding and removing event listeners for all
		// types of this event.
		//
		//*********************************************************************

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ServerEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ServerEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
	}
}