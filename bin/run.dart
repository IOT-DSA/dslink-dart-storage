import "package:dslink/client.dart";
import "package:dslink/responder.dart";

LinkProvider link;

main(List<String> args) async {
  link = new LinkProvider(args, "Storage-", command: "run", defaultNodes: {
    "Create Bucket": {
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
    }
  }, profiles: {
    "createBucket": (String path) => new CreateBucketNode(path),
    "deleteBucket": (String path) => new DeleteNode(path, 1),
    "createEntry": (String path) => new CreateEntryNode(path),
    "deleteEntry": (String path) => new DeleteNode(path, 2)
  });

  if (link.link == null) return;

  link.connect();
}

class CreateBucketNode extends SimpleNode {
  CreateBucketNode(String name) : super(name);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    if (params["name"] == null) return {};

    var name = params["name"];

    link.addNode("/${name}", {
      "Create Entry": {
        r"$is": "createEntry",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [
          {
            "name": "key",
            "type": "string"
          },
          {
            "name": "type",
            "type": "string"
          }
        ],
        r"$columns": []
      },
      "Delete Bucket": {
        r"$is": "deleteBucket",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [],
        r"$columns": []
      }
    });

    link.save();
    return {};
  }
}

class CreateEntryNode extends SimpleNode {
  CreateEntryNode(String path) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    if (params["key"] == null || params["type"] == null) {
      return {};
    }

    var key = params["key"];
    var type = params["type"];

    SimpleNode holder = link.provider.getNode(path.split("/").take(2).join("/"));
    link.provider.addNode("${holder.path}/${key}", {
      "Delete Entry": {
        r"$is": "deleteEntry",
        r"$invokable": "write",
        r"$result": "values",
        r"$params": [],
        r"$columns": []
      },
      r"$type": type,
      r"$writable": "write",
      "?value": null
    });

    listeners["${holder.path}/${key}"] = (link.provider.getNode("${holder.path}/${key}") as SimpleNode).subscribe((value) {
      link.save();
    });

    link.save();
    return {};
  }
}

Map<String, RespSubscribeListener> listeners = {};

class DeleteNode extends SimpleNode {
  final int parts;

  DeleteNode(String path, this.parts) : super(path);

  @override
  Object onInvoke(Map<String, dynamic> params) {
    var p = path.split("/").take(parts + 1).join("/");
    link.removeNode(p);
    if (listeners.containsKey(p)) {
      listeners[p].cancel();
      listeners.remove(p);
    }
    link.save();
    return {};
  }
}
