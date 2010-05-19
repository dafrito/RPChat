package bluespot.sessions {
	import bluespot.collections.IRecord;
	import bluespot.net.Server;
	
	import flash.events.IEventDispatcher;
	
	import mx.collections.IList;
	
	public interface ISession extends IEventDispatcher, IRecord {
		
		function get server():Server;
		function get lastHandled():Object;
		
		function get handledValues():IList;
		
		function handle(value:Object):Boolean;
		function close(confirmFirst:Boolean = false):Boolean;
	}
}