package bluespot.controls {
	import flash.events.*;
	
	import mx.controls.ComboBox;
	import mx.controls.TextInput;
	import mx.events.*;
	import mx.managers.IFocusManager;
	
	public class EditableComboBox extends ComboBox {
		public function EditableComboBox() {
			super();
		}
		
		public function getTextInput():TextInput {
			return this.textInput;
		}

		override protected function focusInHandler(event:FocusEvent):void {
			super.focusInHandler(event);
			var fm:IFocusManager = this.focusManager;
			if(fm)
				fm.defaultButtonEnabled = true;
		}
	
	}
}