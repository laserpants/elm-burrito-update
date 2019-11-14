module Main exposing (main)

import App exposing (Flags, Msg(..), State, init, subscriptions, update, view)
import Burrito.Router as Router
import Burrito.Update.Browser exposing (application)


main : Program Flags State Msg
main =
    application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , onUrlChange = RouterMsg << Router.UrlChange
        , onUrlRequest = RouterMsg << Router.UrlRequest
        }
