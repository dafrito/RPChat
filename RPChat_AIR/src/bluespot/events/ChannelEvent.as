/*
IRC CHANNEL MESSAGES
	Channel mode message (?)
	Topic message (CHANGE_TOPIC)
	Names message (?)
	Join message (JOIN)
	Part message (PART)
	Kick command (KICK)
*/

package bluespot.events {
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import bluespot.net.Communicator;

	public class ChannelEvent extends Event {
		public static const JOIN:String = "JoinChannelEvent";
		public static const PART:String = "PartChannelEvent";
		public static const KICK:String = "KickChannelEvent";
		public static const CHANGE_TOPIC:String = "ChangeTopicChannelEvent";
		private var _channel:Communicator;
		private var _user:Communicator;
		private var _timestamp:Date;
		private var _message:String;

		private static function batchEventListener(source:IEventDispatcher, listener:Function, action:String):void {
			source[action](ChannelEvent.JOIN, listener);
			source[action](ChannelEvent.PART, listener);
			source[action](ChannelEvent.KICK, listener);
			source[action](ChannelEvent.CHANGE_TOPIC, listener);
		}

		public static function addAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChannelEvent.batchEventListener(source, listener, "addEventListener");
		}
		
		public static function removeAllEventListeners(source:IEventDispatcher, listener:Function):void {
			ChannelEvent.batchEventListener(source, listener, "removeEventListener");
		}

		public function ChannelEvent(eventType:String, channel:Communicator, user:Communicator, message:String = null, timestamp:Date = null) {
			super(eventType);
			this._channel = channel;
			this._user = user;
			this._message = message;
			this._timestamp = timestamp || new Date();
		}

		public function get message():String {
			return this._message;
		}

		public function get channel():Communicator {
			return this._channel;
		}

		public function get user():Communicator {
			return this._user;
		}

		public function get timestamp():Date { 
			return this._timestamp; 
		}

	}
}
