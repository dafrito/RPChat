package bluespot.collections {
	import flash.events.EventDispatcher;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import mx.utils.UIDUtil;
	
	import flash.net.registerClassAlias;
	registerClassAlias("Record", Record);
	
	public class Record extends EventDispatcher implements IRecord {

		private var _id:String;
		
		public function get uid():String {
			if (this._id === null)
				this._id = UIDUtil.createUID();
			return this._id;
		}
		
		public function set uid(value:String):void {
			this._id = value;
		}

		private var _name:String;
		[Bindable]
		public function get name():String {
			return this._name;
		}
		
		public function set name(name:String):void {
			this._name = name;
		}

		public function Record(name:String = null) {
			this._name = name;
		}
		
		public function toXML():XML {
			return <Record name="{this.name}"/>;
		}
		
		public function fromXML(node:XML):IRecord {
			this.name = node.text();
			return this;
		}
		
		public function readExternal(input:IDataInput):void {
			var node:XML = new XML(input.readUTFBytes(input.readInt()));
			this.fromXML(node);
		}
		
		public function writeExternal(output:IDataOutput):void {
			var xmlString:String = this.toXML().toXMLString();
			output.writeInt(xmlString.length);
			output.writeUTFBytes(xmlString);
		}

	}
}