{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{- |
   Minimal Pandoc: LaTeX → HTML5 converter
   Only supports LaTeX input and HTML5 output with MathJax
-}
module Main where

import qualified Data.Text.IO as TIO
import qualified Data.Text.Encoding as TE
import qualified Data.ByteString as BS
import qualified Data.Text as T
import Text.Pandoc
import Text.Pandoc.Error (PandocError(..))
import Text.Pandoc.Templates (compileTemplate, WithDefaultPartials(..), Template)
import Control.Monad.Except (throwError)
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure, exitSuccess)
import System.IO (hPutStrLn, stderr)
import Data.FileEmbed (embedFile)

-- Embed the HTML5 template at compile time (minimal template without styles)
embeddedTemplate :: BS.ByteString
embeddedTemplate = $(embedFile "template.html5")

-- MathJax configuration for HTML output
mathJaxOptions :: WriterOptions
mathJaxOptions = def
  { writerHTMLMathMethod = MathJax "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"
  , writerHighlightMethod = NoHighlighting  -- Disable syntax highlighting to reduce dependencies
  }

-- Reader options with common LaTeX extensions
latexReaderOptions :: ReaderOptions
latexReaderOptions = def
  { readerExtensions = getDefaultExtensions "latex"
  }

printUsage :: IO ()
printUsage = do
  progName <- getProgName
  putStrLn $ "Usage: " ++ progName ++ " [OPTIONS] <input.tex>"
  putStrLn ""
  putStrLn "Minimal Pandoc: Converts LaTeX to HTML5 with MathJax support"
  putStrLn ""
  putStrLn "Options:"
  putStrLn "  -h, --help       Show this help message"
  putStrLn "  -s, --standalone Generate standalone HTML document (default: fragment)"
  putStrLn "  -o FILE          Write output to FILE (default: stdout)"
  putStrLn ""
  putStrLn "Examples:"
  putStrLn $ "  " ++ progName ++ " input.tex > output.html"
  putStrLn $ "  " ++ progName ++ " -s input.tex -o output.html"
  putStrLn $ "  " ++ progName ++ " --standalone input.tex"

data Options = Options
  { optStandalone :: Bool
  , optInputFile :: FilePath
  , optOutputFile :: Maybe FilePath
  }

parseArgs :: [String] -> Either String Options
parseArgs args = go args (Options False "" Nothing)
  where
    go [] opts
      | null (optInputFile opts) = Left "No input file specified"
      | otherwise = Right opts
    go ("-h":_) _ = Left "help"
    go ("--help":_) _ = Left "help"
    go ("-s":rest) opts = go rest opts { optStandalone = True }
    go ("--standalone":rest) opts = go rest opts { optStandalone = True }
    go ("-o":file:rest) opts = go rest opts { optOutputFile = Just file }
    go (file:rest) opts
      | null (optInputFile opts) = go rest opts { optInputFile = file }
      | otherwise = Left $ "Unexpected argument: " ++ file

convert :: Options -> IO ()
convert opts = do
  -- Read input
  input <- TIO.readFile (optInputFile opts)
  
  -- Run conversion
  result <- runIO $ do
    doc <- readLaTeX latexReaderOptions input
    
    -- Configure writer with template if standalone
    writerOpts <- if optStandalone opts
      then do
        -- Use embedded template instead of compileDefaultTemplate
        let templateText = TE.decodeUtf8 embeddedTemplate
        res <- runWithDefaultPartials $ compileTemplate "html5" templateText
        case res of
          Left err -> throwError $ PandocTemplateError (T.pack err)
          Right tmpl -> return $ mathJaxOptions { writerTemplate = Just tmpl }
      else
        return mathJaxOptions
    
    writeHtml5String writerOpts doc
  
  case result of
    Left err -> do
      hPutStrLn stderr $ "Error: " ++ show err
      exitFailure
    Right html -> 
      case optOutputFile opts of
        Nothing -> TIO.putStrLn html
        Just outFile -> TIO.writeFile outFile html

main :: IO ()
main = do
  args <- getArgs
  case parseArgs args of
    Left "help" -> printUsage >> exitSuccess
    Left err -> do
      hPutStrLn stderr $ "Error: " ++ err
      hPutStrLn stderr ""
      printUsage
      exitFailure
    Right opts -> convert opts
