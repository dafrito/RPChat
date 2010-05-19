package bluespot.managers
{
	import bluespot.events.*;
	import bluespot.net.*;
	import bluespot.sessions.*;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;

	public class ServerManager {
			
		//--------------------------------
		//  Singleton methods
		//--------------------------------
		
		private static var _instance:ServerManager;
		public static function getInstance():ServerManager {
			if(!_instance)
				_instance = new ServerManager();
			return _instance;
		}
			
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function ServerManager() {
			super();
			this.serverSessions = new Dictionary();
			this.globalSessions = new ArrayCollection();
			this._sessionList = new ArrayCollection();
			this.sessionFactory = new SessionFactory();
		}
		
		/**
		 * The Dictionary of Servers registered with this ServerManager. Each
		 * Server has an array of Sessions associated with it. 
		 */
		protected var serverSessions:Dictionary;
		protected var globalSessions:IList;
	
		//--------------------------------
		//  sessionList
		//--------------------------------
		
		protected var _sessionList:IList;
		
		public function get sessionList():IList {
			return this._sessionList;
		}
	
		//--------------------------------
		//  sessionFactory
		//--------------------------------
	
		protected var _sessionFactory:SessionFactory;
		
		public function get sessionFactory():SessionFactory {
			return this._sessionFactory;
		}
		
		public function set sessionFactory(sessionFactory:SessionFactory):void {
			if(!sessionFactory)
				throw new Error("ServerManager's sessionFactory cannot be falsy");
			this._sessionFactory = sessionFactory;
		}
	
		//---------------------------------------------------------------------
		//
		//  Public Server List Interface
		//
		//---------------------------------------------------------------------
		
		/**
		 * Adds the server to our watched list, attaching listeners and creating
		 * an empty list of sessions for it.
		 * 
		 * If that Server is already registered, an Error is thrown.
		 */
		public function addServer(server:Server):void {
			if(this.serverSessions[server])
				throw new Error("This Server is already on this list!");
			this.serverSessions[server] = new ArrayCollection();
			// Add our listeners to the Server.
			ChannelEvent.addAllEventListeners(server, this.serverEventListener);
			ChatEvent.addAllEventListeners(server, this.serverEventListener);
			UserEvent.addAllEventListeners(server, this.serverEventListener);
			ServerEvent.addAllEventListeners(server, this.serverEventListener);
		}
		
		/**
		 * Removes the given Server from our list, removing all listeners, and
		 * forcefully closing any open Sessions. Finally, the sessions list for
		 * that Server are deleted. 
		 * 
		 * If that Server is not on our list, then no action is taken.
		 */
		public function removeServer(server:Server):void {
			var serverSessions:IList = this.serverSessions[server];
			if(!serverSessions)
				return;
			this.detachServer(server, serverSessions);
			delete this.serverSessions[server];
		}
		
		/**
		 * Remove all of our Servers, forcefully closing all Sessions.
		 */
		public function removeAll():void {
			for(var key:Object in this.serverSessions) {
				var server:Server = Server(key);
				server.disconnect();
			}
			var globalSessions:Array = this.globalSessions.toArray();
			for each(var session:ISession in globalSessions) {
				session.close();
			}
		}
		
		/**
		 * Internal function to actually detach our listeners from this Manager. This
		 * function doesn't actually remove the Server from the list, nor does it
		 * directly remove the Sessions from the sessions list it's associated with.
		 */
		protected function detachServer(server:Server, serverSessionList:IList):void {
			var serverSessions:Array = serverSessionList.toArray();
			for each(var session:ISession in serverSessions) {
				// Force a close on each of our Sessions.
				session.close();
			}
			// Remove all listeners from the given server.
			ChannelEvent.removeAllEventListeners(server, this.serverEventListener);
			ChatEvent.removeAllEventListeners(server, this.serverEventListener);
			UserEvent.removeAllEventListeners(server, this.serverEventListener);
			ServerEvent.removeAllEventListeners(server, this.serverEventListener);
		}
		
		/**
		 * 
		 * Receives an event, and routes it through our current Sessions, calling
		 * handle(event) on each. If no Session successfully handles the event,
		 * a new Session is attempted to be created. If no Session is created from
		 * the event, the event is lost.
		 * 
		 * @param event The ServerEvent dispatched from one of our watched Servers.
		 */
		private function serverEventListener(event:ServerEvent):void {
			var session:ISession;
			var serverSessions:IList = this.serverSessions[event.server];
			var successfullyHandled:Boolean = false;
			for(var i:int = 0; i < this.globalSessions.length; i++) {
				session = ISession(this.globalSessions.getItemAt(i));
				successfullyHandled = session.handle(event) || successfullyHandled;
			}
			for each(session in serverSessions) {
				successfullyHandled = session.handle(event) || successfullyHandled;
			}
			if(!successfullyHandled) {
				// It wasn't handled, so attempt to make a new session from it.
				session = this.sessionFactory.createSession(event);
				if(session) {
					this.addSession(session);
					session.handle(event);
				}
			}
		}
		
		//---------------------------------------------------------------------
		//
		//  Internal Session List Manipulation Functions
		//
		//---------------------------------------------------------------------
		
		protected function addSession(session:ISession, isGlobal:Boolean = false):void {
			if(!session)
				return;
			this.sessionList.addItem(session);
			if(isGlobal) {
				this.globalSessions.addItem(session);
			} else {
				var sessionList:IList = this.serverSessions[session.server];
				sessionList.addItem(session);
			}
			session.addEventListener(Session.CLOSED, isGlobal ?
				this.closeListenerGlobal :
				this.closeListener
			);
		}
		
		protected function removeSession(session:ISession, isGlobal:Boolean = false):void {
			// Remove the session from our global list.
			this.sessionList.removeItemAt(
				this.sessionList.getItemIndex(session)
			);
			var serverSessions:IList = isGlobal ? this.globalSessions : this.serverSessions[session.server];
			serverSessions.removeItemAt(serverSessions.getItemIndex(session));
			session.removeEventListener(Session.CLOSED, isGlobal ?
				this.closeListenerGlobal :
				this.closeListener
			);
		}
		
		//---------------------------------------------------------------------
		//
		//  Global Session Manipulation Methods
		//
		//---------------------------------------------------------------------
		
		public function addGlobalSession(session:ISession):void {
			this.addSession(session, true);
		}
		
		public function removeGlobalSession(session:ISession):void {
			this.removeSession(session, true);
		}
		
		//---------------------------------------------------------------------
		//
		//  Session Event Listeners
		//
		//---------------------------------------------------------------------
		
		private function closeListener(e:Event):void {
			this.removeSession(ISession(e.target), false); 
		}
		
		private function closeListenerGlobal(e:Event):void {
			this.removeSession(ISession(e.target), true);
		}			
	}
}