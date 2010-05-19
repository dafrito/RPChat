package bluespot.events
{
	import flash.events.Event;

	public class ServerEvent extends Event
	{
		public function ServerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}