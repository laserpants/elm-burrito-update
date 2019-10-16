module Burrito.Update.Browser exposing (application, document)

{-|

@docs application, document

-}

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Burrito.Update exposing (Update, run, run2, run3)
import Url exposing (Url)


{-| Used as a drop-in replacement for `Browser.application`, but instead creates a `Program`
where `init` and `update` are based on the `Update` type of this library.

    init : flags -> Url -> Navigation.Key -> Update model msg

    update : msg -> model -> Update model msg

-}
application :
    { init : flags -> Url -> Navigation.Key -> Update model msg
    , onUrlChange : Url -> msg
    , onUrlRequest : UrlRequest -> msg
    , subscriptions : model -> Sub msg
    , update : msg -> model -> Update model msg
    , view : model -> Document msg
    }
    -> Program flags model msg
application config =
    Browser.application
        { init = run3 config.init
        , update = run2 config.update
        , subscriptions = config.subscriptions
        , view = config.view
        , onUrlChange = config.onUrlChange
        , onUrlRequest = config.onUrlRequest
        }


{-| Used as a drop-in replacement for `Browser.document`, but instead creates a `Program`
where `init` and `update` are based on the `Update` type of this library.

    init : flags -> Update model msg

    update : msg -> model -> Update model msg

-}
document :
    { init : flags -> Update model msg
    , subscriptions : model -> Sub msg
    , update : msg -> model -> Update model msg
    , view : model -> Document msg
    }
    -> Program flags model msg
document config =
    Browser.document
        { init = run config.init
        , update = run2 config.update
        , subscriptions = config.subscriptions
        , view = config.view
        }
