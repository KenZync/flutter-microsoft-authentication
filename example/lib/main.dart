import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter_microsoft_authentication/flutter_microsoft_authentication.dart';

void main() => runApp(OneDrive());
var fileDriveList = List<Value>();

class OneDrive extends StatefulWidget {
  @override
  _OneDriveState createState() => _OneDriveState();
}

class _OneDriveState extends State<OneDrive> {
  String _graphURI = "https://graph.microsoft.com/v1.0/me/";

  String _authToken = 'Unknown Auth Token';
  String _username = 'No Account';
  String _msProfile = 'Unknown Profile';
  String _msOneDrive = 'No OneDrive';

  FlutterMicrosoftAuthentication fma;
  ClassOneDrive onedrive;
  @override
  void initState() {
    super.initState();

    fma = FlutterMicrosoftAuthentication(
        kClientID: "<client-id>",
        kAuthority: "https://login.microsoftonline.com/organizations",
        kScopes: [
          "User.Read",
          "User.ReadBasic.All",
          "Sites.ReadWrite.All",
          "Files.ReadWrite.All"
        ],
        androidConfigAssetPath: "assets/android_auth_config.json");
    print('INITIALIZED FMA');
  }

  Future<void> _acquireTokenInteractively() async {
    String authToken;
    try {
      authToken = await this.fma.acquireTokenInteractively;
    } on PlatformException catch (e) {
      authToken = 'Failed to get token.';
      print(e.message);
    }
    setState(() {
      _authToken = authToken;
    });
  }

  Future<void> _acquireTokenSilently() async {
    String authToken;
    try {
      authToken = await this.fma.acquireTokenSilently;
    } on PlatformException catch (e) {
      authToken = 'Failed to get token silently.';
      print(e.message);
    }
    setState(() {
      _authToken = authToken;
    });
  }

  Future<void> _signOut() async {
    String authToken;
    try {
      authToken = await this.fma.signOut;
    } on PlatformException catch (e) {
      authToken = 'Failed to sign out.';
      print(e.message);
    }
    setState(() {
      _authToken = authToken;
    });
  }

  Future<String> _loadAccount() async {
    String username = await this.fma.loadAccount;
    setState(() {
      _username = username;
    });
  }

  _fetchMicrosoftProfile() async {
    var response = await http.get(this._graphURI,
        headers: {"Authorization": "Bearer " + this._authToken});

    setState(() {
      _msProfile = json.decode(response.body).toString();
    });
  }

  //fetchOneDrive
  _fetchOneDrive() async {
    var response = await http.get((this._graphURI) + "drive/root/children",
        headers: {"Authorization": "Bearer " + this._authToken});

    var jsonData = json.decode(response.body);
    onedrive = new ClassOneDrive.fromJson(jsonData);

    var filelist;
    onedrive.value.forEach((element) {
      if (filelist == null) {
        filelist = "${element.name}";
      } else {
        filelist = "$filelist, ${element.name}";
      }
    });
    setState(() {
      // _msOneDrive = json.decode(response.body).toString();
      _msOneDrive = filelist;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Microsoft Authentication'),
          ),
          body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  RaisedButton(
                    onPressed: _acquireTokenInteractively,
                    child: Text('Acquire Token'),
                  ),
                  RaisedButton(
                      onPressed: _acquireTokenSilently,
                      child: Text('Acquire Token Silently')),
                  RaisedButton(onPressed: _signOut, child: Text('Sign Out')),
                  RaisedButton(
                      onPressed: _fetchMicrosoftProfile,
                      child: Text('Fetch Profile')),
                  RaisedButton(
                      onPressed: _fetchOneDrive, child: Text('Fetch OneDrive')),
                  if (Platform.isAndroid == true)
                    RaisedButton(
                        onPressed: _loadAccount, child: Text('Load account')),
                  SizedBox(
                    height: 8,
                  ),
                  Builder(
                    builder: (context) => RaisedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    OneDrivePage(oneDrive: onedrive)));
                      },
                      child: Text('OneDrive Lists'),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  if (Platform.isAndroid == true) Text("Username: $_username"),
                  SizedBox(
                    height: 8,
                  ),
                  Text("Profile: $_msProfile"),
                  SizedBox(
                    height: 8,
                  ),
                  Text("One Drive: $_msOneDrive"),
                  SizedBox(
                    height: 8,
                  ),
                  Text("Token: $_authToken"),
                ],
              ),
            ),
          )),
    );
  }
}

class OneDrivePage extends StatelessWidget {
  final ClassOneDrive oneDrive;
  const OneDrivePage({Key key, this.oneDrive}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final filteredOneDrive =
        oneDrive.value.where((e) => e.name.endsWith(".db")).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text("One Drive"),
      ),
      body: new ListView.builder(
        itemCount: oneDrive == null ? 0 : filteredOneDrive.length,
        itemBuilder: (BuildContext context, int index) {
          return new Container(
            child: new Center(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  new Card(
                      child: new Container(
                          child: new Text(filteredOneDrive[index].name),
                          padding: const EdgeInsets.all(20.0)))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// class SecondRoute extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Second Route"),
//       ),
//       body: Center(
//         child: RaisedButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           child: Text('Go back!'),
//         ),
//       ),
//     );
//   }
// }

// To parse this JSON data, do
//
//     final oneDrive = oneDriveFromJson(jsonString);

// OneDrive oneDriveFromJson(String str) => OneDrive.fromJson(json.decode(str));
// String oneDriveToJson(OneDrive data) => json.encode(data.toJson());
class ClassOneDrive {
  ClassOneDrive({
    this.odataContext,
    this.value,
  });

  final String odataContext;
  final List<Value> value;

  factory ClassOneDrive.fromJson(Map<String, dynamic> json) => ClassOneDrive(
        odataContext: json["@odata.context"],
        value: List<Value>.from(json["value"].map((x) => Value.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "@odata.context": odataContext,
        "value": List<dynamic>.from(value.map((x) => x.toJson())),
      };
}

class Value {
  Value({
    this.createdDateTime,
    this.eTag,
    this.id,
    this.lastModifiedDateTime,
    this.name,
    this.webUrl,
    this.cTag,
    this.size,
    this.createdBy,
    this.lastModifiedBy,
    this.parentReference,
    this.fileSystemInfo,
    this.folder,
    this.microsoftGraphDownloadUrl,
    this.file,
    this.shared,
  });

  final DateTime createdDateTime;
  final String eTag;
  final String id;
  final DateTime lastModifiedDateTime;
  final String name;
  final String webUrl;
  final String cTag;
  final int size;
  final EdBy createdBy;
  final EdBy lastModifiedBy;
  final ParentReference parentReference;
  final FileSystemInfo fileSystemInfo;
  final Folder folder;
  final String microsoftGraphDownloadUrl;
  final FileClass file;
  final Shared shared;

  factory Value.fromJson(Map<String, dynamic> json) => Value(
        createdDateTime: DateTime.parse(json["createdDateTime"]),
        eTag: json["eTag"],
        id: json["id"],
        lastModifiedDateTime: DateTime.parse(json["lastModifiedDateTime"]),
        name: json["name"],
        webUrl: json["webUrl"],
        cTag: json["cTag"],
        size: json["size"],
        createdBy: EdBy.fromJson(json["createdBy"]),
        lastModifiedBy: EdBy.fromJson(json["lastModifiedBy"]),
        parentReference: ParentReference.fromJson(json["parentReference"]),
        fileSystemInfo: FileSystemInfo.fromJson(json["fileSystemInfo"]),
        folder: json["folder"] == null ? null : Folder.fromJson(json["folder"]),
        microsoftGraphDownloadUrl: json["@microsoft.graph.downloadUrl"] == null
            ? null
            : json["@microsoft.graph.downloadUrl"],
        file: json["file"] == null ? null : FileClass.fromJson(json["file"]),
        shared: json["shared"] == null ? null : Shared.fromJson(json["shared"]),
      );

  Map<String, dynamic> toJson() => {
        "createdDateTime": createdDateTime.toIso8601String(),
        "eTag": eTag,
        "id": id,
        "lastModifiedDateTime": lastModifiedDateTime.toIso8601String(),
        "name": name,
        "webUrl": webUrl,
        "cTag": cTag,
        "size": size,
        "createdBy": createdBy.toJson(),
        "lastModifiedBy": lastModifiedBy.toJson(),
        "parentReference": parentReference.toJson(),
        "fileSystemInfo": fileSystemInfo.toJson(),
        "folder": folder == null ? null : folder.toJson(),
        "@microsoft.graph.downloadUrl": microsoftGraphDownloadUrl == null
            ? null
            : microsoftGraphDownloadUrl,
        "file": file == null ? null : file.toJson(),
        "shared": shared == null ? null : shared.toJson(),
      };
}

class EdBy {
  EdBy({
    this.user,
    this.application,
  });

  final User user;
  final Application application;

  factory EdBy.fromJson(Map<String, dynamic> json) => EdBy(
        user: User.fromJson(json["user"]),
        application: json["application"] == null
            ? null
            : Application.fromJson(json["application"]),
      );

  Map<String, dynamic> toJson() => {
        "user": user.toJson(),
        "application": application == null ? null : application.toJson(),
      };
}

class Application {
  Application({
    this.id,
    this.displayName,
  });

  final String id;
  final String displayName;

  factory Application.fromJson(Map<String, dynamic> json) => Application(
        id: json["id"],
        displayName: json["displayName"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "displayName": displayName,
      };
}

class User {
  User({
    this.email,
    this.id,
    this.displayName,
  });

  final String email;
  final String id;
  final String displayName;

  factory User.fromJson(Map<String, dynamic> json) => User(
        email: json["email"],
        id: json["id"],
        displayName: json["displayName"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "id": id,
        "displayName": displayName,
      };
}

class FileClass {
  FileClass({
    this.mimeType,
    this.hashes,
  });

  final String mimeType;
  final Hashes hashes;

  factory FileClass.fromJson(Map<String, dynamic> json) => FileClass(
        mimeType: json["mimeType"],
        hashes: Hashes.fromJson(json["hashes"]),
      );

  Map<String, dynamic> toJson() => {
        "mimeType": mimeType,
        "hashes": hashes.toJson(),
      };
}

class Hashes {
  Hashes({
    this.quickXorHash,
  });

  final String quickXorHash;

  factory Hashes.fromJson(Map<String, dynamic> json) => Hashes(
        quickXorHash: json["quickXorHash"],
      );

  Map<String, dynamic> toJson() => {
        "quickXorHash": quickXorHash,
      };
}

class FileSystemInfo {
  FileSystemInfo({
    this.createdDateTime,
    this.lastModifiedDateTime,
  });

  final DateTime createdDateTime;
  final DateTime lastModifiedDateTime;

  factory FileSystemInfo.fromJson(Map<String, dynamic> json) => FileSystemInfo(
        createdDateTime: DateTime.parse(json["createdDateTime"]),
        lastModifiedDateTime: DateTime.parse(json["lastModifiedDateTime"]),
      );

  Map<String, dynamic> toJson() => {
        "createdDateTime": createdDateTime.toIso8601String(),
        "lastModifiedDateTime": lastModifiedDateTime.toIso8601String(),
      };
}

class Folder {
  Folder({
    this.childCount,
  });

  final int childCount;

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        childCount: json["childCount"],
      );

  Map<String, dynamic> toJson() => {
        "childCount": childCount,
      };
}

class ParentReference {
  ParentReference({
    this.driveId,
    this.driveType,
    this.id,
    this.path,
  });

  final String driveId;
  final String driveType;
  final String id;
  final String path;

  factory ParentReference.fromJson(Map<String, dynamic> json) =>
      ParentReference(
        driveId: json["driveId"],
        driveType: json["driveType"],
        id: json["id"],
        path: json["path"],
      );

  Map<String, dynamic> toJson() => {
        "driveId": driveId,
        "driveType": driveType,
        "id": id,
        "path": path,
      };
}

class Shared {
  Shared({
    this.scope,
  });

  final String scope;

  factory Shared.fromJson(Map<String, dynamic> json) => Shared(
        scope: json["scope"],
      );

  Map<String, dynamic> toJson() => {
        "scope": scope,
      };
}
