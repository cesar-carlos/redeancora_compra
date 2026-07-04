Imports rede_ancora_migration

Namespace run_migrations
    Class RunMigrations
        Shared Sub Run()
            Dim _migration As New RedeAncoraMigration()
            _migration.Run()
            _migration.Free()
        End Sub
        Sub Free()
            MyBase.Free()
        End Sub

       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
