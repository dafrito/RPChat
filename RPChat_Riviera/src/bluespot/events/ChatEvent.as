package bluespot.events {
	
	import bluespot.net.Communicator;
	
	import flash.events.IEventDispatcher;

	public class ChatEvent extends ServerEvent {
	
		//*********************************************************************
		//
		// Event types and the respective registration method.
		//
		//*********************************************************************
	
		public static const INVITE:String = "Invite";
		public static const SAY:String = "Say";
		public static const EMOTE:String = "Emote";
				
		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			var types:Array = ["INVITE", "SAY", "EMOTE"];
			for each(var type:String in types)
				source[action](ChatEvent[type], listener);			
		}
		
		//*********************************************************************
		//
		// Constructor
		//
		//*********************************************************************
		
		/**
		 * ChatEvents are messages related to communication between userss.
		 * @param eventType The type of the event.
		 * @param speaker The speaker who logically originated the event.
		 * @param recipient The recipient (For most events, this is the user, unless the user orignated it.)
		 * @param message The message being sent.
		 * @param domain Where the message was created at. In channels, this is the channel. In whispers, this is always the non-user.
		 * @param timestamp When this message was received.
		 */
		public function ChatEvent(eventType:String, speaker:Communicator, recipient:Communicator, message:String = "", domain:Communicator = null, timestamp:Date = null) {
			super(eventType, null, null, "ChatEvent", timestamp);
			this._speaker = speaker;
			this._recipient = recipient;
			this._message = message;
			this._domain = domain || speaker;
		}
		
		private var _speaker:Communicator;
		private var _recipient:Communicator;
		private var _domain:Communicator;
		private var _message:String;

		//*********************************************************************
		//
		// Event Getters
		//
		//*********************************************************************
		
		public function get domain():Communicator {
			return this._domain;
		}

		public function get speaker():Communicator {
			return this._speaker; 
		}

		public function get recipient():Communicator {
			return this._recipient;
		}

		public function get message():String { 
			return this._message; 
		}

		override public function get params():Array { 
			return [this.domain, this.speaker, this.recipient, this.message, this.timestamp];
		}

		//*********************************************************************
		//
		// Static functions for adding and removing event listeners for all
		// types of this event.
		//
		//*********************************************************************

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChatEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChatEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
	}
}