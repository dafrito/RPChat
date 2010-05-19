package bluespot.controls {
	import bluespot.events.*;
	import bluespot.net.Communicator;
	import bluespot.net.IRCServer;
	import bluespot.net.Server;
	
	import mx.formatters.Formatter;
	import mx.utils.StringUtil;
    	
	public class EventFormatter extends Formatter {
		
		public function EventFormatter() {
			super();
		}
		
		public var formatStack:Array = [];
		
		/**
		 * Formats an Event, routing all messages as necessary to our implementing functions. 
		 * @param value Value to format.
		 * @return A string used in the given context, as decided by the implementing class.
		 */
		override public function format(value:Object):String {
			var formatted:String;
			this.formatStack.push(value);
			switch(value.constructor) {
				case ChatEvent:
					formatted = this.formatChatEvent(value as ChatEvent);
					break;
				case ChannelEvent:
					formatted = this.formatChannelEvent(value as ChannelEvent);
					break;	
				case UserEvent:
					formatted = this.formatUserEvent(value as UserEvent);
					break;
				case Communicator:
					formatted = this.formatCommunicator(value as Communicator);
					break;
				case ServerEvent:
					formatted = this.formatServerEvent(value as ServerEvent);
					break;
				case Date:
					formatted = this.formatDate(value as Date);
					break;
				case IRCServer:
				case Server:
					formatted = this.formatServer(value as Server);
					break;
				case String:
				case Number:
				case Boolean:
					formatted = this.formatPrimitive(value);
					break;
				default:
					throw new Error("Unsupported value given to format '" + value + "'");
			}
			this.formatStack.pop();
			return formatted;
		}
		
		protected function formatAll(values:Array, inPlace:Boolean = false):Array {
			var formatted:Array = [];
			if(!values)
				return formatted;
			for each(var value:Object in values) {
				if(value !== null)
					formatted.push(this.format(value));
			}
			return formatted;
		}
		
		protected function formatCommunicator(communicator:Communicator):String {
			return this.styleMessage("Communicator." + communicator.type, this.escape(communicator.formattedName), false);
		}

		protected function formatChatEvent(event:ChatEvent):String {
			return this.styleEvent(event);
		}
		
		protected function formatUserEvent(event:UserEvent):String {
			return this.styleEvent(event);
		}
		
		protected function formatChannelEvent(event:ChannelEvent):String {
			return this.styleEvent(event);
		}
		
		protected function formatServerEvent(event:ServerEvent):String {
			return this.styleEvent(event);
		}
		
		protected function formatDate(date:Date):String {
			return this.formatPrimitive(date);
		}
		
		protected function formatPrimitive(primitive:Object):String {
			return this.escape(primitive.toString());
		}
		
		protected function formatServer(server:Server):String {
			return this.styleMessage("Communicator.Server", server.name, false);
		}
		
		/**
		 * Styles an escaped message with the given messageKind, optionally wrapping it.
		 *  
		 * @param messageKind The kind of message. This is used to decide how to style it. It's usually the
		 * ServerEvent's .kind (So "ServerEvent.Info.Ping" is an acceptable kind)
		 * 
		 * @param message The escaped message.
		 * 
		 * @param isStandalone Whether to make this message "wrapped." This is implementation-specific, but gneerally means
		 * whether this message is inline or a whole event.
		 * 
		 * @return The formatted message.
		 */
		protected function styleMessage(messageKind:String, message:String, isStandalone:Boolean = true):String {
			return isStandalone ? message + "\n" : message;
		}
		
		protected function substitute(group:String, kind:String, params:Array = null):String {
			return StringUtil.substitute(
				this.resourceManager.getString(group, kind),
				params ? this.formatAll(params) : null
			);
		}
		
		/**
		 * Performs conventional behavior to style up a ServerEvent.
		 */
		protected function styleEvent(event:ServerEvent):String {
			return this.styleMessage(event.kind, this.substituteEvent(event), true);
		}
		
		protected function substituteEvent(event:ServerEvent):String {
			return this.substitute(event.resourceGroup, event.kind, event.params);
		}
		
		public function escape(string:String):String {
			if(!string)
				return "";
			string = string.replace(/&/g, "&amp;");
			string = string.replace(/</g, "&lt;");
			string = string.replace(/>/g, "&gt;");
			string = string.replace(/'/g, "&apos;"); // '
			string = string.replace(/"/g, '&quot;'); // "
			return string;
		}
		
		public function escapeAll(values:Array, inPlace:Boolean = false):Array {
			var escaped:Array = inPlace ? values : [];
			for(var i:int = 0; i < values.length; i++)
				escaped[i] = this.escape(values[i]);
			return escaped;
		}
		
	}
}