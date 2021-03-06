{-
Created       : 2014 Mar 06 (Thu) 17:12:50 by Harold Carr.
Last Modified : 2014 May 17 (Sat) 10:43:10 by Harold Carr.

http://www.haskell.org/haskellwiki/Template_Haskell#Generating_records_which_are_variations_of_existing_records
-}

{-# LANGUAGE ScopedTypeVariables, TemplateHaskell #-}

module TH where

import Language.Haskell.TH
import Language.Haskell.TH.Syntax
import Data.Data
import Data.Generics

addMaybes :: Data.Data.Data b => Maybe String -> b -> Language.Haskell.TH.Syntax.Q b
addMaybes modName input = let

    rename :: GenericT
    rename = mkT $ \n -> if nameModule n == modName
        then mkName $ nameBase n ++ "_opt"
        else n

    addMaybe :: GenericM Q
    addMaybe = mkM $ \(n :: Name, s :: Strict, ty :: Type) -> do
                    ty' <- [t| Maybe $(return ty) |]
                    return (n,s,ty')

  in everywhere rename `fmap` everywhereM addMaybe input

mkOptional :: Language.Haskell.TH.Syntax.Name -> Language.Haskell.TH.Syntax.Q Language.Haskell.TH.Syntax.Dec
mkOptional n = do
    TyConI d <- reify n
    addMaybes (nameModule n) d

------------------------------------------------------------------------------

fooey :: Q [Dec]
fooey = do
    let fooTC = mkName "FooTC"
        barVC = mkName "BarVC"
        bazVC = mkName "BazVC"
        eqD   = mkName "Eq"
        showD = mkName "Show"
        barTC = mkName "BarTC"
        quxVC = mkName "QuxVC"
    aTV   <- newName "aTV"
    bTV   <- newName "bTV"
    return [ DataD [] fooTC [ PlainTV aTV, PlainTV bTV ]
             [ NormalC barVC [ (NotStrict, VarT aTV) ]
             , NormalC bazVC [ (NotStrict, VarT bTV) ]
             ]
             [ eqD
             , showD
             ]
           , DataD [] barTC [ PlainTV aTV ]
             [ NormalC quxVC [ (NotStrict, VarT aTV) ]
             ]
             [ eqD
             , showD
             ]
           ]


-- End of file.
