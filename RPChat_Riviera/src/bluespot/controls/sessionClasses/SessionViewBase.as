package bluespot.controls.sessionClasses
{
	import bluespot.events.ServerEvent;
	import bluespot.sessions.ISession;
	
	import flash.events.Event;
	
	import mx.binding.utils.ChangeWatcher;
	import mx.containers.Canvas;
	import mx.events.PropertyChangeEvent;
		
	public class SessionViewBase extends Canvas implements ISessionView {
		
		public function SessionViewBase() {
			ChangeWatcher.watch(this, ["session", "lastHandled"], this.changeListener);
		}
		
		//----------------------------
		//  session
		//----------------------------
		
		private var _session:ISession;
		
		[Bindable]
		public function get session():ISession {
			return this._session;
		}
		
		public function set session(session:ISession):void {
			if(this.session) {
				this.cleanUpSession(this.session);
			}
			this._session = session;
			if(this.session) {
				this.showSession(this.session);
			}
		}
		
		//--------------------------------
		//  label
		//--------------------------------
		
		override public function get label():String {
			return this.session.name;
		}
		
		//-----------------------------------------------------------------
		//
		//  Pluggable methods for Inheritors
		//
		//-----------------------------------------------------------------
	
		protected function showSession(session:ISession):void {
			for each(var value:Object in session.handledValues) {
				this.handleListener(value);
			}
		}
		
		protected function cleanUpSession(session:ISession):void {
			// No default functionality.
		}
		
		protected function handleListener(value:Object):void {
			// No default functionality.
		}
		
		//-----------------------------------------------------------------
		//
		//  Overridden methods: IDataRenderer
		//
		//-----------------------------------------------------------------
		
		override public function get data():Object {
			return this.session;
		}
		
		override public function set data(data:Object):void {
			this.session = ISession(data);
		}
		
		//---------------------------------------------------------------------
		//
		//  Utility
		//
		//---------------------------------------------------------------------
		
		private function changeListener(e:Event):void {
			if(e is PropertyChangeEvent) {
				// Our Session changed, so do nothing. This is separately handled
				// in showSession.
			} else {
				// Our lastHandled changed, so handle only that event.
				trace("SessionViewBase.changeListener", ServerEvent(this.session.lastHandled).debugMessage);
				this.handleListener(this.session.lastHandled);
			}
		}
		
	}
}