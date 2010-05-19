package bluespot.controls {
	import mx.controls.TextArea;
	import mx.events.FlexEvent;
	
	public class ChatEntryField extends TextArea {
		public function ChatEntryField() {
			super();
			this.addEventListener(FlexEvent.CREATION_COMPLETE, this.creationCompleteListener);
		}
		
		private function creationCompleteListener(e:FlexEvent):void {
			this.textField.useRichTextClipboard = false;
		}
	}
}