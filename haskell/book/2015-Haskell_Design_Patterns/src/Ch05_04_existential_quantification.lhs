type_abstraction
datq_type_abstraction
existential_quantification

> {-# LANGUAGE ExistentialQuantification #-}
>
> module Ch05_04_existential_quantification where
>
> import Test.HUnit      as U
> import Test.HUnit.Util as U hiding (e)

Existential quantification and abstract datatypes

instead of universally qualified

> data U a =           U a (a -> Bool) (a -> String)

the existentially qualified

> data E   = forall a. E a (a -> Bool) (a -> String)

hides type parameter (i.e., `a` no longer present on the left-hand side)

(potential confusion: `forall` used in both universal and existential cases)

type parameter is also "hidden" in type signatures:

> ef1 :: E -> Bool
> ef1 (E v f1 _) = f1 v
>
> ef2 :: E -> String
> ef2 (E v _ f2) = f2 v
>
> e   = E 3 even show
> ee3 = U.t "ee3" (ef1 e) False -- even 3
> se3 = U.t "se3" (ef2 e) "3"   -- show 3

Encapsulated value can only be accessed via functions packaged with the value.

Can NOT apply functions:

> -- INVALID
> -- getV (E v _ _) = v
> -- Couldn't match expected type ‘t’ with actual type ‘a’
> --   because type variable ‘a’ would escape its scope

Existential quantification provides the means to implement abstract datatypes
- providing functions over a type while hiding the representation of the type.

Can also do abstract datatypes via Haskell's module system
- hide algebraic datatype constructors while exporting functions over the type

Universal                    Existential
---------                    -----------
type parametrization         type abstraction

parametric polymorphism      encapsulation

user of data specifies type  implementer of data specifies type

forall = "for all"           forall = "for some"

> runTests_Ch05_04 = runTestTT $ TestList $ ee3 ++ se3
