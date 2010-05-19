package bluespot.controls {
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import mx.collections.IList;
	import mx.core.IContainer;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	public class ViewStackDataBridge {
		
		public function ViewStackDataBridge() {
			super();
			this.bridges = new Dictionary(true);
		}
		
		//---------------------------------------------------------------------
		//
		//  Getters and Setters
		//
		//---------------------------------------------------------------------
		
		//--------------------------------
		//  bridges
		//--------------------------------
		
		protected var bridges:Dictionary;
		
		//--------------------------------
		//  container
		//--------------------------------
		
		protected var _container:IContainer;
		
		public function get container():IContainer {
			return this._container;
		}
		
		public function set container(container:IContainer):void {
			if(container === this.container)
				return;
			if(this.container)
				this.cleanUp();
			this._container = container;
			if(this.container)
				this.attach();
		}
		
		//--------------------------------
		//  dataProvider
		//--------------------------------
		
		protected var _dataProvider:IList;
		
		public function get dataProvider():IList {
			return this._dataProvider;
		}
		
		public function set dataProvider(dataProvider:IList):void {
			if(dataProvider === this.dataProvider)
				return;
			if(this.dataProvider)
				this.cleanUp();
			this._dataProvider = dataProvider;
			if(this.dataProvider)
				this.attach();
		}
		
		//---------------------------------------------------------------------
		//
		//  Interface
		//
		//---------------------------------------------------------------------
		
		protected function createChild(data:Object):DisplayObject {
			return DisplayObject(this.createChildFunction(data));
		}
		
		public var createChildFunction:Function;
		
		//---------------------------------------------------------------------
		//
		//  Internal Utility and Attach/Detach Methods
		//
		//---------------------------------------------------------------------
		
		public function get attached():Boolean {
			return this.container && this.dataProvider;
		}
		
		protected function attach():void {
			if(!this.attached)
				return;
			for(var i:int = 0; i < this.dataProvider.length; i++)
				this.addData(this.dataProvider.getItemAt(i));
			this.dataProvider.addEventListener(CollectionEvent.COLLECTION_CHANGE, this.collectionChangeListener, false, 0, true);
		}
		
		protected function cleanUp():void {
			if(!this.attached)
				return;
			this.dataProvider.removeEventListener(CollectionEvent.COLLECTION_CHANGE, this.collectionChangeListener);
			for(var data:Object in this.bridges)
				this.removeData(data);
		}
		
		protected function addData(data:Object):void {
			var child:DisplayObject = this.createChild(data);
			this.container.addChild(child);
			this.bridges[data] = child;
		}
		
		protected function removeData(data:Object):void {
			this.container.removeChild(this.bridges[data]);
			delete this.bridges[data];
		}

		private function collectionChangeListener(e:CollectionEvent):void {
			var data:Object;
			switch(e.kind) {
				case CollectionEventKind.ADD:
					for each(data in e.items)
						this.addData(data);						
					break;
				case CollectionEventKind.REMOVE:
					for each(data in e.items)
						this.removeData(data);
					break;
			}
		}
		
	}
}