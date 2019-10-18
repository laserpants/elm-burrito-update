module Form.Register.Custom exposing (Error(..), errorToString)


type Error
    = PasswordConfirmationMismatch
    | MustAgreeWithTerms


errorToString : Error -> String
errorToString error =
    case error of
        PasswordConfirmationMismatch ->
            "Password confirmation doesn’t match the password"

        MustAgreeWithTerms ->
            "You must agree with the terms of this service to complete the registration"
