
import 'dart:async';
import 'dart:convert';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool? isConnected=await bluetoothPrint.isConnected;

    bluetoothPrint.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if(isConnected!) {
      setState(() {
        _connected=true;
      });
    }
  }

  // List<int> encodeUtf(string) {
  //   return utf8.encode(string);
  // }
  // decodeUtf(string){
  //   return utf8.decode(string);
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BluetoothPrint example app'),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              bluetoothPrint.startScan(timeout: Duration(seconds: 4)),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      child: Text(tips),
                    ),
                  ],
                ),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothPrint.scanResults,
                  initialData: [],
                  builder: (c, snapshot) => Column(
                    children: snapshot.data!.map((d) => ListTile(
                      title: Text(d.name??''),
                      subtitle: Text(d.address!),
                      onTap: () async {
                        setState(() {
                          _device = d;
                        });
                      },
                      trailing: _device!=null && _device!.address == d.address?Icon(
                        Icons.check,
                        color: Colors.green,
                      ):null,
                    )).toList(),
                  ),
                ),
                Divider(),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            child: Text('connect'),
                            onPressed:  _connected?null:() async {
                              if(_device!=null && _device!.address !=null){
                                await bluetoothPrint.connect(_device!);
                              }else{
                                setState(() {
                                  tips = 'please select device';
                                });
                                print('please select device');
                              }
                            },
                          ),
                          SizedBox(width: 10.0),
                          OutlinedButton(
                            child: Text('disconnect'),
                            onPressed:  _connected?() async {
                              await bluetoothPrint.disconnect();
                            }:null,
                          ),
                        ],
                      ),
                      OutlinedButton(
                        child:const Text('print receipt(esc)'),
                        onPressed:  _connected?() async {
                          Map<String, dynamic> configL = {};
                          List<LineText> list = [];

                          configL['charset'] = 'utf-8';
                          list.add(LineText(type: LineText.TYPE_TEXT, content:  'الموظع',weight: 1, align: LineText.ALIGN_CENTER,linefeed: 1));
                          list.add(LineText(type: LineText.TYPE_TEXT, content: 'محمود' , weight: 0, align: LineText.ALIGN_LEFT,linefeed: 1));
                          list.add(LineText(linefeed: 1));
                          print(list);
                          await bluetoothPrint.printReceipt(configL, list);

                        }:null,
                      ),
                      // OutlinedButton(
                      //   child: Text('print label(tsc)'),
                      //   onPressed:  _connected?() async {
                      //     Map<String, dynamic> config = Map();
                      //     config['width'] = 40; // 标签宽度，单位mm
                      //     config['height'] = 70; // 标签高度，单位mm
                      //     config['gap'] = 2; // 标签间隔，单位mm
                      //     config['charset'] = 'UTF-8';
                      //     List<LineText> list = [];
                      //     list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:10, content: 'الموظع'));
                      //     list.add(LineText(type: LineText.TYPE_TEXT, x:10, y:40, content: 'تیست'));
                      //     list.add(LineText(type: LineText.TYPE_QRCODE, x:10, y:70, content: 'تیست\n'));
                      //     list.add(LineText(type: LineText.TYPE_BARCODE, x:10, y:190, content: 'تیست\n'));
                      //
                      //     List<LineText> list1 = [];
                      //     ByteData data = await rootBundle.load("assets/images/guide3.png");
                      //     List<int> imageBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                      //     String base64Image = base64Encode(imageBytes);
                      //     list1.add(LineText(type: LineText.TYPE_IMAGE, x:10, y:10, content: base64Image,));
                      //
                      //     await bluetoothPrint.printLabel(config, list);
                      //     await bluetoothPrint.printLabel(config, list1);
                      //   }:null,
                      // ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data!) {
              return FloatingActionButton(
                child: Icon(Icons.stop),
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
              );
            } else {
              return FloatingActionButton(
                  child: Icon(Icons.search),
                  onPressed: () => bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}
