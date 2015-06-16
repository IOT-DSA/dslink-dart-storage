import "dart:async";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

LinkProvider link;

final Map<String, dynamic> CREATE_ENTRY = {
  r"$name": "Create Entry",
  r"$is": "createEntry",
  r"$invokable": "write",
  r"$result": "values",
  r"$params": [
    {
      "name": "name",
      "type": "string"
    },
    {
      "name": "type",
      "type": buildEnumType([
        "string",
        "number",
        "bool",
        "color",
        "gradient",
        "fill",
        "array",
        "map",
        "binary"
      ])
    },
    {
      "name": "editor",
      "type": buildEnumType([
        "none",
        "textarea",
        "password",
        "daterange",
        "date"
      ]),
      "default": "none"
    }
  ],
  r"$columns": []
};

final Map<String, dynamic> CREATE_BUCKET = {
  r"$name": "Create Bucket",
  r"$is": "createBucket",
  r"$invokable": "write",
  r"$result": "values",
  r"$params": [
    {
      "name": "name",
      "type": "string"
    }
  ],
  r"$columns": []
};

final Map<String, dynamic> CLONE_BUCKET = {
  r"$name": "Clone Bucket",
  r"$is": "cloneBucket",
  r"$invokable": "write",
  r"$result": "values",
  r"$params": [
    {
      "name": "name",
      "type": "string"
    }
  ],
  r"$columns": []
};

class StorageNodeProvider extends SimpleNodeProvider implements SerializableNodeProvider, MutableNodeProvider {
  @override
  Map save() {
    var x = super.save();
    x.remove("Create_Bucket");
    x.remove("Create_Entry");
    return x;
  }
}

main(List<String> args) async {
  link = new LinkProvider(args, "Storage-", command: "run", defaultNodes: {
    /*r"$is": "bucket"*/
    "Create_Bucket": CREATE_BUCKET,
    "Create_Entry": CREATE_ENTRY
  }, provider: new StorageNodeProvider(), loadNodesJson: true, profiles: {
    "createBucket": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var name = params["name"];
      var x = new Path(path).parentPath;
      var t = "${x == '/' ? '' : x}/${name}";
      link.addNode(t, {
        r"$is": "bucket"
      });
      isSaveScheduled = true;
    }),
    "cloneBucket": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var tpath = new Path(path);
      var sourceBucket = link[tpath.parentPath];
      var targetBucketPath = new Path(tpath.parentPath).parentPath;
      var name = params["name"];

      var npath = "${targetBucketPath == '/' ? '' : targetBucketPath}/${name}";

      link.addNode(npath, sourceBucket.save());
      isSaveScheduled = true;
    }),
    "delete": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var p = new Path(path).parentPath;
      link.removeNode(p);
      if (listeners.containsKey(p)) {
        listeners[p].cancel();
        listeners.remove(p);
      }
      isSaveScheduled = true;
      return {};
    }),
    "createEntry": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var name = params["name"];
      var type = params["type"];
      var editor = params["editor"];

      var x = new Path(path).parentPath;

      var p = "${x == '/' ? '' : x}/${name}";

      var map = {
        r"$is": "entry",
        r"$type": type,
        r"$writable": "write"
      };

      if (editor != null && editor != "none") {
        map[r"$editor"] = editor;
      }

      link.addNode(p, map);

      isSaveScheduled = true;
    }),
    "bucket": (String path) {
      link.removeNode("${path}/Create_Bucket");
      link.removeNode("${path}/Create_Entry");
      link.removeNode("${path}/Clone_Bucket");
      link.removeNode("${path}/Delete_Bucket");

      link.addNode("${path}/Create_Bucket", CREATE_BUCKET);
      link.addNode("${path}/Create_Entry", CREATE_ENTRY);
      link.addNode("${path}/Clone_Bucket", CLONE_BUCKET);

      link.addNode("${path}/Delete_Bucket", {
        r"$name": "Delete Bucket",
        r"$is": "delete",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [],
        r"$columns": []
      });

      return new BucketNode(path);
    },
    "entry": (String path) => new EntryNode(path)
  }, autoInitialize: false);

  (link.provider as StorageNodeProvider).init(null, link.profiles);

  link.init();

  link.removeNode("/Create_Bucket");
  link.removeNode("/Create_Entry");

  link.addNode("/Create_Bucket", CREATE_BUCKET);
  link.addNode("/Create_Entry", CREATE_ENTRY);

  timer = new Timer.periodic(new Duration(seconds: 1), (_) async {
    if (isSaveScheduled) {
      await link.saveAsync();
      isSaveScheduled = false;
    }
  });

  isSaveScheduled = true;
  link.connect();
}

bool isSaveScheduled = false;

Timer timer;

class BucketNode extends SimpleNode {
  BucketNode(String path) : super(path);

  @override
  void onCreated() {
    link.addNode("${path}/Create_Bucket", CREATE_BUCKET);
    link.addNode("${path}/Create_Entry", CREATE_ENTRY);
    link.addNode("${path}/Clone_Bucket", CLONE_BUCKET);

    link.addNode("${path}/Delete_Bucket", {
      r"$name": "Delete Bucket",
      r"$is": "delete",
      r"$invokable": "write",
      r"$result": "values",
      r"$params": [],
      r"$columns": []
    });
  }

  @override
  Map save([bool clean = true]) {
    var x = super.save();
    if (clean) {
      x.remove("Create_Bucket");
      x.remove("Create_Entry");
      x.remove("Clone_Bucket");
      x.remove("Delete_Bucket");
    }
    return x;
  }
}

class EntryNode extends SimpleNode {
  EntryNode(String path) : super(path);

  @override
  void onCreated() {
    link.addNode("${path}/Create_Bucket", CREATE_BUCKET);
    link.addNode("${path}/Create_Entry", CREATE_ENTRY);
    link.addNode("${path}/Clone", CLONE_BUCKET);

    link.removeNode("${path}/Delete_Entry");

    link.addNode("${path}/Delete_Entry", {
      r"$name": "Delete Entry",
      r"$is": "delete",
      r"$invokable": "write",
      r"$result": "values",
      r"$params": [],
      r"$columns": []
    });

    listeners[path] = link.onValueChange(path).listen((x) async {
      isSaveScheduled = true;
    });
  }

  @override
  Map save([bool clean = true]) {
    var x = super.save();
    if (clean) {
      x.remove("Create_Bucket");
      x.remove("Create_Entry");
      x.remove("Clone_Bucket");
      x.remove("Delete_Bucket");
      x.remove("Delete_Entry");
    }
    return x;
  }
}

Map<String, StreamSubscription> listeners = {};
