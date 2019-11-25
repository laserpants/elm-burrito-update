module Helpers.Form exposing (..)

import Bulma.Components exposing (..)
import Bulma.Form exposing (controlCheckBox, controlHelp, controlInput, controlInputModifiers, controlLabel, controlPassword, controlTextArea, controlTextAreaModifiers)
import Bulma.Modifiers exposing (..)
import Burrito.Form as Form
import Form.Error as Error
import Html exposing (text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Maybe.Extra as Maybe


errorHelp =
    controlHelp Danger [] << List.singleton << text << Error.toString


controlErrorHelp =
    Maybe.withDefault (text "") << Maybe.map errorHelp << Form.fieldError


control__ ctrlAttrs inputAttrs children input tag field ph =
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
            inputAttrs ++ [ placeholder ph ] ++ Form.inputAttrs tag field
    in
    input modifiers ctrlAttrs attributes children


controlInput_ =
    control__ [] [] [] controlInput


controlPassword_ =
    control__ [] [] [] controlPassword


controlTextArea_ tag field ph =
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
            [ placeholder ph ] ++ Form.inputAttrs tag field
    in
    controlTextArea modifiers [] attributes []
