Imports Collections
Imports mod_logger

Namespace diag_stack
    ' ============================================================
    ' KILL SWITCH (único) — produção: False
    ' False = desliga Push, Pop, Snapshot, DumpOnError e Trace
    ' (incluindo breadcrumbs boot:). Sem Print.
    ' Runtime: DiagStack.DefinirHabilitado(False)
    ' ============================================================
    Private Dim _habilitado As Boolean = True
    Private Dim _frames As StringList

    Class DiagStack
        Shared Function Habilitado() As Boolean
            Habilitado = _habilitado
        End Function

        Shared Sub DefinirHabilitado(pHabilitado As Boolean)
            _habilitado = pHabilitado
            If Not pHabilitado Then
                DiagStack.Clear()
            End If
        End Sub

        Shared Sub Push(pFrame As String)
            If Not _habilitado Then
                Exit Sub
            End If

            If Not Assigned(_frames) Then
                _frames = New StringList()
            End If

            _frames.Add(pFrame)
            Try
                mod_logger.Info("diag: " + DiagStack.Snapshot())
            Catch exLog As Exception
            End Try
        End Sub

        Shared Sub Pop()
            If Not _habilitado Then
                Exit Sub
            End If

            If Not Assigned(_frames) Then
                Exit Sub
            End If

            If _frames.Count = 0 Then
                Exit Sub
            End If

            _frames.Delete(_frames.Count - 1)
        End Sub

        Shared Function Snapshot() As String
            Dim _text As String = ""
            Dim _i As Integer

            Snapshot = ""

            If Not _habilitado Then
                Exit Function
            End If

            If Not Assigned(_frames) Then
                Exit Function
            End If

            If _frames.Count = 0 Then
                Exit Function
            End If

            For _i = 0 To _frames.Count - 1
                If _i > 0 Then
                    _text = _text + " > "
                End If
                _text = _text + _frames.Strings(_i)
            Next

            Snapshot = _text
        End Function

        Shared Sub DumpOnError(pEx As Exception)
            Dim _dump As String = ""
            Dim _native As String = ""
            Dim _inner As Exception = NULL
            Dim _exMsg As String = ""

            If Not _habilitado Then
                Exit Sub
            End If

            Try
                _dump = "diag-stack: " + DiagStack.Snapshot()

                If Assigned(pEx) Then
                    Try
                        _exMsg = pEx._getMessage()
                    Catch exMsg As Exception
                        _exMsg = ""
                    End Try
                    If _exMsg = "" Then
                        _exMsg = "(empty exception message)"
                    End If
                    _dump = _dump + Char(13) + "ex: " + _exMsg

                    Try
                        _inner = pEx.InnerException
                        If Assigned(_inner) Then
                            _dump = _dump + Char(13) + "inner: " + _inner._getMessage()
                        End If
                    Catch exInner As Exception
                    End Try

                    Try
                        _native = pEx.StackTrace
                        If _native <> "" Then
                            _dump = _dump + Char(13) + "native-stack:" + Char(13) + _native
                        End If
                    Catch exIgnore As Exception
                    End Try
                End If

                mod_logger.Erro(_dump)
            Catch exDump As Exception
                Try
                    mod_logger.Erro("diag-stack: dump failed")
                Catch exIgnore As Exception
                End Try
            End Try
        End Sub

        Shared Sub Trace(pMsg As String)
            If Not _habilitado Then
                Exit Sub
            End If

            Try
                mod_logger.Info(pMsg)
            Catch exLog As Exception
            End Try
        End Sub

        Shared Sub Clear()
            If Not Assigned(_frames) Then
                Exit Sub
            End If
            _frames.Clear()
        End Sub

        Sub New()
            MyBase.New()
        End Sub

        Sub Free()
            MyBase.Free()
        End Sub
    End Class
End Namespace
