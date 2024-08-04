<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class SimuladorController extends Controller
{
    private $dadosSimulador;
    private $simulacao = [];

    public function simular(Request $request)
    {
        $data = $request->all();
        $valorEmprestimo = $data['valor_emprestimo'];
        $instituicoes = $data['instituicoes'];
        $convenios = $data['convenios'];
        $parcela = $data['parcela'];

        // Carregar os dados dos arquivos JSON
        $taxas = json_decode(file_get_contents(storage_path('app/public/simulador/taxas_instituicoes.json')), true);

        $resultados = [];

        foreach ($taxas as $taxa) {
            if (
                (empty($instituicoes) || in_array($taxa['instituicao'], $instituicoes)) &&
                (empty($convenios) || in_array($taxa['convenio'], $convenios)) &&
                ($parcela == null || $taxa['parcelas'] == $parcela)
            ) {
                $valorParcela = $valorEmprestimo * $taxa['coeficiente'];
                $resultados[] = [
                    'instituicao' => $taxa['instituicao'],
                    'valor_solicitado' => $valorEmprestimo,
                    'parcelas' => $taxa['parcelas'],
                    'valor_parcela' => number_format($valorParcela, 2, ',', '.'),
                    'taxa_juros' => $taxa['taxaJuros']
                ];
            }
        }

        return response()->json($resultados);
    }

    private function carregarArquivoDadosSimulador() : self
    {
        $this->dadosSimulador = json_decode(\File::get(storage_path("app/public/simulador/taxas_instituicoes.json")));
        return $this;
    }

    private function simularEmprestimo(float $valorEmprestimo) : self
    {
        foreach ($this->dadosSimulador as $dados) {
            $this->simulacao[$dados->instituicao][] = [
                "taxa"            => $dados->taxaJuros,
                "parcelas"        => $dados->parcelas,
                "valor_parcela"    => $this->calcularValorDaParcela($valorEmprestimo, $dados->coeficiente),
                "convenio"        => $dados->convenio,
            ];
        }
        return $this;
    }

    private function calcularValorDaParcela(float $valorEmprestimo, float $coeficiente) : float
    {
        return round($valorEmprestimo * $coeficiente, 2);
    }

    private function filtrarInstituicao(array $instituicoes) : self
    {
        if (\count($instituicoes))
        {
            $arrayAux = [];
            foreach ($instituicoes AS $key => $instituicao)
            {
                if (\array_key_exists($instituicao, $this->simulacao))
                {
                     $arrayAux[$instituicao] = $this->simulacao[$instituicao];
                }
            }
            $this->simulacao = $arrayAux;
        }
        return $this;
    }

    // SimuladorController.php

    private function filtrarConvenio(array $resultados, array $convenios) {
        return array_filter($resultados, function ($resultado) use ($convenios) {
            return in_array($resultado['convenio'], $convenios);
        });
    }

    private function filtrarParcelas(array $resultados, int $parcelas) {
        return array_filter($resultados, function ($resultado) use ($parcelas) {
            return $resultado['parcelas'] == $parcelas;
        });
    }

}
