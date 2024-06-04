##############################################################################
#                                                                            #
# PowerGuardian - A simple, LightWight Telegram bot sctipt in PowerShell     #
# Written by: Xylex S Rayne © 2024                                           #
#                                                                            #
#                                                                            #
#   Github: https://github.com/ZapDragon/PowerGuardian                       #
#                                                                            #
#   Bot API Docs: http://core.telegram.org/bots/api                          #
#                                                                            #
##############################################################################


# To run this script, you will need to run a PowerShell window as Admin,
# and run "Set-ExecutionPolicy Bypass" - Windows Wont run any PS Scripts without doing this.
# Then cd to the folder where this script is, and run it '.\PowerGuardian.ps1'



# This places the database next to this script - Change the filename if you want.
$Script:DatabasePath = "$PSScriptRoot\BotDatabase.txt"

# Boiler-plate functions

#Log handler.
# LogLevel system to ignore events you only see when it matters.
# Date-Stamped Lines
# Color coded Severities

enum LogLevel
{
  DBUG  = 6		# DEBUG
  INFO  = 5		# INFO
  INTR	= 4		# INTEREST
  WARN  = 3		# WARN
  EROR  = 2		# ERROR
  CRIT  = 1		# CRITICAL
  ALWS	= 0		# ALWAYS
}

function ConsoleLog([LogLevel] $Level, [string] $Text)
{
	if (-not ($Global:LogLevel)) { $Global:LogLevel = [LogLevel]::INFO }
	if ($Level -le $Global:LogLevel)
	{
		$TimeStamp = [DateTime]::Now.ToString('yyyy\.mm\.dd hh\:mm\:ss')
		$Color = [System.ConsoleColor]::White
		$LevelString = $Level.ToString()
		$Prefix = "($TimeStamp) » [$LevelString] » "
		if ($Level -eq 6) { $Color = [System.ConsoleColor]::DarkGray }
		if ($Level -eq 5) { $Color = [System.ConsoleColor]::Gray }
		if ($Level -eq 4) { $Color = [System.ConsoleColor]::Cyan }
		if ($Level -eq 3) { $Color = [System.ConsoleColor]::Yellow }
		if ($Level -eq 2) { $Color = [System.ConsoleColor]::Red }
		if ($Level -eq 1) { $Color = [System.ConsoleColor]::DarkRed }
		if ($Level -eq 0) { $Color = [System.ConsoleColor]::Magenta }

		Write-Host -NoNewLine $Prefix
		Write-Host $Text -ForegroundColor $Color
	}
}

$Global:LogLevel = [LogLevel]::INFO


# Gets the bot ready
# It loads the DB, gets the bot's Info, Checks if the Bot can execute commands,
# displays the bot's Info, checks for debug mode, and sets it, then starts the Bot's main function.
function StartBot()
{
	LoadDatabase
	
	$Script:Bot = getMe
	
	if (-not ($Script:Bot))
	{
		ConsoleLog 1 "Object Type $($Script:Bot.GetType())"
		ConsoleLog 1 "Bot failed to getMe()"
		[Console]::ReadLine()
		exit
	}
	
	# Prints the bot's Info on success.
	Write-Host "($($Script:Bot.id))" -NoNewLine -ForegroundColor Red
	Write-Host " $($Script:Bot.first_name)" -NoNewLine -ForegroundColor Yellow
	Write-Host " ($($Script:Bot.username))" -ForegroundColor Green
	
	if ($Script:Config.debug_mode)
	{
		ConsoleLog 0 "Debug Mode Enabled"
		$Script:DebugPrint = $True
		$Global:LogLevel = [LogLevel]::Debug
	}
	else
	{
		ConsoleLog 0 "Debug Mode Disabled"
		$Script:DebugPrint = $False
		$Script:LogChannel = $Script:Config.admin_chat
	}
	
	Polling
}

### Bot Thread Function

function Polling()
{	
	# The bot needs to keep track of the update id, to avoid getting duplicates.
	$Script:UpdateID = 0
	
	# Since we dont know what Update Id we're on, we need 1 update, at offset 0, and we'll wait 3 minutes before timing out.
	$Payload = getUpdates 0 180 1
	$Updates = @{}
	sendMessage $Script:Config.admin_chat 'Bot is Online' | Out-Null
	ConsoleLog 5 'Bot Is Online'
	while ($True)
	{
		if ($Payload.ok) { $Updates = $Payload.result }
		else { continue }
		
		# This loops through all the updates, getting the new Update Id, and passes it to ParseUpdate()
		foreach ($Update in $Updates) { $Script:UpdateID = ($Update.update_id + 1); ParseUpdate $Update }
		
		# This requests all updates, up to 100 at a time (the max) and processes them all at once.
		$Payload = getUpdates $Script:UpdateID 60 100
		[Console]::Title = ('Update ID: ' + $Script:UpdateID)
	}
}

# This determines what kind of "update" this is, and executes code based on it.
function ParseUpdate($Update)
{
	# Any messages to the bot, or Messages seen in a Group.
	if ($Update.message -ne $Null)
	{
		# Put the Message in a shorter Variable
		$msg = $Update.message
		
		# If this a command, remove the command character, split the command on the space character, and pass it to the command parser.
		if ($msg.text.StartsWith('/') -or $msg.text.StartsWith('!'))
		{
			$msg.text = $msg.text.Remove(0, 1) 
			$cmd = $msg.text.Split(' ')
			BotCommand $msg $cmd
		}
		# Process non-command message. Any message that does not start with a ! or a / will go in this else block.
		else
		{
			
		}
	}
	# Telegram really needs to stop adding more of these.
	elseif ($Update.edited_message -ne $Null) {}
	elseif ($Update.channel_post -ne $Null) {}
	elseif ($Update.edited_channel_post -ne $Null) {}
	elseif ($Update.business_connection -ne $Null) {}
	elseif ($Update.business_message -ne $Null) {}
	elseif ($Update.edited_business_message -ne $Null) {}
	elseif ($Update.deleted_business_messages -ne $Null) {}
	elseif ($Update.message_reaction -ne $Null) {}
	elseif ($Update.message_reaction_count -ne $Null) {}
	elseif ($Update.inline_query -ne $Null) {}
	elseif ($Update.chosen_inline_result -ne $Null) {}
	elseif ($Update.callback_query -ne $Null) {}
	elseif ($Update.shipping_query -ne $Null) {}
	elseif ($Update.pre_checkout_query -ne $Null) {}
	elseif ($Update.poll -ne $Null) {}
	elseif ($Update.poll_answer -ne $Null) {}
	elseif ($Update.my_chat_member -ne $Null) {}
	elseif ($Update.chat_member -ne $Null) {}
	elseif ($Update.chat_join_request -ne $Null) {}
	elseif ($Update.chat_boost -ne $Null) {}
	elseif ($Update.removed_chat_boost -ne $Null) {}
	else { ConsoleLog 3 'Unknown Update' }
}

# 
function BotCommand($msg, $cmd)
{
	# A Parsed message update will ALWAYS come here. This is where you put any logic for commands.
	if ($cmd[0] -eq 'start')
	{
		sendMessage $msg.chat.id 'Hello! :D' | Out-Null
	}
}

function LoadDatabase()
{
	# If the database file doesnt exist, the bot will ask for a token, and a chat id to send messages to.
	# Then it will test the info, and save it to a new Database file.
	if (-not(Test-Path($Script:DatabasePath)))
	{
		$Script:Config = @{}
		$Script:Config.Add('token', 'Contact @BotFather For a Token')
		$Script:Config.Add('user_agent', 'PowerGuardian/1.1 (Windows NT 10.0, Win64, x64)')
		$Script:Config.Add('api_server', 'https://api.telegram.org/bot')
		$Script:Config.Add('admin_chat', 'User Id, Group Id, or Channel Id. Bot must be in the chat, or you need to /start the bot for a user id.')
		$Script:Config.Add('allowed_updates', [System.Collections.Generic.List[System.Object]]::new())
		$Script:Config.Add('debug_mode', $True)
		
		# Look at the ParseUpdate function above. The fields being checked if they are null, they are valid here.
		# Or check https://core.telegram.org/bots/api#getting-updates - All fields under 'Field' are valid here to enable the bot to get those updates.
		$Script:Config.allowed_updates.AddRange(@('message', 'my_chat_member', 'chat_member', 'callback_query'))
		
		while ($True)
		{
			Write-host ''
			Write-host ''
			Write-host 'You need to provide a bot token. You can get that from @BotFather'
			Write-host 'Enter Bot Token: ' -NoNewLine
			$Token = [Console]::ReadLine()
			
			Write-host ''
			Write-host ''
			Write-host 'You need to provide a chat id, or Your ID. You can get that from @UserInfoBot'
			Write-host 'Enter Admin Chat id: ' -NoNewLine
			$AdminChat = [Console]::ReadLine()
			
			clear
			Write-host "Alright, I am going to test the information you've given me. Press any key to proceed..."
			[void] [Console]::ReadKey()
			
			if (testApiToken($Token))
			{
				Write-Host 'Press any key to save this info, and start your bot.'
				[void] [Console]::Readkey()
				$Script:Config.token = $Token
				$Script:Config.admin_chat = $AdminChat
				break;
			}
			else
			{
				Write-Host 'Press any key to enter the information again.'
				[void] [Console]::Readkey()
				continue;
			}
			
		}
		
		ConsoleLog 3 'New Database Created'
		$Script:Config | ConvertTo-Json | Out-String | Out-File -FilePath $Script:DatabasePath -NoClobber
	}
	else
	{
		# Loads the existing database and runs the bot.
		$Script:Config = Get-Content $Script:DatabasePath | Out-String | ConvertFrom-Json
	}
}

### Telegram Bot Methods - Below are the methods for doing anything on the bot API.

# Core Method for sending requests to Telegram - This is not an official function, but helps consolidate code mess for the official ones. All API Functions call this.
function sendRequest
{
	[CmdletBinding()]
    Param(
        [string] $Method,
        [string] $RequestType = 'POST',
        [string] $ContentType = 'application/json',
		[PSCustomObject] $Payload = $Null
    )
	
	#ConsoleLog 4 'SendRequest'
	$Body = ''
	if (![String]::IsNullOrEmpty($Payload)) { $Body = $($Payload | ConvertTo-Json -Compress | Out-String) }
	$URI = ($Script:Config.api_server + $Script:Config.token + '/' + $Method)
	if ($Script:DebugPrint)
	{
		#ConsoleLog 0 "$Method"
		ConsoleLog 6 $URI
		ConsoleLog 6 $Body
	}
	
	if ($RequestType -eq 'GET')
	{
		$Response = @{}
		try { $Response = Invoke-WebRequest -Uri $URI -UserAgent $Script:Config.user_agent }
		catch
		{
			# HTTP GET Failure return
			return @{
				ok=$False;
				method=$Method;
				payload=$Null;
				description=('WebRequest Error: ' + $($_.ErrorDetails) + ' ' + $($_.Exception.ToString().Replace('"','')));
				result=$Null;
			}
		}
		return $Response.Content | Out-String | ConvertFrom-Json
	}
	elseif ($RequestType -eq 'POST')
	{
		$Response = @{}
		try { $Response = Invoke-WebRequest -Method 'POST' -ContentType $ContentType -Uri $URI -Body $Body -UserAgent $Script:Config.user_agent }
		catch
		{
			# HTTP POST Failure return
			return @{
				ok=$False;
				method=$Method;
				payload=$($Body | ConvertTo-Json);
				description=('WebRequest Error: ' + $($_.ErrorDetails) + ' ' + $($_.Exception.ToString().Replace('"','')));
				result=$Null;
			}
		}
		return $Response.Content | Out-String | ConvertFrom-Json
	}
	
	ConsoleLog 1 ('sendRequest - Bad Request Type - ' + $RequestType)
	return $False
}

function testApiToken($Token)
{
	$URI = ('https://api.telegram.org/bot' + $Token + '/getMe')
	try
	{
		$Bot = ((Invoke-WebRequest -Method 'POST' -ContentType 'application/json' -Uri $URI -UserAgent $Script:Config.user_agent).Content | ConvertFrom-Json).result
		ConsoleLog 5  'Congrats! You now have a simple bot running. Below are the details of your bot.'
		$Bot | Select -Property name,id,username
		return
	}
	catch
	{
		#This bizare shit makes the error not print to the console. $_ is the caught exception object.
		$_ | Out-Null
		ConsoleLog 3 'There seems to be a problem. The token you gave me didnt work.'
		return
	}
}

function getMe()
{
	$Me = sendRequest -Method 'getMe' -RequestType 'GET'
	if (-not($Me)) { ConsoleLog 1 'getMe Failed'; Read-Host 'Press Enter to continue...' | Out-Null; return $False }
	elseif (-not($Me.ok)) { ConsoleLog 2 'getMe Failed'; return $False }
	else { return $Me.result }
}

function getUpdates($offset = 0, $timeout = 60, $limit = 100, $allowed_updates = @('message','channel_post','callback_query','my_chat_member'))
{
	$Payload = @{offset=$offset;timeout=$timeout;limit=$limit;allowed_updates=$allowed_updates}
	return sendRequest -Method 'getUpdates' -Payload $Payload
}

function sendMessage($chat_id, $text, $markdown = 'HTML', $keyboard = $False)
{
	$markdown = $markdown.ToLower()
	$Payload = @{chat_id=$chat_id;text=$text}
	if (($Markdown -eq 'html') -or ($Markdown -eq 'markdown') -or ($Markdown -eq 'markdownv2')) { $Payload.Add('parse_mode', $markdown) }
	if ($keyboard) { $Payload.Add('reply_markup', $keyboard) }
	return sendRequest -Method 'sendMessage' -Payload $Payload
}

function sendReply($chat_id, $message_id, $text, $markdown = 'HTML', $keyboard = $False)
{
	$Payload = @{chat_id=$chat_id;reply_to_message_id=$message_id;text=$text}
	
	if (($Keyboard -ne $Null) -and ($Keyboard -ne $False)) { $Payload.Add('reply_markup', $Keyboard) }
	if (($Markdown -eq 'html') -or ($Markdown -eq 'markdown') -or ($Markdown -eq 'markdownv2')) { $Payload.Add('parse_mode', $markdown) }
	
	$Reply = sendRequest -Method 'sendMessage' -Payload $Payload
	if (-not($Reply.ok)) { ConsoleLog 2 "sendReply Error: $($Reply.description)" }
	return $Reply
}

function deleteMessage($chat_id, $message_id)
{
	$Payload = @{chat_id=$chat_id;message_id=$message_id;}
	return sendRequest -Method 'deleteMessage' -Payload $Payload
}

StartBot


### DEV NOTES

## TODO
#> Methods - Working on a tool to generate a custom source file that contains ALL Telegram methods.
#> Exceptions - Telegram has a vast number of exceptions that can be returned. This will be added.
#> DataBase - This isnt very clean code. It needs some improvements, and consolidation