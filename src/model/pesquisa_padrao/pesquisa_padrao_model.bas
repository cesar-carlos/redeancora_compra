Imports mod_tobject

Namespace pesquisa_padrao_model
    Class PesquisaPadraoModel
        Inherits TTObject

        TableCode As Integer
        SchemaName As String
        TableName As String
        DefaultSearchCode As Integer

        Sub New()
            MyBase.New()
            me.SchemaName = ""
            me.TableName = ""
        End Sub

        Sub New(pValue As PesquisaPadraoModel)
            MyBase.New()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As PesquisaPadraoModel)
            If Assigned(pValue) Then
                me.TableCode = pValue.TableCode
                me.SchemaName = pValue.SchemaName
                me.TableName = pValue.TableName
                me.DefaultSearchCode = pValue.DefaultSearchCode
            End If
        End Sub

        Sub Validate()
            If me.TableCode <= 0 Then
                Throw New System.Exception("Invalid TableCode on PesquisaPadraoModel")
            End If

            If me.TableName = "" Then
                Throw New System.Exception("Invalid TableName on PesquisaPadraoModel")
            End If

            If me.DefaultSearchCode <= 0 Then
                Throw New System.Exception("Invalid DefaultSearchCode on PesquisaPadraoModel")
            End If
        End Sub

        Overrides Function Clone() As PesquisaPadraoModel
            Clone = New PesquisaPadraoModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.TableCode.ToString()
        End Function

        Overridable Function ToString() As String
            With me.BuildLogger(me.ClassName)
                .Prop("TableCode", me.TableCode)
                .Prop("SchemaName", me.SchemaName)
                .Prop("TableName", me.TableName)
                .Prop("DefaultSearchCode", me.DefaultSearchCode)
                ToString = .Text()
                .Free()
            End With
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            Try
                If Not me.Disposed Then
                    me.Dispose()
                End If

                MyBase.Free()
            Catch ex As Exception
                Throw New System.Exception("Error freeing PesquisaPadraoModel: " + Char(13) + ex._getMessage())
            End Try
        End Sub
    End Class
End Namespace
