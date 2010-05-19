package bluespot.controls {
	
	import mx.binding.utils.BindingUtils;
	import mx.core.EdgeMetrics;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDetail;
	import mx.events.ScrollEventDirection;
	
	[Style(

	public class BottomFeeder extends UIComponent {
		
		public function BottomFeeder() {
			super();
			mx.binding.utils.BindingUtils.bindSetter(this.textListener, this, "text", true);
			this.addEventListener(ScrollEvent.SCROLL, this.scrollListener);
			//this.addEventListener(ResizeEvent.RESIZE, this.resizeListener);
		}
		
		public var stickToBottom:Boolean = true;
		
		protected var _component:UIComponent;
		protected var currentComponent:UIComponent;
		private var componentChanged:Boolean;
		
		public function set component(component:UIComponent):void {
			this._component = component;
			this.componentChanged = true;
			this.invalidateProperties();
			this.invalidateSize();
			this.invalidateDisplayList();
		}
		
		public function get component():UIComponent {
			return this._component;
		}
		
		override protected function commitProperties():void { 
			super.commitProperties();
			
			if(this.componentChanged) {
				if(this.currentComponent)
					this.removeChild(this.currentComponent);
				this.currentComponent = this._component;
				if(this.currentComponent)
					this.addChild(this.currentComponent);				
			}
		}
		
		override protected function measure():void {
			super.measure();
			
			this.measuredWidth = this.currentComponent.getExplicitOrMeasuredWidth();
			this.measuredHeight = this.currentComponent.getExplicitOrMeasuredHeight();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var vm:EdgeMetrics = this.viewMetrics.clone();
			vm.top += this.getStyle("paddingTop");
			vm.bottom += this.getStyle("paddingBottom");
			vm.left += this.getStyle("paddingLeft");
			
			// First, align with the height of our component.
			var top:int = this.height - vm.bottom - this.textField.getExplicitOrMeasuredHeight();
			textField.move(vm.left, Math.max(vm.top, top));
			this.scrollToBottom();					
		}
		
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
		
		override public function set htmlText(value:String):void {
			super.htmlText = value;
		}
	        
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			var vm:EdgeMetrics = this.viewMetrics.clone();
			vm.top += this.getStyle("paddingTop");
			vm.bottom += this.getStyle("paddingBottom");
			vm.left += this.getStyle("paddingLeft");
			
			// First, align with the height of our component.
			var top:int = this.height - vm.bottom - this.textField.getExplicitOrMeasuredHeight();
			textField.move(vm.left, Math.max(vm.top, top));
			this.scrollToBottom();			
		}
		
	}
}