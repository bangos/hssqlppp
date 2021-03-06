
This is the public module for the type checking functionality.

> {- | Contains functions for typechecking sql asts.
> -}
> module Database.HsSqlPpp.TypeChecker
>     (
>      -- * typechecking/ annotation functions
>      typeCheckStatements
>     ,typeCheckParameterizedStatement
>     ,typeCheckQueryExpr
>     ,typeCheckScalarExpr
>     ,typeCheckScalarExprEnv
>     ,TypeCheckingFlags(..)
>     ,SQLSyntaxDialect(..)
>     ,defaultTypeCheckingFlags
>     ) where
>
> import Database.HsSqlPpp.Internals.AstInternal
> import Database.HsSqlPpp.SqlDialect
> --import Database.HsSqlPpp.Internals.TypeChecking.Utils
> --import Database.HsSqlPpp.Internals.AstAnnotation
