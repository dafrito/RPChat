package freetoes {
	import flash.events.*;
	import flash.net.*;
	
	public class Preferences extends EventDispatcher {
		private var sharedObject:SharedObject;
		
		public function Preferences(name:String = null) {
			super();
			this.sharedObject = SharedObject.getLocal(name);
			this.sharedObject.addEventListener(NetStatusEvent.NET_STATUS, this.netStatusListener);
			if(Preferences._instance)
				throw new Error("Cannot overwrite another singleton instance of Preferences");
			Preferences._instance = this;
		}
		
		private static var _instance:Preferences;
		public static function getInstance():Preferences {
			if(!_instance)
				_instance = new Preferences();
			return _instance;
		}
		
		public function get data():Object {
			return this.sharedObject.data;
		}
		
		public function getProp(name:String):* {
			return this.sharedObject.data[name];
		}
		
		public function setProp(name:String, value:*, flush:Boolean = true):void {
			this.sharedObject.data[name] = value;
			if(flush)
				this.flush();
		}
		
		private function dispatchSaveState(saveStateMessage:String = ""):void {
			this.dispatchEvent(new PreferencesEvent(PreferencesEvent.SAVE_STATE, saveStateMessage));
		}
		
		public function flush():void {
			try {
				if(this.sharedObject.flush() === SharedObjectFlushStatus.FLUSHED) {
					this.dispatchSaveState();
				}
			} catch(e:Error) {
				this.dispatchSaveState("SharedObjects on the client is not enabled.");
			}
		}
		
		private function netStatusListener(e:NetStatusEvent):void {
			var result:String;
			switch(e.info.code) {
				case "SharedObject.Flush.Success":
					result = "";
					break;
				case "SharedObject.Flush.Failed":
					// Fall through.
				default:
					result = "SharedObjects could not allocate enough space to save.";
					break;
			}
			this.dispatchSaveState(result);
		}

	}
}