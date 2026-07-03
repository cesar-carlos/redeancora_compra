Imports mod_logger
Imports run_migrations

Namespace app_boot
    Class AppBoot
        Public Shared Sub Run()
            mod_logger.Printe("=== redeancora_compra :: boot ===")

            Try
                RunMigrations.Run()
                mod_logger.Printe("Migrations Integracao.RedeAncora concluidas.")
            Catch ex As Exception
                mod_logger.Printe("Falha no boot redeancora_compra: " + ex._getMessage())
                Throw ex
            End Try

            mod_logger.Printe("=== redeancora_compra :: pronto ===")
        End Sub
        Public Sub Free()
            MyBase.Free()
        End Sub

        Sub New()
            MyBase.New()
        End Sub

    End Class
End Namespace
