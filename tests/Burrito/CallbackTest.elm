module Burrito.CallbackTest exposing (..)

import Burrito.Update exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


testCallbacks : Test
testCallbacks =
    let
        fun1 { multiplyBy, incrementBy } msg state =
            save 5
                |> andApply (multiplyBy 2)
                |> andApply (incrementBy 3)

        fun2 =
            fun1 { multiplyBy = \a s -> save (s * a), incrementBy = \a s -> save (s + a) } 0 0
                |> runCallbacks
    in
    describe "andApply"
        [ test "expect the value to be 13" <|
            \_ -> Expect.equal fun2 (save 13)
        ]


suite : Test
suite =
    describe "Burrito Callback"
        [ testCallbacks ]
