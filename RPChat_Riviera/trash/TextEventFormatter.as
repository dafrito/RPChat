package bluespot.controls {
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.formatters.Formatter;
	import mx.styles.StyleManager;
	import mx.utils.StringUtil;
	
	import bluespot.events.*;
	import bluespot.net.Communicator;
    	
	public class TextEventFormatter extends EventFormatter {
		
		public var chatroom:Chatroom;
		public static var textFormats:Object = {};
		
		public static const TEXT_FORMAT_VALUES:Array = [
			"font", "color", "size", 
			"bold", "italic", "underline",
			"align", "kerning", "leading", "letterSpacing",
			"leftMargin", "rightMargin",
			"indent", "blockIndent"
		];
		
		public function TextEventFormatter(chatroom:Chatroom = null) {
			super();
			this.chatroom = chatroom;
		}
		
		override protected function styleMessage(messageKind:String, message:String, isStandalone:Boolean = true):String {
			var textFormat:TextFormat = TextEventFormatter.textFormats[messageKind];
			if(!textFormat) {
				var declarations:Array = messageKind.split(".");
				declarations = declarations.map(function(value:*, key:int, array:Array):Object {
					return StyleManager.getStyleDeclaration(".chat" + value);
				}).reverse();
				textFormat = new TextFormat();
				for each(var textFormatProp:String in TEXT_FORMAT_VALUES) 
					textFormat[textFormatProp] = this.getTextFormatStyle(textFormatProp, declarations);
				TextEventFormatter.textFormats[className] = textFormat;
			}
			return this.attachEnds(textFormat, message, isStandalone);
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
			if(chatroom.eventList.length)
				return chatroom.eventList.getItemAt(chatroom.eventList.length - 1);
			return null;			
		}

	}
}