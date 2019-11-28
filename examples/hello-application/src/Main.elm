module Main exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Navigation
import Burrito.Update exposing (..)
import Burrito.Update.Browser exposing (application)
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


setMessage : String -> Model -> Update Model msg a
setMessage message model =
    save { model | message = message }


init : () -> Url -> Navigation.Key -> Update Model Msg a
init () url key =
    save Model
        |> andMap (save "Nothing much going on here.")


update : Msg -> Model -> Update Model Msg a
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
