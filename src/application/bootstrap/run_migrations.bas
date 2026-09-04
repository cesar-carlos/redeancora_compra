Imports rede_ancora_migration
Imports diag_stack

Namespace run_migrations
    Class RunMigrations
        Shared Sub Run()
            Dim _migration As RedeAncoraMigration = NULL

            DiagStack.Push("New RedeAncoraMigration")
            DiagStack.Trace("boot: New RedeAncoraMigration")
            _migration = New RedeAncoraMigration()
            DiagStack.Pop()
            Try
                DiagStack.Push("RedeAncoraMigration.Run")
                DiagStack.Trace("boot: RedeAncoraMigration.Run")
                _migration.Run()
                DiagStack.Pop()
                _migration.Free()
                _migration = NULL
            Catch ex As Exception
                If Assigned(_migration) Then
                    _migration.Free()
                    _migration = NULL
                End If
                Throw ex
            End Try
        End Sub
        Sub Free()
            MyBase.Free()
        End Sub

       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
