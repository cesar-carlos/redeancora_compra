Imports mod_tobject
Imports rede_ancora_marca_model
Imports rede_ancora_marcas_model
Imports rede_ancora_linha_model
Imports rede_ancora_linhas_model
Imports rede_ancora_familia_model
Imports rede_ancora_familias_model
Imports integracao_schema
Imports sql_helper
Imports transactions

Namespace rede_ancora_catalogo_repository
    Class RedeAncoraCatalogoRepository
        Inherits TTObject

        Function ListarMarcas() As RedeAncoraMarcasModel
            ListarMarcas = me.ListarMarcasInterno()
        End Function

        Function ListarLinhas() As RedeAncoraLinhasModel
            ListarLinhas = me.ListarLinhasInterno()
        End Function

        Function ListarFamilias() As RedeAncoraFamiliasModel
            ListarFamilias = me.ListarFamiliasInterno()
        End Function

        Sub SubstituirMarcas(pItens As RedeAncoraMarcasModel)
            me.SubstituirListaMarcas(pItens)
        End Sub

        Sub SubstituirLinhas(pItens As RedeAncoraLinhasModel)
            me.SubstituirListaLinhas(pItens)
        End Sub

        Sub SubstituirFamilias(pItens As RedeAncoraFamiliasModel)
            me.SubstituirListaFamilias(pItens)
        End Sub

        Private Function TabelaMarca() As String
            TabelaMarca = IntegracaoSchema.TabelaMarcaQualificada()
        End Function

        Private Function TabelaLinha() As String
            TabelaLinha = IntegracaoSchema.TabelaLinhaQualificada()
        End Function

        Private Function TabelaFamilia() As String
            TabelaFamilia = IntegracaoSchema.TabelaFamiliaQualificada()
        End Function

        Private Function ListarMarcasInterno() As RedeAncoraMarcasModel
            Dim _result As New RedeAncoraMarcasModel()
            Dim _query As SQL.Command = NULL
            Dim _sql As String = $"SELECT CodMarca, Nome, CodCatalogo, CodErp FROM {me.TabelaMarca()} ORDER BY Nome"

            Try
                _query = SqlHelper.OpenQuery(_sql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraMarcaModel()
                    _item.CodMarca = _query.Field("CodMarca").AsInteger
                    _item.Nome = _query.Field("Nome").AsString
                    _item.CodCatalogo = _query.Field("CodCatalogo").AsInteger
                    _item.CodErp = _query.Field("CodErp").AsInteger
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarMarcasInterno = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraMarca", "9151")
            End Try
        End Function

        Private Function ListarLinhasInterno() As RedeAncoraLinhasModel
            Dim _result As New RedeAncoraLinhasModel()
            Dim _query As SQL.Command = NULL
            Dim _sql As String = $"SELECT CodLinha, Nome FROM {me.TabelaLinha()} ORDER BY Nome"

            Try
                _query = SqlHelper.OpenQuery(_sql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraLinhaModel()
                    _item.CodLinha = _query.Field("CodLinha").AsInteger
                    _item.Nome = _query.Field("Nome").AsString
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarLinhasInterno = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraLinha", "9152")
            End Try
        End Function

        Private Function ListarFamiliasInterno() As RedeAncoraFamiliasModel
            Dim _result As New RedeAncoraFamiliasModel()
            Dim _query As SQL.Command = NULL
            Dim _sql As String = $"SELECT CodFamilia, Nome FROM {me.TabelaFamilia()} ORDER BY Nome"

            Try
                _query = SqlHelper.OpenQuery(_sql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraFamiliaModel()
                    _item.CodFamilia = _query.Field("CodFamilia").AsInteger
                    _item.Nome = _query.Field("Nome").AsString
                    _result.Push(_item)
                    _query.Next()
                Wend

                SqlHelper.ReleaseQuery(_query)
                ListarFamiliasInterno = _result
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _result.Free()
                SqlHelper.HandleQueryError(ex, "Erro ao listar Integracao.RedeAncoraFamilia", "9153")
            End Try
        End Function

        Private Sub SubstituirListaMarcas(pItens As RedeAncoraMarcasModel)
            me.SubstituirMarcasInterno(pItens)
        End Sub

        Private Sub SubstituirListaLinhas(pItens As RedeAncoraLinhasModel)
            me.SubstituirLinhasInterno(pItens)
        End Sub

        Private Sub SubstituirListaFamilias(pItens As RedeAncoraFamiliasModel)
            me.SubstituirFamiliasInterno(pItens)
        End Sub

        Private Sub SubstituirMarcasInterno(pItens As RedeAncoraMarcasModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _deleteQuery As SQL.Command = NULL
            Dim _insertQuery As SQL.Command = NULL
            Dim _i As Integer

            Try
                _tx.StartTransaction("Integracao.RedeAncoraMarca Replace")
                _deleteQuery = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaMarca()}")
                _deleteQuery.ExecSQL()
                SqlHelper.ReleaseQuery(_deleteQuery)

                For _i = 0 To pItens.Length - 1
                    Dim _item As RedeAncoraMarcaModel = pItens.Take(_i)
                    _item.Validate()
                    _insertQuery = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaMarca()} (CodMarca, Nome, CodCatalogo, CodErp) VALUES (:CodMarca, :Nome, :CodCatalogo, :CodErp)")
                    _insertQuery.Param("CodMarca").AsInteger = _item.CodMarca
                    _insertQuery.Param("Nome").AsString = _item.Nome
                    _insertQuery.Param("CodCatalogo").AsInteger = _item.CodCatalogo
                    _insertQuery.Param("CodErp").AsInteger = _item.CodErp
                    _insertQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_insertQuery)
                Next

                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_deleteQuery)
                SqlHelper.ReleaseQuery(_insertQuery)
                _tx.Rollback()
                Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraMarca: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub SubstituirLinhasInterno(pItens As RedeAncoraLinhasModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _deleteQuery As SQL.Command = NULL
            Dim _insertQuery As SQL.Command = NULL
            Dim _i As Integer

            Try
                _tx.StartTransaction("Integracao.RedeAncoraLinha Replace")
                _deleteQuery = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaLinha()}")
                _deleteQuery.ExecSQL()
                SqlHelper.ReleaseQuery(_deleteQuery)

                For _i = 0 To pItens.Length - 1
                    Dim _item As RedeAncoraLinhaModel = pItens.Take(_i)
                    _item.Validate()
                    _insertQuery = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaLinha()} (CodLinha, Nome) VALUES (:CodLinha, :Nome)")
                    _insertQuery.Param("CodLinha").AsInteger = _item.CodLinha
                    _insertQuery.Param("Nome").AsString = _item.Nome
                    _insertQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_insertQuery)
                Next

                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_deleteQuery)
                SqlHelper.ReleaseQuery(_insertQuery)
                _tx.Rollback()
                Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraLinha: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub SubstituirFamiliasInterno(pItens As RedeAncoraFamiliasModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _deleteQuery As SQL.Command = NULL
            Dim _insertQuery As SQL.Command = NULL
            Dim _i As Integer

            Try
                _tx.StartTransaction("Integracao.RedeAncoraFamilia Replace")
                _deleteQuery = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaFamilia()}")
                _deleteQuery.ExecSQL()
                SqlHelper.ReleaseQuery(_deleteQuery)

                For _i = 0 To pItens.Length - 1
                    Dim _item As RedeAncoraFamiliaModel = pItens.Take(_i)
                    _item.Validate()
                    _insertQuery = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaFamilia()} (CodFamilia, Nome) VALUES (:CodFamilia, :Nome)")
                    _insertQuery.Param("CodFamilia").AsInteger = _item.CodFamilia
                    _insertQuery.Param("Nome").AsString = _item.Nome
                    _insertQuery.ExecSQL()
                    SqlHelper.ReleaseQuery(_insertQuery)
                Next

                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_deleteQuery)
                SqlHelper.ReleaseQuery(_insertQuery)
                _tx.Rollback()
                Throw New System.Exception("Erro ao substituir Integracao.RedeAncoraFamilia: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Overrides Sub Dispose()
            If Not me.Disposed Then
                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub
       Sub New()
          MyBase.New()
       End Sub

    End Class
End Namespace
