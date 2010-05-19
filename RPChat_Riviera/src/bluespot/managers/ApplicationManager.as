package bluespot.managers {
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	public class ApplicationManager {
		
		[Embed(source="/assets/preferences.xml",mimeType="application/octet-stream")]
		private var PreferencesDataFile : Class;
		
		public function ApplicationManager() {}
		
		private static var _instance:ApplicationManager;
		public static function getInstance():ApplicationManager {
			if(!ApplicationManager._instance)
				ApplicationManager._instance = new ApplicationManager();
			return ApplicationManager._instance;
		}
		
		public function updateApplication():void {
			// Update the application if needed.
		}
						
		public function loadPreferences():void {
			var file:File = File.applicationStorageDirectory;
			file = file.resolvePath("preferences.xml");
			var preferencesXML:XML;
			if(file.exists) {
				// It exists, so open our preferences.
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				preferencesXML = XML(stream.readUTFBytes(stream.bytesAvailable));
				stream.close();
			} else {
				// Nothing exists, so open defaults.
				preferencesXML = XML(new PreferencesDataFile().toString());	
			}
			this.parsePreferences(preferencesXML);
		}
	
		public function savePreferences():void {
			var file:File = File.applicationStorageDirectory;
			file = file.resolvePath("preferences.xml");
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			var preferences:XML = <Preferences/>;
			preferences.appendChild(ServerAccountManager.getInstance().toXML());
			stream.writeUTFBytes(
				'<?xml version="1.0" encoding="utf-8"?>\n' +
				preferences.toXMLString()
			);
			stream.close();
		}
		
		public function parsePreferences(prefs:XML):void {
			var list:XMLList = prefs.Servers;
			ServerAccountManager.getInstance().fromXML(prefs.Servers[0]);
		}
		
	}
}