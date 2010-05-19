package bluespot.net {
	
	import bluespot.collections.Record;
	import bluespot.collections.IRecord;
	import flash.net.registerClassAlias;
	
	registerClassAlias("Communicator", Communicator);
			
	public class Communicator extends Record {
		
		//---------------------------------------------------------------------
		//
		//  Communicator Types
		//
		//---------------------------------------------------------------------
		
		/**
		 * Channel Communicator Type. Typically, these are created and deleted
		 * when we join and part those channels. 
		 */
		public static const CHANNEL:String = "Channel";
		
		/**
		 * Server Communicator Type. These are information messages received from
		 * the server, along with potentially any services we're aggregating.
		 */
		public static const SERVER:String = "Server";
		
		/**
		 * User Communicator Type. These are day-to-day users, who are opened
		 * when we receive messages from them, and left open unless explicitly closed
		 * or when the user disconnects. 
		 */
		public static const USER:String = "User";
		
		/**
		 * Formats a Communicator's name for pretty visual display.
		 */
		public static function getFormattedName(name:String):String {
			return name;
		}
		
		//---------------------------------------------------------------------
		//
		//  Constructor
		//
		//---------------------------------------------------------------------
		
		/** 
		 * @param type The type of communicator (USER, CHANNEL, or SERVER)
		 * @param server The Server this Communicator is associated with.
		 * @param name The name of this Communicator.
		 * @param status The away-status of this Communicator, optional.
		 */
		public function Communicator(type:String, server:Server, name:String, status:String = null) {
			super(name);
			this.type = type;
			this._server = server;
			this.status = status;
		}
		
		//--------------------------------
		//  server
		//--------------------------------
		
		private var _server:Server;
		
		public function get server():Server {
			return this._server;
		}

		//--------------------------------
		//  type
		//--------------------------------
		
		[Inspectable(enumeration="{Communicator.USER}, {Communicator.CHANNEL}, {Communicator.SERVER}")]
		public var type:String;

		//--------------------------------
		//  formattedName
		//--------------------------------

		public function get formattedName():String {
			return Communicator.getFormattedName(this.name);
		}

		//--------------------------------
		//  status
		//--------------------------------
		
		public var status:String;

		/**
		 * Returns whether this Communicator is the Server's "user"
		 */
		public function isClient():Boolean {
			return this.server.user === this;
		}
		
		//---------------------------------------------------------------------
		//
		// Overridden methods: Record
		//
		//---------------------------------------------------------------------
		
		override public function fromXML(node:XML):IRecord {
			this.name = node.@name;
			this.type = node.@type;
			return this;
		}
		
		override public function toXML():XML {
			return <Communicator name={this.name} type={this.type}/>;	
		}
		
	}
}
