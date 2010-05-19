package bluespot.controls {
	import flash.html.HTMLLoader;
	
	public class ScrolledHTML extends ScrolledComponent {
		public function ScrolledHTML() {
			super();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			
			if(!this.content) {
				this.content = new HTMLLoader();
			}
		}
		
		
		
	}
}