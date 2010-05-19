package bluespot.net {
	import flash.events.Event;
	
	import bluespot.events.ChannelEvent;
	import bluespot.events.ChatEvent;
	import bluespot.events.UserEvent;
	import bluespot.events.InfoChatEvent;
	
	import flash.net.registerClassAlias;
	registerClassAlias("IRCServer", IRCServer);
	
	public class IRCServer extends Server {
		public static const AGGREGATE_SERVICES:Boolean = true;
		public static const MessageParser:RegExp = 
			/(?::(?P<prefix>[^\s]+)\s)?(?P<command>(?:[a-zA-Z]+|\d{3}))\s*(?P<params>(?!:)[^:\r\n]*)(?::(?P<trailing>[^\r\n]*))?\r\n/g;

		[Bindable]
		public var serverPassword:String;

		public function IRCServer(nickname:String, serverName:String, serverPort:uint, serverPassword:String = null) {
			super(nickname, serverName, serverPort);
			this.serverPassword = serverPassword;
		}
		
		override protected function getCommunicatorType(name:String):String {
			if(name.match(/^[#&]/))
				return Communicator.CHANNEL;
			if(name.match(/^\w+\.[\w\.]+$/))
				return Communicator.SERVER;
			if(this.state === Server.AUTHENTICATING && name.match(/^AUTH$/))
				return Communicator.SERVER;
			// This pushes all services into our single Server. ChanServ!ChanServ@Services.StarChat.Net
			if(IRCServer.AGGREGATE_SERVICES && name.match(/^\w+!\w+@services/i))
				return Communicator.SERVER;
			return super.getCommunicatorType(name);
		}
		
		override public function defaultGetName(value:*):String {
			if(value is String) {
				if(this.getCommunicatorType(value) === Communicator.SERVER)
					return Communicator.SERVER;
				return value;
			}
			if(value is Object)
				return value.name;
			throw new Error("getName defaulted!");
		}

		override protected function completeConnection():void {
			// First, dispatch the connection password, if any.
			this.PASS(true);
			// Second, dispatch our nickname and username.
			this.NICK(this.user.name, true);
			this.USER();
		}

		override protected function closeConnection():void {
			this.QUIT();
		}

		override protected function handleData(data:String):String {
			return data.replace(IRCServer.MessageParser, this.messageRegexReplacer);
		}

		private function messageRegexReplacer(match:String, prefix:String, command:String, paramString:String, trailing:String, offset:uint, complete:String):String {
			if(paramString) {
				var params:Array = paramString.split(/\s+/);
				params = params.filter(
					function(msg:String, offset:uint, array:Array):Boolean { 
						return !!msg; 
					}
				);
			}
			match = match.replace(/^\s*|\s*$/g, "");
			this.handleCommand(command, prefix, params, trailing, match);
			return "";
		}

		// Handlers
		private function handleCommand(command:String, prefix:String, params:Array, trailing:String, complete:String = null):void {
			// :Frito!frito@xyz012345.dsl.rcsntx.f55b92fc.net.hmsk PRIVMSG #notime :This is a sample message.
			// :<prefix> PRIVMSG <params[0]> :<trailiing>
			if(command.match(/\d+/)) {
				var numericReply:String = command;
				command = IRCServer.numericReplyNames[command] || command;
			}
			var sourceName:String = null;
			// The prefix can usually contain the hostname and other server cruft. We remove that here, so our sourceName matches that
			// of our Communicator names.
			var prefixMatch:Array = prefix.match(/^[^!]+/);
			if(prefixMatch)
				sourceName = prefixMatch[0];
			// Some random variable names used in our switch; otherwise, we get warnings and these names are usually pretty convenient.
			var target:Communicator, speaker:Communicator, domain:Communicator, recipient:Communicator, user:Communicator;
			var type:String, message:String;
			command = command.toUpperCase();
			switch(command) {
				case "TOPIC":
					var channel:Communicator = null;
					channel = this.procureCommunicator(params[0]);
					var oldTopic:String = channel.status;
					channel.status = trailing;
					this.dispatchEvent(new ChannelEvent(
						ChannelEvent.CHANGE_TOPIC,
						channel,
						this.procureCommunicator(sourceName),
						oldTopic
					));
					break;
				case "JOIN":
					// :Minifrito!Minifrito@e8ed6f8b.dsl.rcsntx.f55b92fc.net.hmsk JOIN :#notime
					// :<user>!<hostname> JOIN :<channel>
					channel = this.procureCommunicator(trailing);
					user = this.procureCommunicator(sourceName);
					this.dispatchEvent(new ChannelEvent(ChannelEvent.JOIN, channel, user));
					break;
				case "PART":
					// :UberFrito!frito@e8ed6f8b.dsl.rcsntx.f55b92fc.net.hmsk PART #notime
					// :<user>!<hostname> PART <channel> :<reason>
					channel = this.procureCommunicator(params[0]);
					user = this.procureCommunicator(sourceName);
					message = trailing;
					this.dispatchEvent(new ChannelEvent(ChannelEvent.PART, channel, user, trailing));
					break;
				case "NICK":
					// Someone has changed their name. The syntax is either these two:
					// :WiZ NICK Kilroy ; IRC standard example
					// :Frito!frito@e8ed6f8b.dsl.rcsntx.f55b92fc.net.hmsk NICK :UberFrito ; real-world example
					// We give preference to the IRC-standard way, if for some reason a trailing and a params[0] is sent.
					// :<oldName> NICK :<newName>
					user = this.procureCommunicator(sourceName);
					var newName:String = params[0] || trailing;
					var oldName:String = user.name;
					user.name = newName;
					// The CHANGE_NAME event is dispatched inside the call to renameCommunicator.
					this.dispatchEvent(new UserEvent(UserEvent.CHANGE_NAME, user, oldName));
					break;
				case "QUIT":
					user = this.procureCommunicator(sourceName);
					if(user.isClient()) {
						// Suppress it if it's the client, since we'll dispatch a QUIT event once
						// we get the ERROR.
						break;
					}	
					message = trailing;
					this.dispatchEvent(new UserEvent(UserEvent.QUIT, user, message));
					this.remove(user);
					break;
				case "PING":
					this.sendCommand("PONG", trailing);
					this.dispatchEvent(new InfoChatEvent(
						this.procureCommunicator(trailing),
						this.user,
						"Detail.InfoChatEvent.Ping"
					));
					break;
				case "PONG":
					this.dispatchEvent(new InfoChatEvent(
						this.procureCommunicator(trailing),
						this.user,
						"Detail.InfoChatEvent.Pong"
					));
					break;
				case "NOTICE":
					// This is a lesser-used kind of PRIVMSG, intended for services. This is usually the same syntax as PRIVMSG:
					// :Frito!frito@e8ed6f8b.dsl.rcsntx.f55b92fc.net.hmsk NOTICE Minifrito :This is a sample message.
					// :<speaker>!<hostname> NOTICE <recipient and domain> :<message>
					// or, in some situations (Such as right when we log in), it looks like this...
					// NOTICE AUTH :*** Processing connection to irc.somenetwork.net
					// NOTICE <speaker> :<message>
					if(IRCServer.AGGREGATE_SERVICES && prefix && this.getCommunicatorType(prefix) === Communicator.SERVER)
						speaker = this.procureServerCommunicator();
					else
						speaker = this.procureCommunicator(sourceName || params[0]);
					message = trailing;
					recipient = this.user;
					domain = this.procureServerCommunicator();
					if(speaker.type === Communicator.SERVER && this.state !== Server.CONNECTED) {
						// It's authentication cruft, so dispatch messages accordingly.
						this.dispatchEvent(new InfoChatEvent(
							speaker,
							recipient,
							"Detail.Server.Authenticating",
							message,
							null,
							domain
						));
					} else {
						this.dispatchEvent(new ChatEvent(ChatEvent.INFO, speaker, recipient, message, domain));
					}
					break;
				case "PRIVMSG":
					// When receiving a message sent to a channel (e.g., Frito talking in #notime), the syntax looks like this:
					// :Frito!frito@xyz012345.dsl.rcsntx.f55b92fc.net.hmsk PRIVMSG #notime :This is a sample message.
					// :<speaker>!<hostname> PRIVMSG <domain and recipient> :<message>
					// When receiving a message sent to the user (e.g., A whisper from Frito in this case), the syntax is:
					// :Frito!frito@e8ed6f8b.dsl.rcsntx.f55b92fc.net.hmsk PRIVMSG Minifrito :This is a sample message.
					// :<speaker and domain>!<hostname> PRIVMSG <recipient> :<message>
					speaker = this.procureCommunicator(sourceName);
					recipient = this.procureCommunicator(params[0]);
					domain = recipient.type === Communicator.CHANNEL ? recipient : speaker;
					message = trailing;
					var num:Number = message.charCodeAt(0);
					this.dispatchEvent(new ChatEvent(ChatEvent.SAY, speaker, recipient, message, domain));
					break;
				case "INVITE":
					// :Angel!wings@irc.org INVITE Wiz #Dust
					// :<speaker and domain>!<hostname> INVITE <recipient> <channel to invite>
					type = ChatEvent.INVITE;
					speaker = this.procureCommunicator(sourceName);
					recipient = this.user;
					message = params[1];
					this.dispatchEvent(new ChatEvent(type, speaker, recipient, message));
					break;
				case "RPL_WELCOME":
					this.state = Server.CONNECTED;
					this.dispatchEvent(new InfoChatEvent(
						this.procureServerCommunicator(),
						this.user,
						"Message.Server.Connected",
						trailing
					));
					break;
				case "RPL_MOTD":
					speaker = this.procureCommunicator(sourceName);
					break;
				case "ERROR":
					if(this.state === Server.DISCONNECTING) {
						// We've disconnected entirely, so send a quit and set to disconnected.
						this.dispatchEvent(new UserEvent(UserEvent.QUIT, this.user, trailing));
						this.state = Server.DISCONNECTED;
						break;	
					}	
				default:
					/*if(!command.match(/\d+/))
						throw new Error('Unknown command, "' +  command + '" in message "' + complete + '"');*/
					trace('Unhandled Message ("' + command + '"): "' + complete.replace(/[\r\n]/g, "\\n") + '"');
			}
		}
		
		// The following are functions intended to be our interface to respective clients.
		override public function joinChannel(channelName:String, password:String = null):void {
			if(this.getCommunicatorType(channelName) === Communicator.CHANNEL) {
				this.JOIN(channelName, password);		
			} else {
				this.dispatchEvent(new ChannelEvent(ChannelEvent.JOIN, this.procureCommunicator(channelName), this.user));	
			}
		}
		
		override public function leaveChannel(channelName:String):void {
			if(this.getCommunicatorType(channelName) === Communicator.CHANNEL) {
				this.PART(channelName);
			} else {
				this.dispatchEvent(new ChannelEvent(ChannelEvent.PART, this.procureCommunicator(channelName), this.user));	
			}
		}
		
		override public function changeName(newName:String):void {
			this.NICK(newName);	
		}
		
		override public function speak(fullMessage:String, domain:Communicator):void {
			for each(var message:String in fullMessage.split(/[\r\n]/g)) {
				if(domain.type === Communicator.SERVER) {
					this.sendCommand(message);
				} else {
					this.PRIVMSG(domain.name, message);
					this.dispatchEvent(new ChatEvent(
						ChatEvent.SAY,
						this.user,
						domain,
						message,
						domain
					));
				}
			}	
				
		}
		
		override public function emote(message:String, domain:Communicator):void {
			this.PRIVMSG(domain.name, "ACTION" + message);
			this.dispatchEvent(new ChatEvent(
				ChatEvent.EMOTE,
				this.user,
				domain,
				message,
				domain
			));
		}

		// Utility functions for formatting and sending messages to the server.
		private function sendTrailingCommand(...args):void {
			var trailing:String = args.pop();
			args.push(":" + trailing);
			this.sendCommand.apply(this, args);
		}

		private function sendCommand(...args):void {
			args = args.filter(function(arg:*, offset:uint, args:Array):Boolean {
				return arg !== "";
			});
			var message:String = args.join(" ");
			this.sendMessage(message + "\r\n");
		}

		// PRIVMSG IRC Protocol Command
		// Parameters: <receiver>{,<receiver>} <text to be sent>
		// Example: PRIVMSG Angel :yes I'm receiving it!
		// Observe that we don't implement multiple targets at all.
		private function PRIVMSG(targetName:String, message:String):void {
			if(message.match(/[\r\n]/))
				throw new Error("Message cannot contain newlines.");
			this.sendTrailingCommand("PRIVMSG", targetName, message);
		}

		// PASS IRC Protocol Command
		// Parameters: <password>
		// Example: PASS secretpasswordhere
		private function PASS(silent:Boolean = false, serverPassword:String = null):void {
			if(this.state !== Server.AUTHENTICATING) {
				throw new Error("PASS: Cannot be used when the server is not authenticating.");
			}
			this.serverPassword = serverPassword || this.serverPassword;
			if(this.serverPassword) {
				this.sendCommand("PASS", this.serverPassword);
			} else if(!silent) {
				throw new Error("PASS: A server password is required.");
			}
		}

		// NICK IRC Protocol Command
		// Parameters: <nickname>
		// Example: NICK Wiz
		private function NICK(newName:String = null, silent:Boolean = false):void {
			if(this.state === Server.DISCONNECTED) {
				throw new Error("NICK: Must be connected or authenticating to set or change your nickname.");
			}
			if(silent) {
				// If silent, we always send the command, and coerce if necessary.
				newName = newName || this.user.name;
			} else if(!newName) {
				// Fail if no name was provided.
				throw new Error("NICK: A nickname must be provided.");
			} else if(this.user.name === newName) {
				// Don't send if it's already our nickname.
				return;
			}
			this.sendCommand("NICK", newName);
		}

		// QUIT IRC Protocol Command
		// Parameters: [ <Quit Message> ]
		// Example: QUIT :Gone to have lunch
		private function QUIT(message:String = "RPChat - A Modern IRC Client"):void {
			if(!this.connected)
				throw new Error("QUIT: Must be connected to quit.");
			this.sendTrailingCommand("QUIT", message);
		}

		// USER IRC Protocol Command
		// RFC 1459 Parameters: <username> <hostname> <servername> <realname>
		// RFC 2812 Parameters: <username> <mode> <unused> <realname>
		// Example: USER guest 0 * :Ronnie Reagan 
		// This command seems to have a great deal of unused options available to it. In searching for what exactly these commands mean, I've seen the username 
		// faked by using the nickname multiple times (either explicitly or by default). The mode and unused parameters typically have meaning when chat occurs
		// between servers, but I haven't seen an implementation where the mode is used correctly, so they're unused here as well. 
		// The realname, however, persists throughout all clients even though I'm not sure what the value is. We will fake even this until a reason is presented not to.
		private function USER():void {
			if(this.state !== Server.AUTHENTICATING) {
				throw new Error("USER: Cannot be used when the server is not authenticating.");
			}
			// USER <username, faked> <mode, unused> <unused> <realname, faked>
			this.sendTrailingCommand("USER",  this.user.name, "0", "*", this.user.name);
		}

		// JOIN IRC Protocol Command
		// Parameters: ( <channel> *( "," <channel> ) [ <key> *( "," <key> ) ] ) / "0"
		// Example: JOIN #foobar
		// Observe that our client doesn't support multiple rooms joined at a single time.
		private function JOIN(channelName:String, keyName:String = null):void {
			if(this.state !== Server.CONNECTED)
				throw new Error("JOIN: Must be connected to a server to join channels.");
			if(!channelName)
				throw new Error("JOIN: A valid channel name must be provided.");
			this.sendCommand("JOIN", channelName, keyName);
		}
		
		// PART IRC Protocol Command
		// Parameters: <channel>{,<channel>}
		// Example: PART #twilight_zone
		// Observe that our client doesn't support leaving multiple rooms at a single time.
		private function PART(channelName:String):void {
			if(this.state !== Server.CONNECTED)
				throw new Error("PART: Must be connected to a server to leave channels.");
			if(!channelName)
				throw new Error("PART: A valid channel name must be provided.");
			this.sendCommand("PART", channelName);
		}

		// Numeric table mostly stolen from the Perl IRC module (Net::IRC).
		private static const numericReplyNames:Object = {
			"001": "RPL_WELCOME",
			"002": "RPL_YOURHOST",
			"003": "RPL_CREATED",
			"004": "RPL_MYINFO",
			"005": "RPL_FEATURELIST", 
			"200": "RPL_TRACELINK",
			"201": "RPL_TRACECONNECTING",
			"202": "RPL_TRACEHANDSHAKE",
			"203": "RPL_TRACEUNKNOWN",
			"204": "RPL_TRACEOPERATOR",
			"205": "RPL_TRACEUSER",
			"206": "RPL_TRACESERVER",
			"207": "RPL_TRACESERVICE",
			"208": "RPL_TRACENEWTYPE",
			"209": "RPL_TRACECLASS",
			"210": "RPL_TRACERECONNECT",
			"211": "RPL_STATSLINKINFO",
			"212": "RPL_STATSCOMMANDS",
			"213": "RPL_STATSCLINE",
			"214": "RPL_STATSNLINE",
			"215": "RPL_STATSILINE",
			"216": "RPL_STATSKLINE",
			"217": "RPL_STATSQLINE",
			"218": "RPL_STATSYLINE",
			"219": "RPL_ENDOFSTATS",
			"221": "RPL_UMODEIS",
			"231": "RPL_SERVICEINFO",
			"232": "RPL_ENDOFSERVICES",
			"233": "RPL_SERVICE",
			"234": "RPL_SERVLIST",
			"235": "RPL_SERVLISTEND",
			"241": "RPL_STATSLLINE",
			"242": "RPL_STATSUPTIME",
			"243": "RPL_STATSOLINE",
			"244": "RPL_STATSHLINE",
			"250": "RPL_LUSERCONNS",
			"251": "RPL_LUSERCLIENT",
			"252": "RPL_LUSEROP",
			"253": "RPL_LUSERUNKNOWN",
			"254": "RPL_LUSERCHANNELS",
			"255": "RPL_LUSERME",
			"256": "RPL_ADMINME",
			"257": "RPL_ADMINLOC1",
			"258": "RPL_ADMINLOC2",
			"259": "RPL_ADMINEMAIL",
			"261": "RPL_TRACELOG",
			"262": "RPL_ENDOFTRACE",
			"263": "RPL_TRYAGAIN",
			"265": "RPL_N_LOCAL",
			"266": "RPL_N_GLOBAL",
			"300": "RPL_NONE",
			"301": "RPL_AWAY",
			"302": "RPL_USERHOST",
			"303": "RPL_ISON",
			"305": "RPL_UNAWAY",
			"306": "RPL_NOWAWAY",
			"311": "RPL_WHOISUSER",
			"312": "RPL_WHOISSERVER",
			"313": "RPL_WHOISOPERATOR",
			"314": "RPL_WHOWASUSER",
			"315": "RPL_ENDOFWHO",
			"316": "RPL_WHOISCHANOP",
			"317": "RPL_WHOISIDLE",
			"318": "RPL_ENDOFWHOIS",
			"319": "RPL_WHOISCHANNELS",
			"321": "RPL_LISTSTART",
			"322": "RPL_LIST",
			"323": "RPL_LISTEND",
			"324": "RPL_CHANNELMODEIS",
			"329": "RPL_CHANNELCREATE",
			"331": "RPL_NOTOPIC",
			"332": "RPL_CURRENTTOPIC",
			"333": "RPL_TOPICINFO",
			"341": "RPL_INVITING",
			"342": "RPL_SUMMONING",
			"346": "RPL_INVITELIST",
			"347": "RPL_ENDOFINVITELIST",
			"348": "RPL_EXCEPTLIST",
			"349": "RPL_ENDOFEXCEPTLIST",
			"351": "RPL_VERSION",
			"352": "RPL_WHOREPLY",
			"353": "RPL_NAMREPLY",
			"361": "RPL_KILLDONE",
			"362": "RPL_CLOSING",
			"363": "RPL_CLOSEEND",
			"364": "RPL_LINKS",
			"365": "RPL_ENDOFLINKS",
			"366": "RPL_ENDOFNAMES",
			"367": "RPL_BANLIST",
			"368": "RPL_ENDOFBANLIST",
			"369": "RPL_ENDOFWHOWAS",
			"371": "RPL_INFO",
			"372": "RPL_MOTD",
			"373": "RPL_INFOSTART",
			"374": "RPL_ENDOFINFO",
			"375": "RPL_MOTDSTART",
			"376": "RPL_ENDOFMOTD",
			"377": "RPL_MOTD2", // 1997-10-16 -- tkil
			"381": "RPL_YOUREOPER",
			"382": "RPL_REHASHING",
			"384": "RPL_MYPORTIS",
			"391": "RPL_TIME",
			"392": "RPL_USERSSTART",
			"393": "RPL_USERS",
			"394": "RPL_ENDOFUSERS",
			"395": "RPL_NOUSERS",
			"401": "ERR_NOSUCHNICK",
			"402": "ERR_NOSUCHSERVER",
			"403": "ERR_NOSUCHCHANNEL",
			"404": "ERR_CANNOTSENDTOCHAN",
			"405": "ERR_TOOMANYCHANNELS",
			"406": "ERR_WASNOSUCHNICK",
			"407": "ERR_TOOMANYTARGETS",
			"409": "ERR_NOORIGIN",
			"411": "ERR_NORECIPIENT",
			"412": "ERR_NOTEXTTOSEND",
			"413": "ERR_NOTOPLEVEL",
			"414": "ERR_WILDTOPLEVEL",
			"421": "ERR_UNKNOWNCOMMAND",
			"422": "ERR_NOMOTD",
			"423": "ERR_NOADMININFO",
			"424": "ERR_FILEERROR",
			"431": "ERR_NONICKNAMEGIVEN",
			"432": "ERR_ERRONEUSNICKNAME", // sic
			"433": "ERR_NICKNAMEINUSE",
			"436": "ERR_NICKCOLLISION",
			"437": "ERR_UNAVAILRESOURCE",
			"441": "ERR_USERNOTINCHANNEL",
			"442": "ERR_NOTONCHANNEL",
			"443": "ERR_USERONCHANNEL",
			"444": "ERR_NOLOGIN",
			"445": "ERR_SUMMONDISABLED",
			"446": "ERR_USERSDISABLED",
			"451": "ERR_NOTREGISTERED",
			"461": "ERR_NEEDMOREPARAMS",
			"462": "ERR_ALREADYREGISTERED",
			"463": "ERR_NOPERMFORHOST",
			"464": "ERR_PASSWDMISMATCH",
			"465": "ERR_YOUREBANNEDCREEP", // sic
			"466": "ERR_YOUWILLBEBANNED",
			"467": "ERR_KEYSET",
			"471": "ERR_CHANNELISFULL",
			"472": "ERR_UNKNOWNMODE",
			"473": "ERR_INVITEONLYCHAN",
			"474": "ERR_BANNEDFROMCHAN",
			"475": "ERR_BADCHANNELKEY",
			"476": "ERR_BADCHANMASK",
			"477": "ERR_NOCHANMODES", 
			"478": "ERR_BANLISTFULL",
			"481": "ERR_NOPRIVILEGES",
			"482": "ERR_CHANOPRIVSNEEDED",
			"483": "ERR_CANTKILLSERVER",
			"484": "ERR_RESTRICTED",   // Connection is restricted
			"485": "ERR_UNIQOPPRIVSNEEDED",
			"491": "ERR_NOOPERHOST",
			"492": "ERR_NOSERVICEHOST",
			"501": "ERR_UMODEUNKNOWNFLAG",
			"502": "ERR_USERSDONTMATCH"
		}

	}
}
