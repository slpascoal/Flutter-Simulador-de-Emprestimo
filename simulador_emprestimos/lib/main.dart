import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:dropdown_search/dropdown_search.dart';

void main() {
  runApp(EmprestimoSimuladorApp());
}

class EmprestimoSimuladorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simulador de Empréstimo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EmprestimoSimuladorPage(),
    );
  }
}

class EmprestimoSimuladorPage extends StatefulWidget {
  @override
  _EmprestimoSimuladorPageState createState() => _EmprestimoSimuladorPageState();
}

class _EmprestimoSimuladorPageState extends State<EmprestimoSimuladorPage> {
  final _valorController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
    precision: 2,
  );
  List<Map<String, String>> _instituicoes = [];
  List<Map<String, String>> _convenios = [];
  String? _instituicaoSelecionada;
  String? _convenioSelecionado;
  int? _parcelasSelecionadas;
  final List<int> _opcoesParcelas = [0, 36, 48, 60, 72, 84];
  List<Map<String, dynamic>> _resultadosSimulacao = [];


  @override
  void initState() {
    super.initState();
    _fetchInstituicoes();
    _fetchConvenios();
  }

  Future<void> _fetchInstituicoes() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/instituicao'));
      if (response.statusCode == 200) {
        List<dynamic> instituicoesJson = json.decode(response.body);
        List<Map<String, String>> instituicoes = instituicoesJson
            .map((instituicao) => {
          'chave': instituicao['chave'].toString(),
          'valor': instituicao['valor'].toString(),
        })
            .toList();
        setState(() {
          _instituicoes = [{'chave': '', 'valor': 'Selecione uma instituição'}] + instituicoes; // Adiciona item vazio
        });
      } else {
        print('Erro ao carregar instituições: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar instituições: $e');
    }
  }

  Future<void> _fetchConvenios() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/convenio'));
      if (response.statusCode == 200) {
        List<dynamic> conveniosJson = json.decode(response.body);
        List<Map<String, String>> convenios = conveniosJson
            .map((convenio) => {
          'chave': convenio['chave'].toString(),
          'valor': convenio['valor'].toString(),
        })
            .toList();



        setState(() {
          _convenios = [{'chave': '', 'valor': 'Selecione um convênio'}] + convenios; // Adiciona item vazio
        });
      } else {
        print('Erro ao carregar convênios: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar convênios: $e');
    }
  }

  Future<void> _simularEmprestimo() async {
    final valor = double.parse(_valorController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
    );
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/simular'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'valor_emprestimo': valor,
        'instituicoes': _instituicaoSelecionada != null && _instituicaoSelecionada!.isNotEmpty
            ? [_instituicaoSelecionada]
            : [],
        'convenios': _convenioSelecionado != null && _convenioSelecionado!.isNotEmpty
            ? [_convenioSelecionado]
            : [],
        'parcela': _parcelasSelecionadas,
      }),
    );
    if (response.statusCode == 200) {
      setState(() {
        _resultadosSimulacao = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      print('Erro ao simular empréstimo: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Simulador de Empréstimo',
          style: TextStyle(
              color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,

      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(

              controller: _valorController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Valor do Empréstimo',
                focusedBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 0.0),
                ),
              ),

              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20,),
            DropdownSearch<Map<String, String>>(
              items: _instituicoes,
              itemAsString: (item) => item['valor']!,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange, width: 0.0),
                  ),
                  labelText: 'Instituição',
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _instituicaoSelecionada = value?['chave'];
                });
              },
              selectedItem: _instituicoes.firstWhere((item) => item['chave'] == _instituicaoSelecionada, orElse: () => _instituicoes.first),
            ),
            SizedBox(height: 20,),
            DropdownSearch<Map<String, String>>(

              items: _convenios,
              itemAsString: (item) => item['valor']!,
              dropdownDecoratorProps: DropDownDecoratorProps(

                dropdownSearchDecoration: InputDecoration(
                    focusedBorder: const OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.orange, width: 0.0),
                    ),
                    labelText: 'Convênio',
                    border: OutlineInputBorder()
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _convenioSelecionado = value?['chave'];
                });
              },
              selectedItem: _convenios.firstWhere((item) => item['chave'] == _convenioSelecionado, orElse: () => _convenios.first),
            ),
            SizedBox(height: 20,),
            DropdownButtonFormField<int>(
              hint: Text('Parcelas'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: const OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange, width: 0.0),
                ),

              ),


              isExpanded: true,
              value: _parcelasSelecionadas,
              onChanged: (newValue) {
                setState(() {
                  _parcelasSelecionadas = newValue;
                });
              },
              items: _opcoesParcelas.map((parcelas) {
                return DropdownMenuItem<int>(
                  child: Text(parcelas == 0 ? 'Selecionar parcelas' : parcelas.toString()),
                  value: parcelas,
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            FilledButton(
                onPressed: _simularEmprestimo,
                child: Text('Simular'),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)
                    )
                ),
            ),
            SizedBox(height: 20),
            _resultadosSimulacao.isNotEmpty ? _buildResultados() : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultados() {
    return Expanded(
      child: ListView.builder(
        itemCount: _resultadosSimulacao.length,
        itemBuilder: (context, index) {
          final resultado = _resultadosSimulacao[index];
          final instituicao = resultado['instituicao'];
          final taxaJuros = resultado['taxa_juros'];
          final valorSolicitado = resultado['valor_solicitado'];
          final parcelas = resultado['parcelas'];
          final valorParcela = resultado['valor_parcela'];


          var convenioList = [];
          _convenios.forEach((valor) => convenioList.add(valor.values.last));
          convenioList.remove('Selecione um convênio');

          return Card(

            child: ListTile(

              contentPadding: EdgeInsets.all(8.0),
              leading: Image.asset('${instituicao}' == 'PAN' ? 'assets/imagens/Bancopanlogo.png' : '${instituicao}' == 'BMG' ? 'assets/imagens/logo-bmg-nova.png' : 'assets/imagens/Ole-consignado-2.webp', width: 50, height: 50),
              title: Text(
                'R\$ ${valorSolicitado} - ${parcelas} x R\$ ${valorParcela}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${instituicao} - ${taxaJuros}%',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        },
      ),
    );
  }

}
