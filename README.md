# PowerGuardian
 A Light-Weight Telegram bot in PowerShell

I wrote this as a small personal test/challenge to see how easy a Telegram bot in PowerShell would be.

This is aimed at users learning PowerShell, Telegram bots, or learning to code in general with a fun goal in mind.

## Getting Started
- Simply grab PowerGuardian.ps1
- Windows Only: Open a new PowerShell Window as Administrator
- Windows Only: Run 'Set-ExecutionPolicy Bypass' - Windows will not let you run scripts without doing this.
- cd to the Directory where you have PowerGuardian, and execute it. '.\PowerGuardian.ps1'
- Contact http://t.me/BotFather and create a new bot with /newbot
- Copy the Access token from BotFather and paste it into PowerGuardian, press Enter
- Next Contact http://t.me/UserInfoBot and do /start
- It will give you your Telegram Account ID
- Copy Your ID and paste it into PowerGuardian and press Enter
- It will test your token, and if successful, it will save your config file as "Database.txt"

## Editing The Code

- You will need to reference the Bot API Docs to understand how all the objects are nested,
What commands will do what, and a very broad overview of limitations.

- Within the BotCommand function, you can change or add commands, and do anything with the $msg object you need.
You can uncomment the $msg | ConvertTo-Json line to see what a message object looks like, and how you can use this for your needs.

- If youre feeling adventurous, you can play around with the fields in the ParseUpdate function.
That entire if/elseif block is required for the script to determine what kind of "update" was sent to it.
message is the most common, and its where you will probably do most code.

### More Details and Edits to come
