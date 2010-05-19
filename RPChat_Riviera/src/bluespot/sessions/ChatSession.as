package bluespot.sessions {
	import bluespot.events.ChannelEvent;
	import bluespot.events.ChatEvent;
	import bluespot.events.ServerEvent;
	import bluespot.events.UserEvent;
	import bluespot.net.Communicator;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	
	import mx.binding.utils.BindingUtils;

	public class ChatSession extends Session {
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function ChatSession(domain:Communicator) {
			super(domain.server);
			this._domain = domain;
			BindingUtils.bindProperty(this, "name", this.domain, "name");
		}
		
		//--------------------------------
		//  domain
		//--------------------------------
		
		protected var _domain:Communicator;
		
		public function get domain():Communicator {
			return this._domain;
		}
		
		//---------------------------------------------------------------------
		//
		//  Overridden methods: Session
		//
		//---------------------------------------------------------------------
		
		override protected function doHandle(value:Object):Boolean {
			var event:ServerEvent = value as ServerEvent;
			if(!event)
				return false;
			if(value is ChannelEvent) {
				var channelEvent:ChannelEvent = ChannelEvent(value);
				if(channelEvent.channel === this.domain) {
					this.handleChannelEvent(channelEvent);
					return true;
				}
			} else if(value is ChatEvent) {
				var chatEvent:ChatEvent = ChatEvent(value);
				if(chatEvent.domain === this.domain) {
					this.handleChatEvent(chatEvent);
					return true;
				}
			} else if(value is ServerEvent) {
				this.handleServerEvent(ServerEvent(value));
				return true;
			} else if(value is UserEvent) {
				var userEvent:UserEvent = UserEvent(value);
				if(userEvent.user === this.domain) {
					this.handleUserEvent(userEvent);
					return true;
				}
			}
			return false;
		}
		
		//---------------------------------------------------------------------
		//
		//  Convenience methods for subclasses
		//
		//---------------------------------------------------------------------
		
		protected function handleChannelEvent(event:ChannelEvent):void {
		}
		
		protected function handleChatEvent(event:ChatEvent):void {
		}
		
		protected function handleServerEvent(event:ServerEvent):void {
		}
		
		protected function handleUserEvent(event:UserEvent):void {
		}
	}
}