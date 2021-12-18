import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  CameraController cameraController;
  CameraImage imgCamera;
  bool isWorking = false;
  double imgHeight;
  double imgWidth;
  List recognitionsList;
  String result ="";

  initCamera()
  {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value)
    {
      if(!mounted)
      {
        return;
      }
      setState((){
        cameraController.startImageStream((imageFromStream) =>
        {
          if(!isWorking)
            {
              isWorking = true,
              imgCamera = imageFromStream,
              runModelOnStreamFrame(),
            }
        });
      });
    });
  }

  runModelOnStreamFrame() async
  {
    imgHeight = imgCamera.height + 0.0;
    imgWidth = imgCamera.width + 0.0;

    recognitionsList = await Tflite.detectObjectOnFrame(

        bytesList: imgCamera.planes.map((plane)
        {
          return plane.bytes;
        }).toList(),

        model: "YOLO",
        imageMean: 0.0,
        imageStd: 255.0,
        threshold: 0.2,       // defaults to 0.1
        numResultsPerClass: 1,// defaults to 5
        asynch: true
    );

    // result = "";
    // recognitionsList.forEach((response)
    // {
    //   // result += response["label"] + " " + (response["confidence"] * 100).toStringAsFixed(0) + "%" + "\n\n";
    //   result += "${response["detectedClass"]}" + "\n\n";
    // });
    //

    isWorking = false;

    setState(() {
      imgCamera;
    });
  }

  Future loadModel() async
  {
    Tflite.close();

    try {
      String res;
      res = await Tflite.loadModel(
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt"
      );
      print(res);
    }
    on PlatformException{
      print("Unable to load model.");
    }
  }

  @override
  void dispose() {
    super.dispose();

    cameraController.stopImageStream();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();

    loadModel();
    initCamera();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen)
  {
    if(recognitionsList == null) return [];

    if(imgHeight == null || imgWidth == null) return []; 

    double factorX = screen.width;
    double factorY = imgHeight;

    Color pink = Colors.pink;

    return recognitionsList.map((result) {
      return Positioned(
        left: result["rect"]["x"] * factorX,
        top: result["rect"]["y"] * factorY,
        width: result["rect"]["w"] * factorX,
        height: result["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 3.0),
          ),
          child: Text(
            "${result['detectedClass']} ${(result['confidenceInClass'] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = pink,
              color: Colors.white,
              fontSize: 15.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildrenWidgets= [];

    stackChildrenWidgets.add(
      Positioned( //implementing live camera
        top: 0.0,
        left: 0.0,
        width: size.width,
        height: size.height - 100,
        child: Container(
          height: size.height - 100,
          child: (!cameraController.value.isInitialized)
              ? new Container()
              : AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController),
          ),
        ),
      ),
    );

    if(imgCamera != null) // if live stream is running
      {
        stackChildrenWidgets.addAll(displayBoxesAroundRecognizedObjects(size));
      }

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            margin: EdgeInsets.only(top:30),
            color: Colors.white,
            child: Stack(
            children: stackChildrenWidgets,
            ),
          ),
      ),
    );
  }
}
