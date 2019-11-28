module Main exposing (..)

import Browser exposing (Document)
import Burrito.Update exposing (..)
import Burrito.Update.Browser exposing (document)
import Html exposing (..)
import Html.Events exposing (..)



-- Button


type ButtonMsg
    = Click


type alias ButtonState =
    { counter : Int }


setCounterValue : Int -> ButtonState -> Update ButtonState ButtonMsg a
setCounterValue count state =
    save { state | counter = count }


buttonInit : Update ButtonState ButtonMsg a
buttonInit =
    save ButtonState
        |> andMap (save 0)


buttonUpdate : { buttonClicked : Int -> a } -> ButtonMsg -> ButtonState -> Update ButtonState ButtonMsg a
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


insertAsButtonIn : State -> ButtonState -> Update State Msg a
insertAsButtonIn state button =
    save { state | button = button }


setMessage : State -> String -> Update State Msg a
setMessage state message =
    save { state | message = message }


init : () -> Update State Msg a
init () =
    save State
        |> andMap (mapCmd ButtonMsg buttonInit)
        |> andMap (save "")


handleButtonClicked : Int -> State -> Update State Msg a
handleButtonClicked times state =
    let
        message =
            "The button has been clicked " ++ String.fromInt times ++ " time(s)."
    in
    setMessage state message


update : Msg -> State -> Update State Msg a
update msg state =
    case msg of
        ButtonMsg buttonMsg ->
            state.button
                |> buttonUpdate { buttonClicked = handleButtonClicked } buttonMsg
                |> mapCmd ButtonMsg
                |> andThen (insertAsButtonIn state)
                |> runCallbacks


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
