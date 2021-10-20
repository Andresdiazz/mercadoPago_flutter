import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttermercadopago/utils/globals.dart' as globals;
import 'package:mercadopago_sdk/mercadopago_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Mercado Pago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage();
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int tokens = 0;

  void aumentarToken() {
    setState(() {
      tokens++;
    });
  }

  void disminuirToken() {
    setState(() {
      tokens--;
    });
  }

  @override
  initState() {
    const channelMercadoPagoRespuesta =
        const MethodChannel("andresadiazz.com/mercadoPagoRespuesta");

    channelMercadoPagoRespuesta.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'mercadoPagoOK':
          var idPago = call.arguments[0];
          var status = call.arguments[1];
          var statusDetails = call.arguments[2];
          return mercadoPagoOK(idPago, status, statusDetails);
        case 'mercadoPagoError':
          var error = call.arguments[0];
          return mercadoPagoERROR(error);
      }
    });
    super.initState();
  }

  void mercadoPagoOK(idPago, status, statusDetails) {
    print("idPago $idPago");
    print("status $status");
    print("statusDetails $statusDetails");
  }

  void mercadoPagoERROR(error) {
    print("error $error");
  }

  Future<Map<String, dynamic>> armarPreferencia() async {
    var mp = MP(globals.mpClientID, globals.mpClientSecret);
    var preference = {
      "items": [
        {
          "title": "Test Modified",
          "quantity": tokens,
          "currency_id": "COP",
          "unit_price": 100000
        }
      ],
      "payer": {"name": "Andres", "email": "andresadiazz@gmail.com"},
      "payment_methods": {"excluded_payment_types": []}
    };

    var result = await mp.createPreference(preference);
    return result;
  }

  Future<void> ejecutarMercadoPago() async {
    armarPreferencia().then((result) {
      if (result != null) {
        var preferenceId = result['response']['id'];
        try {
          const channelMercadoPago =
              const MethodChannel("andresadiazz.com/mercadoPago");
          final response = channelMercadoPago.invokeMethod(
              'mercadoPago', <String, dynamic>{
            "publicKey": globals.mpTESTPublicKey,
            "preferenceId": preferenceId
          });
          print(response);
        } on PlatformException catch (e) {
          print(e.message);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mercado Pago"),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () {
                      if (tokens > 0) disminuirToken();
                    },
                    icon: Icon(Icons.do_disturb_on_rounded)),
                Text("Tokens: $tokens"),
                IconButton(
                    onPressed: aumentarToken,
                    icon: Icon(Icons.add_circle_rounded)),
              ],
            ),
            MaterialButton(
              color: Colors.blue,
              onPressed: ejecutarMercadoPago,
              child: Text(
                "Comprar con Mercado Pago",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
