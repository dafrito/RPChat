package bluespot.sessions {
	import flash.events.IEventDispatcher;
	
	public interface ISessionManagerPolicy extends IEventDispatcher {
		function checkPolicy(session:ISession):Boolean;
	}
}