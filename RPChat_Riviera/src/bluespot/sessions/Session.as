package bluespot.sessions {
	import bluespot.collections.Record;
	import bluespot.net.*;
	
	import flash.events.Event;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;

	public class Session extends Record implements ISession {
		
		//---------------------------------------------------------------------
		//
		//  Session Event Constants
		//
		//---------------------------------------------------------------------
		
		/**
		 * Constant for the CLOSING Session Event. This event is before the 
		 * Session has closed and is cancelable. This event is not necessarily
		 * always called before we CLOSE, if close() is forced.  
		 */
		public static const CLOSING:String = "Closing";
		
		/**
		 * The Session has closed. This event is not cancelable.
		 */
		public static const CLOSED:String = "Closed";
		
		/**
		 * The Session has a new event.
		 */
		public static const HANDLED_VALUE:String = "handledValue";
		
		//---------------------------------------------------------------------
		//
		//  Session Constructor
		//
		//---------------------------------------------------------------------
		
		public function Session(server:Server) {
			super();
			this._server = server;
			this._handledValues = new ArrayCollection();
			mx.binding.utils.BindingUtils.bindProperty(this, "name", this.server, "name");
		}
		
		private var _server:Server;
		
		public function get server():Server {
			return this._server;
		}
		
		//--------------------------------
		//  lastHandled
		//--------------------------------
		
		protected var _lastHandled:Object;
		
		[Bindable("handledValue")]
		public function get lastHandled():Object {
			return this._lastHandled;
		} 
		
		//--------------------------------
		//  handledValues
		//--------------------------------
		
		protected var _handledValues:IList;
		
		public function get handledValues():IList {
			return this._handledValues;
		}
		
		/**
		 * Given some value, this session should respond accordingly. If the Session
		 * successfully handled the value, it should return true. Otherwise, return false.
		 * 
		 * Sessions can listen and respond to values, but still return false if the action taken
		 * wouldn't constitute being "handled".
		 * 
		 * The boolean returned will be used to determine if a new session should be created for the
		 * given event.
		 * 
		 * @param value The value being handled.
		 * @return A Boolean indicating whether this Session completely handled the event. 
		 * 
		 * @see ServerManager
		 */
		final public function handle(value:Object):Boolean {
			var handled:Boolean = this.doHandle(value);
			if(handled) {
				this._lastHandled = value;
				this.handledValues.addItem(value);
				this.dispatchEvent(new Event(Session.HANDLED_VALUE));
			}
			return handled;
		}
		
		protected function doHandle(value:Object):Boolean {
			return false;
		} 
		
		final public function close(confirmFirst:Boolean = false):Boolean {
			if(confirmFirst) {
				if(this.dispatchEvent(new Event(Session.CLOSING, false, true))) {
					return false;
				}	
			}
			this.dispatchEvent(new Event(Session.CLOSED));
			return true;
		}
			
	}
}