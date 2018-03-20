{-# OPTIONS_GHC -Wno-unused-do-bind    #-}

{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes        #-}

module LedgerLockedImpl where

import qualified Control.Concurrent      as CC
import qualified Control.Concurrent.MVar as MV
import qualified Control.Monad           as CM
import qualified Data.Sequence           as Seq
import qualified Data.Text               as T
import           RIO
import qualified System.Random           as Random
------------------------------------------------------------------------------
import           Config
import           Ledger

createLedger
  :: (Env env, Ledgerable a)
  => (T.Text -> a)
  -> IO (Ledger a env)
createLedger ft = do
  mv <- MV.newMVar Seq.empty
  return Ledger
    { lContents = MV.readMVar mv
    , lCommit = \e a -> do
        s <- MV.takeMVar mv
        CM.when (cDOSEnabled (getConfig e)) $ do
          d <- Random.randomRIO (cDOSRandomRange (getConfig e))
          CM.when (d == cDOSRandomHit (getConfig e)) $ do
            runRIO e $ logInfo "BEGIN commitToLedger DOS"
            CC.threadDelay (1000000 * cDOSDelay (getConfig e))
            runRIO e $ logInfo "END commitToLedger DOS"
        MV.putMVar mv (s Seq.|> a)
    , lModify = \i a -> do
        s <- MV.takeMVar mv
        MV.putMVar mv (Seq.update i a s)
    , fromText = ft
    }