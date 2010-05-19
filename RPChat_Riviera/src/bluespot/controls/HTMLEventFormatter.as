package bluespot.controls {

	public class HTMLEventFormatter extends EventFormatter {
		public function HTMLEventFormatter() {
			super();
		}
		
		override protected function styleMessage(messageKind:String, message:String, isStandalone:Boolean=true):String {
			var elementType:String = isStandalone ? "P" : "SPAN";
			return "<" + elementType + " class='" + messageKind.split(".").reverse().join(" ") + "'>" + message + "</" + elementType + ">";	
		}
		
	}
}