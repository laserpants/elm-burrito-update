module Main exposing (main)

import Browser exposing (Document)
import Burrito.Update exposing (..)
import Burrito.Update.Browser exposing (document)
import Html exposing (..)
import Html.Events exposing (..)


type Msg
    = ButtonClicked


type alias Model =
    { message : String
    }


setMessage : String -> Model -> PlainUpdate Model msg
setMessage message model =
    save { model | message = message }


init : () -> PlainUpdate Model Msg
init () =
    save Model
        |> andMap (save "Nothing much going on here.")


update : Msg -> Model -> PlainUpdate Model Msg
update msg =
    case msg of
        ButtonClicked ->
            setMessage "The button was clicked!"


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
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
