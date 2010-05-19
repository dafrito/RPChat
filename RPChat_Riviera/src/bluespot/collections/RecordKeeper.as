package bluespot.collections {
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.ListCollectionView;
	import mx.collections.Sort;
	import mx.collections.SortField;
	
	import flash.net.registerClassAlias;
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
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function RecordKeeper(name:String = "RecordKeeper", recordSource:IList = null) {
			super(name);
			
			this._rawSourceList = recordSource || new ArrayCollection();
			
			// Setup our records, sorting them by name.
			this._records = new ListCollectionView(this.rawSourceList);
			this.records.sort = new Sort();
			this.records.sort.unique = true;
			this.records.sort.fields = [new SortField("name", true)];
			this.records.refresh();
			
			// Create the internal cursor.
			this.cursor = this.records.createCursor();
			
			// Assign our defaults to the plugs.
			this.createRecord = this.defaultCreateRecord;
			this.createBlankRecord = this.defaultCreateBlankRecord;
			this.getName = this.defaultGetName;			
		}
		
		//---------------------------------------------------------------------
		//
		//  Extension points for our IRecord coercion.
		//  If you intend to use RecordKeeper without extending it, these
		//  will be your points to add your own custom functionality to it.
		//  Otherwise, override the default methods.
		//
		//---------------------------------------------------------------------
		
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
		 * Of the three pluggable values, you'll need to set this one most often.
		 * 
		 * The signature expected is <code>function createBlankRecord(hint:*):IRecord</code>
		 */
		public var createBlankRecord:Function;
		
		
		//---------------------------------------------------------------------
		//
		// Default IRecord Coercion Methods.
		// This should be overridden as necessary by inheritors.
		//
		//---------------------------------------------------------------------
			
		/**
		 * Creates a new record from the given hint.
		 * 
		 * You should always override this.
		 * 
		 * @param hint The hint to coerce the Record from.
		 * @return The new Record.
		 * 
		 */		
		protected function defaultCreateBlankRecord(hint:*):IRecord {
			throw new Error("Cannot create new record.");
		}
			
		/**
		 * Coerces a name from some value. Note that this won't necessarily be
		 * a IRecord, but what is given here depends on your content.
		 * 
		 * This should be overridden if your value's don't have .name properties,
		 * or if you sanitize names before using them in this RecordKeeper.
		 *  
		 * @param value The value to get a name from.
		 * @return The name.
		 * 
		 */
		public function defaultGetName(value:*):String {
			if(value is String)
				return value;
			if(value is Object)
				return value.name;
			throw new Error("getName defaulted!");
		}
		
		/**
		 * Creates a record from the given value.
		 * 
		 * You shouldn't need to override this, since the value is given to
		 * createBlankRecord, so just about any value will work.
		 */		
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
		
		//---------------------------------------------------------------------
		//
		//  Public Record Manipulation Methods
		//
		//---------------------------------------------------------------------
		
		//--------------------------------
		//  records
		//--------------------------------
		
		private var _records:ListCollectionView;
		
		public function get records():ListCollectionView {
			return this._records;
		}
		
		//--------------------------------
		//  rawSourceList
		//--------------------------------
		
		private var _rawSourceList:IList;
		
		[Bindable]
		public function get rawSourceList():IList {
			return this._rawSourceList;
		}
		
		public function set rawSourceList(rawSourceList:IList):void {
			this._rawSourceList = rawSourceList;
			this.records.list = this._rawSourceList;
		}
		
		/**
		 * Safely get a IRecord, creating one from the value if none currently exists.
		 * 
		 * @param value The value to search for, or to use as a hint for the created IRecord.
		 * @return The IRecord that was found or created.
		 */
		public function procure(value:*):IRecord {
			var record:IRecord = this.peek(this.getName(value));
			if(!record)
				record = this.doInsert(value);
			return record;
		}
		
		/**
		 * Creates an IRecord using the given value, and inserts it into this RecordKeeper.
		 * 
		 * If an equivalent one is found, an Error is thrown unless <code>silent</code>
		 * is true.
		 *  
		 * @param value The value used to create the IRecord. 
		 * @param silent If this is true, then if the IRecord already exists, this will
		 * silently return that IRecord. If not, then it will throw if an equivalent 
		 * IRecord is found.
		 * 
		 * @return The IRecord that was created, or silently found and returned. 
		 * 
		 */
		public function insert(value:*, silent:Boolean = false):IRecord {
			if(this.peek(this.getName(value))) {
				if(silent)
					return null;
				throw new Error("Attempting to overwrite a record with name '" + this.getName(value) + "'");				
			}
			return this.doInsert(value);
		}
		
		/**
		 * Removes the IRecord matching the given value. If none is found, nothing occurs.
		 */
		public function remove(value:*):void {
			if(this.cursor.findAny({name:this.getName(value)}))
				this.cursor.remove();
		}
		
		/**
		 * Get a IRecord given the name, but doesn't create one if it's not found.
		 * 
		 * @param name The name to search on.
		 * @return The first IRecord that's found with the provided name.
		 */
		public function peek(name:String):IRecord {
			if(this.cursor.findAny({name:name}))
				return IRecord(this.cursor.current);
			return null;
		}
		
		/**
		 * Returns a IViewCursor pointing at the IRecord who matches the name coerced
		 * from value. If none is found, null is returned.
		 */
		public function getCursorFrom(value:*):IViewCursor {
			var cursor:IViewCursor = this.records.createCursor();
			if(cursor.findAny({name:this.getName(value)}))
				return cursor;
			return null;
		}
		
		//---------------------------------------------------------------------
		//
		//  Private Utility Methods and Properties
		//
		//---------------------------------------------------------------------
		
		/**
		 * Internally used cursor. 
		 */
		private var cursor:IViewCursor;
		
		
		/**
		 * Actually creates and inserts a IRecord into our records. This process
		 * is pluggable via the createRecord() method.
		 * 
		 * @see createRecord  
		 */
		private function doInsert(value:*):IRecord {
			var record:IRecord = this.createRecord(value);
			this.cursor.insert(record);
			return record;
		}
		
		/**
		 * Convenience method for serializing all of this RecordKeeper's children. 
		 */
		private function childrenToXML(parent:XML):void {
			for each(var child:IRecord in this.records)
				parent.appendChild(child.toXML());
		}
		
		//---------------------------------------------------------------------
		//
		// Overridden Methods: Record
		//
		//---------------------------------------------------------------------
		
		override public function toXML():XML {
			var node:XML = <{this.name}/>;
			this.childrenToXML(node);
			return node;
		}
		
		override public function fromXML(node:XML):IRecord {
			var children:XMLList = node is XMLList ? node as XMLList : node.children();
			for each(var child:XML in children)
				this.insert(this.createBlankRecord(child).fromXML(child));
			return this;
		}
	}
}