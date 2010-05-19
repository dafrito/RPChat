package bluespot.events {
	
	import bluespot.net.Communicator;
	
	import flash.events.IEventDispatcher;

	public class ChannelEvent extends ServerEvent {
	
		//*********************************************************************
		//
		// Event types and the respective registration method.
		//
		//*********************************************************************
	
		public static const JOIN:String = "Join";
		public static const PART:String = "Part";
		public static const KICK:String = "Kick";
		public static const CHANGE_TOPIC:String = "ChangeTopic";
				
		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			var types:Array = ["JOIN", "PART", "KICK", "CHANGE_TOPIC"];
			for each(var type:String in types)
				source[action](ChannelEvent[type], listener);			
		}
		
		//*********************************************************************
		//
		// Constructor
		//
		//*********************************************************************
		
		/**
		 * A ChannelEvent is an event whose focus is channel-wide, such as someone entering/leaving the room, or someone being kicked.
		 * A topic-change is also a valid event for IRC servers. 
		 * @param eventType The type of the event.
		 * @param channel The channel who was the logical target of this event.
		 * @param user The user who was associated with the event. This is contextual, but generally self-explanatory.
		 * @param message The message. This is contextual based on the type of the event:
		 *   For "Join" events, the message is null.
		 *   For "Part" events, the message is generally null (but technically could be the 'reason' for leaving. This is not the same as a kick.)
		 *   For "Kick" events, the message is the reason for the user being kicked.
		 *   For "ChangeTopic" events, the message is the new topic.
		 * @param timestamp The time at which the event was received.
		 */
		public function ChannelEvent(eventType:String, channel:Communicator, user:Communicator, message:String = null, timestamp:Date = null) {
			super(eventType, null, null, "ChannelEvent", timestamp);
			this._channel = channel;
			this._user = user;
			this._message = message;
		}
		
		private var _channel:Communicator;
		private var _user:Communicator;
		private var _message:String;
		
		//*********************************************************************
		//
		// Event Getters
		//
		//*********************************************************************
		
		public function get channel():Communicator {
			return this._channel;
		}

		public function get user():Communicator {
			return this._user;
		}
		
		public function get message():String {
			return this._message;
		}
		
		override public function get params():Array {
			return[this.channel, this.user, this.message, this.timestamp];
		}

		//*********************************************************************
		//
		// Static functions for adding and removing event listeners for all
		// types of this event.
		//
		//*********************************************************************

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChannelEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChannelEvent.batchEventListener(source, listener, "removeEventListener");
		}
		
	}
}
