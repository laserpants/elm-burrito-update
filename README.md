# Elm Burrito Update

[![Build Status](https://img.shields.io/travis/laserpants/elm-burrito-update/master.svg?style=flat)](https://travis-ci.org/laserpants/elm-burrito-update)
[![Version](https://img.shields.io/badge/elm--version-0.19-blue.svg?colorB=ff69b4)](http://elm-lang.org/)

## Getting started

```elm
module Main exposing (main)

import Browser exposing (Document)
import Burrito.Update.Browser exposing (document)
import Burrito.Update.Simple exposing (..)
import Html exposing (..)
import Html.Events exposing (..)


type alias Flags =
    ()


type Msg
    = ButtonClicked


type alias Model =
    { message : String
    , count : Int
    }


setMessage : String -> Model -> Update Model msg
setMessage message model =
    save { model | message = message }


incrementCounter : Model -> Update Model msg
incrementCounter model =
    save { model | count = model.count + 1 }


init : Flags -> Update Model Msg
init () =
    save Model
        |> andMap (save "Nothing much going on here.")
        |> andMap (save 0)


update : Msg -> Model -> Update Model Msg
update msg model =
    case msg of
        ButtonClicked ->
            let
                clickMsg count =
                    "The button has been clicked " ++ String.fromInt count ++ " times."
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


main : Program Flags Model Msg
main =
    document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
```

## Etymology

Burritos have appeared in some programming tutorials, serving as an analogy for monads.
Whether or not this is a good pedagogical idea, they do seem to [satisfy the monad laws](https://blog.plover.com/prog/burritos.html).
For an in-depth treatment of the subject, see [this excellent paper](http://emorehouse.web.wesleyan.edu/silliness/burrito_monads.pdf) by Ed Morehouse.
