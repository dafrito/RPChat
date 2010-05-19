package bluespot.collections {
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import mx.utils.UIDUtil;
	registerClassAlias("Record", Record);
	
	public class Record extends EventDispatcher implements IRecord {
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		public function Record(name:String = null) {
			this._name = name;
		}

		//---------------------------------------------------------------------
		//
		//  IRecord Implementation
		//
		//---------------------------------------------------------------------
		
		//--------------------------------
		//  name
		//--------------------------------

		private var _name:String;
		
		[Bindable]
		public function get name():String {
			return this._name;
		}
		
		public function set name(name:String):void {
			this._name = name;
		}
	
		//--------------------------------
		//  XML serialization methods
		//--------------------------------

		/**
		 * 
		 * Serializes this record into XML. Inheritors should override this, along with 
		 * fromXML().
		 * 
		 * @return The XML used to create this Record.
		 * 
		 * @see fromXML
		 */		
		public function toXML():XML {
			return <Record name="{this.name}"/>;
		}
		
		/**
		 * 
		 * Deserializes the provided XML into a live record. Inheritors should override this, along with
		 * toXML().
		 *  
		 * @param node The XML used to generate this node.
		 * @return This Record. Used for convenience.
		 * 
		 * @see toXML
		 * 
		 */
		public function fromXML(node:XML):IRecord {
			this.name = node.text();
			return this;
		}
		
		//---------------------------------------------------------------------
		//
		//  IPropertyChangeNotifier Implementation
		//
		//---------------------------------------------------------------------
				
		private var _uid:String;
		
		public function get uid():String {
			if (this._uid === null)
				this._uid = UIDUtil.createUID();
			return this._uid;
		}
		
		public function set uid(value:String):void {
			this._uid = value;
		}
		
		//---------------------------------------------------------------------
		//
		//  IExternalizable Implementation
		//
		//---------------------------------------------------------------------	
		
		public function readExternal(input:IDataInput):void {
			var node:XML = new XML(input.readUTFBytes(input.readInt()));
			this.fromXML(node);
		}
		
		public function writeExternal(output:IDataOutput):void {
			var xmlString:String = this.toXML().toXMLString();
			output.writeInt(xmlString.length);
			output.writeUTFBytes(xmlString);
		}

		override public function toString():String {
			return this.name;
		}

	}
}