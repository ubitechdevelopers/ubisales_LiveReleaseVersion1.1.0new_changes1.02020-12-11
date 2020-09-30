import 'package:Shrine/globals.dart' as prefix0;
import 'package:Shrine/services/services.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Bottomnavigationbar.dart';
import 'Image_view.dart';
import 'drawer.dart';
import 'globals.dart';

class FlexiReport extends StatefulWidget {
  @override
  _FlexiReport createState() => _FlexiReport();
}

TextEditingController today;
String _orgName = "";
//FocusNode f_dept ;
class _FlexiReport extends State<FlexiReport> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  int _currentIndex = 1;
  String emp='0';
  String admin_sts='0';
  bool res = true;
  var formatter = new DateFormat('dd-MMM-yyyy');

  @override
  void initState() {
    super.initState();
    checkNetForOfflineMode(context);

    today = new TextEditingController();
    today.text = formatter.format(DateTime.now());
    // f_dept = FocusNode();
    getOrgName();
  }

  getOrgName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _orgName = prefs.getString('org_name') ?? '';
      admin_sts = prefs.getString('sstatus') ?? '0';
    });
  }

  void showInSnackBar(String value) {
    final snackBar = SnackBar(
        content: Text(
          value,
          textAlign: TextAlign.center,
        ));
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return getmainhomewidget();
  }

  getmainhomewidget() {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text(_orgName, style: new TextStyle(fontSize: 20.0)),

            /*  Image.asset(
                    'assets/logo.png', height: 40.0, width: 40.0),*/
          ],
        ),
        automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            }),
        backgroundColor: appcolor,
      ),
      bottomNavigationBar: Bottomnavigationbar(),
      endDrawer: new AppDrawer(),
      body: Container(
        //   padding: EdgeInsets.only(left: 2.0, right: 2.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 8.0),
            Center(
              child: Text(
                'Flexi Attendance',
                style: new TextStyle(
                  fontSize: 22.0,
                  color: appcolor,
                ),
              ),
            ),
            Divider(color: Colors.black54,height: 1.5,),
//            Divider(
//              height: 10.0,
//            ),
            getEmployee_DD(),
            SizedBox(height: 2.0),
            Container(
              child: DateTimeField(
                //dateOnly: true,
                format: formatter,
                controller: today,
                onShowPicker: (context, currentValue) {
                  return showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      initialDate: currentValue ?? DateTime.now(),
                      lastDate: DateTime.now());

                },
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(0.0),
                    child: Icon(
                      Icons.date_range,
                      color: Colors.grey,
                    ), // icon is 48px widget.
                  ), // icon is 48px widget.
                  labelText: 'Select Date',
                ),
                onChanged: (date) {
                  setState(() {
                    if (date != null && date.toString() != '')
                      res = true; //showInSnackBar(date.toString());
                    else
                      res = false;
                  });
                },
                validator: (date) {
                  if (date == null) {
                    return 'Please select date';
                  }
                },
              ),
            ),
            SizedBox(height: 12.0),
            Container(
              //  padding: EdgeInsets.only(bottom:10.0,top: 10.0),
              //       width: MediaQuery.of(context).size.width * .9,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(width: 1.0,),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.23,
                    child: Text(
                      'Name',
                      style: TextStyle(color: appcolor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.37,
                    child: Text(
                      'Location',
                      style: TextStyle(color: appcolor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.17,
                    child: Text('In',
                        style: TextStyle(color: appcolor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0),
                        textAlign: TextAlign.left),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: Text('Out ',
                        style: TextStyle(color: appcolor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0),
                        textAlign: TextAlign.left),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5.0),
            Divider(
              height: 5.2,
            ),
            SizedBox(height: 5.0),
            new Expanded(
              child: res == true ? getEmpDataList(today.text) : Center(child: Container(
                  height: MediaQuery.of(context).size.height*0.30,
                  child:Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width*1,
                      color: appcolor.withOpacity(0.1),
                      padding:EdgeInsets.only(top:5.0,bottom: 5.0),
                      child:Text("Please select the date",style: TextStyle(fontSize: 18.0),textAlign: TextAlign.center,),
                    ),
                  )
              ),),
            ),
          ],
        ),
      ),
    );
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


  Widget getEmployee_DD() {
    String dc = "0";
    return new FutureBuilder<List<Map>>(
        future: getEmployeesList(1),// with -select- label
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            try {
              return new Container(
                //    width: MediaQuery.of(context).size.width*.45,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Select an employee',
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(1.0),
                      child: Icon(
                        Icons.person,
                        color: Colors.grey,
                      ), // icon is 48px widget.
                    ),
                  ),

                  child: new DropdownButton<String>(
                    isDense: true,
                    style: new TextStyle(
                        fontSize: 15.0,
                        color: Colors.black
                    ),
                    value: emp,
                    onChanged: (String newValue) {
                      setState(() {
                        emp = newValue;
                        res = true;

                      });


                    },
                    items: snapshot.data.map((Map map) {
                      return new DropdownMenuItem<String>(
                        value: map["Id"].toString(),
                        child: new SizedBox(
                            width: MediaQuery.of(context).size.width * 0.80,
                            child: map["Code"]!=''?new Text('('+map["Code"]+') '+map["Name"]):
                            new Text(map["Name"],)),
                      );
                    }).toList(),

                  ),
                ),
              );
            }
            catch(e){
              return Text("EX: Unable to fetch employees");

            }
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return new Text("ER: Unable to fetch employees");
          }
          // return loader();
          return new Center(child: SizedBox(
            child: CircularProgressIndicator(strokeWidth: 2.2,),
            height: 20.0,
            width: 20.0,
          ),);
        });
  }


  getEmpDataList(date) {
    return new FutureBuilder<List<FlexiAtt>>(
        future: getFlexiDataListReport(date,emp),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0) {
              return new ListView.builder(
                  itemCount: snapshot.data.length,
                  //    padding: EdgeInsets.only(left: 15.0,right: 15.0),
                  itemBuilder: (BuildContext context, int index) {
                    return new Container(
                      //          width: MediaQuery.of(context).size.width * .9,
                      child:Column(children: <Widget>[
                        new Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment : MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            SizedBox(width: 8.0,),
                            new Container(
                                width: MediaQuery.of(context).size.width * 0.18,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    new Text(
                                      snapshot.data[index].Emp.toString(),style: TextStyle(fontWeight: FontWeight.bold),textAlign: TextAlign.left,),
                                  ],
                                )),
                            new Container(
                              width: MediaQuery.of(context).size.width * 0.37,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  /* new Text(
                                    snapshot.data[index].client.toString(),style: TextStyle(fontWeight: FontWeight.bold),textAlign: TextAlign.left,
                                  ),*/
                                  InkWell(
                                    child:Text("In: "+
                                        snapshot.data[index].pi_loc.toString(),style: TextStyle(color: Colors.black54,fontSize: 12.0),),
                                    onTap: () {
                                      goToMap(snapshot.data[index].pi_latit,snapshot.data[index].pi_longi.toString());
                                      },
                                  ),
                                  InkWell(
                                    child:Text("Out: "+
                                    snapshot.data[index].po_loc.toString(),
                                    style: TextStyle
                                    (
                                    color: Colors.black54,fontSize: 12.0
                                    ),
                                    ),
                                    onTap: ()
                                    {
                                    goToMap(
                                          snapshot.data[index].po_latit.toString(),
                                          snapshot.data[index].po_longi.toString()
                                          );
                                        },
                                  ),
                                ],
                              ),
                           ),
                            Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.19,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(snapshot.data[index].pi_time
                                        .toString(),style: TextStyle(fontWeight: FontWeight.bold),),
                                    Container(
                                      width: 62.0,
                                      height: 62.0,
                                      child:InkWell(
                                        child: Container(
                                            decoration: new BoxDecoration(
                                            shape: BoxShape .circle,
                                              image: new DecorationImage(
                                              fit: BoxFit.fill,
                                              image: new NetworkImage(snapshot.data[index].pi_img)
                                              )
                                            )),
                                        onTap: ()
                                        {

                                        Navigator.push(
                                        context, MaterialPageRoute(builder: (context) => ImageView(myimage: snapshot.data[index].pi_img,org_name: _orgName)),
                                        );

                                       },
                                      ),
                                    ),
                                    Text(snapshot.data[index].timeindate
                                        .toString(),style: TextStyle(color: Colors.grey),),
                                  ],
                                )

                            ),
                            Container(
                                width: MediaQuery
                                    .of(context)
                                    .size
                                    .width * 0.22,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center,
                                  children: <Widget>[
                                    Text(snapshot.data[index].po_time
                                        .toString(),style: TextStyle(fontWeight: FontWeight.bold),),
                                    Container(
                                      width: 62.0,
                                      height: 62.0,
                                      child:InkWell(
                                        child: Container(
                                            decoration: new BoxDecoration(
                                                shape: BoxShape
                                                    .circle,
                                                image: new DecorationImage(
                                                    fit: BoxFit.fill,
                                                    image: new NetworkImage(
                                                    snapshot.data[index].po_img)
                                                )
                                            )),
                                        onTap: ()
                                        {
                                          Navigator.push(context,MaterialPageRoute(builder: (context) => ImageView(myimage: snapshot.data[index].po_img,org_name: _orgName)),
                                       );

                                       },
                                      ),
                                    ),
                                    Text(snapshot.data[index].timeoutdate .toString(),style: TextStyle(color: Colors.grey
                                    ),),
                                  ],
                                )

                            ),
                          ],
                        ),

                        Divider
                          (
                          color: Colors.blueGrey.withOpacity(0.25),
                          height: 0.2,
                         ),
                      ]),
                    );
                  });
                }
             else
              {

                return new Container(
                    height: MediaQuery.of(context).size.height*0.30,
                    child:Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width*1,
                        color: appcolor.withOpacity(0.1),
                        padding:EdgeInsets.only(top:5.0,bottom: 5.0),
                        child:Text("No Attendance",style: TextStyle(fontSize: 18.0),textAlign: TextAlign.center,),
                      ),
                    )
                );
            }
          }
          else if (snapshot.hasError)
          {
            return new Text("Unable to connect server");
          }
          // return loader();
          return new Center(child: CircularProgressIndicator());
        });
  }
} /////////mail class close
