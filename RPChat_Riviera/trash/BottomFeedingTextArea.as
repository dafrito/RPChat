package bluespot.controls {
	import flash.text.StyleSheet;
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.TextArea;
	import mx.core.EdgeMetrics;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDirection;
	import mx.events.ScrollEventDetail;	
	import mx.events.ResizeEvent;
	import mx.utils.StringUtil;
	import mx.containers.TabNavigator;

	public class BottomFeedingTextArea extends TextArea {
		
		public function BottomFeedingTextArea() {
			super();
			mx.binding.utils.BindingUtils.bindSetter(this.textListener, this, "text", true);
			this.addEventListener(ScrollEvent.SCROLL, this.scrollListener);
			//this.addEventListener(ResizeEvent.RESIZE, this.resizeListener);
		}
		
		public var stickToBottom:Boolean = true; 
		
		private function scrollListener(e:ScrollEvent):void {
			if(e.direction === ScrollEventDirection.VERTICAL && e.detail === ScrollEventDetail.THUMB_POSITION)
				this.stickToBottom = e.position >= this.maxVerticalScrollPosition;
		}
		
		private function textListener(text:String):void {
			this.scrollToBottom();
		}
		
		private function resizeListener(e:ResizeEvent):void {
			this.scrollToBottom();
		}
		
		private function scrollToBottom():void {
			if(!this.stickToBottom || !this.verticalScrollBar)
				return;
			// We add 1 here because maxVerticalScrollPosition subtracts one when it fetches its internal value.
			// I believe this is a mistake, believing that the scrollPosition boundaries are exclusive (That is,
			// scrollPosition is at max, max - 1, like an array, when in fact it's inclusive.
			// At any rate, using the default gives us a noticeable gap when we want to be flush with the bottom,
			// so we add one and it went away.
			this.verticalScrollPosition = this.maxVerticalScrollPosition + 1;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var vm:EdgeMetrics = this.viewMetrics.clone();
			vm.top += this.getStyle("paddingTop");
			vm.bottom += this.getStyle("paddingBottom");
			vm.left += this.getStyle("paddingLeft");
			
			// First, align with the height of our component.
			var top:int = unscaledHeight - vm.bottom - this.textField.getExplicitOrMeasuredHeight();
			textField.move(vm.left, Math.max(vm.top, top));
			this.scrollToBottom();			
		}
		
	}
}