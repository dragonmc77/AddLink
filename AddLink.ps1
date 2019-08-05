function global:AddLinkMetaCritic()
{
    $searchUrl = "https://www.metacritic.com/search/game/{0}/results?plats[3]=1&search_type=advanced"
    $gameUrlTemplate = "https://www.metacritic.com/game/pc/{0}"
    $scriptPath = "$env:appdata\Playnite\Extensions\AddLink"

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$scriptPath\debug.log" -Value "Game: $($game.Name)"
        #build the MetaCritic url for the game
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace(":","").Replace(".","").Replace("'","").Replace("&","").Replace("  "," ")
        Add-Content -Path "$scriptPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already a MetaCritic link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "MetaCritic"}) {
            Add-Content -Path "$scriptPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        #launch the urls. this should open them in the default browser
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if ($response.Result -and $response.SelectedString.Length -eq 0) {
            $gameUrl = $response.SelectedString
            Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl Prompt: (empty)"
        } elseif (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("MetaCritic",$gameUrl)
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$scriptPath\debug.log" -Value "link added: $gameUrl"
        }
        Start-Sleep -Seconds 5
    }
}
function global:AddLinkIGDB()
{
    $searchUrl = "https://www.igdb.com/search?utf8=%E2%9C%93&type=1&q={0}"
    $gameUrlTemplate = "https://www.igdb.com/games/{0}"
    $scriptPath = "$env:appdata\Playnite\Extensions\AddLink"

    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        Add-Content -Path "$scriptPath\debug.log" -Value "Game: $($game.Name)"
        #build the IGDB url for the game
        $urlFriendlyName = $game.Name.ToLower().Replace(" ","-").Replace("/","slash")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"[:\.'&,!]","")
        $urlFriendlyName = [regex]::Replace($urlFriendlyName,"-{2,}","-")

        Add-Content -Path "$scriptPath\debug.log" -Value "urlFriendlyName: $urlFriendlyName"
        $gameUrl = $gameUrlTemplate -f $urlFriendlyName
        Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl: $gameUrl"

        # if there is already an IGDB link, skip this game
        if ($game.Links | Where-Object {$_.Name -eq "IGDB"}) {
            Add-Content -Path "$scriptPath\debug.log" -Value "Skip game: $($game.Name)"
            continue
        }

        #launch the urls. this should open it in the default browser
        Start-Process ($searchUrl -f $game.Name)
        Start-Process $gameUrl

        # ask if this is the correct url
        $response = $PlayniteApi.Dialogs.SelectString("Is this the correct page for this game?","$($game.Name)","$gameUrl")

        # set the final game url based on the response
        if ($response.Result -and $response.SelectedString.Length -eq 0) {
            $gameUrl = $response.SelectedString
            Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl Prompt: (empty)"
        } elseif (-not $response.Result) {
            $gameUrl = ""
            Add-Content -Path "$scriptPath\debug.log" -Value "gameUrl Prompt: (cancel)"
        }

        # add the link to the game
        if ($gameUrl.Length -gt 0) {
            $link = [Playnite.SDK.Models.Link]::New("IGDB",$gameUrl)
            $game.Links.Add($link)
            $PlayniteApi.Database.Games.Update($game)
            Add-Content -Path "$scriptPath\debug.log" -Value "link added: $gameUrl"
        }
        Start-Sleep -Seconds 5
    }
}
function global:FixLink()
{
    # retrieve the currently selected games
    $selection = $PlayniteApi.MainView.SelectedGames

    foreach ($game in $selection) {
        $link = $game.Links | Where-Object {$_.Url.StartsWith("https://www.igdb")}
        if ($link -ne $null) {$link.Name = "IGDB"}
        $PlayniteApi.Database.Games.Update($game)
    }
}