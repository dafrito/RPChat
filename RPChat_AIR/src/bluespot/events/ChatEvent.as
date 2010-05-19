/*
IRC COMMUNICATION MESSAGES: ChatEventListener
	Private messages (SAY, EMOTE)
	Notice (SAY)
	Invite message (INVITE)
	Ping message (PING)
	Pong message (PONG)
	Squery (?)
*/

package bluespot.events {
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import bluespot.net.Communicator;

	public class ChatEvent extends Event {
		public static const INVITE:String = "InviteChatEvent";
		public static const SAY:String = "SayChatEvent";
		public static const EMOTE:String = "EmoteChatEvent";
		public static const INFO:String = "InfoChatEvent";

		private var _speaker:Communicator;
		private var _recipient:Communicator;
		private var _domain:Communicator;
		private var _message:String;
		private var _timestamp:Date;

		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			source[action](ChatEvent.INVITE, listener);
			source[action](ChatEvent.SAY, listener);
			source[action](ChatEvent.EMOTE, listener);
			source[action](ChatEvent.INFO, listener);
		}

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChatEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChatEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
		public function ChatEvent(eventType:String, speaker:Communicator, recipient:Communicator, message:String = "", domain:Communicator = null, timestamp:Date = null) {
			super(eventType);
			this._speaker = speaker;
			this._recipient = recipient;
			this._message = message;
			this._timestamp = timestamp || new Date();
			this._domain = domain || speaker;
		}

		public function get domain():Communicator {
			return this._domain;
		}

		public function get speaker():Communicator {
			return this._speaker; 
		}

		public function get recipient():Communicator {
			return this._recipient;
		}

		public function get timestamp():Date { 
			return this._timestamp; 
		}

		public function get message():String { 
			return this._message; 
		}
		
	}
}
