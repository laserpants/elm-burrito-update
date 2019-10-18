module Ui.Toast exposing (container)

import Css exposing (..)
import Css.Media exposing (minWidth, only, screen, withMedia)
import Html exposing (Html)
import Html.Styled exposing (div, fromUnstyled, toUnstyled)
import Html.Styled.Attributes exposing (css)


container : Html msg -> Html msg
container html =
    div
        [ css
            [ width (pct 100)
            , position fixed
            , bottom (px 0)
            , pointerEvents none
            , displayFlex
            , flexDirection column
            , padding (px 15)
            , withMedia
                [ only screen
                    [ minWidth (px 768) ]
                ]
                [ alignItems start ]
            , zIndex (int 9000)
            ]
        ]
        [ fromUnstyled html ]
        |> toUnstyled
