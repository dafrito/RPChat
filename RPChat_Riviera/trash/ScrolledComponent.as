package bluespot.controls {
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.EdgeMetrics;
	import mx.core.IDataRenderer;
	import mx.core.IUIComponent;
	import mx.core.ScrollControlBase;
	import mx.events.ScrollEvent;
	import mx.events.ScrollEventDetail;
	import mx.events.ScrollEventDirection;

	[DefaultProperty("data")]
	
	[Style(name="verticalAlign", format="String", enumeration="top, bottom", defaultValue="top")]
	
	[Style(name="horizontalAlign", format="String", enumeration="left, right", defaultValue="left")]
	
	public class ScrolledComponent extends ScrollControlBase implements IDataRenderer, IListItemRenderer {
		public function ScrolledComponent() {
			super();
			this.horizontalScrollPolicy = "auto";
		}
	
		private var contentChanged:Boolean = true;
		protected var currentContent:DisplayObject;
		protected var _content:DisplayObject;
		protected var _verticalPinPolicy:Boolean;
		protected var verticallyPinned:Boolean;
	
		public function get content():DisplayObject {
			return this._content;
		}
		
		public function set content(content:DisplayObject):void {
			this._content = content;
			this.contentChanged = true;
			this.invalidateProperties();
			this.invalidateSize();
			this.invalidateDisplayList();
		}
		
		public function get contentHeight():Number {
			if(!this.currentContent)
				return 0;
			if(this.currentContent is IUIComponent)
				return IUIComponent(this.currentContent).getExplicitOrMeasuredHeight();
			return this.currentContent.height;
		}
		
		public function get contentWidth():Number {
			if(!this.currentContent)
				return 0;
			if(this.currentContent is IUIComponent)
				return IUIComponent(this.currentContent).getExplicitOrMeasuredWidth();
			return this.currentContent.width;
		}
	
		public function set data(data:Object):void {
			if(data is IUIComponent) {
				this.content = DisplayObject(data);
			} else if(data is Class) {
				this.content = DisplayObject(new (Class(data))());
			} else if(data is DisplayObject) {
				this.content = DisplayObject(data);
			}
		}
		
		public function get data():Object {
			return this.content;
		}
		
		
		[Inspectable(enumeration="true, false", format="Boolean", defaultValue="false")]
		
		public function get verticalPinPolicy():Boolean {
			return this._verticalPinPolicy;
		}
		
		public function set verticalPinPolicy(verticalPinPolicy:Boolean):void {
			this._verticalPinPolicy = verticalPinPolicy;
			this.verticalScrollPosition = this.maxVerticalScrollPosition;
			this.verticallyPinned = true;
			this.verticalScrollPosition = this.maxVerticalScrollPosition;
		}
		
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			switch(styleProp) {
				case "horizontalAlign":
				case "verticalAlign":
					this.invalidateDisplayList();
					break;
			}
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			if(this.contentChanged) {
				this.contentChanged = false;
				if(this.currentContent) {
					// Clear our old image if any.
					this.removeChild(this.currentContent);
					this.currentContent.mask = null;
					this.currentContent = null;
				}
				if(this.content) {
					// We have new content, so load it up.
					this.currentContent = this.content;
					
					// Make it invisible for now until it's properly positioned.
					this.currentContent.visible = false;
					this.currentContent.mask = this.maskShape;
					
					// Finally, add it to our display list.
					this.addChild(this.currentContent);
				}	 
			}
		}
		
		override protected function measure():void {
			super.measure();
			
			var edgeMetrics:EdgeMetrics = this.viewMetrics;
			
			var width:Number = edgeMetrics.left + edgeMetrics.right;
			var height:Number = edgeMetrics.top + edgeMetrics.bottom;
			
			if(this.currentContent) {
				width += this.contentWidth;
				height += this.contentHeight;
			} else {
				// No image, so just set it to our edgeMetrics, with an added default size of 40x40
				var defaultSize:Number = 40;
				width += defaultSize;
				height += defaultSize;
			}
			this.measuredWidth = width;
			this.measuredHeight = height;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(!this.currentContent)
				return;
				
			var component:IUIComponent = this.currentContent as IUIComponent;
			var edgeMetrics:EdgeMetrics = this.viewMetrics;
			
			this.positionContent();
			
			// Make the image visible.
			this.currentContent.visible = true;
			
			if(component) {
				// If it's a IUIComponent, we need to set its actual size, otherwise it's going to be invisible.
				component.setActualSize(
					component.getExplicitOrMeasuredWidth(),
					component.getExplicitOrMeasuredHeight()
				);
			}
			
			this.setScrollBarProperties(
				this.contentWidth,
				unscaledWidth - edgeMetrics.left - edgeMetrics.right,
				this.contentHeight,
				unscaledHeight - edgeMetrics.top - edgeMetrics.bottom
			);
			
			if(this.verticallyPinned && this.verticalScrollPosition < this.maxVerticalScrollPosition) {
				this.verticalScrollPosition = this.maxVerticalScrollPosition;
			}
		}
		
		override protected function scrollHandler(event:Event):void {
			// Immediately return if there's no image.
			if(!this.currentContent)
				return;
			
			// Return if it's not a ScrollEvent. This is for TextField scroll events bubbling up that
			// we wouldn't understand.
			if(!(event is ScrollEvent))
				return;
			
			// And finally, if we're not liveScrolling, and we're in the middle of scrolling, return.
			if (!liveScrolling && ScrollEvent(event).detail == ScrollEventDetail.THUMB_TRACK)
				return;
			
			super.scrollHandler(event);
			
			if(ScrollEvent(event).direction === ScrollEventDirection.VERTICAL)
				this.verticallyPinned = this.verticalPinPolicy && (ScrollEvent(event).position >= this.maxVerticalScrollPosition);
			
			this.positionContent();
			
		}
		
		protected function positionContent():void {
			if(!this.currentContent)
				return;
			var left:Number = this.viewMetrics.left - this.horizontalScrollPosition;
			var top:Number = this.viewMetrics.top - this.verticalScrollPosition;
			switch(this.getStyle("verticalAlign")) {
				case "bottom":
					// This starts our content at the bottom, and scrolls it up. When it exceeds the viewing area of our window,
					// it acts like a normal scrollbox.
					top = Math.max(top, 
						this.getExplicitOrMeasuredHeight() - this.viewMetrics.bottom - this.contentHeight - this.verticalScrollPosition
					);
					break;
				case "top":
				default:
					// pass		
			}
			switch(this.getStyle("horizontalAlign")) {
				case "right":
					left = Math.max(left,
						this.getExplicitOrMeasuredWidth() - this.viewMetrics.right - this.contentWidth - this.horizontalScrollPosition
					);
					break;
				case "left":
				default:
					// pass
			}
			if(this.currentContent is IUIComponent) {
				IUIComponent(this.currentContent).move(left, top);
			} else {
				this.currentContent.x = left;
				this.currentContent.y = top;
			}
		}
		
	}
}