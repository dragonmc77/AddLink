function OnApplicationStarted()
{
    $__logger.Info("OnApplicationStarted")
}

function OnApplicationStopped()
{
    $__logger.Info("OnApplicationStopped")
}

function OnLibraryUpdated()
{
    $__logger.Info("OnLibraryUpdated")
}

function OnGameStarting()
{
    param($evnArgs)
    $__logger.Info("OnGameStarting $($evnArgs.Game)")
}

function OnGameStarted()
{
    param($evnArgs)
    $__logger.Info("OnGameStarted $($evnArgs.Game)")
}

function OnGameStopped()
{
    param($evnArgs)
    $__logger.Info("OnGameStopped $($evnArgs.Game) $($evnArgs.ElapsedSeconds)")
}

function OnGameInstalled()
{
    param($evnArgs)
    $__logger.Info("OnGameInstalled $($evnArgs.Game)")
}

function OnGameUninstalled()
{
    param($evnArgs)
    $__logger.Info("OnGameUninstalled $($evnArgs.Game)")
}

function OnGameSelected()
{
    param($gameSelectionEventArgs)
    $__logger.Info("OnGameSelected $($gameSelectionEventArgs.OldValue) -> $($gameSelectionEventArgs.NewValue)")
}

function AddLinkMetaCritic()
{
    $searchUrl = "https://www.metacritic.com/search/game/{0}/results?plats[3]=1&search_type=advanced"
    $gameUrlTemplate = "https://www.metacritic.com/game/pc/{0}"
    
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000
    
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the MetaCritic url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace(":","").Replace(".","").Replace("'","").Replace("&","").Replace("  "," ")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already a MetaCritic link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "MetaCritic"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box #>
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl
        $startTime = Get-Date

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        } else {
            $gameUrl = $response.SelectedString
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("MetaCritic",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timeElapsed = ((Get-Date) - $startTime).TotalMilliseconds
        if ($timeElapsed -lt $interval) {Start-Sleep -Milliseconds ($interval - $timeElapsed)}
    }
}
function AddLinkIGDB()
{
    param(
        $scriptMainMenuItemActionArgs
    )

    $searchUrl = "https://www.igdb.com/search?utf8=%E2%9C%93&type=1&q={0}"
    $gameUrlTemplate = "https://www.igdb.com/games/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the IGDB url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace("/","slash")
        $urlFriendlyName = $urlFriendlyName.Replace("&","and").Replace("'","-")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"[:\.,!]","")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"-{2,}","-")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already an IGDB link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "IGDB"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box
        #>
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl
        $startTime = Get-Date

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        } else {
            $gameUrl = $response.SelectedString
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("IGDB",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timeElapsed = ((Get-Date) - $startTime).TotalMilliseconds
        if ($timeElapsed -lt $interval) {Start-Sleep -Milliseconds ($interval - $timeElapsed)}
    }
}
function FixLinkMetaCritic()
{
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        $link = $game.Links | Where-Object {$_.Name -eq "MetaCritic"}
        if ($link) {
            try {
                Invoke-WebRequest -Uri $link.Url
            } catch {
                Add-Content -Path "$logPath\debug.log" -Value "Fixing Game: $($game.Name)"
                try {
                    $game.Links.Remove($link)
                    $game.Version = "FixMetaCritic"
                    $PlayniteApi.Database.Games.Update($game)
                } catch {Add-Content -Path "$logPath\debug.log" -Value "Error removing link: $($game.Name)"}
            }
        }
        Start-Sleep -Seconds 5
    }
}
function FixLinkIGDB()
{
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        $link = $game.Links | Where-Object {$_.Name -eq "IGDB"}
        if ($link) {
            try {
                Invoke-WebRequest -Uri $link.Url
            } catch {
                Add-Content -Path "$logPath\debug.log" -Value "Fixing Game: $($game.Name)"
                try {
                    $game.Links.Remove($link)
                    $game.Version = "FixIGDB"
                    $PlayniteApi.Database.Games.Update($game)
                } catch {Add-Content -Path "$logPath\debug.log" -Value "Error removing link: $($game.Name)"}
            }
        }
        Start-Sleep -Seconds 5
    }
}
function AddLinkGamesDatabase()
{
    $searchUrl = "https://www.gamesdatabase.org/list.aspx?in=1&searchtext={0}&searchtype=1"
    $gameUrlTemplate = "https://www.gamesdatabase.org/game/valve-steam/{0}"
    <#  logPath is used for logging to a text file for debug purposes. if Playnite is running in Install mode, this path
        will be the extension folder in %appdata%
        otherwise, it will be a temp folder to avoid any permissions issues
    #>
    $logPath = "$env:appdata\Playnite\Extensions\AddLink"
    if (-not (Test-Path $logPath)) {$logPath = [IO.Path]::GetTempPath()}
    <#  the minimum time in milliseconds between processing each game
        this avoids 429 errors, as both IGDB and MetaCritic have rate limiting and velocity checks
        after some rudimentary testing, an interval of 5 seconds was deemed adequate
    #>
    $interval = 5000

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$logPath\debug.log" -Value "Game: $($game.Name)"
        <#  build the GamesDatabase url for the game
            this is a best guess based on the url structure used for games on the site
            this works best if the game name on Playnite is as close as possible to the official name of the game
        #>
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"[:\.'&,!]","")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"-{2,}","-")
        Add-Content -Path "$logPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$logPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already an GamesDatabase link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "GamesDatabase"}) {
            Add-Content -Path "$logPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        <# launch the urls. this should open them in the default browser
            one page is an attempt to open the actual page for the game on the site, based on a best effort to guess the correct url
            this should work for the majority of games
            second page is a search page for the game on the site, in case the scripts attempt at the actual game URL is incorrect
            in this case, the user can copy the correct link to the game from the search page and paste it in the dialog box
        #>
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl
        $startTime = Get-Date

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$logPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        } else {
            $gameUrl = $response.SelectedString
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("GamesDatabase",$gameUrl)
            # if the game has never had any links, a new Links collection will have to be initialized and assigned to the Links property
            if (-not $game.Links) {
                $Links = New-Object System.Collections.ObjectModel.ObservableCollection[Playnite.SDK.Models.Link]
                $game.Links = $Links
            }
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$logPath\debug.log" -Value "link added: $gameUrl"
        }
        $timeElapsed = ((Get-Date) - $startTime).TotalMilliseconds
        if ($timeElapsed -lt $interval) {Start-Sleep -Milliseconds ($interval - $timeElapsed)}
    }
}

function GetMainMenuItems()
{
    param(
        $getMainMenuItemsArgs
    )

    $menuItem = New-Object Playnite.SDK.Plugins.ScriptMainMenuItem
    $menuItem.Description = "Add IGDB link"
    $menuItem.FunctionName = "AddLinkIGDB"
    $menuItem.MenuSection = "@"
	return $menuItem
}