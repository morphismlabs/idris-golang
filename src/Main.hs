module Main where

import Idris.Core.TT
import Idris.AbsSyntax
import Idris.ElabDecls
import Idris.REPL

import IRTS.Compiler
import IRTS.CodegenCommon
import IRTS.CodegenGo

import Data.List
import System.Environment
import System.Exit

data Opts = Opts { inputs :: [FilePath],
                   output :: FilePath }

showUsage = do putStrLn "Usage: idris-go <ibc-files> [-o <output-file>]"
               exitWith ExitSuccess

getOpts :: IO Opts
getOpts = do xs <- getArgs
             return $ process (Opts [] "a.out") xs
  where
    process opts ("-o":o:xs) = process (opts { output = o }) xs
    process opts (x:xs) = process (opts { inputs = x:inputs opts }) xs
    process opts [] = opts

go_main :: Opts -> Idris ()
go_main opts = do elabPrims
                  loadInputs (inputs opts) Nothing
                  mainProg <- elabMain
                  ir <- compile (Via "go") outputFilename mainProg
                  let ir' = if ".go" `isSuffixOf` outputFilename then ir {outputType=Raw}
                                                                 else ir
                  runIO $ codegenGo ir'
                    where outputFilename = output opts

main :: IO ()
main = do opts <- getOpts
          if (null (inputs opts)) 
             then showUsage
             else runMain (go_main opts)

