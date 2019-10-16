module Main exposing (..)

import Browser exposing (Document)
import Burrito.Unwrap exposing (..)
import Burrito.Update exposing (..)
import Burrito.Update.Browser exposing (document)
import Html exposing (..)
import Html.Events exposing (..)



--


type ButtonMsg
    = Click


type alias ButtonState =
    { counter : Int }


setCounterValue : Int -> ButtonState -> UpdateT ButtonState ButtonMsg a
setCounterValue count state =
    save { state | counter = count }


buttonInit : UpdateT ButtonState ButtonMsg a
buttonInit =
    save ButtonState
        |> andMap (save 0)


buttonUpdate : { buttonClicked : Int -> a } -> ButtonMsg -> ButtonState -> UpdateT ButtonState ButtonMsg a
buttonUpdate { buttonClicked } msg state =
    case msg of
        Click ->
            let
                count =
                    1 + state.counter
            in
            state
                |> setCounterValue count
                |> andThen (apply (buttonClicked count))


buttonView : Html ButtonMsg
buttonView =
    div [] [ button [ onClick Click ] [ text "Click me" ] ]



-- Main application


type Msg
    = ButtonMsg ButtonMsg


type alias State =
    { button : ButtonState
    , message : String
    }


setButton : State -> ButtonState -> UpdateT State Msg a
setButton state button =
    save { state | button = button }


setMessage : State -> String -> UpdateT State Msg a
setMessage state message =
    save { state | message = message }


init : () -> UpdateT State Msg a
init () =
    save State
        |> andMap (mapCmd ButtonMsg buttonInit)
        |> andMap (save "")


handleButtonClicked : Int -> State -> UpdateT State Msg a
handleButtonClicked times state =
    let
        message =
            "The button has been clicked " ++ String.fromInt times ++ " time(s)."
    in
    setMessage state message


update : Msg -> State -> UpdateT State Msg a
update msg state =
    case msg of
        ButtonMsg buttonMsg ->
            state.button
                |> buttonUpdate { buttonClicked = handleButtonClicked } buttonMsg
                |> mapCmd ButtonMsg
                |> andThen (setButton state)
                |> unwrap


view : State -> Document Msg
view { message } =
    { title = ""
    , body = [ Html.map ButtonMsg buttonView, text message ]
    }


main : Program () State Msg
main =
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
