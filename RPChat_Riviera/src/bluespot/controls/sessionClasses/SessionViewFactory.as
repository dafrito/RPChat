package bluespot.controls.sessionClasses
{
	import bluespot.controls.ChatSessionView;
	import bluespot.sessions.ISession;
	
	public class SessionViewFactory {
			
		//--------------------------------
		//  Singleton methods
		//--------------------------------
		
		private static var _instance:SessionViewFactory;
		public static function getInstance():SessionViewFactory {
			if(!_instance)
				_instance = new SessionViewFactory();
			return _instance;
		}
			
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function SessionViewFactory() {
			// Pass
		}

		public function createSessionView(session:ISession):ISessionView {
			// Create sessions.
			var sessionView:ISessionView = new ChatSessionView();
			sessionView.session = session;
			return sessionView;
		}

	}
}