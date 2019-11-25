module Helpers.Form exposing (controlErrorHelp, control, controlInput, controlPassword, controlTextArea)

import Bulma.Components exposing (..)
import Bulma.Form exposing (Control, ControlInputModifiers, controlHelp, controlInput, controlInputModifiers, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form exposing (Msg, Field)
import Form.Error as Error exposing (Error)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe


errorHelp : Error -> Control msg
errorHelp =
    controlHelp Danger [] << List.singleton << text << Error.toString


controlErrorHelp : Field Error -> Html msg
controlErrorHelp =
    Maybe.withDefault (text "") << Maybe.map errorHelp << Form.fieldError


control :
    a
    -> List (Attribute (Msg field))
    -> b
    ->
        (ControlInputModifiers msg
         -> a
         -> List (Attribute (Msg field))
         -> b
         -> Control (Msg field)
        )
    -> field
    -> Field err
    -> String
    -> Control (Msg field)
control ctrlAttrs inputAttrs children input tag field ph =
    let
        error =
            Form.fieldError field

        modifiers =
            { controlInputModifiers
                | color =
                    if Maybe.isNothing error then
                        controlInputModifiers.color

                    else
                        Danger
            }

        attributes =
            placeholder ph :: inputAttrs ++ Form.inputAttrs tag field
    in
    input modifiers ctrlAttrs attributes children


controlInput : field -> Field err -> String -> Control (Msg field)
controlInput =
    control [] [] [] Bulma.Form.controlInput


controlPassword : field -> Field err -> String -> Control (Msg field)
controlPassword =
    control [] [] [] Bulma.Form.controlPassword


controlTextArea : field -> Field err -> String -> Control (Msg field)
controlTextArea tag field ph =
    let
        error =
            Form.fieldError field

        modifiers =
            { controlTextAreaModifiers
                | color =
                    if Maybe.isNothing error then
                        controlInputModifiers.color

                    else
                        Danger
            }

        attributes =
            placeholder ph :: Form.inputAttrs tag field
    in
    Bulma.Form.controlTextArea modifiers [] attributes []
