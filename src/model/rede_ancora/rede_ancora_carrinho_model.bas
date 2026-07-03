Imports mod_tobject
Imports rede_ancora_carrinho_itens_model

Namespace rede_ancora_carrinho_model
    Class RedeAncoraCarrinhoModel
        Inherits TTObject

        CodCarrinho As Integer
        IdCarrinho As String
        Convertido As String
        Canal As String
        QtdItens As Integer
        QtdItensTotal As Integer
        Subtotal As Double
        Impostos As Double
        Total As Double
        DataAtualizacao As TDateTime
        Itens As RedeAncoraCarrinhoItensModel

        Sub New()
            MyBase.New()
            me.CodCarrinho = 0
            me.IdCarrinho = ""
            me.Convertido = "N"
            me.Canal = ""
            me.Itens = New RedeAncoraCarrinhoItensModel()
        End Sub

        Sub New(pValue As RedeAncoraCarrinhoModel)
            MyBase.New()
            me.Itens = New RedeAncoraCarrinhoItensModel()
            me.Assign(pValue)
        End Sub

        Sub Assign(pValue As RedeAncoraCarrinhoModel)
            If Assigned(pValue) Then
                me.CodCarrinho = pValue.CodCarrinho
                me.IdCarrinho = pValue.IdCarrinho
                me.Convertido = pValue.Convertido
                me.Canal = pValue.Canal
                me.QtdItens = pValue.QtdItens
                me.QtdItensTotal = pValue.QtdItensTotal
                me.Subtotal = pValue.Subtotal
                me.Impostos = pValue.Impostos
                me.Total = pValue.Total
                me.DataAtualizacao = pValue.DataAtualizacao

                Dim _itensAntigos As RedeAncoraCarrinhoItensModel = me.Itens
                me.Itens = New RedeAncoraCarrinhoItensModel()

                If Assigned(pValue.Itens) Then
                    Dim _i As Integer

                    For _i = 0 To pValue.Itens.Length - 1
                        me.Itens.Push(pValue.Itens.Take(_i).Clone())
                    Next
                End If

                If Assigned(_itensAntigos) Then
                    _itensAntigos.Free()
                End If
            End If
        End Sub

        Sub Validate()
            If me.CodCarrinho <= 0 Then
                Throw New System.Exception("CodCarrinho invalido em RedeAncoraCarrinhoModel")
            End If

            If me.IdCarrinho.Trim() = "" Then
                Throw New System.Exception("IdCarrinho invalido em RedeAncoraCarrinhoModel")
            End If
        End Sub

        Overrides Function Clone() As RedeAncoraCarrinhoModel
            Clone = New RedeAncoraCarrinhoModel(me)
        End Function

        Overrides Function GetID() As String
            GetID = me.IdCarrinho
        End Function

        Overrides Sub Dispose()
            If Not me.Disposed Then
                If Assigned(me.Itens) Then
                    me.Itens.Free()
                    me.Itens = NULL
                End If

                me.Disposed = True
            End If
        End Sub

        Sub Free()
            If Not me.Disposed Then
                me.Dispose()
            End If

            MyBase.Free()
        End Sub
    End Class
End Namespace
