package freetoes.bluespot {
	import bluespot.collections.RecordKeeper;
	
	import mx.collections.ICollectionView;
	
	import bluespot.collections.RecordKeeper;
	import bluespot.collections.IRecord;
	
	public class ChatroomManager extends RecordKeeper {
		
		public function ChatroomManager(createRecordFunc:Function=null, getNameFunc:Function=null, records:ICollectionView=null) {
			super(createRecordFunc, getNameFunc, records);
			this.name = "ChatroomManager";
		}
		
		public function defaultGetName(value:*):String {
			if(value is Communicator)
				return (value as Communicator).getFormattedName();
			if(value is Chatroom)
				return (value as Chatroom).label;
			super.defaultGetName(value);
		}
		
		protected function defaultCreateRecord(value:*):IRecord {
			return new Record(this.getName(value));
		}
		
		protected function createNewRecord():IRecord {
			return new Chatroom();	
		}
	
	}
}