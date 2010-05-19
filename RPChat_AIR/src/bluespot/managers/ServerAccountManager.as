package bluespot.managers {
	import bluespot.collections.IRecord;
	import bluespot.collections.RecordKeeper;
	import bluespot.net.ServerAccount;
	
	import flash.net.registerClassAlias;
	
	import mx.collections.ICollectionView;
	registerClassAlias("ServerAccountManager", ServerAccountManager);
	
	public class ServerAccountManager extends RecordKeeper {
		
		public function ServerAccountManager() {
			super();
			this.name = "Servers";
		}
		
		public function get accounts():ICollectionView {
			return this.records;
		}
		
		private static var _instance:ServerAccountManager;
		public static function getInstance():ServerAccountManager {
			if(!_instance)
				_instance = new ServerAccountManager();
			return _instance;
		}
		
		override protected function defaultCreateRecord(value:*):IRecord {
			return ServerAccount(value);
		}
		
		override protected function defaultCreateBlankRecord(hint:*):IRecord {
			return new ServerAccount();
		}
		
	}
}