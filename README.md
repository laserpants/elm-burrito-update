# Elm Burrito Update

[![Build Status](https://img.shields.io/travis/laserpants/elm-burrito-update/master.svg?style=flat)](https://travis-ci.org/laserpants/elm-burrito-update)
[![Version](https://img.shields.io/badge/elm--version-0.19-blue.svg?colorB=ff69b4)](http://elm-lang.org/)

## Getting started

```elm
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
    , count : Int
    }


setMessage : String -> Model -> PlainUpdate Model msg
setMessage message model =
    save { model | message = message }


incrementCounter : Model -> PlainUpdate Model msg
incrementCounter model =
    save { model | count = model.count + 1 }


init : () -> PlainUpdate Model Msg
init () =
    save Model
        |> andMap (save "Nothing much going on here.")
        |> andMap (save 0)


update : Msg -> Model -> PlainUpdate Model Msg
update msg model =
    case msg of
        ButtonClicked ->
            let
                clickMsg count = "The button has been clicked " ++ String.fromInt count ++ " times."
            in
            model
                |> incrementCounter
                |> andThen (with .count (setMessage << clickMsg))


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
```

## Documentation

TODO

## Etymology

TODO
