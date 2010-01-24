Copyright 2010 Jake Wheat

Tests for the local bindings lookup code, which is a bit convoluted in
places, particularly for joins

> module Database.HsSqlPpp.Tests.LocalBindingsTests (localBindingsTests) where

> import Test.HUnit
> import Test.Framework
> import Test.Framework.Providers.HUnit
> import Data.Char
> --import Text.Show.Pretty
> --import Debug.Trace

> import Database.HsSqlPpp.AstInternals.TypeChecking.LocalBindings

> import Database.HsSqlPpp.Ast.SqlTypes
> --import Database.HsSqlPpp.Ast.Annotation
> --import Database.HsSqlPpp.Parsing.Parser
> --import Database.HsSqlPpp.Ast.TypeChecker
> --import Database.HsSqlPpp.Ast.Catalog

> data Item = Group String [Item]
>           | Lookup [([LocalBindingsUpdate]
>                     ,String -- correlation name
>                     ,String -- id name
>                     ,Either [TypeError] (String,String,String,Type))] -- source, corr, type
>           | StarExpand [([LocalBindingsUpdate], String, Either [TypeError] [(String,String,String,Type)])]

> localBindingsTests :: [Test.Framework.Test]
> localBindingsTests = itemToTft testData

test plan:
no updates uncor lookup, star
cor lookup,star
1 update
  uncor match, match sys, no match, star (with sys not appearing)
  cor same "
  join update: join col type tests + incompatible
               join on system columns
               ambiguous ids
               do cor tests with both cors
2 updates: just one pair: lookup in head with shadowing
           lookup in tail
           no match
           use difference cor to get to shadowed in tail
case insensitive tests
expand composite tests
n layers of joins with ids from each layer cor and uncor, plus star expands

> testData :: Item
> testData =
>   Group "local bindings tests" [ Lookup [
>     testUnRec [] "" "test"
>    ,testUnRec [] "test" "test"
>    ,testRec [LBQualifiedIds "source1"
>                      ""
>                      [("test1", typeInt)
>                      ,("test2", typeBool)]
>                      []]
>              ("source1","","test1",typeInt)

>    ,testRec [unquids1] res11
>    ,testRec [unquids1] res12
>    ,testRec [unquids1] res13
>    ,testRec [unquids1] res14
>    ,testUnRec [unquids1] "" "asdasd"

>    ,testRec [quids1] res21
>    ,testRec [quids1] res22
>    ,testRec [quids1] res23
>    ,testRec [quids1] res24
>    ,testUnRec [quids1] "qid1" "asdasd"
>    ,testUnRec [quids1] "" "asdasd"

>    ,testRec [quids2] res31
>    ,testRec [quids2] res32
>    ,testRec [quids2] res33
>    ,testRec [quids2] res34
>    ,testUnRec [quids2] "qid2" "asdasd"
>    ,testUnRec [quids2] "" "asdasd"

>    ,testRecNoCor [quids2] res31
>    ,testRecNoCor [quids2] res32
>    ,testRecNoCor [quids2] res33
>    ,testRecNoCor [quids2] res34


>    ]
>    ,StarExpand [
>     testStar [unquids1] "" $ Right [res11,res12]
>    ,testStar [unquids1] "test" $ Left [UnrecognisedCorrelationName "test"]
>    ,testStar [quids1] "" $ Right [res21,res22]
>    ,testStar [quids1] "test2" $ Left [UnrecognisedCorrelationName "test2"]
>    ,testStar [quids2] "" $ Right [res31,res32]
>    ,testStar [quids2] "qid2" $ Right [res31,res32]
>    ,testStar [quids2] "qid3" $ Left [UnrecognisedCorrelationName "qid3"]

>   ]]
>   where
>     unquids1 = LBUnqualifiedIds "unqid1s"
>                             [("test1", typeInt)
>                             ,("test2", typeBool)]
>                             [("inttest1", typeInt)
>                             ,("inttest2", typeBool)]
>     res11 = ("unqid1s","","test1",typeInt)
>     res12 = ("unqid1s","","test2",typeBool)
>     res13 = ("unqid1s","","inttest1",typeInt)
>     res14 = ("unqid1s","","inttest2",typeBool)

>     unquids2 = LBUnqualifiedIds "unqid2s"
>                             [("test1", ScalarType "text")
>                             ,("test3", ScalarType "int2")]
>                             [("inttest1", ScalarType "text")
>                             ,("inttest3", ScalarType "int2")]
>     res211 = ("unqid2s","","test1",ScalarType "text")
>     res212 = ("unqid2s","","test3",ScalarType "int2")
>     res213 = ("unqid2s","","inttest1",ScalarType "text")
>     res214 = ("unqid2s","","inttest3",ScalarType "int2")


>     quids1 = LBQualifiedIds "qid1s"
>                             ""
>                             [("test1", typeInt)
>                             ,("test2", typeBool)]
>                             [("inttest1", typeInt)
>                             ,("inttest2", typeBool)]
>     res21 = ("qid1s","","test1",typeInt)
>     res22 = ("qid1s","","test2",typeBool)
>     res23 = ("qid1s","","inttest1",typeInt)
>     res24 = ("qid1s","","inttest2",typeBool)

>     quids2 = LBQualifiedIds "qid2s"
>                             "qid2"
>                             [("test3", typeInt)
>                             ,("test4", typeBool)]
>                             [("inttest3", typeInt)
>                             ,("inttest4", typeBool)]
>     res31 = ("qid2s","qid2","test3",typeInt)
>     res32 = ("qid2s","qid2","test4",typeBool)
>     res33 = ("qid2s","qid2","inttest3",typeInt)
>     res34 = ("qid2s","qid2","inttest4",typeBool)


>     testUnRec :: [LocalBindingsUpdate] -> String -> String
>               -> ([LocalBindingsUpdate]
>                  ,String -- correlation name
>                  ,String -- id name
>                  ,Either [TypeError] (String,String,String,Type))
>     testUnRec lbus cor i = (lbus,cor,i
>                            , Left [UnrecognisedIdentifier $
>                                    if cor == "" then i else cor ++ "." ++ i])
>     testRec :: [LocalBindingsUpdate]
>             -> (String,String,String,Type)
>             -> ([LocalBindingsUpdate]
>                ,String -- correlation name
>                ,String -- id name
>                ,Either [TypeError] (String,String,String,Type))
>     testRec lbus (src,cor,i,ty) = (lbus,cor,i,Right (src,cor,i,ty))

>     testRecNoCor :: [LocalBindingsUpdate]
>                  -> (String,String,String,Type)
>                  -> ([LocalBindingsUpdate]
>                     ,String -- correlation name
>                     ,String -- id name
>                     ,Either [TypeError] (String,String,String,Type))
>     testRecNoCor lbus (src,cor,i,ty) = (lbus,"",i,Right (src,cor,i,ty))


>     testStar :: [LocalBindingsUpdate]
>              -> String
>              -> Either [TypeError] [(String,String,String,Type)]
>              -> ([LocalBindingsUpdate]
>                 ,String -- correlation name
>                 ,Either [TypeError] [(String,String,String,Type)])
>     testStar lbus cor res = (lbus,cor,res)

LBQualifiedIds {
                              source :: String
                             ,correlationName :: String
                             ,ids :: [(String,Type)]
                             ,internalIds :: [(String,Type)]
                             }
                          | LBUnqualifiedIds {
                              source :: String
                             ,ids :: [(String,Type)]
                             ,internalIds :: [(String,Type)]
                             }
                          | LBJoinIds {
                              source1 :: String
                             ,correlationName1 :: String
                             ,ids1 :: [(String,Type)]
                             ,internalIds1 :: [(String,Type)]
                             ,source2 :: String
                             ,correlationName2 :: String
                             ,ids2 :: [(String,Type)]
                             ,internalIds2 :: [(String,Type)]
                             ,joinIds :: [String]
                             }


================================================================================

> testIdLookup :: [LocalBindingsUpdate]
>              -> String
>              -> String
>              -> Either [TypeError] (String,String,String,Type)
>              -> Test.Framework.Test
> testIdLookup lbus cn i res = testCase ("lookup " ++ cn ++ "." ++ i) $ do
>     let lb = foldr lbUpdate emptyBindings lbus
>         r = lbLookupID lb cn i
>     assertEqual "lookupid" res r

> testStarExpand :: [LocalBindingsUpdate]
>                -> String
>                -> Either [TypeError] [(String,String,String,Type)]
>                -> Test.Framework.Test
> testStarExpand lbus cn res = testCase ("expand star " ++ cn) $ do
>     let lb = foldr lbUpdate emptyBindings lbus
>         r = lbExpandStar lb cn
>     assertEqual "lookupid" res r

> itemToTft :: Item -> [Test.Framework.Test]
> itemToTft (Lookup es) = map (\(a,b,c,d) -> testIdLookup a b c d) es
> itemToTft (StarExpand es) = map (\(a,b,c) -> testStarExpand a b c) es
> itemToTft (Group s is) = [testGroup s $ concatMap itemToTft is]