module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Burrito.Update exposing (andMap, andThen, save, with)
import Burrito.Update.Browser exposing (application)
import Burrito.Update.Simple exposing (Update)
import Html exposing (..)
import Html.Events exposing (..)
import Url exposing (Url)


type Msg
    = ButtonClicked
    | OnUrlChange Url
    | OnUrlRequest UrlRequest


type alias Model =
    { message : String
    }


setMessage : String -> Model -> Update Model msg
setMessage message model =
    save { model | message = message }


init : () -> Url -> Navigation.Key -> Update Model Msg
init () url key =
    save Model
        |> andMap (save "Nothing much going on here.")


update : Msg -> Model -> Update Model Msg
update msg =
    case msg of
        ButtonClicked ->
            setMessage "The button was clicked!"

        OnUrlChange url ->
            save

        OnUrlRequest urlRequest ->
            save


view : Model -> Document Msg
view { message } =
    { title = ""
    , body =
        [ div []
            [ text message
            ]
        , div []
            [ button [ onClick ButtonClicked ] [ text "Click me" ]
            ]
        ]
    }


main : Program () Model Msg
main =
    application
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
