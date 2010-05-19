package bluespot.collections {
	import flash.net.registerClassAlias;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.collections.SortField;
	registerClassAlias("RecordKeeper", RecordKeeper);
	
	/**
	 * The RecordKeeper wraps a given List, providing gated insertion and removal of its elements.
	 * 
	 * I've found it's common to want to have a list of elements, unique by name. I also enjoy the
	 * ability to create new elements to fill a requested name on demand, making this process transparent
	 * when used. 
	 * 
	 * @see Record
	 */
	public class RecordKeeper extends Record {
		private var cursor:IViewCursor;
		
		private var _records:ListCollectionView;
		private var _rawSourceList:IList;
		
		/**
		 * Creates a record given a value expected for this RecordKeeper.
		 * 
		 * The signature looks like <code>function createRecord(value:*):IRecord
		 * 
		 * A common use case is to have the values expected be themselves IRecords,
		 * in which case this function simply returns them cast as such. 
		 */
		public var createRecord:Function;
		
		/**
		 * Retrieves a name given some value expected for this RecordKeeper.
		 * 
		 * The signature looks like <code>function getName(value:*):String
		 */
		public var getName:Function;
		
		/**
		 * Creates a brand new IRecord. This function is used in creating a RecordKeeper's
		 * Records from a XML-state. It's also used in our default implementation of createRecord,
		 * where it's passed the value.
		 * 
		 * The signature expected is <code>function createNewRecord():IRecord</code>
		 */
		public var createBlankRecord:Function;
		
		//*** Override these for full functionality.
		
		public function defaultGetName(value:*):String {
			if(value is String)
				return value;
			if(value is Object)
				return value.name;
			throw new Error("getName defaulted!");
		}
		
		protected function defaultCreateRecord(value:*):IRecord {
			if(value is String || value is Number) {
				var record:IRecord = this.createBlankRecord(value);
				record.name = String(value);
				return record;
			}
			if(value is IRecord)
				return value as IRecord;
			throw new Error("Value isn't coercible!");
		}
		
		protected function defaultCreateBlankRecord(hint:*):IRecord {
			throw new Error("Cannot create new record.");
		}
		
		//*** Utility stuff, IRecord implementation.
		
		public function get records():ListCollectionView {
			return this._records;
		}
		
		[Bindable]
		public function get rawSourceList():IList {
			return this._rawSourceList;
		}
		
		public function set rawSourceList(rawSourceList:IList):void {
			this._rawSourceList = rawSourceList;
			this.records.list = this._rawSourceList;
		}
		
		override public function toXML():XML {
			var node:XML = <{this.name}/>;
			this.childrenToXML(node);
			return node;
		}
		
		protected function childrenToXML(parent:XML):void {
			for each(var child:IRecord in this.records)
				parent.appendChild(child.toXML());
		}
		
		override public function fromXML(node:XML):IRecord {
			var children:XMLList = node is XMLList ? node as XMLList : node.children();
			for each(var child:XML in children)
				this.insert(this.createBlankRecord(child).fromXML(child));
			return this;
		}

		public function RecordKeeper(name:String = "RecordKeeper", recordSource:IList = null) {
			super(name);
			this._rawSourceList = recordSource || new ArrayCollection();
			this._records = new ListCollectionView();
			BindingUtils.bindProperty(this.records, "list", this, "rawSourceList");
			var sort:Sort = new Sort();
			sort.unique = true;
			this.records.sort = sort;
			this.records.sort.fields = [new SortField("name", true)];
			this.records.refresh();
			this.cursor = this.records.createCursor();
			this.createRecord = this.defaultCreateRecord;
			this.createBlankRecord = this.defaultCreateBlankRecord;
			this.getName = this.defaultGetName;
		}
		
		// Get a Record, or create one from the value if none is found.
		public function procure(value:*):IRecord {
			var record:IRecord = this.peek(this.getName(value));
			if(!record)
				record = this.doInsert(value);
			return record;
		}
		
		public function getCursorFrom(value:*):IViewCursor {
			var cursor:IViewCursor = this.records.createCursor();
			if(cursor.findAny({name:this.getName(value)}))
				return cursor;
			return null;
		}
		
		// Get a Record given the name.
		public function peek(name:String):IRecord {
			if(this.cursor.findAny({name:name}))
				return IRecord(this.cursor.current);
			return null;
		}
		
		// Insert a record that's created from the given value.
		// If an equivalent one is found, then throw if silent is false, otherwise
		// return the found one.  
		public function insert(value:*, silent:Boolean = false):IRecord {
			if(this.peek(this.getName(value))) {
				if(silent)
					return null;
				throw new Error("Attempting to overwrite a record with name '" + this.getName(value) + "'");				
			}
			return this.doInsert(value);
		}
		
		// Remove a Record given the value.
		public function remove(value:*):void {
			if(this.cursor.findAny({name:this.getName(value)}))
				this.cursor.remove();
		}
		
		// Utilty function to insert values.
		private function doInsert(value:*):IRecord {
			var record:IRecord = this.createRecord(value);
			this.cursor.insert(record);
			return record;
		}
	}
}