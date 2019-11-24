module Form.Error exposing (Error(..), toString)


type Error
    = MustNotBeEmpty
    | MustBeInt
    | MustBeValidEmail
    | MustAgreeWithTerms
    | MustMatchPassword
    | PasswordTooShort


toString : Error -> String
toString error =
    case error of
        MustNotBeEmpty ->
            "This field is required"

        MustBeInt ->
            "This value must be an integer"

        MustBeValidEmail ->
            "Not a valid email address"

        MustAgreeWithTerms ->
            "You must agree with the terms of service to complete the registration"

        MustMatchPassword ->
            "Confirmation doesn’t match password"

        PasswordTooShort ->
            "The password must be at least eight characters long"
