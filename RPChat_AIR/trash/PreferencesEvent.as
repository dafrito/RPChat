package freetoes {
	import flash.events.Event;

	public class PreferencesEvent extends Event	{
		public static const SAVE_STATE:String = "SaveState";
		
		private var _message:String;
		
		public function get message():String {
			return this._message;
		}
		
		public function get successful():Boolean {
			return !this.message.length;
		}
		
		public function PreferencesEvent(type:String, message:String) {
			super(type);
			this._message = message;
		}
	}
}