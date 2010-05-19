/*
IRC USER MESSAGES:
	Nick message (CHANGE_NAME)
	Quit (QUIT)
	Away (AWAY)
	User mode message (?)
	Oper message (?)
*/

package bluespot.events {
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import bluespot.net.Communicator;

	public class UserEvent extends Event {
		public static const CHANGE_NAME:String = "ChangeNameUserEvent";
		public static const AWAY:String = "AwayUserEvent";
		public static const QUIT:String = "QuitUserEvent";
		
		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			source[action](UserEvent.CHANGE_NAME, listener);
			source[action](UserEvent.AWAY, listener);
			source[action](UserEvent.QUIT, listener);
		}

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			UserEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			UserEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
		// Message is contextual with UserEvent:
		// If type is AWAY, then message is the away message.
		// If type is QUIT, then message is the quit message.
		// If type is CHANGE_NAME, then the message is the old name.
		public function UserEvent(eventType:String, user:Communicator, message:String = null, timestamp:Date = null) {
			super(eventType);
			this._user = user;
			this._message = message;
			this._timestamp = timestamp;
		}

		private var _message:String;
		public function get message():String {
			return this._message;
		}

		private var _user:Communicator;
		public function get user():Communicator {
			return this._user;
		}
		
		private var _timestamp:Date;
		public function get timestamp():Date {
			return this._timestamp;
		}
	}
}
