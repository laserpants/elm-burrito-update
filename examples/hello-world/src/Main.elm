module Main exposing (main)

import Browser exposing (Document, document)
import Html exposing (..)
import Html.Events exposing (..)


type alias Flags =
    ()


type Msg
    = IncrementAyes
    | IncrementNays


type alias Model =
    { ayes : Int
    , nays : Int
    }


init flags =
    ( { ayes = 0, nays = 0 }, Cmd.none )


update msg model =
    case msg of
        IncrementAyes ->
            ( { model | ayes = model.ayes + 1 }, Cmd.none )

        IncrementNays ->
            ( { model | nays = model.nays + 1 }, Cmd.none )


view model =
    { title = ""
    , body =
        [ div [] 
            [ text ("Ayes : " ++ String.fromInt model.ayes)
            ]
        , div [] 
            [ text ("Nays: " ++ String.fromInt model.nays)
            ]
        , div [] 
            [ button 
                [ onClick IncrementAyes ]  
                [ text "Aye" ]
            , button 
                [ onClick IncrementNays ]  
                [ text "Nay" ]
            ]
        ]
    }


main : Program Flags Model Msg
main =
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }



--import Browser exposing (Document)
--import Burrito.Update.Browser exposing (document)
--import Burrito.Update exposing (..)
--import Html exposing (..)
--import Html.Events exposing (..)
--
--
--type Msg
--    = ButtonClicked
--
--
--type alias Model =
--    { message : String
--    , count : Int
--    }
--
--
--setMessage : String -> Model -> Update Model msg a
--setMessage message model =
--    save { model | message = message }
--
--
--incrementCounter : Model -> Update Model msg a
--incrementCounter model =
--    save { model | count = model.count + 1 }
--
--
--init : () -> Update Model Msg a
--init () =
--    save Model
--        |> andMap (save "Nothing much going on here.")
--        |> andMap (save 0)
--
--
--update : Msg -> Model -> Update Model Msg a
--update msg model =
--    case msg of
--        ButtonClicked ->
--            let
--                clickMsg count =
--                    "The button has been clicked " ++ String.fromInt count ++ " times."
--            in
--            model
--                |> incrementCounter
--                |> andThen (with .count (setMessage << clickMsg))
--
--
--view : Model -> Document Msg
--view { message } =
--    { title = ""
--    , body =
--        [ div []
--            [ text message
--            ]
--        , div []
--            [ button [ onClick ButtonClicked ] [ text "Click me" ]
--            ]
--        ]
--    }
--
--
--main : Program () Model Msg
--main =
--    document
--        { init = init
--        , update = update
--        , subscriptions = always Sub.none
--        , view = view
--        }
