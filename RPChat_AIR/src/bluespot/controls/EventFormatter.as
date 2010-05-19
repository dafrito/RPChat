package bluespot.controls {
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.formatters.Formatter;
	import mx.styles.StyleManager;
	import mx.utils.StringUtil;
	
	import bluespot.events.ChannelEvent;
	import bluespot.events.ChatEvent;
	import bluespot.events.InfoChatEvent;
	import bluespot.events.UserEvent;
	import bluespot.net.Communicator;
    	
	public class EventFormatter extends Formatter {
		
		public var chatroom:Chatroom;
		public static var textFormats:Object = {};
		
		public static const TEXT_FORMAT_VALUES:Array = [
			"font", "color", "size", 
			"bold", "italic", "underline",
			"align", "kerning", "leading", "letterSpacing",
			"leftMargin", "rightMargin",
			"indent", "blockIndent"
		];
		
		public function EventFormatter(chatroom:Chatroom = null) {
			super();
			this.chatroom = chatroom;
		}
		
		public function escape(string:String):String {
			if(!string)
				return "";
			string = string.replace(/&/g, "&amp;");
			string = string.replace(/</g, "&lt;");
			string = string.replace(/>/g, "&gt;");
			string = string.replace(/'/g, "&apos;"); // '
			string = string.replace(/"/g, '&quot;'); // "
			return string;
		}
		
		public function escapeAll(values:Array, inPlace:Boolean = false):Array {
			var escaped:Array = inPlace ? values : [];
			for(var i:int = 0; i < values.length; i++)
				escaped[i] = this.escape(values[i]);
			return escaped;
		}
		
		protected function formatAll(values:Array, inPlace:Boolean = false):Array {
			var formatted:Array = [];
			if(!values)
				return formatted;
			for each(var value:Object in values)
				formatted.push(this.format(value));
			return formatted;
		}
		
		override public function format(value:Object):String {
			switch(value.constructor) {
				case InfoChatEvent:
					return this.formatInfoChatEvent(value as InfoChatEvent);
				case ChatEvent:
					return this.formatChatEvent(value as ChatEvent);
				case ChannelEvent:
					return this.formatChannelEvent(value as ChannelEvent);	
				case UserEvent:
					return this.formatUserEvent(value as UserEvent);
				case Communicator:
					return this.formatCommunicator(value as Communicator);
				case String:
				case Number:
				case Boolean:
					return this.escape(String(value));
			}
			throw new Error("Unsupported value given to format '" + value + "'");
		}
		
		protected function formatCommunicator(communicator:Communicator):String {
			return this.styleMessage("Communicator", this.escape(communicator.getFormattedName()), false);
		}

		protected function formatInfoChatEvent(e:InfoChatEvent):String {
			if(!e)
				return "";
			var params:Array = e.params;
			if(e.category === "Detail") {
				var last:InfoChatEvent = this.peekLast(chatroom) as InfoChatEvent;
				if(last && e.kind === last.kind) {
					// They're the same type of message, so suppress.
					return "";
				}
			}
			switch(e.kind) {
				case "Detail.InfoChatEvent.Ping":
				case "Detail.InfoChatEvent.Pong":
					params = [e.speaker];
					break;	
				case "Message.Server.Connected":
				case "Detail.Server.Authenticating":
					var server:Server = e.domain.server;
					params = [server.serverName, server.serverPort];
					break;
			}
			return this.styleMessage(e.category, this.substitute(e.kind, this.formatAll(params)));
		}
		
		protected function formatChatEvent(e:ChatEvent):String {
			var formatted:String = "";
			if(!e)
				return formatted;
			var category:String = "";
			switch(e.type) {
				case ChatEvent.INFO:
					category = "Message.Detail";
					break;
				case ChatEvent.EMOTE:
					category = "Message.Emote";
					break;
				case ChatEvent.INVITE:
					category = "Message.Emote";
					formatted = this.substitute(
						"Message.ChatEvent.Invite",
						this.formatAll([e.speaker, e.speaker.server.procure(e.message)])
					);
					break;
				case ChatEvent.SAY:
					category = "Message"; 				
			}
			return this.styleMessage(category, formatted || this.formatSourcedMessage(category, e.speaker, e.message));
		}
		
		protected function formatUserEvent(e:UserEvent):String {
			var formatted:String = "";
			if(!e)
				return formatted;
			var type:String = "";
			var kind:String = "";
			switch(e.type) {
				case UserEvent.QUIT:
					type = "Emote.Left";
					kind = "Message.UserEvent.Quit";
					break;
				case UserEvent.AWAY:
					type = "Detail";
					kind = "Message.UserEvent.Away";
					break;
				case UserEvent.CHANGE_NAME:
					type = "Detail";
					kind = "Message.UserEvent.ChangeName";
			}
			return this.styleMessage(type,
				this.substitute(kind, this.formatAll([e.user, e.message], true))
			);
		}
		
		protected function formatChannelEvent(e:ChannelEvent):String {
			var formatted:String = "";
			if(!e)
				return formatted;
			var type:String = "";
			var kind:String = "";
			var params:Array;
			switch(e.type) {
				case ChannelEvent.KICK:
					type = "Emote.Left";
					kind = "Message.ChannelEvent.Kick";
					params = [e.user, e.channel];
					break; 
				case ChannelEvent.PART:
					type = "Emote.Left";
					kind = "Message.ChannelEvent.Part";
					params = [e.user, e.channel];
					break;	
				case ChannelEvent.CHANGE_TOPIC:
					type = "Detail";
					kind = "Message.ChannelEvent.ChangeTopic";
					params = [e.user, e.channel, e.message];
					break;
				case ChannelEvent.JOIN:
					type = "Emote.Join";
					kind = "Message.ChannelEvent.Join";
					params = [e.user, e.channel];
					break;
			}
			return this.styleMessage(type,
				this.substitute(kind, this.formatAll(params, true))
			);
		}
		
		protected function substitute(kind:String, values:Array, escapeValues:Boolean = false):String {
			if(escapeValues)
				values = this.escapeAll(values);
			var message:String = this.resourceManager.getString("EventMessages", kind);
			return StringUtil.substitute(this.escape(message), values);
		}
		
		protected function formatSourcedMessage(type:String, source:Communicator, message:String, escapeValues:Boolean = true):String {
			var formatted:String = "";
			if(!message)
				return formatted;
			var kind:String = "Template." + type;
			return this.substitute(kind, [this.format(source), escapeValues ? this.escape(message) : message]);
		}
		
		protected function styleMessage(className:String, message:String, wrap:Boolean = true):String {
			var textFormat:TextFormat = EventFormatter.textFormats[className];
			if(!textFormat) {
				var declarations:Array = className.split(".");
				declarations = declarations.map(function(value:*, key:int, array:Array):Object {
					return StyleManager.getStyleDeclaration(".chat" + value);
				}).reverse();
				textFormat = new TextFormat();
				for each(var textFormatProp:String in TEXT_FORMAT_VALUES) 
					textFormat[textFormatProp] = this.getTextFormatStyle(textFormatProp, declarations);
				EventFormatter.textFormats[className] = textFormat;
			}
			return this.attachEnds(textFormat, message, wrap);
		}
		
		
		protected function attachEnds(textFormat:TextFormat, string:String, wrap:Boolean = true):String {
			if(!string)
				return string;
			var prefix:String = "";
			var suffix:String = "";
			// Utility functions for our ends.
			var styleRule:Function = function(key:String, value:String):String {
				return key.toUpperCase() + "='" + value + "'";
			}
			var pushRule:Function = function(ruleName:String, attributes:Array = null):void {
				if(attributes && !attributes.length)
					return;
				ruleName = ruleName.toUpperCase();
				prefix += "<" + ruleName;
				if(attributes && attributes.length)
					prefix += " " + attributes.join(" ");
				prefix += ">";
				suffix = "</" + ruleName + ">" + suffix;
			}
			var addAttribute:Function = function(attributes:Array, formatName:String, styleName:String = null, defaultValue:Object = null):void {
				var value:Object = textFormat[formatName];
				if(defaultValue !== null && value === null)
					value = defaultValue;
				if(!styleName)
					styleName = formatName;
				if(value !== null)
					attributes.push(styleRule(styleName, value));
			}
			var addAttributes:Function = function(attributes:Array, ruleNames:Array, defaultValue:Object = null):void {
				for each(var ruleName:String in ruleNames)
					addAttribute(attributes, ruleName, null, defaultValue);	
			}
			var pushRuleWithAttributes:Function = function(ruleGroupName:String, ruleNames:Array, defaultValue:Object = null):void {
				var attributes:Array = [];
				addAttributes(attributes, ruleNames, defaultValue);
				pushRule(ruleGroupName, attributes);
			}
			if(wrap)
				pushRule("P");
			if(textFormat.bold)
				pushRule("B");
			if(textFormat.underline)
				pushRule("U");
			if(textFormat.italic)
				pushRule("I");
			
			var textFormatAttributes:Array = [];
			addAttributes(textFormatAttributes, ["indent", "leading", "leftMargin", "rightMargin"]);
			// Workaround for strange bug involving C/P selected across indented areas while text is entered.
			addAttribute(textFormatAttributes, "blockIndent", null, 0);
			// pushRuleWithAttributes("textFormat", ["blockIndent", "indent", "leading", "leftMargin", "rightMargin"], 0);
			pushRule("textFormat", textFormatAttributes);
			var fontValues:Array = [];
			if(textFormat.color) {
				var hexColor:String = (textFormat.color as uint).toString(16);
				while(hexColor.length < 6)
					hexColor = "0" + hexColor;
				hexColor = "#" + hexColor;
				fontValues.push("COLOR='" + hexColor + "'");
			}
			addAttribute(fontValues, "size");
			addAttribute(fontValues, "font", "face");
			addAttribute(fontValues, "letterSpacing");
			pushRule("font", fontValues);
			if(wrap) {
				prefix = this.styleMessage("Spacer", "<P>a</P>", false) + prefix; 	
			}
			return prefix + string + suffix;
		}
	
		/* This function is given a name of a textFormat property, and a number of CSSStyleDeclarations.
			It will return the proper one, using the order of styleDeclarations as precedence. */
		protected function getTextFormatStyle(styleProp:String, declarations:Array):Object {
			var styleValue:Object;
			for each(var declaration:Object in declarations) {
				if(!declaration)
					continue;
				switch(styleProp) {
					case "align":
						styleValue = declaration.getStyle("textAlign");
						break;
					case "font":
						styleValue = StringUtil.trimArrayElements(
							declaration.getStyle("fontFamily"),","
						);
						break;
					case "size":
						styleValue = declaration.getStyle("fontSize");
						break;
					case "bold":
						styleValue = declaration.getStyle("fontWeight") === "bold";
						break;
					case "italic":
						styleValue = declaration.getStyle("fontStyle") === "italic";
						break;
					case "underline":
						styleValue = declaration.getStyle("textDecoration") === "underline";
						break;
					case "leftMargin":
						styleValue = declaration.getStyle("paddingLeft");
						break;
					case "rightMargin":
						styleValue = declaration.getStyle("paddingRight");
						break;
					default:
						styleValue = declaration.getStyle(styleProp);
				}
				if(styleValue !== null)
					return styleValue;
			}
			return styleValue;
		}
		
		protected function peekLast(chatroom:Chatroom):Object {
			if(chatroom.chatValues.length)
				return chatroom.chatValues.getItemAt(chatroom.chatValues.length - 1);
			return null;			
		}

	}
}