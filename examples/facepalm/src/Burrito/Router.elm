module Burrito.Router exposing (Msg(..), State, StateUpdate, init, redirect, update)

import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation
import Burrito.Update exposing (Update, addCmd, andApply, save, using)
import Url exposing (Url)


type Msg
    = UrlChange Url
    | UrlRequest UrlRequest


type alias State route =
    { route : Maybe route
    , key : Navigation.Key
    , fromUrl : Url -> Maybe route
    , basePath : String
    }


type alias StateUpdate route a =
    State route -> Update (State route) Msg a


setRoute : Maybe route -> StateUpdate route a
setRoute route state =
    save { state | route = route }


init : (Url -> Maybe route) -> String -> Navigation.Key -> Update (State route) msg a
init fromUrl basePath key =
    save
        { route = Nothing
        , key = key
        , fromUrl = fromUrl
        , basePath = basePath
        }


redirect : String -> StateUpdate route a
redirect href =
    using (\{ key, basePath } -> addCmd (Navigation.replaceUrl key (basePath ++ href)))


update :
    Msg
    -> { onRouteChange : Url -> Maybe route -> a }
    -> StateUpdate route a
update msg { onRouteChange } =
    using
        (\{ basePath, key, fromUrl } ->
            case msg of
                UrlChange url ->
                    let
                        path =
                            String.dropLeft (String.length basePath) url.path

                        route =
                            fromUrl { url | path = path }
                    in
                    setRoute route
                        >> andApply (onRouteChange url route)

                UrlRequest (Browser.Internal url) ->
                    let
                        urlStr =
                            Url.toString { url | path = basePath ++ url.path }
                    in
                    addCmd (Navigation.pushUrl key urlStr)

                UrlRequest (Browser.External "") ->
                    save

                UrlRequest (Browser.External href) ->
                    addCmd (Navigation.load href)
        )
