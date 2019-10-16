module Burrito exposing (suite, testAddCmd, testAndMap, testJoin, testMap, testMap2, testMap3, testSave)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Burrito.Update exposing (..)


testSave : Test
testSave =
    let
        state =
            5

        ( a, b ) =
            save state
    in
    describe "save"
        [ test "state" <|
            \_ -> Expect.equal a state
        , test "cmds" <|
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
        [ test "increment" <|
            \_ -> Expect.equal a (state + 1)
        ]


testJoin : Test
testJoin =
    let
        ( a, b ) =
            join (save (save 5))
    in
    describe "join"
        [ test "this" <|
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
        [ test "this" <|
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
        [ test "this" <|
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
        [ test "this" <|
            \_ -> Expect.equal d 18
        ]


testAddCmd : Test
testAddCmd =
    let
        myCmd1 =
            Cmd.map (always 1) Cmd.none

        myCmd2 =
            Cmd.map (always 2) Cmd.none

        ( _, cmds1 ) =
            save 5
                |> addCmd myCmd1
    in
    describe "addCmd"
        [ test "one" <|
            \_ -> Expect.equal cmds1 [ myCmd1 ]
        ]


suite : Test
suite =
    describe "Magic Update"
        [ testSave
        , testMap
        , testJoin
        , testMap2
        , testMap3
        , testAndMap
        , testAddCmd
        ]
