package bluespot {
	
	import flash.display.Screen;
	import flash.geom.Rectangle;
	import flash.display.InteractiveObject;
	import flash.display.DisplayObjectContainer;
	
	import mx.core.WindowedApplication;
	
	public class utils {
		public function utils() {
			super();	
		}
		
		public static function positionWindow(application:WindowedApplication, window:Rectangle, maximize:Boolean = true):void {
			var screen:Rectangle = Screen.mainScreen.bounds;
			// Center our window.
			if(screen.width < window.width) {
				// Our window's width is bigger than the screen, so position at the left.
				window.x = screen.left;
			} else {
				// Center horizontally:
				// Specifically, we take the left side of our mainScreen, then add half
				// the width so that our left-side is aligned with the center, then subtract
				// half the width of the window to get the proper horizontal center.
				window.x = screen.left + (screen.width / 2) - (window.width / 2);
			}
			if(screen.height < window.height) {
				// Our window's height is bigger than the screen's, so position at the top.
				window.y = screen.top;
			} else {
				// Center vertically:
				// Specifically, we take the top side of our mainScreen, then add half
				// the height so that our top edge of the window is aligned with the vertical
				// center line of the screen. We then subtract half the height of our window
				// to get the proper vertical alignment.
				window.y = screen.top + (screen.height / 2) - (window.height / 2); 
			}
			application.nativeWindow.x = window.x;
			application.nativeWindow.y = window.y;
			
			// Maximize our window.
			if(maximize) {
				application.nativeWindow.maximize();
			}
		}

		public static function isChildOf(child:InteractiveObject, candidateParent:DisplayObjectContainer):Boolean {
			if(!child)
				return false;
			if(!child.parent)
				return false;
			if(child.parent === candidateParent)
				return true;
			return isChildOf(child.parent, candidateParent);
		}
		
	}
}