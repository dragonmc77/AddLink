# AddLink
AddLink Extension for Playnite

Install as any extension:
1. Create a folder called AddLink in %appdata%\Playnite\Extensions.
2. Copy the two files (Addlink.ps1 and extension.yaml) to the folder.
3. Make sure the extension is enabled in Playnite -> Settings -> Extensions.

To use, select one or multiple games and run the appropriate command from the Extensions menu.

NOTES:
I value accuracy over speed, so this extension is designed to confirm all links added. In most cases, this means simply clicking OK on a confirmation dialog box for each game because the code is pretty good at guessing the correct IGDB or MetaCritic URL for the game.

When running the extension goes through each game and opens up two web pages. One is the best attempt at the correct URL for the game. If this URL is correct (i.e. you see the page for the game load) then simply click OK on the dialog box and it will add a link and move to the next game. If not correct, the second page is a search of the game on the site. You can copy the correct link for the game and paste it in the dialog box in Playnite to add the link.

Also, there is a 5 second wait timer built in between games, because attempting to load pages too fast from either of these sites will trigger an error and timeout before you are allowed access again. Refer to the code for the particulars.
