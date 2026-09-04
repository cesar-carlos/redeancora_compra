Imports mod_logger
Imports run_migrations
Imports diag_stack

Namespace app_boot
    Class AppBoot
        Shared Sub Run()
            DiagStack.Trace("=== redeancora_compra :: boot ===")
            DiagStack.Push("AppBoot.Run")

            Try
                DiagStack.Push("RunMigrations")
                DiagStack.Trace("boot: RunMigrations start")
                RunMigrations.Run()
                DiagStack.Pop()
                mod_logger.Printe("Migrations Integracao.RedeAncora concluidas.")
            Catch ex As Exception
                Dim _msg As String = ""

                DiagStack.DumpOnError(ex)
                Try
                    If Assigned(ex) Then
                        _msg = ex._getMessage()
                    End If
                Catch exMsg As Exception
                    _msg = ""
                End Try
                If _msg = "" Then
                    _msg = "Access Violation (empty exception message)"
                End If
                mod_logger.Printe("Falha no boot redeancora_compra: " + _msg)
                Throw ex
            End Try

            DiagStack.Pop()
            DiagStack.Trace("=== redeancora_compra :: pronto ===")
        End Sub
        Sub Free()
            MyBase.Free()
        End Sub

        Sub New()
            MyBase.New()
        End Sub

    End Class
End Namespace
