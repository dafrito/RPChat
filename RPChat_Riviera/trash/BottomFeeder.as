package bluespot.controls {
	
	import mx.binding.utils.BindingUtils;
	import mx.controls.TextArea;
	import mx.core.EdgeMetrics;
	import mx.core.ScrollControlBase;
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDetail;
	import mx.events.ScrollEventDirection;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	import mx.core.UITextField;
	import mx.core.IUITextField;
	import mx.core.IUIComponent;
	
	import flash.display.DisplayObject;
	
	[Style(name="paddingLeft", type="int")]
	
	[Style(name="paddingRight", type="int")]
	
	[Style(name="paddingTop", type="int")]
	
	[Style(name="paddingBottom", type="int")]
	
	[DefaultProperty("component")]
	
	public class BottomFeeder extends ScrollControlBase {
		
		private static var classConstructed:Boolean = classConstruct();
		private static function classConstruct():Boolean {
			if (!StyleManager.getStyleDeclaration("BottomFeeder")) {
				var styles:CSSStyleDeclaration = new CSSStyleDeclaration();
				styles.defaultFactory = function():void {
					this.paddingLeft = this.paddingRight = 4;
					this.paddingTop = this.paddingBottom = 4;
				}
				StyleManager.setStyleDeclaration("BottomFeeder", styles, true);
			}
			return true;
		}
		
		/**
		 * Constructor
		 */
		
		public function BottomFeeder() {
			super();
			this.addEventListener(ScrollEvent.SCROLL, this.scrollListener);
		}
		
		public var stickToBottom:Boolean = true;
		
		protected var _component:IUIComponent;
		protected var currentComponent:IUIComponent;
		private var componentChanged:Boolean;
		
		public function set component(component:IUIComponent):void {
			this._component = component;
			this.componentChanged = true;
			this.invalidateProperties();
			this.invalidateSize();
			this.invalidateDisplayList();
		}
		
		public function get component():IUIComponent {
			return this._component;
		}

		
		/*
		 *  Overridden methods: UIComponent
		 */
	
		override protected function createChildren():void {
			super.createChildren();
			
			if(!this.currentComponent) {
				this.currentComponent = IUITextField(this.createInFontContext(UITextField));
				this.addChild(DisplayObject(this.currentComponent));
			}
		}
		
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
		}
		
		override protected function commitProperties():void { 
			super.commitProperties();
			
			if(this.componentChanged) {
				this.componentChanged = false;
				if(this.currentComponent)
					this.removeChild(DisplayObject(this.currentComponent));
				this.currentComponent = this._component;
				if(this.currentComponent)
					this.addChild(DisplayObject(this.currentComponent));				
			}
		}
		
		override protected function measure():void {
			super.measure();
			
			this.measuredWidth = this.currentComponent.getExplicitOrMeasuredWidth();
			this.measuredHeight = this.currentComponent.getExplicitOrMeasuredHeight();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(!this.component)
				return;
			
			var vm:EdgeMetrics = this.viewMetrics.clone();
			vm.top += this.getStyle("paddingTop");
			vm.bottom += this.getStyle("paddingBottom");
			vm.left += this.getStyle("paddingLeft");
			vm.right += this.getStyle("paddingRight");
			
			this.component.setActualSize(unscaledWidth - vm.right - vm.left, this.component.getExplicitOrMeasuredHeight() *4);
			
			component.move(vm.left, Math.max(
				unscaledHeight - vm.bottom - this.currentComponent.getExplicitOrMeasuredHeight(),
				vm.top
			));
			
			
			this.scrollToBottom();					
		}
		
		private function scrollListener(e:ScrollEvent):void {
			if(e.direction === ScrollEventDirection.VERTICAL && e.detail === ScrollEventDetail.THUMB_POSITION)
				this.stickToBottom = e.position >= this.maxVerticalScrollPosition;
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
		
	}
}