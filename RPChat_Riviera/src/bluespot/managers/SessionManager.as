package bluespot.managers {
	import bluespot.sessions.ISessionManagerPolicy;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import mx.collections.ICollectionView;
	import mx.collections.ListCollectionView;
	import mx.events.CollectionEvent;
	
	public class SessionManager extends EventDispatcher {
		
		public static const POLICY_UPDATE:String = "PolicyUpdate";
		public static const SESSIONS_UPDATE:String = "SessionsUpdate";
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function SessionManager(serverManager:ServerManager = null, policy:ISessionManagerPolicy = null) {
			super();
			this._serverManager = serverManager || ServerManager.getInstance();
			this._sessions = new ListCollectionView(this.serverManager.sessionList);
			this._sessions.addEventListener(CollectionEvent.COLLECTION_CHANGE, this.sessionsListener);
			this.policy = policy;
		}
		
		//--------------------------------
		//  serverManager
		//--------------------------------
		
		protected var _serverManager:ServerManager;
		
		public function get serverManager():ServerManager {
			return this._serverManager;
		}
		
		//--------------------------------
		//  sessions
		//--------------------------------
		
		protected var _sessions:ICollectionView;
		
		[Bindable("SessionsUpdate")]
		public function get sessions():ICollectionView {
			return this._sessions;
		}
		
		private function sessionsListener(e:Event):void {
			if(this.hasSessions !== (!!this.sessions.length)) {
				this._hasSessions = !!this.sessions.length;
				this.dispatchEvent(new Event(SessionManager.SESSIONS_UPDATE));
			}
		}
		
		//--------------------------------
		//  hasSessions
		//--------------------------------
		
		protected var _hasSessions:Boolean;
		
		public function get hasSessions():Boolean {
			return this._hasSessions;
		}
			
		//--------------------------------
		//  policy
		//--------------------------------
		
		protected var _policy:ISessionManagerPolicy;
		
		public function get policy():ISessionManagerPolicy {
			return this._policy;
		}
		
		public function set policy(policy:ISessionManagerPolicy):void {
			if(this.policy === policy)
				return;
			if(this.policy) {
				this.policy.removeEventListener(SessionManager.POLICY_UPDATE, this.policyListener);
			}
			this._policy = policy;
			if(this.policy) {
				this.sessions.filterFunction = this.policy.checkPolicy;
				this.policy.addEventListener(SessionManager.POLICY_UPDATE, this.policyListener);
			} else {
				this.sessions.filterFunction = null;
			}
			this.sessions.refresh();
		}
		
		//---------------------------------------------------------------------
		//
		//  Policy Event Listeners and Utility
		//
		//---------------------------------------------------------------------
		
		public function refresh():void {
			this.sessions.refresh();
		}
		
		private function policyListener(e:Event):void {
			this.refresh();
		}
	
	}
}