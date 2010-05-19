package bluespot.controls.sessionClasses
{
	import bluespot.sessions.ISession;
	
	import mx.core.IDataRenderer;
	
	public interface ISessionView extends IDataRenderer {
		function get session():ISession;
		function set session(session:ISession):void;
	}
}