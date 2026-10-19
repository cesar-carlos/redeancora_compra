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
Imports mod_logger

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

        Sub DefinirCodLinhaData7(pCodLinha As Integer, pCodLinhaData7 As Integer)
            me.DefinirCodigoData7(me.TabelaLinha(), "CodLinha", "CodLinhaData7", pCodLinha, pCodLinhaData7, "Linha", "Integracao.RedeAncoraLinha")
        End Sub

        Sub DefinirCodFamiliaData7(pCodFamilia As Integer, pCodFamiliaData7 As Integer)
            me.DefinirCodigoData7(me.TabelaFamilia(), "CodFamilia", "CodFamiliaData7", pCodFamilia, pCodFamiliaData7, "Familia", "Integracao.RedeAncoraFamilia")
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
            Dim _sql As String = $"SELECT CodLinha, Nome, CodLinhaData7 FROM {me.TabelaLinha()} ORDER BY Nome"

            Try
                _query = SqlHelper.OpenQuery(_sql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraLinhaModel()
                    _item.CodLinha = _query.Field("CodLinha").AsInteger
                    _item.Nome = _query.Field("Nome").AsString
                    _item.CodLinhaData7 = _query.Field("CodLinhaData7").AsInteger
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
            Dim _sql As String = $"SELECT CodFamilia, Nome, CodFamiliaData7 FROM {me.TabelaFamilia()} ORDER BY Nome"

            Try
                _query = SqlHelper.OpenQuery(_sql)
                _query.Open()

                While Not _query.EOF
                    Dim _item As New RedeAncoraFamiliaModel()
                    _item.CodFamilia = _query.Field("CodFamilia").AsInteger
                    _item.Nome = _query.Field("Nome").AsString
                    _item.CodFamiliaData7 = _query.Field("CodFamiliaData7").AsInteger
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
            Dim _query As SQL.Command = NULL
            Dim _existentes As RedeAncoraMarcasModel = NULL
            Dim _item As RedeAncoraMarcaModel = NULL
            Dim _atual As RedeAncoraMarcaModel = NULL
            Dim _api As RedeAncoraMarcaModel = NULL
            Dim _i As Integer

            If Not Assigned(pItens) Then
                Throw New System.Exception("Lista de marcas vazia. Nenhuma marca foi apagada.")
            End If

            If pItens.Length <= 0 Then
                Throw New System.Exception("Sincronizacao de marcas sem itens. Nenhuma marca foi apagada.")
            End If

            _existentes = me.ListarMarcasInterno()

            Try
                _tx.StartTransaction("Integracao.RedeAncoraMarca Upsert")

                For _i = 0 To pItens.Length - 1
                    _item = pItens.Take(_i)
                    _item.Validate()
                    _atual = _existentes.ObterPorCodigo(_item.CodMarca)

                    If Assigned(_atual) Then
                        _query = SqlHelper.OpenQuery($"UPDATE {me.TabelaMarca()} SET Nome = :Nome, CodCatalogo = :CodCatalogo, CodErp = :CodErp WHERE CodMarca = :CodMarca")
                    Else
                        _query = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaMarca()} (CodMarca, Nome, CodCatalogo, CodErp) VALUES (:CodMarca, :Nome, :CodCatalogo, :CodErp)")
                    End If

                    _query.Param("CodMarca").AsInteger = _item.CodMarca
                    _query.Param("Nome").AsString = _item.Nome
                    _query.Param("CodCatalogo").AsInteger = _item.CodCatalogo
                    _query.Param("CodErp").AsInteger = _item.CodErp
                    _query.ExecSQL()
                    SqlHelper.ReleaseQuery(_query)
                    _query = NULL
                Next

                For _i = 0 To _existentes.Length - 1
                    _atual = _existentes.Take(_i)
                    _api = pItens.ObterPorCodigo(_atual.CodMarca)

                    If Not Assigned(_api) Then
                        _query = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaMarca()} WHERE CodMarca = :CodMarca")
                        _query.Param("CodMarca").AsInteger = _atual.CodMarca
                        _query.ExecSQL()
                        SqlHelper.ReleaseQuery(_query)
                        _query = NULL
                    End If
                Next

                _existentes.Free()
                _existentes = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If Assigned(_existentes) Then
                    _existentes.Free()
                End If

                _tx.Rollback()
                Throw New System.Exception("Erro ao sincronizar Integracao.RedeAncoraMarca: " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub SubstituirLinhasInterno(pItens As RedeAncoraLinhasModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL
            Dim _existentes As RedeAncoraLinhasModel = NULL
            Dim _item As RedeAncoraLinhaModel = NULL
            Dim _atual As RedeAncoraLinhaModel = NULL
            Dim _api As RedeAncoraLinhaModel = NULL
            Dim _i As Integer
            Dim _preservadas As Integer = 0

            If Not Assigned(pItens) Then
                Throw New System.Exception("Lista de linhas vazia. CodLinhaData7 preservado; nenhuma linha foi apagada.")
            End If

            If pItens.Length <= 0 Then
                Throw New System.Exception("Sincronizacao de linhas sem itens. CodLinhaData7 preservado; nenhuma linha foi apagada.")
            End If

            _existentes = me.ListarLinhasInterno()

            Try
                _tx.StartTransaction("Integracao.RedeAncoraLinha Upsert")

                For _i = 0 To pItens.Length - 1
                    _item = pItens.Take(_i)
                    _item.Validate()
                    _atual = _existentes.ObterPorCodigo(_item.CodLinha)

                    If Assigned(_atual) Then
                        _query = SqlHelper.OpenQuery($"UPDATE {me.TabelaLinha()} SET Nome = :Nome WHERE CodLinha = :CodLinha")
                    Else
                        _query = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaLinha()} (CodLinha, Nome) VALUES (:CodLinha, :Nome)")
                    End If

                    _query.Param("CodLinha").AsInteger = _item.CodLinha
                    _query.Param("Nome").AsString = _item.Nome
                    _query.ExecSQL()
                    SqlHelper.ReleaseQuery(_query)
                    _query = NULL
                Next

                For _i = 0 To _existentes.Length - 1
                    _atual = _existentes.Take(_i)
                    _api = pItens.ObterPorCodigo(_atual.CodLinha)

                    If Not Assigned(_api) Then
                        If _atual.CodLinhaData7 > 0 Then
                            _preservadas = _preservadas + 1
                        Else
                            _query = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaLinha()} WHERE CodLinha = :CodLinha")
                            _query.Param("CodLinha").AsInteger = _atual.CodLinha
                            _query.ExecSQL()
                            SqlHelper.ReleaseQuery(_query)
                            _query = NULL
                        End If
                    End If
                Next

                _existentes.Free()
                _existentes = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If Assigned(_existentes) Then
                    _existentes.Free()
                End If

                _tx.Rollback()
                Throw New System.Exception("Erro ao sincronizar Integracao.RedeAncoraLinha: " + Char(13) + ex._getMessage())
            End Try

            If _preservadas > 0 Then
                mod_logger.Printe("Rede Ancora sync linhas: " + _preservadas.ToString() + " linha(s) fora da API mantida(s) por CodLinhaData7.")
            End If
        End Sub

        Private Sub SubstituirFamiliasInterno(pItens As RedeAncoraFamiliasModel)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL
            Dim _existentes As RedeAncoraFamiliasModel = NULL
            Dim _item As RedeAncoraFamiliaModel = NULL
            Dim _atual As RedeAncoraFamiliaModel = NULL
            Dim _api As RedeAncoraFamiliaModel = NULL
            Dim _i As Integer
            Dim _preservadas As Integer = 0

            If Not Assigned(pItens) Then
                Throw New System.Exception("Lista de familias vazia. CodFamiliaData7 preservado; nenhuma familia foi apagada.")
            End If

            If pItens.Length <= 0 Then
                Throw New System.Exception("Sincronizacao de familias sem itens. CodFamiliaData7 preservado; nenhuma familia foi apagada.")
            End If

            _existentes = me.ListarFamiliasInterno()

            Try
                _tx.StartTransaction("Integracao.RedeAncoraFamilia Upsert")

                For _i = 0 To pItens.Length - 1
                    _item = pItens.Take(_i)
                    _item.Validate()
                    _atual = _existentes.ObterPorCodigo(_item.CodFamilia)

                    If Assigned(_atual) Then
                        _query = SqlHelper.OpenQuery($"UPDATE {me.TabelaFamilia()} SET Nome = :Nome WHERE CodFamilia = :CodFamilia")
                    Else
                        _query = SqlHelper.OpenQuery($"INSERT INTO {me.TabelaFamilia()} (CodFamilia, Nome) VALUES (:CodFamilia, :Nome)")
                    End If

                    _query.Param("CodFamilia").AsInteger = _item.CodFamilia
                    _query.Param("Nome").AsString = _item.Nome
                    _query.ExecSQL()
                    SqlHelper.ReleaseQuery(_query)
                    _query = NULL
                Next

                For _i = 0 To _existentes.Length - 1
                    _atual = _existentes.Take(_i)
                    _api = pItens.ObterPorCodigo(_atual.CodFamilia)

                    If Not Assigned(_api) Then
                        If _atual.CodFamiliaData7 > 0 Then
                            _preservadas = _preservadas + 1
                        Else
                            _query = SqlHelper.OpenQuery($"DELETE FROM {me.TabelaFamilia()} WHERE CodFamilia = :CodFamilia")
                            _query.Param("CodFamilia").AsInteger = _atual.CodFamilia
                            _query.ExecSQL()
                            SqlHelper.ReleaseQuery(_query)
                            _query = NULL
                        End If
                    End If
                Next

                _existentes.Free()
                _existentes = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)

                If Assigned(_existentes) Then
                    _existentes.Free()
                End If

                _tx.Rollback()
                Throw New System.Exception("Erro ao sincronizar Integracao.RedeAncoraFamilia: " + Char(13) + ex._getMessage())
            End Try

            If _preservadas > 0 Then
                mod_logger.Printe("Rede Ancora sync familias: " + _preservadas.ToString() + " familia(s) fora da API mantida(s) por CodFamiliaData7.")
            End If
        End Sub

        Private Sub DefinirCodigoData7(pTabela As String, pColunaChave As String, pColunaData7 As String, pChave As Integer, pCodigoData7 As Integer, pRotulo As String, pTabelaErro As String)
            Dim _tx As Transaction = Transaction.Instance()
            Dim _query As SQL.Command = NULL
            Dim _chave As String = SqlHelper.ValidateIdentifier(pColunaChave)
            Dim _data7 As String = SqlHelper.ValidateIdentifier(pColunaData7)

            If pChave <= 0 Then
                Throw New System.Exception(pRotulo + " invalido para vinculo Data7 em " + pTabelaErro)
            End If

            Try
                _tx.StartTransaction(pTabelaErro + " " + _data7)
                _query = SqlHelper.OpenQuery("SELECT " + _chave + " FROM " + pTabela + " WHERE " + _chave + " = :Chave")
                _query.Param("Chave").AsInteger = pChave
                _query.Open()

                If _query.EOF Then
                    SqlHelper.ReleaseQuery(_query)
                    _query = NULL
                    Throw New System.Exception(pRotulo + " " + pChave.ToString() + " nao encontrada em " + pTabelaErro)
                End If

                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                me.ExigirCodigoData7Livre(pTabela, _chave, _data7, pChave, pCodigoData7)
                _query = SqlHelper.OpenQuery("UPDATE " + pTabela + " SET " + _data7 + " = CASE WHEN :CodigoData7 = 0 THEN NULL ELSE :CodigoData7 END WHERE " + _chave + " = :Chave")
                _query.Param("Chave").AsInteger = pChave
                _query.Param("CodigoData7").AsInteger = pCodigoData7
                _query.ExecSQL()
                SqlHelper.ReleaseQuery(_query)
                _query = NULL
                _tx.AutoCommit()
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                _tx.Rollback()
                Throw New System.Exception("Erro ao gravar " + _data7 + " em " + pTabelaErro + ": " + Char(13) + ex._getMessage())
            End Try
        End Sub

        Private Sub ExigirCodigoData7Livre(pTabela As String, pColunaChave As String, pColunaData7 As String, pChave As Integer, pCodigoData7 As Integer)
            Dim _query As SQL.Command = NULL
            Dim _chave As String = SqlHelper.ValidateIdentifier(pColunaChave)
            Dim _data7 As String = SqlHelper.ValidateIdentifier(pColunaData7)
            Dim _ocupada As Integer = 0

            If pCodigoData7 <= 0 Then
                Exit Sub
            End If

            Try
                _query = SqlHelper.OpenQuery("SELECT " + _chave + " AS Chave FROM " + pTabela + " WHERE " + _data7 + " = :CodigoData7 AND " + _chave + " <> :Chave")
                _query.Param("CodigoData7").AsInteger = pCodigoData7
                _query.Param("Chave").AsInteger = pChave
                _query.Open()

                If Not _query.EOF Then
                    _ocupada = _query.Field("Chave").AsInteger
                End If

                SqlHelper.ReleaseQuery(_query)
                _query = NULL
            Catch ex As Exception
                SqlHelper.ReleaseQuery(_query)
                Throw ex
            End Try

            If _ocupada > 0 Then
                Throw New System.Exception(_data7 + " " + pCodigoData7.ToString() + " ja vinculado ao codigo " + _ocupada.ToString())
            End If
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
