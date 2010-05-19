package bluespot.events {
	
	import bluespot.net.Communicator;
	
	import flash.events.IEventDispatcher;

	public class UserEvent extends ServerEvent {
	
		//*********************************************************************
		//
		// Event types and the respective registration method.
		//
		//*********************************************************************
	
		public static const CHANGE_NAME:String = "ChangeName";
		public static const AWAY:String = "Away";
		public static const QUIT:String = "Quit";
		
		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			var types:Array = ["CHANGE_NAME", "AWAY", "QUIT"];
			for each(var type:String in types)
				source[action](UserEvent[type], listener);			
		}

		//*********************************************************************
		//
		// Constructor
		//
		//*********************************************************************
		
		/**
		 * 
		 * @param eventType The type of the event.
		 * @param user The user who's the logical target of the event.
		 * @param message The message associated with the event.
		 * Message is contextual with UserEvent:
		 * If type is AWAY, then message is the away message.
		 * If type is QUIT, then message is the quit message.
		 * If type is CHANGE_NAME, then the message is the old name.
		 * @param timestamp The time the event was received.
		 * 
		 */
		public function UserEvent(eventType:String, user:Communicator, message:String = null, timestamp:Date = null) {
			super(eventType, null, null, "UserEvent", timestamp);
			this._user = user;
			this._message = message;
			this._timestamp = timestamp;
		}

		//*********************************************************************
		//
		// Event Getters
		//
		//*********************************************************************
		
		private var _message:String;
		public function get message():String {
			return this._message;
		}

		private var _user:Communicator;
		public function get user():Communicator {
			return this._user;
		}
		
		override public function get params():Array {
			return [this.user, this.message, this.timestamp]; 
		}
		
		//*********************************************************************
		//
		// Static functions for adding and removing event listeners for all
		// types of this event.
		//
		//*********************************************************************
		
		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			UserEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			UserEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
	}
}