Imports mod_tobject

Namespace base_listener
    Class BaseListener
        Inherits TTObject

        Private _millisecondsInterval As Integer
        Private _timer As Forms.Timer
        Private _isExecuting As Boolean
        Private _singleShot As Boolean

        Property Interval As Integer
            Get
                Interval = me._millisecondsInterval
            End Get
            Set(pValue As Integer)
                me.ApplyInterval(pValue)
            End Set
        End Property

        Property SingleShot As Boolean
            Get
                SingleShot = me._singleShot
            End Get
            Set(pValue As Boolean)
                me._singleShot = pValue
            End Set
        End Property

        Protected Sub New(pMillisecondsInterval As Integer = 1000, pAutoStart As Boolean = False, pSingleShot As Boolean = False)
            MyBase.New()
            me._isExecuting = False
            me._singleShot = pSingleShot
            me.ApplyInterval(pMillisecondsInterval)
            me.Build()

            If pAutoStart Then
                me.StartListener()
            End If
        End Sub

        Private Sub ApplyInterval(pMillisecondsInterval As Integer)
            Dim _interval As Integer = pMillisecondsInterval

            If _interval < 100 Then
                _interval = 100
            End If

            me._millisecondsInterval = _interval

            If Assigned(me._timer) Then
                me._timer.Interval = _interval
            End If
        End Sub

        Private Sub Build()
            me._timer = New Forms.Timer(Null)
            me._timer.OnTimer = me.OnTimer
            me._timer.Enabled = False
            me._timer.Interval = me._millisecondsInterval
        End Sub

        Sub StartListener()
            If me.Disposed Then
                Exit Sub
            End If

            If Assigned(me._timer) Then
                me._timer.Enabled = True
            End If
        End Sub

        Sub StopListener()
            If Assigned(me._timer) Then
                me._timer.Enabled = False
            End If
        End Sub

        Sub Restart()
            me.StopListener()
            me.StartListener()
        End Sub

        Function IsRunning() As Boolean
            IsRunning = False

            If Assigned(me._timer) Then
                If me._timer.Enabled Then
                    IsRunning = True
                End If
            End If
        End Function

        Private Sub OnTimer(Sender As TObject)
            If me.Disposed Or me._isExecuting Then
                Exit Sub
            End If

            me._isExecuting = True

            Try
                me.OnListener()

                If me._singleShot Then
                    me.StopListener()
                End If
            Catch ex As Exception
                me.SafeHandleListenerError(ex)
            End Try

            me._isExecuting = False
        End Sub

        ' Isola falhas do proprio OnListenerError (subclasse) para garantir que
        ' OnTimer sempre libere _isExecuting, mesmo se o handler de erro falhar.
        Private Sub SafeHandleListenerError(pException As Exception)
            Try
                me.OnListenerError(pException)
            Catch ex As Exception
                ' Handler de erro tambem falhou: nao ha nada mais seguro a fazer
                ' aqui alem de nao deixar a excecao travar o listener.
            End Try
        End Sub

        Overridable Sub OnListener()
            ' override in subclass
        End Sub

        Overridable Sub OnListenerError(pException As Exception)
            ' override in subclass to log or handle errors
        End Sub

        Overridable Sub OnDispose()
            me.StopListener()

            If Assigned(me._timer) Then
                me._timer.OnTimer = Null
                me._timer.Free()
                me._timer = Null
            End If
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.OnDispose()
                me.Disposed = True
            End If
        End Sub

        Overridable Function ToString() As String
            With me.BuildLogger(me.ClassName)
                .Prop("Interval", me._millisecondsInterval)
                .Prop("IsRunning", me.IsRunning())
                .Prop("SingleShot", me._singleShot)
                .Prop("Disposed", me.Disposed)
                ToString = .Text()
                .Free()
            End With
        End Function

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing BaseListener: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
