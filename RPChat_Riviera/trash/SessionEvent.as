package bluespot.events {
	import bluespot.net.Session;
	
	import flash.events.Event;

	public class SessionEvent extends Event {
		
		
		public function SessionEvent(type:String) {
			super(type, false, type === SessionEvent.CLOSING);
		}
		
		public function get session():Session {
			return Session(this.target);
		}
		
	}
}