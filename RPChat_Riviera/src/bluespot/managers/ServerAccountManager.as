package bluespot.managers {
	import bluespot.collections.IRecord;
	import bluespot.collections.RecordKeeper;
	import bluespot.net.ServerAccount;
	
	import mx.collections.ICollectionView;
	
	import flash.net.registerClassAlias;
	registerClassAlias("ServerAccountManager", ServerAccountManager);
	
	public class ServerAccountManager extends RecordKeeper {
		
		//--------------------------------
		//  Singleton methods
		//--------------------------------
		
		private static var _instance:ServerAccountManager;
		public static function getInstance():ServerAccountManager {
			if(!_instance)
				_instance = new ServerAccountManager();
			return _instance;
		}
			
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function ServerAccountManager() {
			super("Servers");
		}
		
		//--------------------------------
		//  accounts
		//--------------------------------
		
		/**
		 * Just an alias for records
		 * 
		 * @see records 
		 */
		public function get accounts():ICollectionView {
			return this.records;
		}
		
		//---------------------------------------------------------------------
		//
		//  Overridden Methods: RecordKeeper
		//
		//---------------------------------------------------------------------
		
		override protected function defaultCreateRecord(value:*):IRecord {
			return ServerAccount(value);
		}
		
		override protected function defaultCreateBlankRecord(hint:*):IRecord {
			return new ServerAccount();
		}
		
	}
}