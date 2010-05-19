package bluespot.collections {
	
	import flash.utils.IExternalizable;
	import mx.core.IPropertyChangeNotifier;
	
	public interface IRecord extends IPropertyChangeNotifier, IExternalizable {
		function set name(name:String):void;
		function get name():String;
		function toXML():XML;
		function fromXML(node:XML):IRecord;
	}
}