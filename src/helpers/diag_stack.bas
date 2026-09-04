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
                mod_logger.Info("diag: push " + pFrame)
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

        ' Sempre ativo (nao depende do kill switch): Catch precisa descrever AV
        ' com Message vazia. Nao atribui o nome da Function dentro de Try.
        Shared Function FormatException(pEx As Exception) As String
            Dim _type As String = "?"
            Dim _msg As String = ""
            Dim _result As String = "(null exception)"

            If Not Assigned(pEx) Then
                FormatException = _result
                Exit Function
            End If

            Try
                _type = pEx.ClassName()
            Catch exType As Exception
                _type = "?"
            End Try

            If _type = "" Then
                _type = "?"
            End If

            Try
                _msg = pEx._getMessage()
            Catch exMsg As Exception
                _msg = ""
            End Try

            If _msg = "" Then
                _msg = "(empty exception message)"
            End If

            _result = "type=" + _type + " msg=" + _msg
            FormatException = _result
        End Function

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
                _dump = DiagStack.Snapshot()
                If _dump = "" Then
                    mod_logger.Erro("diag-stack: (empty)")
                Else
                    mod_logger.Erro("diag-stack: " + _dump)
                End If

                If Assigned(pEx) Then
                    _exMsg = DiagStack.FormatException(pEx)
                    mod_logger.Erro("diag-ex: " + _exMsg)

                    Try
                        _inner = pEx.InnerException
                        If Assigned(_inner) Then
                            mod_logger.Erro("diag-inner: " + DiagStack.FormatException(_inner))
                        End If
                    Catch exInner As Exception
                    End Try

                    Try
                        _native = pEx.StackTrace
                        If _native <> "" Then
                            mod_logger.Erro("diag-native: " + _native)
                        End If
                    Catch exIgnore As Exception
                    End Try
                End If
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
