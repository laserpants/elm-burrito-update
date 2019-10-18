port module Ports exposing (clearSession, setSession, websocketIn, websocketOut)

import Data.Session exposing (Session)


port setSession : Session -> Cmd msg


port clearSession : () -> Cmd msg


port websocketIn : (String -> msg) -> Sub msg


port websocketOut : String -> Cmd msg
