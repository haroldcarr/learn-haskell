> {-# LANGUAGE DataKinds #-}
> {-# LANGUAGE FlexibleInstances #-}
> {-# LANGUAGE GADTs #-}
> {-# LANGUAGE KindSignatures #-}
> {-# LANGUAGE OverloadedStrings #-}
> {-# LANGUAGE ScopedTypeVariables #-}
> {-# LANGUAGE TypeFamilies #-}
> {-# LANGUAGE UndecidableInstances #-}
>
> module T6_polymorphic_containers where
>
> import           Control.Applicative  ((<$>))
> import           Control.Monad        (mzero)
> import           Data.Aeson
> import           Data.Aeson.Types
> import qualified Data.Aeson           as A
> import qualified Data.ByteString.Lazy as BL
> import           Data.Monoid          ((<>))
> import           Data.Proxy           (Proxy(Proxy))
> import           GHC.TypeLits         (KnownSymbol, Symbol, symbolVal)
> import           Data.Text            (pack)
> import           Test.HUnit           (Counts, Test (TestList), runTestTT)
> import qualified Test.HUnit.Util      as U (t, tt)
> import           Text.RawString.QQ

> type family TypeKey (a :: *) :: Symbol where
>   TypeKey Int    = "int"
>   TypeKey String = "string"

> instance {-# OVERLAPPING #-} KnownSymbol s => ToJSON   (Proxy s) where
>   toJSON = A.String . pack . symbolVal

> instance {-# OVERLAPPING #-} KnownSymbol s => FromJSON (Proxy s) where
>   parseJSON (A.String s) | s == pack (symbolVal (Proxy :: Proxy s)) = return (Proxy :: Proxy s)
>   parseJSON _      = mzero

> data Payload (s :: Symbol) a :: * where
>   Payload :: a -> Payload (TypeKey a) a

> instance (s ~ TypeKey a, KnownSymbol s, ToJSON   a) => ToJSON   (Payload s a) where
>   toJSON (Payload a) = object [ "type" .= (Proxy :: Proxy s)
>                               , "data" .= a
>                               ]

> instance (s ~ TypeKey a, KnownSymbol s, FromJSON a) => FromJSON (Payload s a) where
>   parseJSON (Object v) = (v .: "type" :: Parser (Proxy s))
>                          >>
>                          Payload <$> v .: "data"
>   parseJSON _          = mzero

> instance (KnownSymbol s, Show a) => Show (Payload s a) where
>   show (Payload a) = "Payload " <> symbolVal (Proxy :: Proxy s) <> " " <> show a

assumptions now in type

don't want to specify keys everywhere

want to keep global index for a reference

want polymorphic container that hides underlying type-level machinery

do via GADT and UndecidableInstances (https://downloads.haskell.org/~ghc/7.8.2/docs/html/users_guide/type-class-extensions.html#undecidable-instances)

> -- wraps `Payload s a` automatically
> -- hiding deails from client

> data Message a where
>   Message :: (s ~ TypeKey a, KnownSymbol s)
>           => Payload s a
>           -> Message a

> instance ToJSON a => ToJSON (Message a) where
>   toJSON (Message payload) = object [ "payload" .= payload ]

> instance (s ~ TypeKey a, KnownSymbol s, FromJSON a) => FromJSON (Message a) where
>   parseJSON (Object v) = Message <$> v .: "payload"
>   parseJSON _ = mzero

> instance Show a => Show (Message a) where
>   show (Message p) = "Message ( " <> show p <> " )"

> t6j :: BL.ByteString
> t6j  = "{\"type\": \"string\", \"data\": \"cool\"}"

> t6p :: Payload "int" Int
> t6p  = Payload 10

> msgA :: BL.ByteString
> msgA = "{ \"payload\": {\"type\": \"string\", \"data\": \"cool\"} }"

> msgB :: BL.ByteString
> msgB = "{ \"payload\": {\"type\": \"string\", \"data\": 10} }"

> p :: Message Int
> p = Message (Payload 10 :: Payload "int" Int)

> data Env a = Env { m :: Message a }

> instance FromJSON (Message a) => FromJSON (Env a) where
>   parseJSON (Object v) = Env <$> v .: "envelope"
>   parseJSON _ = mzero

> t6e1 = decode msgA :: Maybe (Message String)
> -- => Just Message ( Payload string "cool" )

> t6e2 = decode msgA :: Maybe (Message Int)
> -- => Nothing

> t6e3 = Message (Payload  420)  :: Message Int

> t6e4 = Message (Payload "420") :: Message String

> data Cool = Cool

Message (Payload Cool) :: Message Cool

    No instance for (KnownSymbol (TypeKey Cool))

`Message a` has he desired behaviour
- can deserialize strings only if `type` key has right value
- value of `type` key, and therefore type-level string needed instance `Payload s a` not exposed to clients using `Message`
- can't create `Message` with type not indexed in closed type family `TypeKey`

