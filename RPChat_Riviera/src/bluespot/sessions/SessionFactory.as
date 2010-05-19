package bluespot.sessions
{
	import bluespot.events.*;
	
	public class SessionFactory
	{
		public function SessionFactory() {
		}
		
		public function createSession(hint:Object):ISession {
			var session:ISession;
			if(hint is ChatEvent) {
				// It's a ChatEvent, so make a Session from its domain.
				return new ChatSession((hint as ChatEvent).domain);	
			} else if(hint is ChannelEvent) {
				var channelEvent:ChannelEvent = hint as ChannelEvent;
				if(channelEvent.type === ChannelEvent.JOIN && channelEvent.user.isClient()) {
					// We've joined a channel, so make a session from that.
					return new ChatSession(channelEvent.channel);
				}
			}
			return null;
		}
	}
}