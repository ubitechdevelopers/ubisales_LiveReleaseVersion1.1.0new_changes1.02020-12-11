// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:Shrine/services/fetch_location.dart';
import 'package:pdf/widgets.dart' as prefix0;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'genericCameraClass.dart';
import 'askregister.dart';
import 'package:Shrine/services/gethome.dart';
import 'package:Shrine/services/saveimage.dart';
import 'package:Shrine/model/timeinout.dart';
import 'attendance_summary.dart';
import 'database_models/qr_offline.dart';
import 'punchlocation.dart';
import 'drawer.dart';
import 'timeoff_summary.dart';
import 'package:Shrine/services/services.dart';
import 'globals.dart';
import 'package:Shrine/services/newservices.dart';
import 'leave_summary.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'punchlocation_summary.dart';
import 'settings.dart';
import 'profile.dart';
import 'reports.dart';
import 'services/services.dart';
import 'bulkatt.dart';
import 'package:Shrine/globals.dart' as globals;
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:Shrine/database_models/attendance_offline.dart';
import 'package:flutter/services.dart';
import 'package:Shrine/database_models/visits_offline.dart';
import "package:Shrine/notifications.dart";
import "offline_home.dart";
import 'Bottomnavigationbar.dart';
import 'login.dart';
import 'package:Shrine/addEmployee.dart';

// This app is a stateful, it tracks the user's current choice.
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const platform = const MethodChannel('location.spoofing.check');
  AppLifecycleState state;
  // StreamLocation sl = new StreamLocation();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  /*var _defaultimage =
      new NetworkImage("http://ubiattendance.ubihrm.com/assets/img/avatar.png");*/
  var profileimage;
  bool _checkLoaded = true;
  int _currentIndex = 1;
  String userpwd = "new";
  String newpwd = "new";
  int Is_Delete = 0;
  bool _visible = true;

  String admin_sts = '0';
  String mail_varified = '1';
  String AbleTomarkAttendance = '1';
  String act = "";
  String act1 = "";
  int alertdialogcount = 0;
  Timer timer;
  Timer timer1;
  Timer timerrefresh;
  int response;
  final Widget removedChild = Center();
  String fname = "",
      lname = "",
      empid = "",
      email = "",
      status = "",
      orgid = "",
      orgdir = "",
      sstatus = "",
      org_name = "",
      desination = "",
      desinationId = "",
      profile;
  bool issave = false;
  String areaStatus = '0';
  String aid = "";
  String shiftId = "";
  List<Widget> widgets;
  bool refreshsts = false;
  bool fakeLocationDetected = false;
  bool offlineDataSaved = false;
  bool internetAvailable = true;
  String address = '';

  @override
  void initState() {
    print('aintitstate');
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checknetonpage(context);
    initPlatformState();
    //setLocationAddress();
    // startTimer();
    platform.setMethodCallHandler(_handleMethod);
  }

  syncOfflineQRData() async {
    address = await getAddressFromLati(
        globals.assign_lat.toString(), globals.assign_long.toString());
    print(address +
        "xnjjjjjjlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");

    int serverAvailable = await checkConnectionToServer();
    if (serverAvailable == 1) {
      /*****************************For Attendances***********************************************/

      QROffline qrOffline = new QROffline.empty();

      List<QROffline> qrs = await qrOffline.select();

      List<Map> jsonList = [];
      if (qrs.isNotEmpty) {
        for (int i = 0; i < qrs.length; i++) {
          var address =
              await getAddressFromLati(qrs[i].Latitude, qrs[i].Longitude);
          print(address);
          jsonList.add({
            "Id": qrs[i].Id,
            "SupervisorId": qrs[i].SupervisorId,
            "Action": qrs[i].Action, // 0 for time in and 1 for time out
            "Date": qrs[i].Date,
            "OrganizationId": qrs[i].OrganizationId,
            "PictureBase64": qrs[i].PictureBase64,
            "Latitude": qrs[i].Latitude,
            "Longitude": qrs[i].Longitude,
            "Time": qrs[i].Time,
            "UserName": qrs[i].UserName,
            "Password": qrs[i].Password,
            "FakeLocationStatus": qrs[i].FakeLocationStatus,
            "FakeTimeStatus": qrs[i].FakeTimeStatus,
            "Address": address
          });
        }
        var jsonList1 = json.encode(jsonList);
        //LogPrint('response1: ' + jsonList1.toString());
        //LogPrint(attendances);
        FormData formData = new FormData.from({"data": jsonList1});

        Dio dioForSavingOfflineAttendance = new Dio();
        dioForSavingOfflineAttendance
            .post(path + "saveOfflineQRData", data: formData)
            .then((responseAfterSavingOfflineData) async {
          var response = json.decode(responseAfterSavingOfflineData.toString());

          print(
              '--------------------- Data Syncing Response--------------------------------');
          print(responseAfterSavingOfflineData);

          print(
              '--------------------- Data Syncing Response--------------------------------');
          for (int i = 0; i < response.length; i++) {
            var map = response[i];
            map.forEach((localDbId, status) {
              QROffline qrOffline = QROffline.empty();
              print(status);
              qrOffline.delete(int.parse(localDbId));
            });
          }
        });
      } else {
        setState(() {
          //  offlineDataSaved=true;
        });
      }
    }

    /*****************************For Attendances***********************************************/
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "locationAndInternet":
        locationThreadUpdatedLocation = true;
        // print(call.arguments["internet"].toString()+"akhakahkahkhakha");
        // Map<String,String> responseMap=call.arguments;
        if (call.arguments["internet"].toString() == "Internet Not Available") {
          internetAvailable = false;
          print("internet nooooot aaaaaaaaaaaaaaaaaaaaaaaavailable");
          //Navigator.of(context).pushReplacement(new MaterialPageRoute(builder: (BuildContext context) => OfflineHomePage(),maintainState: false));
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => OfflineHomePage()),
            (Route<dynamic> route) => false,
          );
        }
        var long = call.arguments["longitude"].toString();
        var lat = call.arguments["latitude"].toString();
        //lat=assign_lat.toString();
        //long=assign_long.toString();
        assign_lat = double.parse(lat);
        assign_long = double.parse(long);
        address = await getAddressFromLati(lat, long);
        print(address +
            "xnjjjjjjlllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll");
        globalstreamlocationaddr = address;
        print(call.arguments["mocked"].toString());
        getAreaStatus().then((res) {
          // print('called again');
          if (mounted) {
            setState(() {
              areaStatus = res.toString();
              if (areaId != 0 && geoFence == 1)
                AbleTomarkAttendance = res.toString();
            });
          }
        }).catchError((onError) {
          print('Exception occured in clling function.......');
          print(onError);
        });
        setState(() {
          if (call.arguments["mocked"].toString() == "Yes") {
            fakeLocationDetected = true;
          } else {
            fakeLocationDetected = false;
          }
          if (call.arguments["TimeSpoofed"].toString() == "Yes") {
            timeSpoofed = true;
          }
        });
        break;

        return new Future.value("");
    }
  }

  syncVisits(visits) async {
    for (int i = 0; i < visits.length; i++) {
      if (visits[i].VisitInLatitude.isEmpty) visits[i].VisitInLatitude = "0.0";
      if (visits[i].VisitOutLatitude.isEmpty)
        visits[i].VisitOutLatitude = "0.0";
      if (visits[i].VisitInLongitude.isEmpty)
        visits[i].VisitInLongitude = "0.0";
      if (visits[i].VisitOutLongitude.isEmpty)
        visits[i].VisitOutLongitude = "0.0";

      var VisitInaddress = await getAddressFromLati_offline(
          double.parse(visits[i].VisitInLatitude),
          double.parse(visits[i].VisitInLongitude));
      print("-------------------------------jhkhk--------------------------");
      print(visits[i].VisitOutLatitude + "   ");
      print(visits[i].VisitOutLongitude);
      var VisitOutaddress = await getAddressFromLati_offline(
          double.parse(visits[i].VisitOutLatitude),
          double.parse(visits[i].VisitOutLongitude));
      // print(address);
      List<Map> jsonList = [];
      jsonList.add({
        'Id': visits[i].Id,
        'EmployeeId': visits[i].EmployeeId,
        'VisitInLatitude': visits[i].VisitInLatitude,
        'VisitInLongitude': visits[i].VisitInLongitude,
        'VisitInTime': visits[i].VisitInTime,
        'VisitInDate': visits[i].VisitInDate,
        'VisitOutLatitude': visits[i].VisitOutLatitude,
        'VisitOutLongitude': visits[i].VisitOutLongitude,
        'VisitOutTime': visits[i].VisitOutTime,
        'VisitOutDate': visits[i].VisitOutDate,
        'ClientName': visits[i].ClientName,
        'VisitInDescription': visits[i].VisitInDescription,
        'VisitOutDescription': visits[i].VisitOutDescription,
        'OrganizationId': visits[i].OrganizationId,
        'Skipped': visits[i].Skipped,
        'VisitInImage': visits[i].VisitInImage,
        'VisitOutImage': visits[i].VisitOutImage,
        'VisitInAddress': VisitInaddress,
        'VisitOutAddress': VisitOutaddress,
        'FakeLocationStatusVisitIn': visits[i].FakeLocationStatusVisitIn,
        'FakeLocationStatusVisitOut': visits[i].FakeLocationStatusVisitOut,
        'FakeVisitInTimeStatus': visits[i].FakeVisitInTimeStatus,
        'FakeVisitOutTimeStatus': visits[i].FakeVisitOutTimeStatus
      });

      var jsonList1 = json.encode(jsonList);
      LogPrint('response1: ' + jsonList1.toString());
      //LogPrint(attendances);
      FormData formData = new FormData.from({"data": jsonList1});

      Dio dioForSavingOfflineAttendance = new Dio();
      dioForSavingOfflineAttendance
          .post(globals.path + "saveOfflineVisits", data: formData)
          .then((responseAfterSavingOfflineData) async {
        var response = json.decode(responseAfterSavingOfflineData.toString());

        print(
            '--------------------- Visit Syncing Response--------------------------------');
        LogPrint(responseAfterSavingOfflineData);

        print(
            '--------------------- Visit Syncing Response--------------------------------');
        for (int i = 0; i < response.length; i++) {
          var map = response[i];
          map.forEach((localDbId, status) {
            VisitsOffline visitsOffline = VisitsOffline.empty();
            print(status);
            visitsOffline.delete(int.parse(localDbId));
          });
        }
        setState(() {
          offlineDataSaved = true;
        });
      });
    }
  }

  syncOfflineData() async {
    int serverAvailable = await checkConnectionToServer();
    if (serverAvailable == 1) {
      /*****************************For Attendances***********************************************/
      await syncOfflineQRData();

      AttendanceOffline attendanceOffline = new AttendanceOffline.empty();
      VisitsOffline visitsOffline = VisitsOffline.empty();

      List<AttendanceOffline> attendances = await attendanceOffline.select();
      List<VisitsOffline> visits = await visitsOffline.select();

      List<Map> jsonList = [];
      List<Map> jsonListVisits = [];
      if (visits.isNotEmpty) {
        await syncVisits(visits);
      } else {
        offlineDataSaved = true;
      }
      if (attendances.isNotEmpty) {
        for (int i = 0; i < attendances.length; i++) {
          var address = await getAddressFromLati_offline(
             double.parse(attendances[i].Latitude) , double.parse(attendances[i].Longitude));
          print(address);
          jsonList.add({
            "Id": attendances[i].Id,
            "UserId": attendances[i].UserId,
            "Action": attendances[i].Action, // 0 for time in and 1 for time out
            "Date": attendances[i].Date,
            "OrganizationId": attendances[i].OrganizationId,
            "PictureBase64": attendances[i].PictureBase64,
            "Latitude": attendances[i].Latitude,
            "Longitude": attendances[i].Longitude,
            "Time": attendances[i].Time,
            "FakeLocationStatus": attendances[i].FakeLocationStatus,
            "FakeTimeStatus": attendances[i].FakeTimeStatus,
            "Address": address
          });
        }
        var jsonList1 = json.encode(jsonList);
        //LogPrint('response1: ' + jsonList1.toString());
        //LogPrint(attendances);
        FormData formData = new FormData.from({"data": jsonList1});

        Dio dioForSavingOfflineAttendance = new Dio();
        dioForSavingOfflineAttendance
            .post(globals.path + "saveOfflineData", data: formData)
            .then((responseAfterSavingOfflineData) async {
          var response = json.decode(responseAfterSavingOfflineData.toString());

          print('--------------------- Data Syncing Response--------------------------------');
          LogPrint(responseAfterSavingOfflineData);

          print('--------------------- Data Syncing Response--------------------------------');
          for (int i = 0; i < response.length; i++) {
            var map = response[i];
            map.forEach((localDbId, status) {
              AttendanceOffline attendanceOffline = AttendanceOffline.empty();
              print(status);
              attendanceOffline.delete(int.parse(localDbId));
            });
          }
          setState(() {
            offlineDataSaved = true;
          });

          Home ho = new Home();

          act = await ho.checkTimeIn(empid, orgdir);
          print("Action from check time in");
          ho.managePermission(empid, orgdir, desinationId);

          setState(() {
            act1 = act;
          });
        });
      } else {
        setState(() {
          offlineDataSaved = true;
        });
      }
    }

    Home ho = new Home();
    act = await ho.checkTimeIn(empid, orgdir);
    print("Action from check time in1");
    if (timeoutdate == 'nextdate' && act == 'TimeOut') dialogwidget(context);
    ho.managePermission(empid, orgdir, desinationId);

    setState(() {
      act1 = act;
    });

    /*****************************For Attendances***********************************************/
  }

  static void LogPrint(Object object) async {
    int defaultPrintLength = 1020;
    if (object == null || object.toString().length <= defaultPrintLength) {
      print(object);
    } else {
      String log = object.toString();
      int start = 0;
      int endIndex = defaultPrintLength;
      int logLength = log.length;
      int tmpLogLength = log.length;
      while (endIndex < logLength) {
        print(log.substring(start, endIndex));
        endIndex += defaultPrintLength;
        start += defaultPrintLength;
        tmpLogLength -= defaultPrintLength;
      }
      if (tmpLogLength > 0) {
        print(log.substring(start, logLength));
      }
    }
  }

  void didChangeAppLifecycleState(AppLifecycleState appLifecycleState) {
    /*
    setState(() {
      state = appLifecycleState;
      if(state==AppLifecycleState.resumed){
        //print('WidgetsBindingObserver called');

        if(timerrefresh.isActive){
          timerrefresh.cancel();
        }
        if(refreshsts) {
          //timerrefresh.cancel();
          if(timerrefresh.isActive){
            timerrefresh.cancel();
          }
          refreshsts=false;
          print('WidgetsBindingObserver called refreshsts false');
          initPlatformState();
          setLocationAddress();
          startTimer();
        }
      }else if(state==AppLifecycleState.paused){
       // print('AppLifecycleState.paused');

        const tenSec = const Duration(seconds: 180);
        timerrefresh = new Timer.periodic(tenSec, (Timer t) {
          print('refreshsts true');
          refreshsts=true;
          timerrefresh.cancel();
        });
      }
    });*/
  }
/*
  startTimer() {
    const fiveSec = const Duration(seconds: 2);
    int count = 0;
    // print('called timer');
    timer = new Timer.periodic(fiveSec, (Timer t) {
      //print("timmer is running");
      count++;
      //print("timer counter" + count.toString());
     // setLocationAddress();
      if (stopstreamingstatus) {
        t.cancel();
        //print("timer canceled");
      }
      /*  if(count==5){
        t.cancel();
      }*/
    });
  }

  startTimer1() {
    const fiveSec = const Duration(seconds: 1);
    int count = 0;
    timer1 = new Timer.periodic(fiveSec, (Timer t) {
      print("timer is running");
    });
  }

  setLocationAddress() async {

    //print('called');
    getAreaStatus().then((res) {
      // print('called again');
      if (mounted) {
        setState(() {
          areaStatus = res.toString();
        });
      }
    }).catchError((onError) {
      print('Exception occured in clling function.......');
      print(onError);
    });
    if (mounted) {
      setState(() {
        streamlocationaddr = globalstreamlocationaddr;
        print('loc: ' + streamlocationaddr);
        if (list != null && list.length > 0) {
          lat = list[list.length - 1].latitude.toString();
          long = list[list.length - 1].longitude.toString();
          if (streamlocationaddr == '') {
            streamlocationaddr = lat + ", " + long;
          }
        }
        if (streamlocationaddr == '') {
          print('again');
          timer.cancel();
        //  sl.startStreaming(5);
         // startTimer();
        }
        //print("home addr" + streamlocationaddr);
        //print(lat + ", " + long);

        //print(stopstreamingstatus.toString());
      });
    }
  }
*/
  launchMap(String lat, String long) async {
    String url = "https://maps.google.com/?q=" + lat + "," + long;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      //print('Could not launch $url');
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  initPlatformState() async {
    /*await availableCameras();*/
    checknetonpage(context);
    //checkLocationEnabled(context);
    appResumedPausedLogic(context);

    Future.delayed(const Duration(milliseconds: 3000), () {
// Here you can write your code
      if (mounted)
        setState(() {
          locationThreadUpdatedLocation = locationThreadUpdatedLocation;
        });
    });
    SystemChannels.lifecycle.setMessageHandler((msg) async {});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    empid = prefs.getString('empid') ?? '';
    orgdir = prefs.getString('orgdir') ?? '';
    desinationId = prefs.getString('desinationId') ?? '';
    response = prefs.getInt('response') ?? 0;
    getAreaStatus().then((res) {
      // print('called again');
      if (mounted) {
        setState(() {
          areaStatus = res.toString();
          if (areaId != 0 && geoFence == 1)
            AbleTomarkAttendance = res.toString();
        });
      }
    }).catchError((onError) {
      print('Exception occured in clling function.......');
      print(onError);
    });
    if (response == 1) {
      Loc lock = new Loc();

      await syncOfflineData();
      // //print(act);
      ////print("this is-----> "+act);
      ////print("this is main "+location_addr);
      prefs = await SharedPreferences.getInstance();
      var netAvailable = 0;
      netAvailable = await checkNet();
      if (mounted && netAvailable == 1) {
        setState(() {
          Is_Delete = prefs.getInt('Is_Delete') ?? 0;
          newpwd = prefs.getString('newpwd') ?? "";
          userpwd = prefs.getString('usrpwd') ?? "";
          print("New pwd" + newpwd + "  User ped" + userpwd);

          admin_sts = prefs.getString('sstatus').toString() ?? '0';
          mail_varified = prefs.getString('mail_varified').toString() ?? '0';
          alertdialogcount = globalalertcount;
          print('aid again');
          response = prefs.getInt('response') ?? 0;
          fname = prefs.getString('fname') ?? '';
          lname = prefs.getString('lname') ?? '';
          empid = prefs.getString('empid') ?? '';
          email = prefs.getString('email') ?? '';
          status = prefs.getString('status') ?? '';
          orgid = prefs.getString('orgid') ?? '';
          orgdir = prefs.getString('orgdir') ?? '';
          org_name = prefs.getString('org_name') ?? '';
          desination = prefs.getString('desination') ?? '';
          profile = prefs.getString('profile') ?? '';
          print("Profile Image" + profile);
          profileimage = new NetworkImage(profile);
          setaddress();
          // _checkLoaded = false;
          // //print("1-"+profile);
          profileimage
              .resolve(new ImageConfiguration())
              .addListener(new ImageStreamListener((_, __) {
            if (mounted) {
              setState(() {
                _checkLoaded = false;
              });
            }
          }));
          // //print("2-"+_checkLoaded.toString());
          shiftId = prefs.getString('shiftId') ?? "";
          aid = prefs.getString('aid') ?? "";
          print('aid again' + aid);
          print('act again' + aid);
          ////print("this is set state "+location_addr1);
          act1 = act;
          print(act1);
        });
      }
    }
    appResumedPausedLogic(context);
  }

  setaddress() async {
    globalstreamlocationaddr = await getAddressFromLati(
        globals.assign_lat.toString(), globals.assign_long.toString());
    var serverConnected = await checkConnectionToServer();
    if (serverConnected != 0) if (globals.assign_lat == 0.0 ||
        globals.assign_lat == null ||
        !locationThreadUpdatedLocation) {
      cameraChannel.invokeMethod("openLocationDialog");
      /*
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return WillPopScope(
                onWillPop: () {},
                child: new AlertDialog(
            title: new Text(""),
            content: new Text("Sorry we can't continue without GPS"),
            actions: <Widget>[
              RaisedButton(
                child: new Text(
                  "Turn On",
                  style: new TextStyle(
                    color: Colors.white,
                  ),
                ),
                color: Colors.orangeAccent,
                onPressed: () async{
                  cameraChannel.invokeMethod("openLocationDialog");
                  //openLocationSetting();
                },
              ),
              RaisedButton(
                child: new Text(
                  "Done",
                  style: new TextStyle(
                    color: Colors.white,
                  ),
                ),
                color: Colors.orangeAccent,
                onPressed: () {
                  cameraChannel.invokeMethod("startAssistant");
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                 /*
                  Navigator.of(context, rootNavigator: true)
                      .pop();
*/
                },
              ),
            ],
          ));});

       */
    }
  }

  @override
  Widget build(BuildContext context) {
    (mail_varified == '0' && alertdialogcount == 0 && admin_sts == '1')
        ? Future.delayed(Duration.zero, () => _showAlert(context))
        : "";

    return (response == 0 ||
            userpwd != newpwd ||
            Is_Delete != 0 ||
            orgid == '10932')
        ? new AskRegisterationPage()
        : getmainhomewidget();
    /* return MaterialApp(
      home: (response==0) ? new AskRegisterationPage() : getmainhomewidget(),
    );*/
  }

  void showInSnackBar(String value) {
    final snackBar = SnackBar(
        content: Text(
      value,
      textAlign: TextAlign.center,
    ));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  getmainhomewidget() {
    return new WillPopScope(
        onWillPop: () async => true,
        child: new Scaffold(
          backgroundColor: Colors.white,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                new Text(org_name, style: new TextStyle(fontSize: 20.0)),
              ],
            ),
            automaticallyImplyLeading: false,
            backgroundColor: appcolor,
            // backgroundColor: Color.fromARGB(255,63,163,128),
          ),
          //bottomSheet: getQuickLinksWidget(),
          persistentFooterButtons: <Widget>[
            quickLinkList1(),
          ],

          bottomNavigationBar: Bottomnavigationbar(),

          endDrawer: new AppDrawer(),
          body: (act1 == '') ? Center(child: loader()) : checkalreadylogin(),
          floatingActionButton: (admin_sts == '1' || admin_sts == '2')
              ? new FloatingActionButton(
                  mini: false,
                  backgroundColor: buttoncolor,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddEmployee()),
                    );
                  },
                  tooltip: 'Add Employee',
                  child: new Icon(Icons.person_add),
                )
              : new Center(),
        ));
  }

  checkalreadylogin() {
    ////print("---->"+response.toString());
    if (response == 1) {
      return new IndexedStack(
        index: _currentIndex,
        children: <Widget>[
          underdevelopment(),
          (globalstreamlocationaddr != "Location not fetched." ||
                  globals.globalstreamlocationaddr.isNotEmpty)
              ? mainbodyWidget()
              : refreshPageWidgit(),
          //(false) ? mainbodyWidget() : refreshPageWidgit(),
          underdevelopment()
        ],
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AskRegisterationPage()),
        (Route<dynamic> route) => false,
      );
    }

    /* if(userpwd!=newpwd){
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AskRegisterationPage()),
            (Route<dynamic> route) => false,
      );
    }*/
  }

  refreshPageWidgit() {
    if (globals.globalstreamlocationaddr.isNotEmpty) {
      return new Container(
        child: Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 20.0,
                    ),
                    /*
                    Icon(
                      Icons.all_inclusive,
                      color: Colors.teal,
                    ),
                    Text(
                      "Sorry! can't fetch location. \nPlease check if GPS is enabled on your device",
                      style: new TextStyle(fontSize: 20.0, color: Colors.red),
                    )*/
                    Container(
                      decoration: new ShapeDecoration(
                        shape: new RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(13.0)),
                        color: Colors.red,
                      ),
                      child: Text(
                        '\nProblem Getting Location! Please turn on GPS and try again.',
                        textAlign: TextAlign.center,
                        style:
                            new TextStyle(color: Colors.white, fontSize: 15.0),
                      ),
                      width: 220.0,
                      height: 90.0,
                    ),
                  ]),
              SizedBox(height: 15.0),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 20.0,
                    ),
                    /*
                    Text(
                      "Note: ",
                      style: new TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    Text(
                      " If Location not being fetched automatically?",
                      style: new TextStyle(fontSize: 12.0, color: Colors.black),
                      textAlign: TextAlign.left,
                    ),*/
                    /* new InkWell(
                      child: new Text(
                        "Fetch Location now",
                        style: new TextStyle(
                            color: Colors.teal,
                            decoration: TextDecoration.underline),
                      ),
                      onTap: () {
                        sl.startStreaming(5);
                        startTimer();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );
                      },
                    )*/
                  ]),
              FlatButton(
                child: new Text(
                  "Try now",
                  style: new TextStyle(
                      color: appcolor, decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  //  sl.startStreaming(5);
                  // startTimer();
                  cameraChannel.invokeMethod("startAssistant");
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );*/
                },
              ),
            ],
          ),
        ),
      );
    } else {
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Sorry we can not continue with out location.',
            textAlign: TextAlign.center,
            style: new TextStyle(fontSize: 14.0, color: Colors.red)),
        RaisedButton(
          child: Text('Open Settings'),
          onPressed: () {
            PermissionHandler().openAppSettings();
          },
        ),
      ]);
    }
  }

  loader() {
    return new Container(
      child: Center(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Image.asset('assets/spinner.gif', height: 50.0, width: 50.0),
            ]),
      ),
    );
  }

  underdevelopment() {
    return new Container(
      child: Center(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Icon(
                Icons.android,
                color: appcolor,
              ),
              Text(
                "Under development",
                style: new TextStyle(fontSize: 30.0, color: appcolor),
              )
            ]),
      ),
    );
  }

  poorNetworkWidget() {
    return Container(
      child: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.error,
                      color: appcolor,
                    ),
                    Text(
                      " Poor network connection.",
                      style: new TextStyle(fontSize: 20.0, color: appcolor),
                    ),
                  ]),
              SizedBox(height: 5.0),
              FlatButton(
                child: new Text(
                  "Refresh Page",
                  style: new TextStyle(
                      color: appcolor, decoration: TextDecoration.underline),
                ),
                onPressed: () {
                  // sl.startStreaming(5);
                  // startTimer();
                  cameraChannel.invokeMethod("startAssistant");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
            ]),
      ),
    );
  }

  mainbodyWidget() {
    ////to do check act1 for poor network connection

    if (act1 == "Poor network connection") {
      return poorNetworkWidget();
    } else {
      return ListView(
        physics: NeverScrollableScrollPhysics(),
        children: <Widget>[
          Container(
            // foregroundDecoration: BoxDecoration(color:Colors.red ),
            height: MediaQuery.of(context).size.height * 0.80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * .06),
                new GestureDetector(
                  onTap: () {
                    // profile navigation
                    /* Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));*/
                  },
                  child: new Stack(children: <Widget>[
                    Container(
                        //   foregroundDecoration: BoxDecoration(color:Colors.yellow ),
                        width: MediaQuery.of(context).size.height * .16,
                        height: MediaQuery.of(context).size.height * .16,
                        decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            image: new DecorationImage(
                              fit: BoxFit.fill,
                              image: _checkLoaded
                                  ? AssetImage('assets/avatar.png')
                                  : profileimage,
                              //image: AssetImage('assets/avatar.png')
                            ))),
                    /*new Positioned(
                    left: MediaQuery.of(context).size.width*.14,
                    top: MediaQuery.of(context).size.height*.11,
                    child: new RawMaterialButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
                      },
                      child: new Icon(
                        Icons.edit,
                        size: 18.0,
                      ),
                      shape: new CircleBorder(),
                      elevation: 0.5,
                      fillColor: Colors.teal,
                      padding: const EdgeInsets.all(1.0),
                    ),
                  ),*/
                  ]),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * .02),

                Text(fname.toUpperCase() + " " + lname.toUpperCase(),
                    style: new TextStyle(
                      color: Colors.black87,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    )),

                SizedBox(height: MediaQuery.of(context).size.height * .01),
                // SizedBox(height: MediaQuery.of(context).size.height*.01),
                (act1 == '') ? loader() : getMarkAttendanceWidgit(),
              ],
            ),
          ),
        ],
      );
    }
  }

  getMarkAttendanceWidgit() {
    if (act1 == "Imposed") {
      return getAlreadyMarkedWidgit();
    } else {
      return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            /* Text('Mark Attendance',
                style: new TextStyle(fontSize: 30.0, color: Colors.teal)),
            SizedBox(height: 10.0),*/
            getwidget(globals.globalstreamlocationaddr),
            //    SizedBox(height: MediaQuery.of(context).size.height*.1),
            /*      Container(
            //foregroundDecoration: BoxDecoration(color:Colors.green ),
            margin: EdgeInsets.only(bottom:MediaQuery.of(context).size.height*0),
            //padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.02,bottom:MediaQuery.of(context).size.height*0.02),
              height: MediaQuery.of(context).size.height*.10,
              color: Colors.teal.withOpacity(0.8),
              child: Column(
                  children:[
                    SizedBox(height: 10.0,),
                    getQuickLinksWidget()
                  ]),
            ),
*/
          ]);
    }
  }

  Widget quickLinkList1() {
    return Container(
      // color: appcolor,

      width: MediaQuery.of(context).size.width * 0.95,
      // padding: EdgeInsets.only(top:MediaQuery.of(context).size.height*0.03,bottom:MediaQuery.of(context).size.height*0.03, ),
      child: getBulkAttnWid(),
    );
  }

  Widget getBulkAttnWid() {
    List<Widget> widList = List<Widget>();

    if (bulkAttn.toString() == '1' && (admin_sts == '1' || admin_sts == '2')) {
      widList.add(Container(
        padding: EdgeInsets.only(top: 5.0),
        constraints: BoxConstraints(
          maxHeight: 50.0,
          minHeight: 20.0,
        ),
        child: new GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Bulkatt()),
              );
            },
            child: Column(
              children: [
                Icon(
                  const IconData(0xe81d, fontFamily: "CustomIcon"),
                  size: 30.0,
                  color: iconcolor,
                ),
                Text('Group',
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontSize: 12.0, color: iconcolor)),
              ],
            )),
      ));
    }
    widList.add(Container(
      padding: EdgeInsets.only(top: 5.0),
      constraints: BoxConstraints(
        maxHeight: 50.0,
        minHeight: 20.0,
      ),
      child: new GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
            );
          },
          child: Column(
            children: [
              Icon(
                const IconData(0xe81c, fontFamily: "CustomIcon"),
                size: 30.0,
                color: iconcolor,
              ),
              Text('Log',
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 12.0, color: iconcolor)),
            ],
          )),
    ));

    if (visitpunch.toString() == '1') {
      widList.add(Container(
        padding: EdgeInsets.only(top: 5.0),
        constraints: BoxConstraints(
          maxHeight: 50.0,
          minHeight: 20.0,
        ),
        child: new GestureDetector(
            onTap: () {
              /*showInSnackBar("Under development.");*/
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PunchLocationSummary()),
              );
            },
            child: Column(
              children: [
                Icon(
                  const IconData(0xe821, fontFamily: "CustomIcon"),
                  size: 30.0,
                  color: iconcolor,
                ),
                Text('Visits',
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontSize: 12.0, color: iconcolor)),
              ],
            )),
      ));
    }

    if (timeOff.toString() == '1') {
      widList.add(Container(
        padding: EdgeInsets.only(top: 5.0),
        constraints: BoxConstraints(
          maxHeight: 50.0,
          minHeight: 20.0,
        ),
        child: new GestureDetector(
            onTap: () {
              //  //print('----->>>>>'+getOrgPerm(1).toString());
              getOrgPerm(1).then((res) {
                {
                  //   //print('----->>>>>'+res.toString());
                  if (res) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TimeoffSummary()),
                    );
                  } else
                    showInSnackBar('Please buy this feature');
                }
              });
            },
            child: Column(
              children: [
                Icon(
                  const IconData(0xe818, fontFamily: "CustomIcon"),
                  size: 30.0,
                  color: iconcolor,
                ),
                Text(' Time Off',
                    textAlign: TextAlign.center,
                    style: new TextStyle(fontSize: 12.0, color: iconcolor)),
              ],
            )),
      ));
    }

    /* widList.add();
    widList.add();*/
    return (Row(
      children: widList,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    ));
  }

  List<GestureDetector> quickLinkList() {
    List<GestureDetector> list = new List<GestureDetector>();
    // //print("permission list-->>>>>>"+data.toString());
    list.add(new GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MyApp()),
          );
        },
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 30.0,
              color: Colors.white,
            ),
            Text('Attendance',
                textAlign: TextAlign.center,
                style: new TextStyle(fontSize: 15.0, color: Colors.white)),
          ],
        )));

    if (punchlocation_permission == 1) {
      list.add(new GestureDetector(
          onTap: () {
            /*showInSnackBar("Under development.");*/
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PunchLocation()),
            );
          },
          child: Column(
            children: [
              Icon(
                Icons.add_location,
                size: 30.0,
                color: Colors.white,
              ),
              Text('Visits',
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 15.0, color: Colors.white)),
            ],
          )));
    }

    if (timeoff_permission == 1) {
      list.add(new GestureDetector(
          onTap: () {
            //  //print('----->>>>>'+getOrgPerm(1).toString());
            getOrgPerm(1).then((res) {
              {
                //   //print('----->>>>>'+res.toString());
                if (res) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TimeoffSummary()),
                  );
                } else
                  showInSnackBar('Please buy this feature');
              }
            });
          },
          child: Column(
            children: [
              Icon(
                Icons.access_alarm,
                size: 30.0,
                color: Colors.white,
              ),
              Text('Time Off',
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 15.0, color: Colors.white)),
            ],
          )));
    }

    if (leave_permission == 1) {
      list.add(new GestureDetector(
          onTap: () {
            getOrgPerm(1).then((res) {
              {
                //   //print('----->>>>>'+res.toString());
                if (res) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LeaveSummary()),
                  );
                } else
                  showInSnackBar('Please buy this feature');
              }
            });
          },
          child: Column(
            children: [
              Icon(
                Icons.exit_to_app,
                size: 30.0,
                color: Colors.white,
              ),
              Text('Leave',
                  textAlign: TextAlign.center,
                  style: new TextStyle(fontSize: 15.0, color: Colors.white)),
            ],
          )));
    }
    return list;
  }

  getQuickLinksWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: quickLinkList(),
    );
  }

  getAlreadyMarkedWidgit() {
    return Column(children: <Widget>[
      SizedBox(height: MediaQuery.of(context).size.height * .05),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Card(
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Colors.amber.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              child: Text(
                ' Attendance has been marked. Thank You!',
                textAlign: TextAlign.center,
                style: new TextStyle(
                    color: Colors.amber,
                    fontSize: 18.0,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  getwidget(String addrloc) {
    if (addrloc != "Location not fetched.") {
      return Column(children: [
        ButtonTheme(
          minWidth: 120.0,
          height: 45.0,
          child: getTimeInOutButton(),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * .04),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 1,
              ),
            ),
            elevation: 0.0,
            borderOnForeground: true,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height * .15,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FlatButton(
                          child: new Text(
                              globals.globalstreamlocationaddr != null
                                  ? globals.globalstreamlocationaddr
                                  : "Location not fetched",
                              textAlign: TextAlign.center,
                              style: new TextStyle(
                                  fontSize: 14.0, color: Colors.black54)),
                          onPressed: () {
                            launchMap(globals.assign_lat.toString(),
                                globals.assign_long.toString());
                            /* Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HomePage()),
                        );*/
                          },
                        ),
                        new Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new InkWell(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        const IconData(0xe81a,
                                            fontFamily: "CustomIcon"),
                                        size: 15.0,
                                        color: Colors.teal,
                                      ),
                                      Text("  "),
                                      Text(
                                        "Refresh Location", // main  widget
                                        style: new TextStyle(
                                            color: appcolor,
                                            decoration: TextDecoration.none),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    //  startTimer();
                                    //  sl.startStreaming(5);
                                    cameraChannel
                                        .invokeMethod("startAssistant");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => HomePage()),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
                        ),
//                    SizedBox(
//                      height: 5.0,
//                    ),
                        if (fakeLocationDetected)
                          Container(
                            padding: EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              color: Color(0xfffc6203),
                              //  border: Border(left: 1.0,right: 1.0,top: 1.0,bottom: 1.0),
                            ),
                            child: Text(
                              'Fake Location',
                              style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0),
                            ),
                          )
                        else
                          (areaId != 0 && geoFence == 1)
                              ? areaStatus == '0'
                                  ? Container(
                                      padding:
                                          EdgeInsets.only(top: 5.0, right: 5.0),
                                      child: Text(
                                        'Outside Fenced Area',
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.0),
                                      ),
                                    )
                                  : Container(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text(
                                        'Within Fenced Area',
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.0),
                                      ),
                                    )
                              : Center(),
                      ])),
            ),
          ),
        ),
      ]);
    } else {
      return Column(children: [
        Text('Sorry we can not continue without location',
            textAlign: TextAlign.center,
            style: new TextStyle(fontSize: 14.0, color: Colors.red)),
        RaisedButton(
          child: Text('Open Settings'),
          onPressed: () {
            PermissionHandler().openAppSettings();
          },
        ),
      ]);
    }
    return Container(width: 0.0, height: 0.0);
  }

  getTimeInOutButton() {
    if (act1 == 'TimeIn') {
      return RaisedButton(
        elevation: 0.0,
        highlightElevation: 0.0,
        highlightColor: Colors.transparent,
        disabledElevation: 0.0,
        focusColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
//          side: BorderSide( color: Colors.green.withOpacity(0.5), width: 2,),
        ),
        clipBehavior: Clip.antiAlias,
        child: Text('TIME IN',
            style: new TextStyle(
                fontSize: 18.0, color: Colors.white, letterSpacing: 2)),
        color: globals.buttoncolor,
        onPressed: () {
          globals.globalCameraOpenedStatus = true;
          // //print("Time out button pressed");

          saveImage();
          //Navigator.pushNamed(context, '/home');
        },
      );
    } else if (act1 == 'TimeOut') {
      return RaisedButton(
        clipBehavior: Clip.antiAlias,
        elevation: 0.0,
        highlightElevation: 0.0,
        highlightColor: Colors.transparent,
        disabledElevation: 50.0,
        focusColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
//          side: BorderSide( color: Colors.red.withOpacity(0.5), width: 2,),
        ),
        child: Text('TIME OUT',
            style: new TextStyle(
                fontSize: 18.0, color: Colors.white, letterSpacing: 2)),
        color: globals.buttoncolor,
        onPressed: () {
          globals.globalCameraOpenedStatus = true;
          // //print("Time out button pressed");
          saveImage();
        },
      );
    }
  }

  Text getText(String addrloc) {
    if (addrloc != "PermissionStatus.deniedNeverAsk") {
      return Text('You are at: ' + addrloc,
          textAlign: TextAlign.center, style: new TextStyle(fontSize: 14.0));
    } else {
      return new Text(
          'Location access is denied. Enable the access through the settings.',
          textAlign: TextAlign.center,
          style: new TextStyle(fontSize: 14.0, color: Colors.red));
      /*return new  Text('Location is restricted from app settings, click here to allow location permission and refresh', textAlign: TextAlign.center, style: new TextStyle(fontSize: 14.0,color: Colors.red));*/
    }
  }

  saveImage() async {
    timeWhenButtonPressed = DateTime.now();
    //  sl.startStreaming(5);
    print('aidId' + aid);
    var FakeLocationStatus = 0;

    if(AbleTomarkAttendance != '1' && globals.ableToMarkAttendance == 1 && geoFence == 1) {
      showDialog(
          context: context,
          child: new AlertDialog(
            //title: new Text("Warning!"),
            content: new Text("You Can't punch Attendance from Outside fence."),
          ));
      return null;
    }

    if (fakeLocationDetected) {
      FakeLocationStatus = 1;
    }
    MarkTime mk = new MarkTime(
        empid,
        globals.globalstreamlocationaddr,
        aid,
        act1,
        shiftId,
        orgdir,
        globals.assign_lat.toString(),
        assign_long.toString(),
        FakeLocationStatus);
    /* mk1 = mk;*/
    print("inside saveImage Home");
    var connectivityResult = await (new Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraExampleHome()),
      );*/
      SaveImage saveImage = new SaveImage();
      bool issave = false;
      if (mounted) {
        setState(() {
          act1 = "";
        });
      }
      issave = await saveImage.saveTimeInOutImagePicker(mk, context);
      print(issave);
      if (issave == null) {
        globals.timeWhenButtonPressed = null;
        showDialog(
            context: context,
            child: new AlertDialog(
              title: new Text(""),
              content: new Text(
                  "Sorry you have taken more time than expected to mark attendance. Please mark again!"),
            ));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }

      if (issave) {
        showDialog(
            context: context,
            child: new AlertDialog(
              content: new Text("Attendance marked successfully!"),
            ));
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyApp()),
        );
        if (mounted) {
          setState(() {
            act1 = act;
          });
        }
      } else {
        showDialog(
            context: context,
            child: new AlertDialog(
              title: new Text("Warning!"),
              content: new Text("Problem while marking attendance, try again."),
            ));
        if (mounted) {
          setState(() {
            act1 = act;
          });
        }
      }
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int offlinemode = prefs.getInt("OfflineModePermission");
      if (offlinemode == 1) {
        print("Routing");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => OfflineHomePage()),
          (Route<dynamic> route) => false,
        );
      } else {
        showDialog(
            context: context,
            child: new AlertDialog(
              content: new Text("Internet connection not found!."),
            ));
      }
    }

    /*SaveImage saveImage = new SaveImage();
    bool issave = false;
    setState(() {
      act1 = "";
    });
    issave = await saveImage.saveTimeInOut(mk);
    ////print(issave);
    if (issave) {

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
      setState(() {
        act1 = act;
      });
    } else {
      setState(() {
        act1 = act;
      });
    }*/
  }

  void dialogwidget(BuildContext context) {
    print("Sohan patel");
    showDialog(
        context: context,
        barrierDismissible: false,
        child: new AlertDialog(
          content: new Text('Do you want mark yesterday timeout?'),
          actions: <Widget>[
            RaisedButton(
              child: Text(
                ' Yes ',
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.amber,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
            FlatButton(
              child: Text(' No '),
              shape: Border.all(),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                Home ho = new Home();
                print("Test");
                await ho.updateTimeOut(empid, orgdir);
                act = await ho.checkTimeIn(empid, orgdir);
                print("Action from check time in1");
                if (timeoutdate == 'nextdate' && act == 'TimeOut')
                  dialogwidget(context);
                ho.managePermission(empid, orgdir, desinationId);

                setState(() {
                  act1 = act;
                });
              },
            ),
          ],
        ));
  }
/*
  saveImage_old() async {
   // sl.startStreaming(5);
var FakeLocationStatus=0;
    if(fakeLocationDetected){
      FakeLocationStatus=1;
    }
    MarkTime mk = new MarkTime(
        empid, streamlocationaddr, aid, act1, shiftId, orgdir, lat, long,FakeLocationStatus
    );
    /* mk1 = mk;*/

    var connectivityResult = await (new Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      /* Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraExampleHome()),
      );*/
      SaveImage saveImage = new SaveImage();
      if (mounted)
        setState(() {
          act1 = "";
        });

      saveTimeInOutImagePicker_new(mk).then((res) {
        /*
           print("res: "+res.toString());
           print("issave: "+issave.toString());
           if (issave==true || res==true) {
             showDialog(context: context, child:
             new AlertDialog(
               content: new Text("Attendance marked successfully!"),
             )
             );
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => MyApp()),
             );
             setState(() {
               act1 = act;
             });
           } else {
             showDialog(context: context, child:
             new AlertDialog(
               title: new Text("Warning!"),
               content: new Text("Problem while marking attendance, try again."),
             )
             );
             setState(() {
               act1 = act;
             });
           }*/
      });
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int offlinemode=prefs.getInt("OfflineModePermission");
      if(offlinemode==1){
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OfflineHomePage()),
        );

      }
      else{
        showDialog(
            context: context,
            child: new AlertDialog(
              content: new Text("Internet connection not found!."),
            ));
      }
    }

    /*SaveImage saveImage = new SaveImage();
    bool issave = false;
    setState(() {
      act1 = "";
    });
    issave = await saveImage.saveTimeInOut(mk);
    ////print(issave);
    if (issave) {

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
      setState(() {
        act1 = act;
      });
    } else {
      setState(() {
        act1 = act;
      });
    }*/
  }
*/
/*  saveImage() async {

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CameraApp()),
      );

  }*/

  resendVarification() async {
    NewServices ns = new NewServices();
    bool res = await ns.resendVerificationMail(orgid);
    if (res) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  content: Row(children: <Widget>[
                Text(
                    "Verification link has been sent to \nyour organization's registered Email."),
              ])));
    }
  }

  void _showAlert(BuildContext context) {
    globalalertcount = 1;
    if (mounted)
      setState(() {
        alertdialogcount = 1;
      });
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text("Verify Email"),
            content: Container(
                height: MediaQuery.of(context).size.height * 0.22,
                child: Column(children: <Widget>[
                  Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                          "Your organization's Email is not verified. Please verify now.")),
                  new Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        ButtonBar(
                          children: <Widget>[
                            FlatButton(
                              child: Text('Later'),
                              shape: Border.all(color: Colors.black54),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                            ),
                            new RaisedButton(
                              child: new Text(
                                "Verify",
                                style: new TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              color: globals.buttoncolor,
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                                resendVarification();
                              },
                            ),
                          ],
                        ),
                      ])
                ]))));
  }
  //////////////////////////////////////////////////////////////////

  Future<bool> saveTimeInOutImagePicker_new(MarkTime mk) async {
    String base64Image;
    String base64Image1;
    print('saveTimeInOutImagePicker_new CALLED');
    String location = globalstreamlocationaddr;

    String lat = assign_lat.toString();
    String long = assign_long.toString();
    try {
      ///////////////////////////
      StreamLocation sl = new StreamLocation();
      // sl.startStreaming(5);
      Location _location = new Location();

      ////////////////////////////////suumitted block
      File imagei = null;
      imageCache.clear();
      if (globals.attImage == 1) {
        Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (BuildContext context) => new TakePictureScreen(),
              fullscreenDialog: true,
            )).then((imagei) {
          if (imagei != null) {
            _location.getLocation().then((res) {
              if (res.latitude != '') {
                var addresses = '';
                Geocoder.local
                    .findAddressesFromCoordinates(
                        Coordinates(res.latitude, res.longitude))
                    .then((add) {
                  print(
                      'Location taekn--------------------------------------------------');
                  print(
                      res.latitude.toString() + ' ' + res.longitude.toString());
                  var first = add.first;
                  print("${first.addressLine}");
                  print(
                      'Location taekn--------------------------------------------------');
                  lat = res.latitude.toString();
                  long = res.longitude.toString();

                  //// sending this base64image string +to rest api
                  Dio dio = new Dio();

                  print("saveImage?uid=" +
                      mk.uid +
                      "&location=" +
                      location +
                      "&aid=" +
                      mk.aid +
                      "&act=" +
                      mk.act +
                      "&shiftid=" +
                      mk.shiftid +
                      "&refid=" +
                      mk.refid +
                      "&latit=" +
                      lat +
                      "&longi=" +
                      long);
                  FormData formData = new FormData.from({
                    "uid": mk.uid,
                    "location": location,
                    "aid": mk.aid,
                    "act": mk.act,
                    "shiftid": mk.shiftid,
                    "refid": mk.refid,
                    "latit": lat,
                    "longi": long,
                    "file": new UploadFileInfo(imagei, "image.png"),
                  });
                  print("5");
                  dio
                      .post(globals.path + "saveImage", data: formData)
                      .then((response1) {
                    print('response1: ' + response1.toString());
                    imagei.deleteSync();
                    imageCache.clear();
                    /*getTempImageDirectory();*/
                    Map MarkAttMap = json.decode(response1.data);
                    print('MarkAttMap["status"]: ' +
                        MarkAttMap["status"].toString());
                    if (MarkAttMap["status"] == 1 ||
                        MarkAttMap["status"] == 2) {
                      print("res: " + res.toString());
                      print("issave: " + issave.toString());
                      //     if (issave==true || res==true) {

                      showDialog(
                          context: context,
                          child: new AlertDialog(
                            content:
                                new Text("Attendance marked successfully !"),
                          ));
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MyApp()),
                      );
                      if (mounted)
                        setState(() {
                          act1 = act;
                        });
                    } else {
                      showDialog(
                          context: context,
                          child: new AlertDialog(
                            title: new Text("Warning!"),
                            content: new Text(
                                "Problem while marking attendance, try again."),
                          ));
                      if (mounted)
                        setState(() {
                          act1 = act;
                        });
                    }
                    /* setState(() {
                        issave=true;
                        print('new issave'+issave.toString());
                      });*/
                  }).catchError((err) {
                    print('Exception in setting data in saveImage' +
                        err.toString());
                    return true;
                  });
                });
              } else {
                showDialog(
                    context: context,
                    child: new AlertDialog(
                      title: new Text("Warning!"),
                      content: new Text("Location not fetched..."),
                    ));
              }
            });
            //*****
          } else {
            ///////////////////////////// camera closed by pressing back button

            showDialog(
                context: context,
                child: new AlertDialog(
                  title: new Text("Warning!"),
                  content: new Text("Camera closed improperly"),
                ));
            if (mounted)
              setState(() {
                act1 = act;
              });

            ///////////////////////////// camera closed by pressing back button/
            print("6");
            return false;
          }
          return true;
        }).catchError((err) {
          print('Exception Occured in getting FILE' + err.toString());
          return true;
        });
      } else {
        // block for marking attendance without taking the picture
        _location.getLocation().then((res) {
          if (res.latitude != '') {
            var addresses = '';
            Geocoder.local
                .findAddressesFromCoordinates(
                    Coordinates(res.latitude, res.longitude))
                .then((add) {
              print(
                  'Location taekn 2--------------------------------------------------');
              print(res.latitude.toString() + ' ' + res.longitude.toString());
              var first = add.first;
              print("${first.addressLine}");
              print(
                  'Location taekn 2--------------------------------------------------');
              lat = res.latitude.toString();
              long = res.longitude.toString();

              //// sending this base64image string +to rest api
              Dio dio = new Dio();

              print("--saveImage?uid=" +
                  mk.uid +
                  "&location=" +
                  location +
                  "&aid=" +
                  mk.aid +
                  "&act=" +
                  mk.act +
                  "&shiftid=" +
                  mk.shiftid +
                  "&refid=" +
                  mk.refid +
                  "&latit=" +
                  lat +
                  "&longi=" +
                  long);
              FormData formData = new FormData.from({
                "uid": mk.uid,
                "location": location,
                "aid": mk.aid,
                "act": mk.act,
                "shiftid": mk.shiftid,
                "refid": mk.refid,
                "latit": lat,
                "longi": long,
                //   "file": new UploadFileInfo(imagei, "image.png"),
              });
              print("5");
              dio.post(globals.path + "saveImage", data: formData).then((response1) {
                print('response2: ' + response1.toString());
                //     imagei.deleteSync();
                //    imageCache.clear();
                /*getTempImageDirectory();*/
                Map MarkAttMap = json.decode(response1.data);
                print(
                    'MarkAttMap["status"]: ' + MarkAttMap["status"].toString());
                if (MarkAttMap["status"] == 1 || MarkAttMap["status"] == 2) {
                  print("res: " + res.toString());
                  print("issave: " + issave.toString());
                  //     if (issave==true || res==true) {

                  showDialog(
                      context: context,
                      child: new AlertDialog(
                        content: new Text("Attendance marked successfully !"),
                      ));
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyApp()),
                  );
                  if (mounted)
                    setState(() {
                      act1 = act;
                    });
                } else {
                  showDialog(
                      context: context,
                      child: new AlertDialog(
                        title: new Text("Warning!"),
                        content: new Text(
                            "Problem while marking attendance, try again."),
                      ));
                  if (mounted)
                    setState(() {
                      act1 = act;
                    });
                }
                /* setState(() {
                        issave=true;
                        print('new issave'+issave.toString());
                      });*/
              }).catchError((err) {
                print(
                    'Exception in setting data in saveImage' + err.toString());
                return true;
              });
            });
          } else {
            showDialog(
                context: context,
                child: new AlertDialog(
                  title: new Text("Warning!"),
                  content: new Text("Location not fetched..."),
                ));
          }
        });
        //*****

      }
      ////////////////////////////////suumitted block/
      ///////////////////////////
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
//////////////////////////////////////////////////////////////////
}
