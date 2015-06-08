import "dart:async";

import "package:dslink/dslink.dart";
import "package:dslink/nodes.dart";

LinkProvider link;

main(List<String> args) async {
  link = new LinkProvider(args, "Storage-", command: "run", defaultNodes: {
    r"$is": "bucket"
  }, profiles: {
    "createBucket": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var name = params["name"];
      var x = new Path(path).parentPath;
      var t = "${x}/${name}";
      link.addNode(t, {
        r"$is": "bucket"
      });
      link.save();
    }),
    "delete": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var p = new Path(path).parentPath;
      link.removeNode(p);
      if (listeners.containsKey(p)) {
        listeners[p].cancel();
        listeners.remove(p);
      }
      link.save();
      return {};
    }),
    "createEntry": (String path) => new SimpleActionNode(path, (Map<String, dynamic> params) {
      var name = params["name"];
      var type = params["type"];

      var p = "${new Path(path).parentPath}/${name}";

      link.addNode(p, {
        r"$is": "entry",
        r"$type": type,
        r"$writable": "write"
      });

      link.save();
    }),
    "bucket": (String path) => new BucketNode(path),
    "entry": (String path) => new EntryNode(path)
  });

  link.connect();
}

class BucketNode extends SimpleNode {
  BucketNode(String path) : super(path);

  @override
  onCreated() {
    link.removeNode("${path}/Create_Bucket");
    link.removeNode("${path}/Create_Entry");
    link.removeNode("${path}/Delete_Bucket");

    link.addNode("${path}/Create_Bucket", {
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
    });

    link.addNode("${path}/Create_Entry", {
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
            "map"
          ])
        }
      ],
      r"$columns": []
    });

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
  Map save() {
    var x = super.save();
    x.remove("Create_Bucket");
    x.remove("Create_Entry");
    x.remove("Delete_Bucket");
    return x;
  }
}

class EntryNode extends SimpleNode {
  EntryNode(String path) : super(path);

  @override
  onCreated() {
    link.removeNode("${path}/Delete_Entry");

    link.addNode("${path}/Delete_Entry", {
      r"$name": "Delete Entry",
      r"$is": "delete",
      r"$invokable": "write",
      r"$result": "values",
      r"$params": [],
      r"$columns": []
    });

    listeners[path] = link.onValueChange(path).listen((x) {
      link.save();
    });
  }

  @override
  Map save() {
    var x = super.save();
    x.remove("Delete_Entry");
    return x;
  }
}

Map<String, StreamSubscription> listeners = {};
