module Burrito.UpdateTest exposing (..)

import Burrito.Update exposing (..)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


testSave : Test
testSave =
    let
        state =
            5

        ( a, b ) =
            save state
    in
    describe "save"
        [ test "expect 5 to appear in tuple" <|
            \_ -> Expect.equal a state
        , test "expect no cmds" <|
            \_ -> Expect.equal [] b
        ]


testMap : Test
testMap =
    let
        state =
            5

        ( a, b ) =
            map (\x -> x + 1) (save state)
    in
    describe "map"
        [ test "expect value in tuple to increment by 1" <|
            \_ -> Expect.equal a (state + 1)
        ]


testJoin : Test
testJoin =
    let
        ( a, _ ) =
            join (save (save 5))
    in
    describe "join"
        [ test "expect 5 to appear in tuple" <|
            \_ -> Expect.equal a 5
        ]


testMap2 : Test
testMap2 =
    let
        a =
            save 5

        b =
            save 8

        ( c, _ ) =
            map2 (\x y -> x + y) a b
    in
    describe "map2"
        [ test "expect sum to appear in first component" <|
            \_ -> Expect.equal c 13
        ]


testMap3 : Test
testMap3 =
    let
        a =
            save 5

        b =
            save 8

        c =
            save 2

        ( d, _ ) =
            map3 (\x y z -> x + (y - z)) a b c
    in
    describe "map3"
        [ test "expect sum to appear in first component" <|
            \_ -> Expect.equal d 11
        ]


testAndMap : Test
testAndMap =
    let
        f x y z =
            x + y + z

        a =
            save 5

        b =
            save 6

        c =
            save 7

        ( d, _ ) =
            map f a
                |> andMap b
                |> andMap c
    in
    describe "andMap"
        [ test "expect sum to appear in first component" <|
            \_ -> Expect.equal d 18
        ]


testAddCmd : Test
testAddCmd =
    let
        myCmd1 =
            Cmd.map (always 1) Cmd.none

        ( _, cmds1 ) =
            save 5
                |> addCmd myCmd1
    in
    describe "addCmd"
        [ test "expect appear cmd to appear in list" <|
            \_ -> Expect.equal cmds1 [ myCmd1 ]
        ]


testSequence : Test
testSequence =

    let 
        cmds1 =
          [ always (save 1)
          , always (save 3)
          ]

        cmds2 =
          [ \x -> save (x/2)
          , \y -> save (y+1)
          ]

        d = sequence cmds1 5
        e = sequence cmds2 8

    in
    describe "sequence"
        [ test "expect the value to be 3" <|
            \_ -> Expect.equal d (save 3)
        , test "expect the result of 8/2+1 to be 5" <|
            \_ -> Expect.equal e (save 5)
        ]



suite : Test
suite =
    describe "Burrito Update"
        [ testSave
        , testMap
        , testJoin
        , testMap2
        , testMap3
        , testAndMap
        , testAddCmd
        , testSequence
        ]
