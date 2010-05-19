package bluespot.controls {
	import flexlib.containers.SuperTabNavigator;
	
	public class TabNavigator extends SuperTabNavigator {
		
		public function TabNavigator() {
			super();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if(this.tabBar.selectedIndex !== this.selectedIndex)
				this.tabBar.selectedIndex = this.selectedIndex;
		}
		
	}
}