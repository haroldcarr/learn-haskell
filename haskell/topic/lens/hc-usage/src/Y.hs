{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE FunctionalDependencies     #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MonoLocalBinds             #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NoImplicitPrelude          #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}

module Y where

------------------------------------------------------------------------------
import           Init
import           Types
------------------------------------------------------------------------------
import           Control.Lens
-- import qualified Control.Lens.Internal.FieldTH  as FTH
-- import           Control.Lens.TH
import           Control.Monad.Trans.RWS.Strict
import qualified Data.Map.Strict                as Map
-- import qualified Language.Haskell.TH.Datatype   as THD
-- import qualified Language.Haskell.TH.Lib        as THL
-- import qualified Language.Haskell.TH.Syntax     as THS
import           Protolude                      hiding (get, gets, round, to)
------------------------------------------------------------------------------

makeClassy ''EventProcessor
makeClassy ''BlockStore
makeClassy ''Pacemaker
makeClassy ''BlockTree
makeClassy ''Author

instance HasBlockStore (EventProcessor a) a where
  blockStore = lens _eventProcessorBlockStore (\x y -> x { _eventProcessorBlockStore = y})

instance HasBlockTree (EventProcessor a) a where
  blockTree = lens (^.eventProcessorBlockStore.blockStoreInner)
                   (\x y -> x & eventProcessorBlockStore.blockStoreInner .~ y)

instance HasPacemaker (EventProcessor a) where
  pacemaker = lens _eventProcessorPacemaker (\x y -> x { _eventProcessorPacemaker = y})

instance HasAuthor (EventProcessor a) where
  author = lens _eventProcessorAuthor (\x y -> x { _eventProcessorAuthor = y})

------------------------------------------------------------------------------
-- EventProcessor

ep :: (HasAuthor s, HasPacemaker s, HasBlockStore s a, HasBlockTree s a)
   => RWS () [Text] s ()
ep  = do
  pm
  author <- use author
  bs author

------------------------------------------------------------------------------
-- Pacemaker

pm :: HasPacemaker s
   => RWS () [Text] s ()
pm  = do
  r <- use (pacemaker.pacemakerHighestCommittedRound)
  tell ["PM " <> show r]

------------------------------------------------------------------------------
-- BlockStore

bs :: (HasBlockStore s a, HasBlockTree s a)
   => Author -> RWS () [Text] s ()
bs author = do
  s <- use (blockStore.blockStoreStuff)
  tell ["BS " <> show s]
  bt author

------------------------------------------------------------------------------
-- BlockTree

bt :: (HasBlockTree s a)
    => Author -> RWS () [Text] s ()
bt author = do
  vdm <- use (blockTree.blockTreeVoteDataMap)
  let vd = Map.lookup (HashValue "junk") vdm
  tell ["BT " <> show author <> " " <> show vd]

------------------------------------------------------------------------------
-- run

run :: EventProcessor a -> [Text]
run ep0 = let (_,_,t) = runRWS ep () ep0 in t

runEpT :: [Text]
runEpT  = run epT

