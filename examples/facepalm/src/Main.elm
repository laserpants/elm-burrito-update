module Main exposing (main)

import App exposing (Flags, Msg(..), State, init, subscriptions, update, view)
import Burrito.Update.Browser exposing (application)
import Burrito.Update.Router as Router


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
