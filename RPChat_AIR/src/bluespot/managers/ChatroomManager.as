package bluespot.managers {
	import bluespot.collections.RecordKeeper;
	
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	public class ChatroomManager extends RecordKeeper {
		
		public function ChatroomManager() {
			super();
			this.addEventListener(CollectionEvent.COLLECTION_CHANGE, this.collectionListener);
		}
		
		public function get servers():IList {
			return this.rawSourceList;
		}
		
		public function set servers(servers:IList):void {
			this.rawSourceList = servers;
		}
		
		private function collectionListener(e:CollectionEvent):void {
			switch(e.kind) {
				case CollectionEventKind.ADD:
					for each(var server:Server in e.items) {
						
						ChannelEvent.addAllEventListeners(server, this.serverEventListener);
						ChatEvent.addAllEventListeners(server, this.serverEventListener);
						UserEvent.addAllEventListeners(server, this.serverEventListener);	
					}	
					break;
				case CollectionEventKind.REMOVE:
					for each(var server:Server in e.items) {
						ChannelEvent.removeAllEventListeners(server, this.serverEventListener);
						ChatEvent.removeAllEventListeners(server, this.serverEventListener);
						UserEvent.removeAllEventListeners(server, this.serverEventListener);
					}
					break;
			}
		}
		
	}
}